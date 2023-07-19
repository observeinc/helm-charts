#!/bin/sh

repo=$(git rev-parse --show-toplevel)
ns="testing"

test -f $repo/test/kind.cluster && cluster=$(cat $repo/test/kind.cluster)
rm -f $repo/test/kind.cluster

kc="kubectl --context kind-$cluster --kubeconfig $repo/.kubeconfig --namespace $ns"
helm="helm --kubeconfig=$repo/.kubeconfig --namespace $ns"

$helm uninstall --wait test-stack 2>/dev/null
$helm uninstall --wait test-traces 2>/dev/null
$kc delete configmap/cluster-info 2>/dev/null
$kc delete namespace $ns 2>/dev/null
test -z "$cluster" || $repo/test/kind.sh delete_cluster $cluster
