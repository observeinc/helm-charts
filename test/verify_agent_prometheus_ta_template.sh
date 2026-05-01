#!/usr/bin/env bash
# Verifies rendered agent chart when Target Allocator is enabled (ci/prometheus-ta-values.yaml).
# Usage: from repo root: ./test/verify_agent_prometheus_ta_template.sh
set -euo pipefail

repo="$(git rev-parse --show-toplevel)"
chart="$repo/charts/agent"
values="$chart/ci/prometheus-ta-values.yaml"

if [[ ! -f "$values" ]]; then
  echo "missing $values" >&2
  exit 1
fi

helm dependency build "$chart" >/dev/null

out="$(helm template verify-ta "$chart" --namespace testing -f "$values")"

# Both Target Allocator Deployments should render (one per scrape job).
for ta in verify-ta-prometheus-ta-pod-metrics verify-ta-prometheus-ta-cadvisor; do
  grep -q "name: $ta$" <<<"$out" || {
    echo "expected TA resource named $ta" >&2
    exit 1
  }
done

# target-allocator container must exist (same image in both Deployments).
grep -q 'name: target-allocator' <<<"$out" || {
  echo "expected target-allocator container" >&2
  exit 1
}

# FQDN must not contain quoted namespace, e.g. ."testing".
if grep -E '\."testing"\.svc\.cluster\.local' <<<"$out"; then
  echo "FAIL: namespace in URL appears quoted (bad DNS)" >&2
  exit 1
fi

# Each receiver must point at its own TA — no cross-wiring.
grep -qE 'endpoint: http://verify-ta-prometheus-ta-pod-metrics\.testing\.svc\.cluster\.local:8080' <<<"$out" || {
  echo "expected prometheus/pod_metrics endpoint -> pod-metrics TA" >&2
  exit 1
}
grep -qE 'endpoint: http://verify-ta-prometheus-ta-cadvisor\.testing\.svc\.cluster\.local:8080' <<<"$out" || {
  echo "expected prometheus/cadvisor endpoint -> cadvisor TA" >&2
  exit 1
}

# Each TA ConfigMap should carry exactly its own scrape job — isolation is what prevents
# the two-receiver duplication problem, so verify cross-contamination does not happen.
# Split the render on YAML-document boundaries ("---\n") and pick the ConfigMap whose name matches.
extract_cm() {
  awk -v name="$1" '
    BEGIN { RS = "---\n" }
    /kind: ConfigMap/ && $0 ~ ("  name: " name "\n") { print; exit }
  ' <<<"$out"
}
pod_ta_cm="$(extract_cm verify-ta-prometheus-ta-pod-metrics)"
cad_ta_cm="$(extract_cm verify-ta-prometheus-ta-cadvisor)"

grep -q 'job_name: pod-metrics' <<<"$pod_ta_cm" || {
  echo "pod-metrics TA ConfigMap is missing job_name: pod-metrics" >&2
  exit 1
}
if grep -q 'kubernetes-nodes-cadvisor' <<<"$pod_ta_cm"; then
  echo "pod-metrics TA ConfigMap leaked cadvisor job" >&2
  exit 1
fi
grep -q 'kubernetes-nodes-cadvisor' <<<"$cad_ta_cm" || {
  echo "cadvisor TA ConfigMap is missing kubernetes-nodes-cadvisor job" >&2
  exit 1
}
if grep -q 'job_name: pod-metrics' <<<"$cad_ta_cm"; then
  echo "cadvisor TA ConfigMap leaked pod-metrics job" >&2
  exit 1
fi

# Sharding strategy is set on both.
ta_count="$(grep -c 'allocation_strategy: consistent-hashing' <<<"$out" || true)"
if [[ "$ta_count" -lt 2 ]]; then
  echo "expected consistent-hashing on both TAs, found $ta_count" >&2
  exit 1
fi

# Invalid combo must fail at template time (prometheus-scraper-configmap.yaml).
bad_out="$(helm template bad-ta "$chart" --namespace testing \
  -f "$chart/ci/test-values.yaml" \
  --set application.prometheusScrape.independentDeployment=false \
  --set application.prometheusScrape.targetAllocator.enabled=true 2>&1)" || true
if ! grep -q 'targetAllocator.enabled requires application.prometheusScrape.independentDeployment=true' <<<"$bad_out"; then
  echo "expected helm template to fail when TA is enabled without independentDeployment" >&2
  echo "$bad_out" >&2
  exit 1
fi

# Non-TA render must still work (regression guard — no TA resources, inline scrape_configs kept).
plain_out="$(helm template plain "$chart" --namespace testing -f "$chart/ci/test-values.yaml")"
if grep -q 'prometheus-ta' <<<"$plain_out"; then
  echo "non-TA render should not include TA resources" >&2
  exit 1
fi
grep -q 'job_name: pod-metrics' <<<"$plain_out" || {
  echo "non-TA render is missing inline pod-metrics scrape_configs" >&2
  exit 1
}

echo "verify_agent_prometheus_ta_template.sh: OK"
