#!/usr/bin/env bash
# Checks the OpenTelemetry Collector Helm chart values in charts/agent/examples/oss-collector. The
# collector configuration in each values file's alternateConfig must validate with upstream
# otelcol-contrib, and the forwarder must keep the deployment environment that applications set
# while falling back to DEPLOYMENT_ENVIRONMENT. Each values file must render, with the pinned
# OpenTelemetry Collector chart, into exactly that configuration and set what it reads.
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

# Validation builds the receivers, and kubeletstats' serviceAccount auth needs in-cluster
# credentials. Validate its configuration against a kubeconfig that is parsed but never contacted.
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

chart_name=$(yq '.name' "$OSS_DIR/scripts/upstream-chart.yaml")
helm pull "$chart_name" --repo "$(yq '.repository' "$OSS_DIR/scripts/upstream-chart.yaml")" \
  --version "$(yq '.version' "$OSS_DIR/scripts/upstream-chart.yaml")" --untar --untardir "$tmp/chart"

for values in "$OSS_DIR"/*-values.yaml; do
  name=$(basename "$values" -values.yaml)
  label=$(basename "$values")
  config="$tmp/$name.yaml"
  yq '.alternateConfig' "$values" > "$config"

  yq '
    (.receivers | select(has("kubeletstats")) | .kubeletstats.auth_type) = "none" |
    (.receivers | select(has("kubeletstats")) | .kubeletstats.k8s_api_config.auth_type) = "kubeConfig"
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
