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
OTLP_HTTP="127.0.0.1:34318"

for cmd in helm yq jq curl "$OBSERVE_AGENT"; do
  command -v "$cmd" >/dev/null || { echo "$cmd could not be found" >&2; exit 1; }
done

tmp=$(mktemp -d)
agent_pid=""
cleanup() {
  [ -n "$agent_pid" ] && kill "$agent_pid" 2>/dev/null || true
  rm -rf "$tmp"
}
trap cleanup EXIT

any_failed=false
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; any_failed=true; }

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

# Keeps the app-telemetry pipelines and points each one at a local file.
APP_PIPELINES='
  .connectors.spanmetrics.metrics_flush_interval = "100ms" |
  .connectors."spanmetrics/summary".metrics_flush_interval = "100ms" |
  .service.pipelines |= with_entries(select(.key == "traces/observe-forward" or .key == "logs/observe-forward" or .key == "metrics/observe-forward" or .key == "traces/spanmetrics" or .key == "metrics/spanmetrics" or .key == "metrics/spanmetrics/summary")) |
  .service.pipelines."traces/observe-forward".exporters = ["file/traces"] |
  .service.pipelines."logs/observe-forward".exporters = ["file/logs"] |
  .service.pipelines."metrics/observe-forward".exporters = ["file/metrics"] |
  .service.pipelines."traces/spanmetrics".exporters = ["spanmetrics", "spanmetrics/summary"] |
  .service.pipelines."metrics/spanmetrics".exporters = ["file/red_metrics"] |
  .service.pipelines."metrics/spanmetrics/summary".exporters = ["nop"]
'

# Keeps the node pod-logs pipeline, fed from OTLP instead of filelog. The OTLP resources stand
# in for what k8sattributes extracts from resource.opentelemetry.io/* pod annotations.
NODE_LOGS_PIPELINE='
  .service.pipelines |= with_entries(select(.key == "logs")) |
  .service.pipelines.logs.receivers = ["otlp/app-telemetry"] |
  .service.pipelines.logs.exporters = ["file/logs"]
'

