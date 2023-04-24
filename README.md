# Observe Helm Charts

This repository contains Helm charts for installing the telemetry agents required for Observe Kubernetes apps.

Contents:
* stack: Installs several agents required for the Kubernetes Observe app
  * logs (provided by fluent-bit)
  * metrics (provide by grafana-agent)
  * events (kubernetes state events)
* traces: Installs trace collection for the OpenTelemetry Observe app

# Installation

First, update the chart dependencies:

```bash
make deps
```

## Required Values
You must set `global.observe.customer`. To have Helm create a Kubernetes secret containing your
datastream token, you must also set `observe.token.value`. Otherwise, you must set `observe.token.create`
to `false`, and manually create the secrets (see [Managing Secrets Manually](#managing-secrets-manually)).

These values can be set in a custom values file:

```yaml
global:
  observe:
    customer: "123456789012"

observe:
  token:
    value: <datastream token>
```

Or using the `--set` flag during installation.

## Installation

We recommend following the convention "observe-\<chart name\>" for release names.

Stack:
```bash
# custom values file
helm install -n observe observe-stack ./stack -f my_values.yaml

# using --set
helm install -n observe observe-stack ./stack \
  --set global.observe.customer=\"123456789012\" \
  --set observe.token.value=...
```

Traces:
```bash
# custom values file
helm install -n observe observe-traces ./staces -f my_values.yaml

# using --set
helm install -n observe observe-stack ./stack \
  --set global.observe.customer=\"123456789012\" \
  --set observe.token.value=...
```

# Managing Secrets Manually

If you do not wish to have Helm manage your token as a Kubernetes secret (for example,
to prevent it from appearing when `helm get values observe-stack` is run), you can create
it manually.

## Stack

```bash
kubectl -n observe create secret generic credentials --from-literal=OBSERVE_TOKEN=<datastream token>
```

## Traces

```bash
kubectl -n observe create secret generic otel-credentials --from-literal=OBSERVE_TOKEN=<datastream token>
```
