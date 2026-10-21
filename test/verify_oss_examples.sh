#!/usr/bin/env bash
# Checks the OpenTelemetry Collector Helm chart values in charts/agent/examples/oss-collector. The
# collector configuration in each values file's alternateConfig must validate with upstream
# otelcol-contrib, and the forwarder must keep the deployment environment that applications set
# while falling back to DEPLOYMENT_ENVIRONMENT. Each values file must render, with the pinned
# OpenTelemetry Collector chart, into exactly that configuration and set what it reads.
#
# Set EXPECTED_COLLECTOR_VERSION to also check that the values are pinned to that collector version.
#
# Requires yq (https://github.com/mikefarah/yq), jq, curl, helm and otelcol-contrib
# (override the binary with OTELCOL_CONTRIB=/path/to/otelcol-contrib). node-values.yaml only
# validates on Linux with the node's root filesystem at /hostfs; for a local run, `sudo ln -s / /hostfs`.
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
OSS_DIR="$repo/charts/agent/examples/oss-collector"
OTELCOL_CONTRIB="${OTELCOL_CONTRIB:-otelcol-contrib}"

for cmd in yq jq curl helm "$OTELCOL_CONTRIB"; do
  command -v "$cmd" >/dev/null || { echo "$cmd could not be found" >&2; exit 1; }
done

source "$repo/test/lib/deployment_environment.sh"

# Placeholder values for the variables the examples read.
export OBSERVE_COLLECTION_URL=https://123456789012.collect.observeinc.com
export OBSERVE_TOKEN=example-datastream:example-token
export OBSERVE_CLUSTER_NAME=example-cluster OBSERVE_CLUSTER_UID=example-cluster-uid
export MY_POD_IP=127.0.0.1 K8S_NODE_NAME=example-node
export DEPLOYMENT_ENVIRONMENT=prod

# feature_gates <values file>: prints the --feature-gates argument the values start the collector with.
feature_gates() {
  yq '(.command.extraArgs // [])[] | select(test("^--feature-gates="))' "$1"
}

run_collector() {
  exec "$OTELCOL_CONTRIB" --config "$1" $collector_args
}

echo "otelcol-contrib version: $("$OTELCOL_CONTRIB" --version)"

# Validation builds the receivers, and the serviceAccount auth of kubeletstats and k8sobjects needs
# in-cluster credentials. Validate them against a kubeconfig that is parsed but never contacted.
cat > "$tmp/kubeconfig" <<'EOF'
apiVersion: v1
kind: Config
clusters:
  - name: validate
    cluster:
      server: https://127.0.0.1:6443
contexts:
  - name: validate
    context:
      cluster: validate
      user: validate
current-context: validate
users:
  - name: validate
    user:
      token: validate
EOF
export KUBECONFIG="$tmp/kubeconfig"
# Prometheus scrapes that authenticate with the pod's service account read its token and CA
# certificate; validate them against placeholder files.
mkdir -p "$tmp/serviceaccount"
echo validate > "$tmp/serviceaccount/token"
: > "$tmp/serviceaccount/ca.crt"

chart_name=$(yq '.name' "$OSS_DIR/scripts/upstream-chart.yaml")
helm pull "$chart_name" --repo "$(yq '.repository' "$OSS_DIR/scripts/upstream-chart.yaml")" \
  --version "$(yq '.version' "$OSS_DIR/scripts/upstream-chart.yaml")" --untar --untardir "$tmp/chart"

collector_version=$(yq '.collectorVersion' "$OSS_DIR/scripts/upstream-chart.yaml")
chart_app_version=$(yq '.appVersion' "$tmp/chart/$chart_name/Chart.yaml")
if [ "$chart_app_version" = "$collector_version" ]; then
  pass "the pinned chart's appVersion is collectorVersion $collector_version"
else
  fail "the pinned chart's appVersion is collectorVersion $collector_version (it is $chart_app_version)"
fi
if [ -n "${EXPECTED_COLLECTOR_VERSION:-}" ]; then
  if [ "$collector_version" = "$EXPECTED_COLLECTOR_VERSION" ]; then
    pass "collectorVersion is the Observe Agent's collector version $EXPECTED_COLLECTOR_VERSION"
  else
    fail "collectorVersion is the Observe Agent's collector version $EXPECTED_COLLECTOR_VERSION (it is $collector_version; update scripts/upstream-chart.yaml)"
  fi
fi

