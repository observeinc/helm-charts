#!/usr/bin/env bash
# Generates the plain OpenTelemetry Collector configurations in kubernetes/ from the Observe Agent
# Helm chart: renders the chart with kubernetes/reference-values.yaml, takes the collector config
# of each component, drops debug-only exporters, and replaces the variables that the observe-agent
# binary sets at startup with variables a plain collector can be given.
#
# Requires helm and yq (https://github.com/mikefarah/yq). Run through `make generate-oss-examples`.
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$dir/../.." && pwd)
out_dir="$dir/kubernetes"
values="$out_dir/reference-values.yaml"

manifest=$(mktemp)
trap 'rm -f "$manifest"' EXIT
helm template oss-example "$repo/charts/agent" --namespace observe --values "$values" > "$manifest"

reference_url=$(yq '.observe.collectionEndpoint.value | sub("/$"; "")' "$values")
reference_token=$(yq '.observe.token.value' "$values")
reference_environment=$(yq '.cluster.deploymentEnvironment.name' "$values")

# Descriptions for every environment variable the generated configurations may reference. The
# generator fails on a variable that isn't listed here, so new chart variables get documented.
describe_env() {
  case "$1" in
    OBSERVE_COLLECTION_URL) echo "Your collection URL, e.g. https://123456789012.collect.observeinc.com" ;;
    OBSERVE_TOKEN) echo "An Observe ingest token" ;;
    OBSERVE_CLUSTER_NAME) echo "The cluster name, set as k8s.cluster.name" ;;
    OBSERVE_CLUSTER_UID) echo "The UID of the kube-system namespace: kubectl get namespace kube-system -o jsonpath='{.metadata.uid}'" ;;
    DEPLOYMENT_ENVIRONMENT) echo "Fallback deployment.environment.name for telemetry that does not set one" ;;
    MY_POD_IP) echo "The collector pod's IP address (downward API: status.podIP)" ;;
    K8S_NODE_NAME) echo "The node the collector pod runs on (downward API: spec.nodeName)" ;;
    *) return 1 ;;
  esac
}

# generate <ConfigMap name> <output file> <description>
generate() {
  local configmap=$1 out="$out_dir/$2" description=$3
  local config
  config=$(yq -e "select(.kind == \"ConfigMap\" and .metadata.name == \"$configmap\").data.relay" "$manifest")
  config=$(yq '
    del(.exporters."debug/override") |
    (.service.pipelines[].exporters) |= map(select(. != "debug/override"))
  ' <<< "$config")
  config=$(REF_ENV="$reference_environment" perl -pe '
    s/\$\{env:OBSERVE_OTEL_ENDPOINT\}/\${env:OBSERVE_COLLECTION_URL}\/v2\/otel/g;
    s/\$\{env:OBSERVE_PROMETHEUS_ENDPOINT\}/\${env:OBSERVE_COLLECTION_URL}\/v1\/prometheus/g;
    s/\$\{env:OBSERVE_COLLECTOR_URL\}/\${env:OBSERVE_COLLECTION_URL}/g;
    s/\$\{env:OBSERVE_AUTHORIZATION_HEADER\}/Bearer \${env:OBSERVE_TOKEN}/g;
    s/Bearer \$\{env:TRACE_TOKEN\}/Bearer \${env:OBSERVE_TOKEN}/g;
    s/\Q$ENV{REF_ENV}\E/\${env:DEPLOYMENT_ENVIRONMENT}/g;
  ' <<< "$config")

  for leftover in "$reference_url" "$reference_token" "$reference_environment" "oss-example"; do
    if grep -qF "$leftover" <<< "$config"; then
      echo "error: $2 still contains the reference value \"$leftover\"" >&2
      return 1
    fi
  done

  {
    echo "# $description"
    echo "#"
    echo "# GENERATED FILE, DO NOT EDIT. This file is generated from the Observe Agent Helm chart with"
    echo "# reference-values.yaml. Run \"make generate-oss-examples\" to regenerate it."
    echo "#"
    echo "# Set these environment variables on the collector container:"
    local var
    for var in $(grep -oE '\$\{env:[A-Z0-9_]+\}' <<< "$config" | sed -E 's/\$\{env:([A-Z0-9_]+)\}/\1/' | sort -u); do
      if ! describe_env "$var" > /dev/null; then
        echo "error: $2 references \${env:$var}; add a description for it to describe_env in $0" >&2
        return 1
      fi
      printf '#   %-24s %s\n' "$var" "$(describe_env "$var")"
    done
    echo "$config"
  } > "$out"
}

generate forwarder forwarder.yaml \
  "DaemonSet collector that receives application traces, logs, and metrics over OTLP and generates RED metrics."
generate node-logs-metrics node.yaml \
  "DaemonSet collector for container logs, kubelet stats, and node metrics."
generate cluster-metrics cluster-metrics.yaml \
  "Single-replica Deployment collector for cluster-level Kubernetes metrics."
