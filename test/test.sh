#!/bin/sh

set -e

repo=$(git rev-parse --show-toplevel)

trap $repo/test/clean.sh EXIT

kubectl create namespace testing 2>/dev/null || true

for chart in stack traces; do
    echo
    echo "Testing chart/$chart..."
    sleep 1

    helm install -n testing --wait test-$chart charts/$chart -f charts/$chart/ci/test-values.yaml
    echo
    helm test -n testing --filter name=test-$chart test-$chart

    echo
    echo chart/$chart tests PASSED
    echo 
    echo results:
    kubectl -n testing logs test-$chart
    echo

    helm uninstall --wait -n testing test-$chart 2>/dev/null
    kubectl -n testing delete configmap/cluster-info 2>/dev/null || true
done
