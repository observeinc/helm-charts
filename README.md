# Observe Helm Charts

Contents:
* stack: The Observe Kubernetes agent stack

The `stack` chart installs the following components, which are also provided as standalone charts:
* logs: Log collection (provided by fluent-bit)
* metrics: Metrics collection (provided by grafana-agent)
* traces: Traces collection (provided by opentelemetry-collector)
* events: Kubernetes cluster event collection

# Installation

## Configure secrets

First, store your datastream tokens as kubernetes secrets.

The Kubernetes datastream token:

```bash
OBSERVE_TOKEN='some_token'
kubectl -n observe create secret generic credentials \
        --from-literal=OBSERVE_TOKEN=${OBSERVE_TOKEN?}
```

The OpenTelemetry datastream token:

```bash
OBSERVE_OTEL_TOKEN='connection_token_for_otel_app'
kubectl -n observe create secret generic otel-credentials \
        --from-literal=OBSERVE_TOKEN=${OBSERVE_OTEL_TOKEN?}
```

## Local chart install

To install `stack`, first install the chart dependencies:

```bash
helm dep update stack
```

Then install `stack`:

```bash
helm install --namespace=observe --create-namespace observe stack \
    --set global.observe_customer=mycustomerID
```
