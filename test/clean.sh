#!/bin/sh

helm uninstall --wait -n testing test-stack 2>/dev/null
helm uninstall --wait -n testing test-traces 2>/dev/null
kubectl -n testing delete configmap/cluster-info 2>/dev/null
kubectl delete namespace testing 2>/dev/null 
exit 0
