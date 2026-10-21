#!/usr/bin/env bash
# Generates the OpenTelemetry Collector Helm chart values in charts/agent/examples/oss-collector, one
# per collector, from the Observe Agent chart rendered with values.yaml into rendered/ there.
# `make generate-examples` runs this script. See README.md.
#
# For each entry in collectors.yaml it takes the collector ConfigMap's configuration, merges
# otel-config.yaml on top, keeps only the listed pipelines and extensions, and deletes every
# component they don't use. A connector is only kept when a kept pipeline is on both sides of it.
# The chart values wrap that configuration with the workload settings the collector's rendered
# DaemonSet or Deployment uses: feature gates, downward API variables, volumes, security context,
# resources, ports, and the chart's read-only RBAC rules.
#
# Requires helm and yq (https://github.com/mikefarah/yq).
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
out_dir=$(cd "$dir/.." && pwd)
repo=$(cd "$out_dir/../../../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/values"

# Render the Observe Agent chart the way `make generate-examples` renders the chart examples: the
# chart's templates in rendered/, and each subchart's in rendered/<subchart>/.
rendered="$work/rendered"
if helm dependency list "$repo/charts/agent" | awk 'NR > 1 && NF && $4 != "ok"' | grep -q .; then
  helm dependency build "$repo/charts/agent" > /dev/null
fi
helm template example "$repo/charts/agent" --namespace default --values "$dir/values.yaml" --output-dir "$work/helm-output" > /dev/null
mkdir -p "$rendered"
mv "$work/helm-output/agent/templates/"* "$rendered/"
for subchart in "$work/helm-output/agent/charts/"*/; do
  mkdir -p "$rendered/$(basename "$subchart")"
  mv "$subchart/templates/"* "$rendered/$(basename "$subchart")/"
done
find "$rendered" -type f -name '*.yaml' -exec perl -0777 -i -pe 's/[ \t]+$//mg; s/\s+\z/\n/' {} +

chart_repository=$(yq '.repository' "$dir/upstream-chart.yaml")
chart_name=$(yq '.name' "$dir/upstream-chart.yaml")
chart_version=$(yq '.version' "$dir/upstream-chart.yaml")
collector_version=$(yq '.collectorVersion' "$dir/upstream-chart.yaml")
# The Secret that the chart values read every variable from that isn't set from the downward API.
secret=observe-collector
# Variables that the OpenTelemetry Collector chart sets on every collector container.
chart_env='["MY_POD_IP", "OTEL_K8S_NODE_NAME", "OTEL_K8S_NODE_IP", "OTEL_K8S_NAMESPACE", "OTEL_K8S_POD_NAME", "OTEL_K8S_POD_IP"]'
# The OpenTelemetry Collector chart's default ports, which stay enabled unless the values disable them.
chart_ports='["otlp", "otlp-http", "jaeger-compact", "jaeger-thrift", "jaeger-grpc", "zipkin", "metrics"]'
rbac_rules=$(yq ea -o=json -I=0 '[select(.kind == "ClusterRole") | .rules[] | select((.verbs - ["get", "list", "watch"]) | length == 0)]' "$rendered/cluster-role.yaml")

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
    .service.extensions = ($exts | ... style = "") |
    with(select(.service.extensions | length == 0); del(.service.extensions)) |
    with(select(.connectors | length == 0); del(.connectors)) |
    with(select(.extensions | length == 0); del(.extensions))
  ' "$1"
}

