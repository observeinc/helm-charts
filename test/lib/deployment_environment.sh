# Shared helpers for running a collector config locally, sending OTLP data from apps with
# different deployment environment keys, and checking the resource attributes it forwards.
#
# Scripts that source this file must define:
#   run_collector <collector config>   execs the collector (exec, so that killing the
#                                      background job stops the collector itself)
# and may set OTLP_HTTP (default 127.0.0.1:34318).
#
# Requires yq (https://github.com/mikefarah/yq), jq, and curl.

OTLP_HTTP="${OTLP_HTTP:-127.0.0.1:34318}"

tmp=$(mktemp -d)
collector_pid=""
cleanup() {
  [ -n "$collector_pid" ] && kill "$collector_pid" 2>/dev/null || true
  rm -rf "$tmp"
}
trap cleanup EXIT

any_failed=false
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; any_failed=true; }

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

# make_testable <collector config> <out dir> <pipelines yq expression>
# Writes <out dir>/collector.yaml: a copy of the config that runs outside of Kubernetes. The
# pipelines selected by the yq expression are kept, k8sattributes and tail sampling (which holds
# spans for its decision wait) are dropped, and the pipelines export to local JSON-lines files.
make_testable() {
  local config=$1 out=$2 pipelines=$3
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
  " "$config" > "$out/collector.yaml"
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
  run_collector "$out/collector.yaml" > "$out/collector.log" 2>&1 &
  collector_pid=$!
  if ! wait_for 0 sh -c "curl -s -o /dev/null http://$OTLP_HTTP/; echo \$?"; then
    cat "$out/collector.log" >&2
    fail "$label: collector did not start"
    kill "$collector_pid" 2>/dev/null || true
    wait "$collector_pid" 2>/dev/null || true
    collector_pid=""
    return 1
  fi
}

# stop_collector <label> <out dir>: fails the case if the collector already exited on its own.
stop_collector() {
  local label=$1 out=$2
  if ! kill "$collector_pid" 2>/dev/null; then
    fail "$label: collector exited unexpectedly"
    cat "$out/collector.log" >&2
  fi
  wait "$collector_pid" 2>/dev/null || true
  collector_pid=""
}

# check_app_pipelines <label> <out dir> <expected>
# Sends traces, logs, and metrics, and checks forwarded telemetry and RED metrics.
check_app_pipelines() {
  local label=$1 out=$2 want=$3
  send_traces
  send_logs
  send_metrics
  check "$label: traces" "$want" summarize "$out/traces.jsonl" resourceSpans
  check "$label: logs" "$want" summarize "$out/logs.jsonl" resourceLogs
  check "$label: metrics" "$want" summarize "$out/metrics.jsonl" resourceMetrics
  check "$label: RED metrics" "$want" summarize "$out/red_metrics.jsonl" resourceMetrics
}