# Renders the chart and rewrites the given ConfigMap's collector config so it can run outside
# of Kubernetes: the pipelines selected by the given yq expression are kept, k8sattributes and
# tail sampling (which holds spans for its decision wait) are dropped, and the pipelines export
# to local JSON-lines files.
render_config() {
  local configmap=$1 out=$2 pipelines=$3
  shift 3
  helm template test "$CHART_DIR" --namespace default \
    --set observe.token.create=true --set observe.token.value=fake-ds:fake-token \
    --set application.REDMetrics.enabled=true \
    --set node.forwarder.metrics.outputFormat=otel \
    "$@" > "$out/manifest.yaml"
  yq -e "select(.kind == \"ConfigMap\" and .metadata.name == \"$configmap\").data.relay" "$out/manifest.yaml" > "$out/rendered.yaml"

  OUT="$out" OTLP_HTTP="$OTLP_HTTP" yq "
    .receivers = {\"otlp/app-telemetry\": {\"protocols\": {\"http\": {\"endpoint\": strenv(OTLP_HTTP)}}}} |
    .extensions = {} |
    .processors.\"resourcedetection/cloud\".detectors = [\"env\"] |
    .exporters = {
      \"nop\": {},
      \"file/traces\": {\"path\": strenv(OUT) + \"/traces.jsonl\", \"flush_interval\": \"100ms\"},
      \"file/logs\": {\"path\": strenv(OUT) + \"/logs.jsonl\", \"flush_interval\": \"100ms\"},
      \"file/metrics\": {\"path\": strenv(OUT) + \"/metrics.jsonl\", \"flush_interval\": \"100ms\"},
      \"file/red_metrics\": {\"path\": strenv(OUT) + \"/red_metrics.jsonl\", \"flush_interval\": \"100ms\"}
    } |
    .service.extensions = [] |
    .service.telemetry = {\"metrics\": {\"level\": \"none\"}, \"logs\": {\"level\": \"warn\"}} |
    $pipelines |
    (.service.pipelines[].processors) |= map(select(test(\"^(k8sattributes|tail_sampling)\") | not))
  " "$out/rendered.yaml" > "$out/collector.yaml"
}

# Three app resources: no environment, only the deprecated key, only the current key.
resources_json() {
  local record=$1
  jq -cn --argjson record "$record" '
    [
      {svc: "no-env", attrs: {}},
      {svc: "legacy-env", attrs: {"deployment.environment": "staging"}},
      {svc: "new-env", attrs: {"deployment.environment.name": "dev"}}
    ] | to_entries | map({
      resource: {attributes: ([{key: "service.name", value: {stringValue: .value.svc}}]
        + (.value.attrs | to_entries | map({key: .key, value: {stringValue: .value}})))},
      idx: .key
    }) | map(.resource as $r | .idx as $i | $record | .resource = $r | walk(if type == "string" then sub("IDX"; "\($i + 1)") else . end))
  '
}

send_traces() {
  local now
  now="$(date +%s)000000000"
  local span="{\"resource\": {}, \"scopeSpans\": [{\"spans\": [{\"traceId\": \"0000000000000000000000000000000IDX\", \"spanId\": \"000000000000000IDX\", \"name\": \"GET /\", \"kind\": 2, \"startTimeUnixNano\": \"$now\", \"endTimeUnixNano\": \"$now\"}]}]}"
  curl -sf -o /dev/null -H 'Content-Type: application/json' "http://$OTLP_HTTP/v1/traces" -d "{\"resourceSpans\": $(resources_json "$span")}"
}

send_logs() {
  local log='{"resource": {}, "scopeLogs": [{"logRecords": [{"body": {"stringValue": "hello"}}]}]}'
  curl -sf -o /dev/null -H 'Content-Type: application/json' "http://$OTLP_HTTP/v1/logs" -d "{\"resourceLogs\": $(resources_json "$log")}"
}

send_metrics() {
  local now
  now="$(date +%s)000000000"
  local metric="{\"resource\": {}, \"scopeMetrics\": [{\"metrics\": [{\"name\": \"app.requests\", \"gauge\": {\"dataPoints\": [{\"asInt\": \"1\", \"timeUnixNano\": \"$now\"}]}}]}]}"
  curl -sf -o /dev/null -H 'Content-Type: application/json' "http://$OTLP_HTTP/v1/metrics" -d "{\"resourceMetrics\": $(resources_json "$metric")}"
}

# Prints "service=<deployment.environment.name>/<deployment.environment>" for the first
# resource seen per service in a file exporter output file, sorted by service.
summarize() {
  local file=$1 key=$2
  [ -f "$file" ] || return 0
  jq -r --arg key "$key" '
    .[$key][].resource.attributes
    | map({(.key): .value.stringValue}) | add
    | "\(.["service.name"])=\(.["deployment.environment.name"] // "<unset>")/\(.["deployment.environment"] // "<unset>")"
  ' "$file" | awk -F= '!seen[$1]++' | sort | tr '\n' ' ' | sed 's/ $//'
}
wait_for() {
  local want=$1
  shift
  for _ in $(seq 1 100); do
    [ "$("$@")" = "$want" ] && return 0
    sleep 0.1
  done
  return 1
}

check() {
  local label=$1 want=$2
  shift 2
  if wait_for "$want" "$@"; then
    pass "$label"
  else
    fail "$label: want '$want', got '$("$@")'"
  fi
}

# start_collector <label> <out dir>: returns non-zero if the collector does not come up.
start_collector() {
  local label=$1 out=$2
  "$OBSERVE_AGENT" start --observe-config "$tmp/agent.yaml" --config="file:$out/collector.yaml" > "$out/agent.log" 2>&1 &
  agent_pid=$!
  if ! wait_for 0 sh -c "curl -s -o /dev/null http://$OTLP_HTTP/; echo \$?"; then
    cat "$out/agent.log" >&2
    fail "$label: collector did not start"
    kill "$agent_pid" 2>/dev/null || true
    wait "$agent_pid" 2>/dev/null || true
    agent_pid=""
    return 1
  fi
}

# stop_collector <label> <out dir>: fails the case if the collector already exited on its own.
stop_collector() {
  local label=$1 out=$2
  if ! kill "$agent_pid" 2>/dev/null; then
    fail "$label: collector exited unexpectedly"
    cat "$out/agent.log" >&2
  fi
  wait "$agent_pid" 2>/dev/null || true
  agent_pid=""
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

  send_traces
  send_logs
  send_metrics
  check "$label: traces" "$want" summarize "$out/traces.jsonl" resourceSpans
  check "$label: logs" "$want" summarize "$out/logs.jsonl" resourceLogs
  check "$label: metrics" "$want" summarize "$out/metrics.jsonl" resourceMetrics
  check "$label: RED metrics" "$want" summarize "$out/red_metrics.jsonl" resourceMetrics
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
