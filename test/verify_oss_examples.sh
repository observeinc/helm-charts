#!/usr/bin/env bash
# Checks the plain OpenTelemetry Collector examples in examples/oss-collector/kubernetes with
# upstream otelcol-contrib: every example must validate, and the forwarder example must keep the
# deployment environment that applications set while falling back to DEPLOYMENT_ENVIRONMENT.
#
# Requires yq (https://github.com/mikefarah/yq), jq, curl and otelcol-contrib
# (override the binary with OTELCOL_CONTRIB=/path/to/otelcol-contrib). node.yaml only validates on
# Linux with the node's root filesystem at /hostfs; for a local run, `sudo ln -s / /hostfs`.
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
EXAMPLES_DIR="$repo/examples/oss-collector/kubernetes"
OTELCOL_CONTRIB="${OTELCOL_CONTRIB:-otelcol-contrib}"

for cmd in yq jq curl "$OTELCOL_CONTRIB"; do
  command -v "$cmd" >/dev/null || { echo "$cmd could not be found" >&2; exit 1; }
done

source "$repo/test/lib/deployment_environment.sh"

# Placeholder values for the variables the examples read.
export OBSERVE_COLLECTION_URL=https://123456789012.collect.observeinc.com
export OBSERVE_TOKEN=example-datastream:example-token
export OBSERVE_CLUSTER_NAME=example-cluster OBSERVE_CLUSTER_UID=example-cluster-uid
export MY_POD_IP=127.0.0.1 K8S_NODE_NAME=example-node
export DEPLOYMENT_ENVIRONMENT=prod

run_collector() {
  exec "$OTELCOL_CONTRIB" --config "$1"
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

for config in "$EXAMPLES_DIR"/forwarder.yaml "$EXAMPLES_DIR"/node.yaml "$EXAMPLES_DIR"/cluster-metrics.yaml; do
  name=$(basename "$config")
  yq '
    (.receivers | select(has("kubeletstats")) | .kubeletstats.auth_type) = "none" |
    (.receivers | select(has("kubeletstats")) | .kubeletstats.k8s_api_config.auth_type) = "kubeConfig"
  ' "$config" > "$tmp/$name"
  if "$OTELCOL_CONTRIB" validate --config "$tmp/$name" > "$tmp/validate.log" 2>&1; then
    pass "$name validates"
  else
    cat "$tmp/validate.log" >&2
    fail "$name validates"
  fi
done

out="$tmp/forwarder"
mkdir -p "$out"
make_testable "$EXAMPLES_DIR/forwarder.yaml" "$out" "$APP_PIPELINES"
if start_collector "forwarder.yaml" "$out"; then
  check_app_pipelines "forwarder.yaml" "$out" "legacy-env=staging/staging new-env=dev/dev no-env=prod/prod"
  stop_collector "forwarder.yaml" "$out"
fi

if [ "$any_failed" = true ]; then
  exit 1
fi