# chart_values <workload> <container> <config> <variables JSON list> <feature gates> <has service>:
# prints values for the OpenTelemetry Collector chart that run <config> like the rendered <workload>
# runs it.
chart_values() {
  WORKLOAD=$1 CONTAINER=$2 CONFIG=$3 VARS=$4 GATES=$5 HAS_SERVICE=$6 CHART_ENV=$chart_env CHART_PORTS=$chart_ports \
    RBAC_RULES=$rbac_rules SECRET=$secret COLLECTOR_VERSION=$collector_version yq -n '
    load(strenv(WORKLOAD)) as $w | $w.spec.template.spec as $pod |
    ($pod.containers[] | select(.name == strenv(CONTAINER))) as $c |
    [($pod.volumes // [])[] | select(has("configMap") or has("secret") or has("projected")) | .name] as $chart_volumes |
    env(VARS) as $vars | env(CHART_ENV) as $chart_env |
    [load(strenv(CONFIG)).receivers | .. | select(tag == "!!str" and test(":[0-9]+$")) | sub(".*:", "")] as $listening |

    .mode = ($w.kind | downcase) |
    with(select($w.kind == "Deployment"); .replicaCount = ($w.spec.replicas // 1)) |
    .image.repository = "otel/opentelemetry-collector-contrib" |
    .image.tag = strenv(COLLECTOR_VERSION) |
    with(select(strenv(GATES) != ""); .command.extraArgs = ["--feature-gates=" + strenv(GATES)]) |
    .clusterRole.create = true |
    .clusterRole.rules = env(RBAC_RULES) |
    .extraEnvsFrom = [{"secretRef": {"name": strenv(SECRET)}}] |
    .extraEnvs = [($c.env // [])[] | select(.valueFrom.fieldRef) |
      select(.name as $n | (($vars | any_c(. == $n)) and (($chart_env | any_c(. == $n)) | not)))] |
    .extraVolumes = [($pod.volumes // [])[] | select(.name as $n | $chart_volumes | any_c(. == $n) | not)] |
    .extraVolumeMounts = [($c.volumeMounts // [])[] | select(.name as $n | $chart_volumes | any_c(. == $n) | not)] |
    # The monitor collector scrapes the collectors that carry observe_monitor_* annotations, and
    # observeinc_com_scrape: "false" keeps Prometheus pod scraping from scraping them a second time.
    .podAnnotations = (($w.spec.template.metadata.annotations // {}) | with_entries(select(.key | test("^(observe_monitor_|observeinc_com_)")))) |
    .affinity = ($pod.affinity // {}) |
    .nodeSelector = ($pod.nodeSelector // {}) |
    .tolerations = ($pod.tolerations // []) |
    .podSecurityContext = ($pod.securityContext // {}) |
    .securityContext = ($c.securityContext // {}) |
    .resources = ($c.resources // {}) |
    .ports = ((env(CHART_PORTS) | map({"key": ., "value": {"enabled": false}}) | from_entries) *
      ([($c.ports // [])[] | select((.containerPort | tostring) as $p | $listening | any_c(. == $p))] |
        map(. as $p | {"key": $p.name, "value": (({"enabled": true, "servicePort": $p.containerPort}) * ($p | del(.name)))}) | from_entries)) |
    # The chart creates a Service unless told not to, and the API server rejects one without ports.
    .service.enabled = ((strenv(HAS_SERVICE) == "true") and ([.ports[] | select(.enabled)] | length > 0)) |
    ... style = "" |
    .alternateConfig = load(strenv(CONFIG)) |

    with(select(.extraEnvs | length == 0); del(.extraEnvs)) |
    with(select(.extraVolumes | length == 0); del(.extraVolumes)) |
    with(select(.extraVolumeMounts | length == 0); del(.extraVolumeMounts)) |
    with(select(.podAnnotations | length == 0); del(.podAnnotations)) |
    with(select(.affinity | length == 0); del(.affinity)) |
    with(select(.nodeSelector | length == 0); del(.nodeSelector)) |
    with(select(.tolerations | length == 0); del(.tolerations)) |
    with(select(.podSecurityContext | length == 0); del(.podSecurityContext)) |
    with(select(.securityContext | length == 0); del(.securityContext)) |
    with(select(.resources | length == 0); del(.resources))
  '
}

generate() {
  local index=$1 configmap name output description pipelines extensions
  configmap=$(yq ".[$index].configmap" "$dir/collectors.yaml")
  name=$(yq ".[$index].name" "$dir/collectors.yaml")
  output="$name-values.yaml"
  description=$(yq ".[$index].description" "$dir/collectors.yaml")
  pipelines=$(yq -o=json -I=0 ".[$index].pipelines" "$dir/collectors.yaml")
  extensions=$(yq -o=json -I=0 ".[$index].extensions // []" "$dir/collectors.yaml")
  replace_processors=$(yq -o=json -I=0 ".[$index].replace_processors // {}" "$dir/collectors.yaml")

  local tmp="$work/$index"
  mkdir -p "$tmp"
  CONFIGMAP=$configmap yq ea -e 'select(.kind == "ConfigMap" and .metadata.name == strenv(CONFIGMAP)) | .data.relay' "$rendered"/*.yaml > "$tmp/relay.yaml" 2> /dev/null ||
    { echo "error: $output: no ConfigMap named $configmap with a relay key in rendered/" >&2; return 1; }
  yq ". * (load(\"$dir/otel-config.yaml\") | ... comments = \"\")" "$tmp/relay.yaml" > "$tmp/merged.yaml"

  local processor replacement
  for processor in $(yq -r 'keys | .[]' <<< "$replace_processors"); do
    replacement=$(yq -r ".\"$processor\"" <<< "$replace_processors")
    PROCESSOR=$processor yq -e '.service.pipelines[].processors[] | select(. == strenv(PROCESSOR))' "$tmp/merged.yaml" > /dev/null 2>&1 ||
      { echo "error: $output: replace_processors lists $processor, which no pipeline in the $configmap ConfigMap uses" >&2; return 1; }
    yq -e ".processors.\"$replacement\"" "$tmp/merged.yaml" > /dev/null 2>&1 ||
      { echo "error: $output: replace_processors replaces $processor with $replacement, which otel-config.yaml doesn't define" >&2; return 1; }
  done
  REPLACE=$replace_processors yq -i '
    env(REPLACE) as $replace | .service.pipelines[].processors |= (map(. as $p | ($replace[$p] // $p)) | ... style = "")
  ' "$tmp/merged.yaml"

  local workloads=("$rendered/$configmap"/*.yaml) gates
  yq ea -e '[select(.kind == "DaemonSet" or .kind == "Deployment" or .kind == "StatefulSet")] | length == 1' "${workloads[@]}" > /dev/null 2>&1 ||
    { echo "error: $output: expected one DaemonSet, Deployment, or StatefulSet in rendered/$configmap" >&2; return 1; }
  yq ea 'select(.kind == "DaemonSet" or .kind == "Deployment" or .kind == "StatefulSet")' "${workloads[@]}" > "$tmp/workload.yaml"
  CONTAINER=$configmap yq -e '.spec.template.spec.containers[] | select(.name == strenv(CONTAINER))' "$tmp/workload.yaml" > /dev/null 2>&1 ||
    { echo "error: $output: the workload in rendered/$configmap has no container named $configmap" >&2; return 1; }
  # The chart passes feature gates as container arguments, not in the collector configuration.
  gates=$(yq -r '.spec.template.spec.containers[].args[] | select(test("^--feature-gates=")) | sub("^--feature-gates=", "")' "$tmp/workload.yaml" | paste -sd, -)

  local pipeline
  for pipeline in $(yq -r '.[]' <<< "$pipelines"); do
    yq -e ".service.pipelines.\"$pipeline\"" "$tmp/merged.yaml" > /dev/null 2>&1 ||
      { echo "error: $output: pipeline $pipeline is not in the $configmap ConfigMap" >&2; return 1; }
  done
  local extension
  for extension in $(yq -r '.[]' <<< "$extensions"); do
    yq -e ".extensions.\"$extension\"" "$tmp/merged.yaml" > /dev/null 2>&1 ||
      { echo "error: $output: extension $extension is not in the $configmap ConfigMap" >&2; return 1; }
  done

  prune "$tmp/merged.yaml" "$pipelines" "$extensions" > "$tmp/config.yaml"
  if yq -e '.service.pipelines[] | select((.receivers | length) == 0 or (.exporters | length) == 0)' "$tmp/config.yaml" > /dev/null 2>&1; then
    echo "error: $output: a pipeline has no receivers or exporters left after removing connectors with no kept pipeline on the other side" >&2
    return 1
  fi

  local vars var
  vars=$(grep -oE '\$\{env:[A-Za-z0-9_]+\}' "$tmp/config.yaml" | sed -E 's/\$\{env:([A-Za-z0-9_]+)\}/\1/' | sort -u)
  for var in $vars; do
    describe_env "$var" > /dev/null ||
      { echo "error: $output references \${env:$var}; replace it in otel-config.yaml or describe it in describe_env in $0" >&2; return 1; }
  done

  local vars_json
  vars_json="[$(printf '"%s",' $vars | sed 's/,$//')]"
  local has_service=false
  yq ea -e '[select(.kind == "Service")] | length > 0' "${workloads[@]}" > /dev/null 2>&1 && has_service=true
  chart_values "$tmp/workload.yaml" "$configmap" "$tmp/config.yaml" "$vars_json" "$gates" "$has_service" > "$tmp/values.yaml"
  # Variables the chart values don't set from the downward API come from the Secret.
  local secret_vars
  secret_vars=$(VARS=$vars_json CHART_ENV=$chart_env yq -r '
    [.extraEnvs[]?.name] as $set | env(CHART_ENV) as $chart_env |
    env(VARS)[] | select(. as $n | (($set + $chart_env) | any_c(. == $n)) | not)
  ' "$tmp/values.yaml")


  {
    echo "# $description"
    echo "#"
    echo "# GENERATED FILE, DO NOT EDIT. Run \"make generate-examples\" to regenerate it from the Observe"
    echo "# Agent Helm chart (see scripts/README.md)."
    echo "#"
    echo "# Values for the $chart_name Helm chart $chart_version, running otelcol-contrib $collector_version, the"
    echo "# collector version of the Observe Agent the values are generated from. Create the $secret"
    echo "# Secret (see README.md), then:"
    echo "#"
    echo "#   helm install observe-$name $chart_name --repo $chart_repository \\"
    echo "#     --version $chart_version --namespace observe --values $output"
    echo "#"
    echo "# The collector reads these variables from the $secret Secret:"
    for var in $secret_vars; do
      printf '#   %-24s %s\n' "$var" "$(describe_env "$var")"
    done
    cat "$tmp/values.yaml"
  } > "$work/values/$output"
}

# Every collector the chart renders, and every pipeline in it, must be kept, so a chart change that
# adds one can't drop out of the examples unnoticed.
missing=""
for cm in $(yq ea -r 'select(.kind == "ConfigMap" and .data.relay != null) | .metadata.name' "$rendered"/*.yaml | grep -v '^---$'); do
  kept=$(CM=$cm yq -r '.[] | select(.configmap == strenv(CM)) | .pipelines[]' "$dir/collectors.yaml")
  for pipeline in $(CM=$cm yq ea -r 'select(.kind == "ConfigMap" and .metadata.name == strenv(CM)) | .data.relay | from_yaml | (.service.pipelines // {}) | keys | .[]' "$rendered"/*.yaml | grep -v '^---$'); do
    grep -qxF "$pipeline" <<< "$kept" || missing+="  $cm $pipeline"$'\n'
  done
done
if [ -n "$missing" ]; then
  echo "error: collectors.yaml doesn't keep these collector pipelines that the chart renders:" >&2
  printf '%s' "$missing" >&2
  exit 1
fi

count=$(yq 'length' "$dir/collectors.yaml")
for ((i = 0; i < count; i++)); do
  generate "$i"
done

# Replace the outputs only once every file generated, so that collectors no longer listed in
# collectors.yaml are removed too.
rm -rf "${out_dir:?}/rendered"
rm -f "$out_dir"/*-values.yaml
mv "$work/rendered" "$out_dir/rendered"
mv "$work/values/"*-values.yaml "$out_dir/"