for values in "$OSS_DIR"/*-values.yaml; do
  name=$(basename "$values" -values.yaml)
  label=$(basename "$values")
  config="$tmp/$name.yaml"
  yq '.alternateConfig' "$values" > "$config"

  SERVICEACCOUNT=$tmp/serviceaccount yq '
    (.receivers | select(has("kubeletstats")) | .kubeletstats.auth_type) = "none" |
    (.receivers | select(has("kubeletstats")) | .kubeletstats.k8s_api_config.auth_type) = "kubeConfig" |
    (.receivers | with_entries(select(.key | test("^k8sobjects(/|$)"))) | .[].auth_type) = "kubeConfig" |
    (.. | select(tag == "!!str" and test("^/var/run/secrets/kubernetes.io/serviceaccount/"))) |= sub("^/var/run/secrets/kubernetes.io/serviceaccount/", strenv(SERVICEACCOUNT) + "/")
  ' "$config" > "$tmp/$name-validate.yaml"
  if "$OTELCOL_CONTRIB" validate --config "$tmp/$name-validate.yaml" $(feature_gates "$values") > "$tmp/validate.log" 2>&1; then
    pass "$label configuration validates"
  else
    cat "$tmp/validate.log" >&2
    fail "$label configuration validates"
  fi

  if ! helm template "observe-$name" "$tmp/chart/$chart_name" --namespace observe --values "$values" > "$tmp/$name-chart.yaml" 2> "$tmp/helm.log"; then
    cat "$tmp/helm.log" >&2
    fail "$label renders"
    continue
  fi

  yq ea 'select(.kind == "ConfigMap" and .data.relay) | .data.relay' "$tmp/$name-chart.yaml" | yq -P 'sort_keys(..)' > "$tmp/$name-chart-config.yaml"
  yq -P 'sort_keys(..)' "$config" > "$tmp/$name-config.yaml"
  if diff -u "$tmp/$name-config.yaml" "$tmp/$name-chart-config.yaml" > "$tmp/diff.log"; then
    pass "$label renders exactly its alternateConfig"
  else
    cat "$tmp/diff.log" >&2
    fail "$label renders exactly its alternateConfig"
  fi

  yq ea 'select(.kind == "DaemonSet" or .kind == "Deployment") | .spec.template.spec.containers[0]' "$tmp/$name-chart.yaml" > "$tmp/$name-container.yaml"
  duplicates=$(yq '.env[].name' "$tmp/$name-container.yaml" | sort | uniq -d)
  # The variables the values file's header says come from the Secret.
  from_secret=$(sed -nE 's/^#   ([A-Z][A-Z0-9_]+) .*/\1/p' "$values")
  missing=""
  for var in $(grep -oE '\$\{env:[A-Za-z0-9_]+\}' "$config" | sed -E 's/\$\{env:([A-Za-z0-9_]+)\}/\1/' | sort -u); do
    VAR=$var yq -e '.env[] | select(.name == strenv(VAR))' "$tmp/$name-container.yaml" > /dev/null 2>&1 ||
      grep -qx "$var" <<< "$from_secret" || missing="$missing $var"
  done
  if [ -z "$duplicates$missing" ] && yq -e '.envFrom[] | select(.secretRef)' "$tmp/$name-container.yaml" > /dev/null 2>&1; then
    pass "$label sets every variable the configuration reads, once"
  else
    fail "$label sets every variable the configuration reads, once (duplicated:${duplicates:+ }$duplicates; missing:$missing)"
  fi

  if [ "$(yq '.image.tag' "$values")" = "$collector_version" ]; then
    pass "$label pins the image to otelcol-contrib $collector_version"
  else
    fail "$label pins the image to otelcol-contrib $collector_version"
  fi

  gates=$(feature_gates "$values")
  if [ -z "$gates" ] || GATES=$gates yq -e '.args[] | select(. == strenv(GATES))' "$tmp/$name-container.yaml" > /dev/null 2>&1; then
    pass "$label passes the feature gates"
  else
    fail "$label passes the feature gates"
  fi

  # helm template doesn't catch this, but the API server rejects it.
  if yq ea -e 'select(.kind == "Service") | select((.spec.ports // []) | length == 0)' "$tmp/$name-chart.yaml" > /dev/null 2>&1; then
    fail "$label renders no Service without ports"
  else
    pass "$label renders no Service without ports"
  fi

  unused=""
  for port in $(yq '.ports[].containerPort' "$tmp/$name-container.yaml"); do
    grep -qE ":$port\$" <(yq '.receivers | .. | select(tag == "!!str")' "$config") || unused="$unused $port"
  done
  if [ -z "$unused" ]; then
    pass "$label only opens ports the configuration listens on"
  else
    fail "$label only opens ports the configuration listens on (unused:$unused)"
  fi
done

