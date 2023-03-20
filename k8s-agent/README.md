This Helm chart installs the Observe Kubernetes agent stack for ingesting data into Observe.

# Quick Start

## Configure secrets
```bash
OBSERVE_TOKEN='connection_token_for_otel_app'
kubectl -n observe create secret generic otel-credentials \
        --from-literal=OBSERVE_TOKEN=${OBSERVE_TOKEN?}
```

## Local chart install
```bash
$ helm install -n observe observe-stack observe \
    --set global.observe_customer=mycustomerID
```
