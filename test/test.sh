#!/bin/sh

set -e

repo=$(git rev-parse --show-toplevel)
id=$(openssl rand -hex 10)
cluster="helm-chart-testing-$id"
ns="testing"
helm="helm --kubeconfig=$repo/.kubeconfig --namespace $ns"

trap $repo/test/clean.sh EXIT

echo "$cluster" > $repo/test/kind.cluster
$repo/test/kind.sh create_cluster "$cluster"
$repo/test/kind.sh load_images "$cluster"

kc="kubectl --context kind-$cluster --kubeconfig $repo/.kubeconfig --namespace $ns"
$kc create namespace $ns || true

podlogs() {
    for pod in $($kc get pods -o=name); do
        echo "@@@@@@@@@@@@@@@@@@@" "START:" kubectl logs $pod "@@@@@@@@@@@@@@@@@@@"
        $kc logs $pod
        echo "@@@@@@@@@@@@@@@@@@@" "END:" kubectl logs $pod "@@@@@@@@@@@@@@@@@@@"
        echo
    done
}

for chart in "$@"; do
    echo
    echo "Testing charts/$chart..."
    echo

    echo dependencies for $chart:
    $helm dep list $repo/charts/$chart
    echo

    $helm install --debug --wait test-$chart $repo/charts/$chart -f $repo/charts/$chart/ci/test-values.yaml
    sleep 30 # allow some observations to come through once everything is ready
    echo
    $helm test --filter name=test-$chart test-$chart ||
        {
            echo
            echo charts/$chart tests FAILED
            echo
            echo results:
            $kc logs test-$chart
            echo
            podlogs
            echo
            echo pods:
            $kc get pods
            echo
            echo daemonsets:
            $kc get daemonsets
            echo
            echo deployments:
            $kc get deployments
            echo
            echo services:
            $kc get services
            exit 1
        }

    echo
    echo charts/$chart tests PASSED
    echo
    echo results:
    $kc logs test-$chart
    echo

    $helm uninstall --wait test-$chart 2>/dev/null
done