# Kubernetes objects from k8sobjects include Secrets, whose values must not reach Observe. In every
# pipeline that receives them, transform/redact_secrets must run before any processor that reads or
# copies the log body; only these may run before it.
for values in "$OSS_DIR"/*-values.yaml; do
  label=$(basename "$values")
  problems=$(yq -o=json '.alternateConfig' "$values" | jq -r '
    [(.receivers // {}) | to_entries[] | select(.key | test("^k8sobjects(/|$)")) | select(any(.value.objects[]?; .name == "secrets")) | .key] as $secret_receivers |
    .service.pipelines | to_entries[] | select(any(.value.receivers[]; . as $r | $secret_receivers | index($r))) |
    .key as $pipeline | (.value.processors // []) as $processors | ($processors | index("transform/redact_secrets")) as $i |
    if $i == null then "\($pipeline) has no transform/redact_secrets"
    else ($processors[:$i] | map(select(test("^(memory_limiter|batch|resource/.+|transform/unify)$") | not))) as $before |
      if ($before | length) > 0 then "\($pipeline) runs \($before | join(", ")) before transform/redact_secrets" else empty end
    end')
  if [ -z "$problems" ]; then
    pass "$label redacts Secrets before anything else reads them"
  else
    fail "$label redacts Secrets before anything else reads them ($problems)"
  fi
done

# Send a pulled and a watched Secret through the processors of the cluster-events pipeline that
# receives Secrets, in their real order, and check that no Secret value comes out anywhere.
redaction="$tmp/redaction"
mkdir -p "$redaction"
yq '.alternateConfig as $c | ($c.service.pipelines["logs/objects"].processors) as $processors | {
  "receivers": {"otlp": {"protocols": {"http": {"endpoint": "127.0.0.1:4319"}}}},
  "processors": ($processors | map(. as $id | {"key": $id, "value": $c.processors[$id]}) | from_entries),
  "exporters": {"file": {"path": "'"$redaction"'/out.json"}},
  "service": {
    "telemetry": {"metrics": {"level": "none"}},
    "pipelines": {"logs": {"receivers": ["otlp"], "processors": $processors, "exporters": ["file"]}}
  }
}' "$OSS_DIR/cluster-events-values.yaml" > "$redaction/collector.yaml"
"$OTELCOL_CONTRIB" --config "$redaction/collector.yaml" > "$redaction/collector.log" 2>&1 &
redaction_pid=$!
secret='{"apiVersion": "v1", "kind": "Secret", "metadata": {"name": "example", "namespace": "default", "uid": "example-uid",
  "annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"data\":{\"token\":\"c2VjcmV0LXZhbHVl\"}}", "keep": "yes"}},
  "data": {"token": "c2VjcmV0LXZhbHVl"}, "stringData": {"password": "secret-value\nsecond line"}}'
jq -n --argjson secret "$secret" '
  def anyvalue: if type == "object" then {kvlistValue: {values: [to_entries[] | {key, value: (.value | anyvalue)}]}}
    elif type == "array" then {arrayValue: {values: map(anyvalue)}} else {stringValue: tostring} end;
  {resourceLogs: [{scopeLogs: [{logRecords: [
    {body: ($secret | anyvalue)},
    {body: ({type: "ADDED", object: $secret} | anyvalue)}
  ]}]}]}' > "$redaction/logs.json"
sent=false
for _ in $(seq 1 30); do
  if curl -sf -o /dev/null -H 'Content-Type: application/json' --data @"$redaction/logs.json" http://127.0.0.1:4319/v1/logs; then
    sent=true
    break
  fi
  sleep 1
done
sleep 3
kill "$redaction_pid" 2> /dev/null || true
wait "$redaction_pid" 2> /dev/null || true
bodies=$(jq -c '
  def plain: if .kvlistValue then ((.kvlistValue.values // []) | map({key, value: (.value | plain)}) | from_entries)
    elif .arrayValue then (.arrayValue.values | map(plain)) elif has("stringValue") then .stringValue else . end;
  .resourceLogs[].scopeLogs[].logRecords[].body | plain' "$redaction/out.json" 2> /dev/null || true)
if [ "$sent" = true ] && [ "$(grep -c . <<< "$bodies")" -eq 2 ] && ! grep -q 'secret-value\|c2VjcmV0LXZhbHVl' "$redaction/out.json" &&
  jq -se 'all(.[]; .data.token == "UkVEQUNURUQ=" and .stringData.password == "REDACTED"
    and (.metadata.annotations | has("kubectl.kubernetes.io/last-applied-configuration") | not) and .metadata.annotations.keep == "yes")' <<< "$bodies" > /dev/null 2>&1; then
  pass "cluster-events-values.yaml redacts pulled and watched Secrets in every field it exports"
else
  cat "$redaction/collector.log" >&2
  echo "$bodies" >&2
  fail "cluster-events-values.yaml redacts pulled and watched Secrets in every field it exports"
fi

out="$tmp/forwarder"
mkdir -p "$out"
make_testable "$tmp/forwarder.yaml" "$out" "$APP_PIPELINES"
collector_args=$(feature_gates "$OSS_DIR/forwarder-values.yaml")
if start_collector "forwarder-values.yaml" "$out"; then
  check_app_pipelines "forwarder-values.yaml" "$out" "legacy-env=staging/staging new-env=dev/dev no-env=prod/prod"
  stop_collector "forwarder-values.yaml" "$out"
fi

if [ "$any_failed" = true ]; then
  exit 1
fi
