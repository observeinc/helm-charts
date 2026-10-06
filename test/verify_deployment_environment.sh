#!/usr/bin/env bash
# Verifies how cluster.deploymentEnvironment.name is applied to application telemetry by
# running the rendered forwarder / gateway collector configs with a local observe-agent
# binary, sending OTLP data with different deployment environment keys, and checking the
# resource attributes that come out of the app-telemetry pipelines.
#
# Requires helm, yq (https://github.com/mikefarah/yq), jq, curl and observe-agent
# (override the binary with OBSERVE_AGENT=/path/to/observe-agent).
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
CHART_DIR="$repo/charts/agent"
OBSERVE_AGENT="${OBSERVE_AGENT:-observe-agent}"

for cmd in helm yq jq curl "$OBSERVE_AGENT"; do
  command -v "$cmd" >/dev/null || { echo "$cmd could not be found" >&2; exit 1; }
done

source "$repo/test/lib/deployment_environment.sh"

# Minimal observe-agent config: only the collector config passed via --config is used.
cat > "$tmp/agent.yaml" <<'EOF'
observe_url: https://test.collect.observeinc.com/
token: 12345678901234567890:abcdefghijklmnopqrstuvwxyzABCDEF
omit_base_components: true
forwarding:
  enabled: false
health_check:
  enabled: false
internal_telemetry:
  enabled: false
host_monitoring:
  enabled: false
self_monitoring:
  enabled: false
EOF

export OBSERVE_CLUSTER_NAME=test-cluster OBSERVE_CLUSTER_UID=test-cluster-uid MY_POD_IP=127.0.0.1

run_collector() {
  exec "$OBSERVE_AGENT" start --observe-config "$tmp/agent.yaml" --config="file:$1"
}

# render_config <ConfigMap name> <out dir> <pipelines yq expression> [helm args...]
render_config() {
  local configmap=$1 out=$2 pipelines=$3
  shift 3
  helm template test "$CHART_DIR" --namespace default \
    --set observe.token.create=true --set observe.token.value=fake-ds:fake-token \
    --set application.REDMetrics.enabled=true \
    --set node.forwarder.metrics.outputFormat=otel \
    "$@" > "$out/manifest.yaml"
  yq -e "select(.kind == \"ConfigMap\" and .metadata.name == \"$configmap\").data.relay" "$out/manifest.yaml" > "$out/rendered.yaml"
  make_testable "$out/rendered.yaml" "$out" "$pipelines"
}

# run_case <label> <configmap> <expected> [helm args...]
# The expectation applies to forwarded traces, logs and metrics, and to RED metrics.
run_case() {
  local label=$1 configmap=$2 want=$3
  shift 3
  local out="$tmp/$configmap-$RANDOM"
  mkdir -p "$out"
  render_config "$configmap" "$out" "$APP_PIPELINES" "$@"
  start_collector "$label" "$out" || return 0
  check_app_pipelines "$label" "$out" "$want"
  stop_collector "$label" "$out"
}

# run_node_logs_case <label> <expected> [helm args...]
run_node_logs_case() {
  local label=$1 want=$2
  shift 2
  local out="$tmp/node-logs-metrics-$RANDOM"
  mkdir -p "$out"
  render_config node-logs-metrics "$out" "$NODE_LOGS_PIPELINE" "$@"
  start_collector "$label" "$out" || return 0

  send_logs
  check "$label: pod logs" "$want" summarize "$out/logs.jsonl" resourceLogs
  stop_collector "$label" "$out"
}

honored="legacy-env=staging/staging new-env=dev/dev no-env=prod/prod"
overridden="legacy-env=prod/prod new-env=prod/prod no-env=prod/prod"

run_case "forwarder, fallback (default)" forwarder "$honored" \
  --set cluster.deploymentEnvironment.name=prod --set gatewayDeployment.enabled=false
run_case "forwarder, overrideApplication=true" forwarder "$overridden" \
  --set cluster.deploymentEnvironment.name=prod --set cluster.deploymentEnvironment.overrideApplication=true --set gatewayDeployment.enabled=false
run_case "gateway, fallback (default)" gateway "$honored" \
  --set cluster.deploymentEnvironment.name=prod --set gatewayDeployment.enabled=true
run_case "gateway, overrideApplication=true" gateway "$overridden" \
  --set cluster.deploymentEnvironment.name=prod --set cluster.deploymentEnvironment.overrideApplication=true --set gatewayDeployment.enabled=true
run_node_logs_case "node logs, fallback (default)" "$honored" \
  --set cluster.deploymentEnvironment.name=prod
run_node_logs_case "node logs, overrideApplication=true" "$overridden" \
  --set cluster.deploymentEnvironment.name=prod --set cluster.deploymentEnvironment.overrideApplication=true

if [ "$any_failed" = true ]; then
  exit 1
fi
