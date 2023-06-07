# Observe Helm Charts

This repository contains Helm charts for installing the telemetry agents required for Observe Kubernetes apps.

Contents:
* stack: Installs several agents required for the Kubernetes Observe app
  * logs (provided by fluent-bit)
  * metrics (provide by grafana-agent)
  * events (kubernetes state events)
* traces: Installs trace collection for the OpenTelemetry Observe app

# Installation

First, install and update the observe helm repository:

```bash
helm repo add observe https://observeinc.github.io/helm-charts
helm repo update
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

## Sizing

By default, we attempt to choose defaults which have a wide operating
range. However, some clusters will inevitably fall outside this range. We
provide example values files corresponding to several different use cases:

- [stack/xs](https://github.com/observeinc/helm-charts/tree/main/examples/stack/values-xs.yaml) - intended to run on small clusters such as development environments, where resources are scarce and reliability is less of a concern
- [stack/m](https://github.com/observeinc/helm-charts/tree/main/examples/stack/values-m.yaml) - the default sizing, intended to run on clusters with hundreds of pods. Start here and adjust up or down accordingly.
- [stack/l](https://github.com/observeinc/helm-charts/tree/main/examples/stack/values-l.yaml) - used for similar sized clusters as `m`, but with higher throughput in logs, metrics or events. This may be due to verbose logging, high cardinality metrics or frequent cluster reconfiguration.
- [stack/xl](https://github.com/observeinc/helm-charts/tree/main/examples/stack/values-xl.yaml) - intended to run on large clusters with 100+ nodes. Collection is preferentially performed using daemonsets rather than deployments.

Resource limits for each sizing is as follows:

|         |     `xs`     |      `m`      |      `l`      |     `xl`      |
|--------:|:------------:|:-------------:|:-------------:|:-------------:|
|  events | 20m<br>64Mi  | 50m<br>256Mi  |  200m<br>1Gi  |  400m<br>2Gi  |
|    logs | 10m<br>64Mi  | 100m<br>128Mi | 200m<br>192Mi | 500m<br>256Mi |
| metrics | 50m<br>256Mi |  250m<br>2Gi  |  500m<br>4Gi  | 200m*<br>1Gi  |

By default, the `logs` component is a daemonset, while `events` and `metrics` are
single-replica deployments. Some use cases may require scaling the `metrics`
agent beyond a single replica; in this case we recommend using a daemonset.
Configuration for this is provided in [stack/xl](https://github.com/observeinc/helm-charts/tree/main/examples/stack/values-xl.yaml).

## Installation

We recommend following the convention "observe-\<chart name\>" for release names.

Stack:
```bash
# installing with a custom values file
helm install --namespace=observe --create-namespace \
  observe-stack observe/stack -f my_values.yaml

# installing by setting values on the command line
helm install --namespace=observe --create-namespace \
  --set-json 'global.observe.customerID="123456789012"' \
  --set-json 'observe.token.value="..."' \
  observe-stack observe/stack
```

Traces:
```bash
# installing with a custom values file
helm install --namespace=observe --create-namespace \
  observe-traces observe/traces -f my_values.yaml

# installing by setting values on the command line
helm install --namespace=observe --create-namespace \
  --set-json 'global.observe.customer="123456789012"' \
  --set-json 'observe.token.value="..."' \
  observe-stack observe/traces
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
