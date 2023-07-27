#!/bin/sh

repo=$(git rev-parse --show-toplevel)
cluster="$2"

create_cluster() {
    kind create cluster --kubeconfig "$repo/.kubeconfig" -n $cluster
}

delete_cluster() {
    kind delete cluster --kubeconfig "$repo/.kubeconfig" -n $cluster
}

load_images() {
    kind load docker-image -n $cluster test-client:latest
    kind load docker-image -n $cluster test-collector:latest
}

"$1"
