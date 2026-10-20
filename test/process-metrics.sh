#!/usr/bin/env bash

set -euo pipefail

repo=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
chart="$repo/charts/agent"

render() {
    helm template process-review "$chart" "$@"
}

assert_yaml() {
    local yaml="$1" expression="$2"
    if ! printf '%s\n' "$yaml" | yq -o=json '.' - | jq -e -s "length > 0 and all(.[]; $expression)"; then
        printf 'FAIL: %s\n' "$expression" >&2
        exit 1
    fi
}

assert_failure() {
    local expected="$1" output
    shift
    if output=$(render "$@" 2>&1); then
        printf 'FAIL: rendering should have failed: %s\n' "$*" >&2
        exit 1
    fi
    if [[ "$output" != *"$expected"* ]]; then
        printf 'FAIL: expected %s, got:\n%s\n' "$expected" "$output" >&2
        exit 1
    fi
}

collector_config() {
    yq ea -r 'select(.kind == "ConfigMap" and .metadata.name == "node-logs-metrics") | .data.relay' -
}

node_pod() {
    yq ea 'select(.kind == "DaemonSet" and .metadata.name == "process-review-node-logs-metrics-agent") | .spec.template.spec' -
}

defaults=$(render)
config=$(printf '%s\n' "$defaults" | collector_config)
assert_yaml "$config" '.receivers.hostmetrics.scrapers | has("process") == false'
pod=$(printf '%s\n' "$defaults" | node_pod)
assert_yaml "$pod" '.hostPID == false and .shareProcessNamespace != true'

enabled=(--set node.metrics.process.enabled=true --set node-logs-metrics.hostPID=true)
manifest=$(render "${enabled[@]}")
config=$(printf '%s\n' "$manifest" | collector_config)
assert_yaml "$config" '.receivers.hostmetrics.scrapers.process == {"mute_process_exe_error": true, "mute_process_io_error": true, "mute_process_user_error": true, "resource_attributes": {"process.command": {"enabled": false}, "process.command_line": {"enabled": false}}}'
assert_yaml "$config" '.service.pipelines."metrics/hostmetrics".receivers == ["hostmetrics"]'
assert_yaml "$config" '.service.pipelines."metrics/hostmetrics".exporters == ["prometheusremotewrite/observe"]'
assert_yaml "$config" '.exporters."prometheusremotewrite/observe".resource_to_telemetry_conversion.enabled == true'
pod=$(printf '%s\n' "$manifest" | node_pod)
assert_yaml "$pod" '.hostPID == true and .shareProcessNamespace != true'
assert_yaml "$pod" '.volumes[] | select(.name == "hostfs") | .hostPath.path == "/"'
assert_yaml "$pod" '.containers[].volumeMounts[] | select(.name == "hostfs") | .mountPath == "/hostfs" and .readOnly == true'
other_pods=$(printf '%s\n' "$manifest" | yq ea '[select(.kind == "DaemonSet" or .kind == "Deployment") | select(.metadata.name != "process-review-node-logs-metrics-agent") | .spec.template.spec]' -)
assert_yaml "$other_pods" 'length > 0 and all(.[]; .hostPID != true)'

assert_failure 'requires node-logs-metrics.hostPID=true' --set node.metrics.process.enabled=true
assert_failure 'cannot be enabled together' "${enabled[@]}" --set node-logs-metrics.shareProcessNamespace=true
assert_failure 'cannot be enabled together' --set node-logs-metrics.hostPID=true --set node-logs-metrics.shareProcessNamespace=true
assert_failure 'cannot be enabled together' "${enabled[@]}" --set node.metrics.enabled=false --set node-logs-metrics.shareProcessNamespace=true

manifest=$(render --set node.metrics.process.enabled=true --set node.metrics.enabled=false)
config=$(printf '%s\n' "$manifest" | collector_config)
assert_yaml "$config" '.receivers | has("hostmetrics") == false'
assert_yaml "$config" '.service.pipelines | has("metrics/hostmetrics") == false'

manifest=$(render --set node.metrics.process.enabled=true --set node.enabled=false)
resources=$(printf '%s\n' "$manifest" | yq ea -o=json -I=0 '[select(.metadata.name == "node-logs-metrics" or .metadata.name == "process-review-node-logs-metrics-agent")] | length' -)
assert_yaml "$resources" '. == 0'

manifest=$(render "${enabled[@]}" --set agent.config.nodeLogsMetrics.receivers.hostmetrics.scrapers.process.mute_process_io_error=false)
config=$(printf '%s\n' "$manifest" | collector_config)
assert_yaml "$config" '.receivers.hostmetrics.scrapers.process.mute_process_io_error == false'
assert_yaml "$config" '.receivers.hostmetrics.scrapers.process.resource_attributes."process.command_line".enabled == false'

manifest=$(render "${enabled[@]}" --set 'agent.config.nodeLogsMetrics.receivers.hostmetrics.scrapers.process.resource_attributes.process\.command_line.enabled=true')
config=$(printf '%s\n' "$manifest" | collector_config)
assert_yaml "$config" '.receivers.hostmetrics.scrapers.process.resource_attributes."process.command_line".enabled == true'
assert_yaml "$config" '.receivers.hostmetrics.scrapers.process.resource_attributes."process.command".enabled == false'

manifest=$(render --set node-logs-metrics.shareProcessNamespace=true)
pod=$(printf '%s\n' "$manifest" | node_pod)
assert_yaml "$pod" '.hostPID == false and .shareProcessNamespace == true'

printf 'Process metrics render tests passed.\n'
