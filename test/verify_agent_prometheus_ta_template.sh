#!/usr/bin/env bash
set -euo pipefail

CHART_DIR="$(cd "$(dirname "$0")/../charts/agent" && pwd)"
TA_VALUES="${CHART_DIR}/ci/prometheus-ta-values.yaml"
DEFAULT_VALUES="${CHART_DIR}/ci/test-values.yaml"

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; exit 1; }

# ─── Render the merged-receiver template ──────────────────────────────────────
TA_MANIFEST=$(helm template test-release "${CHART_DIR}" -f "${TA_VALUES}")

COLLECTOR_CM=$(echo "${TA_MANIFEST}" | awk 'BEGIN{RS="---\n"} /kind: ConfigMap/ && /name: prometheus-scraper/')

# 1. Collector uses single prometheus/k8s_metrics receiver
echo "${COLLECTOR_CM}" | grep -q 'prometheus/k8s_metrics' \
  && pass "Collector uses prometheus/k8s_metrics receiver" \
  || fail "Collector is missing prometheus/k8s_metrics receiver"

# 2. Collector does NOT use the old per-job receivers in merged mode
echo "${COLLECTOR_CM}" | grep -q 'prometheus/pod_metrics' \
  && fail "Collector still has prometheus/pod_metrics in merged mode" \
  || pass "Collector has no prometheus/pod_metrics in merged mode"

# 3. Merged receiver has pod-metrics job inline
echo "${COLLECTOR_CM}" | grep -q 'job_name: pod-metrics' \
  && pass "Merged receiver has pod-metrics job inline" \
  || fail "Merged receiver missing pod-metrics job"

# 4. Merged receiver has cadvisor job inline
echo "${COLLECTOR_CM}" | grep -q 'job_name.*kubernetes-nodes-cadvisor' \
  && pass "Merged receiver has cadvisor job inline" \
  || fail "Merged receiver missing cadvisor job"

# 5. Collector config has filter processors
echo "${COLLECTOR_CM}" | grep -q 'filter/pod_metrics' \
  && pass "Collector has filter/pod_metrics processor" \
  || fail "Collector missing filter/pod_metrics processor"
echo "${COLLECTOR_CM}" | grep -q 'filter/cadvisor' \
  && pass "Collector has filter/cadvisor processor" \
  || fail "Collector missing filter/cadvisor processor"

# ─── Render the default (non-merged) template ─────────────────────────────────
DEFAULT_MANIFEST=$(helm template test-release "${CHART_DIR}" -f "${DEFAULT_VALUES}")

# 6. Default path uses original per-job receivers
DEFAULT_CM=$(echo "${DEFAULT_MANIFEST}" | awk 'BEGIN{RS="---\n"} /kind: ConfigMap/ && /name: prometheus-scraper/')
echo "${DEFAULT_CM}" | grep -q 'prometheus/pod_metrics' \
  && pass "Default path has prometheus/pod_metrics receiver" \
  || fail "Default path missing prometheus/pod_metrics receiver"

echo ""
echo "All checks passed."
