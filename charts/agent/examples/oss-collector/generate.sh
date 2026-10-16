#!/usr/bin/env bash
# Generates plain OpenTelemetry Collector configurations in collector/ from this example's rendered
# chart output (rendered/, written by `make generate-examples`, which also runs this script).
#
# For each entry in collectors.yaml it takes the collector ConfigMap's configuration, merges
# otel-config.yaml on top, keeps only the listed pipelines and extensions, and deletes every
# component they don't use. A connector is only kept when a kept pipeline is on both sides of it.
#
# Requires yq (https://github.com/mikefarah/yq).
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
out_dir="$dir/collector"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/collector"

# Descriptions for every environment variable a generated configuration may reference. The
# generator fails on a variable that isn't listed here, which catches chart variables that a plain
# collector doesn't set (otel-config.yaml should replace those) and documents new ones.
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

# prune <config file> <pipelines JSON list> <extensions JSON list>: prints the pruned config.
prune() {
  KEEP_PIPELINES=$2 KEEP_EXTENSIONS=$3 yq '
    env(KEEP_PIPELINES) as $keep |
    env(KEEP_EXTENSIONS) as $exts |
    .service.pipelines |= with_entries(.key as $k | select($keep | any_c(. == $k))) |

    ((.connectors // {}) | keys) as $conns |
    [.service.pipelines[].exporters[]] as $exported |
    [.service.pipelines[].receivers[]] as $received |
    ($conns | map(. as $id | select(($exported | any_c(. == $id)) and ($received | any_c(. == $id))))) as $usable |
    (.service.pipelines[].receivers, .service.pipelines[].exporters) |=
      map(. as $id | select((($conns | any_c(. == $id)) | not) or ($usable | any_c(. == $id)))) |

    [.service.pipelines[].receivers[]] as $r |
    [.service.pipelines[].processors[]] as $p |
    [.service.pipelines[].exporters[]] as $e |
    .receivers = ((.receivers // {}) | with_entries(.key as $k | select($r | any_c(. == $k)))) |
    .processors = ((.processors // {}) | with_entries(.key as $k | select($p | any_c(. == $k)))) |
    .exporters = ((.exporters // {}) | with_entries(.key as $k | select($e | any_c(. == $k)))) |
    .connectors = ((.connectors // {}) | with_entries(.key as $k | select(($r + $e) | any_c(. == $k)))) |
    .extensions = ((.extensions // {}) | with_entries(.key as $k | select($exts | any_c(. == $k)))) |
    .service.extensions = $exts |
    with(select(.service.extensions | length == 0); del(.service.extensions)) |
    with(select(.connectors | length == 0); del(.connectors)) |
    with(select(.extensions | length == 0); del(.extensions))
  ' "$1"
}

generate() {
  local index=$1 configmap output description pipelines extensions
  configmap=$(yq ".[$index].configmap" "$dir/collectors.yaml")
  output=$(yq ".[$index].output" "$dir/collectors.yaml")
  description=$(yq ".[$index].description" "$dir/collectors.yaml")
  pipelines=$(yq -o=json -I=0 ".[$index].pipelines" "$dir/collectors.yaml")
  extensions=$(yq -o=json -I=0 ".[$index].extensions // []" "$dir/collectors.yaml")

  local rendered="$dir/rendered/$configmap-configmap.yaml" tmp="$work/$index"
  mkdir -p "$tmp"
  yq -e '.data.relay' "$rendered" > "$tmp/relay.yaml"
  yq ". * (load(\"$dir/otel-config.yaml\") | ... comments = \"\")" "$tmp/relay.yaml" > "$tmp/merged.yaml"

  # The chart passes feature gates as container arguments, not in the collector configuration.
  local workloads=("$dir/rendered/$configmap"/*.yaml) gates
  yq ea -e '[select(.kind == "DaemonSet" or .kind == "Deployment" or .kind == "StatefulSet")] | length == 1' "${workloads[@]}" > /dev/null 2>&1 ||
    { echo "error: $output: expected one DaemonSet, Deployment, or StatefulSet in $dir/rendered/$configmap" >&2; return 1; }
  gates=$(yq ea -r '
    select(.kind == "DaemonSet" or .kind == "Deployment" or .kind == "StatefulSet") |
    .spec.template.spec.containers[].args[] | select(test("^--feature-gates=")) | sub("^--feature-gates=", "")
  ' "${workloads[@]}" | paste -sd, -)

  local pipeline
  for pipeline in $(yq -r '.[]' <<< "$pipelines"); do
    yq -e ".service.pipelines.\"$pipeline\"" "$tmp/merged.yaml" > /dev/null 2>&1 ||
      { echo "error: $output: pipeline $pipeline is not in $rendered" >&2; return 1; }
  done
  local extension
  for extension in $(yq -r '.[]' <<< "$extensions"); do
    yq -e ".extensions.\"$extension\"" "$tmp/merged.yaml" > /dev/null 2>&1 ||
      { echo "error: $output: extension $extension is not in $rendered" >&2; return 1; }
  done

  prune "$tmp/merged.yaml" "$pipelines" "$extensions" > "$tmp/config.yaml"
  if yq -e '.service.pipelines[] | select((.receivers | length) == 0 or (.exporters | length) == 0)' "$tmp/config.yaml" > /dev/null 2>&1; then
    echo "error: $output: a pipeline has no receivers or exporters left after removing connectors with no kept pipeline on the other side" >&2
    return 1
  fi

  {
    echo "# $description"
    echo "#"
    echo "# GENERATED FILE, DO NOT EDIT. Run \"make generate-examples\" to regenerate it from the Observe"
    echo "# Agent Helm chart (see README.md)."
    echo "#"
    echo "# Set these environment variables on the collector container:"
    local var
    for var in $(grep -oE '\$\{env:[A-Za-z0-9_]+\}' "$tmp/config.yaml" | sed -E 's/\$\{env:([A-Za-z0-9_]+)\}/\1/' | sort -u); do
      if ! describe_env "$var" > /dev/null; then
        echo "error: $output references \${env:$var}; replace it in otel-config.yaml or describe it in describe_env in $0" >&2
        return 1
      fi
      printf '#   %-24s %s\n' "$var" "$(describe_env "$var")"
    done
    if [ -n "$gates" ]; then
      echo "#"
      echo "# Start the collector with these arguments, as the chart does:"
      echo "#   --feature-gates=$gates"
    fi
    cat "$tmp/config.yaml"
  } > "$work/collector/$output"
}

count=$(yq 'length' "$dir/collectors.yaml")
for ((i = 0; i < count; i++)); do
  generate "$i"
done

# Replace collector/ only once every configuration generated, so that outputs no longer listed in
# collectors.yaml are removed too.
rm -rf "$out_dir"
mv "$work/collector" "$out_dir"
