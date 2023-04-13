This Helm chart installs the Observe Kubernetes agent stack for ingesting data into Observe.

# Quick Start

## Configure secrets

```bash
OBSERVE_TOKEN='some_token'
kubectl -n observe create secret generic credentials \
        --from-literal=OBSERVE_TOKEN=${OBSERVE_TOKEN?}
```

```bash
OBSERVE_OTEL_TOKEN='connection_token_for_otel_app'
kubectl -n observe create secret generic otel-credentials \
        --from-literal=OBSERVE_TOKEN=${OBSERVE_OTEL_TOKEN?}
```

## Local chart install
```bash
$ helm install --namespace=observe --create-namespace observe . \
    --set global.observe_customer=mycustomerID
```
