#!/bin/sh

set -e

repo=$(git rev-parse --show-toplevel)

trap $repo/test/clean.sh EXIT

ns=testing
kubectl create namespace $ns 2>/dev/null || true

podlogs() {
    for pod in $(kubectl get pods -n $ns -o=name); do
        echo "@@@@@@@@@@@@@@@@@@@" "START:" kubectl logs -n $ns $pod "@@@@@@@@@@@@@@@@@@@"
        kubectl logs -n $ns $pod
        echo "@@@@@@@@@@@@@@@@@@@" "END:" kubectl logs -n $ns $pod "@@@@@@@@@@@@@@@@@@@"
        echo
    done
}

for chart in "$@"; do
    echo
    echo "Testing chart/$chart..."
    sleep 1

    helm install -n $ns --wait test-$chart charts/$chart -f charts/$chart/ci/test-values.yaml
    echo
    helm test -n $ns --filter name=test-$chart test-$chart ||
        {
            echo
            echo chart/$chart tests FAILED
            echo 
            echo results:
            kubectl -n $ns logs test-$chart
            echo
            podlogs
            exit 1
        }

    echo
    echo chart/$chart tests PASSED
    echo 
    echo results:
    kubectl -n $ns logs test-$chart
    echo

    helm uninstall --wait -n $ns test-$chart 2>/dev/null
    kubectl -n $ns delete configmap/cluster-info 2>/dev/null || true
done
