#!/bin/sh
set -ex

repo=$(git rev-parse --show-toplevel)
make -C "$repo" build-deps
ct lint --all
make -C "$repo" test-images
kind load docker-image -n chart-testing test-client:latest
kind load docker-image -n chart-testing test-collector:latest
kubectl create namespace testing || true
ct install --namespace testing --charts charts/stack
kubectl -n testing delete configmap/cluster-info
ct install --namespace testing --charts charts/traces
