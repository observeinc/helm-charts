# Observe Helm Charts

This repository contains Helm charts for installing the telemetry agents required for Observe apps on Kubernetes.

Contents:
* stack: Installs several agents required for the Kubernetes Observe app
  * logs (provided by fluent-bit)
  * metrics (provide by grafana-agent)
  * events (kubernetes state events)
* traces: Installs trace collection for the OpenTelemetry Observe app

# Quick Start

First, install and update the observe helm repository:

```bash
helm repo add observe https://observeinc.github.io/helm-charts
helm repo update
```

## Namespace

We currently require that Observe charts are installed to an `observe` namespace.
The namespace should further be annotated with a human-readable cluster name. Helm
supports creating namespaces as a convenience feature, but does not support managing
and configuring the namespace (that is, the `--create-namespace` option in `helm install`
is equivalent to manually running `kubectl create namespace`). Thus it is recommended to
manage the namespace externally to Helm. This can likely be done by following the same
methodology you use to manage the creation of your Kubernetes clusters, and/or your other
namespaces.

You can also manage the namespace manually using the following commands:
```
CLUSTER_NAME="My Cluster"
kubectl create namespace observe && \
	kubectl annotate namespace observe observeinc.com/cluster-name="$CLUSTER_NAME"
```

## Installing Stack

The values for `${OBSERVE_COLLECTION_ENDPOINT}` and `${OBSERVE_TOKEN}` are provided
when you install the Kubernetes app in Observe, and set up a new connection.

```
helm install --namespace=observe observe-stack observe/stack \
	--set global.observe.collectionEndpoint="${OBSERVE_COLLECTION_ENDPOINT}" \
	--set observe.token.value="${OBSERVE_TOKEN}"

# store values for further configuration and upgrades
helm -n observe get values observe-stack -o yaml > observe-stack-values.yaml
```

## Installing Traces

The values for `${OBSERVE_COLLECTION_ENDPOINT}` and `${OBSERVE_TOKEN}` are provided
when you install the OpenTelemetry app in Observe, and set up a new connection.

The same token should not be re-used for the `stack` (Kubernetes) and `traces` (OpenTelemetry)
charts. Instead, create a new connection for the OpenTelemetry app, and provide the new token
you are prompted to create.

```
helm install --namespace=observe observe-traces observe/traces \
	--set global.observe.collectionEndpoint="${OBSERVE_COLLECTION_ENDPOINT}" \
  --set observe.token.value="${OBSERVE_TOKEN}" \
  --create-namespace


# store values for further configuration and upgrades
helm -n observe get values observe-traces -o yaml > observe-traces-values.yaml
```

### Using v2 of OpenTelemetry collection endpoint

If you are using the 1.0.0 release of the OpenTelemetry Observe app or newer, you should use the v2 collection endpoint which
provides a more efficient representation of trace observations in the datastream. To use the v2 collection endpoint,
set `global.observe.otelPath` to `/v2/otel`. The default value is `/v1/otel`.

If you are installing the `traces` chart:

```
helm install --namespace=observe observe-traces observe/traces \
	--set global.observe.collectionEndpoint="${OBSERVE_COLLECTION_ENDPOINT}" \
	--set global.observe.otelPath="/v2/otel" \
	--set observe.token.value="${OBSERVE_TOKEN}"
```

When upgrading the `traces` chart:

```
helm upgrade --namespace=observe observe-traces observe/traces --reuse-values \
	--set global.observe.otelPath="/v2/otel"
```

# Configuration

## Required Values
You must set `global.observe.collectionEndpoint`, which is provided when configuring a connection in
Observe. To have Helm manage a Kubernetes secret containing your datastream token, you must also set
`observe.token.value`. Otherwise, you must set `observe.token.create` to `false`, and manually create
the secrets (see [Managing Secrets Manually](#managing-secrets-manually)).

These values should be persisted in a custom values file:

```yaml
global:
  observe:
    # A unique URL associated with your customer ID, provided in the new connection installation instructions.
    collectionEndpoint: "https://123456789012.collect.observeinc.com"

observe:
  token:
    # The Datastream token. This will typically be unique to each chart being installed, or each release of
    # of a chart.
    value: <datastream token>
```

## Kubernetes Event Batch Limits

You can add `-collector-listerwatcher-limit batch_size` to the
`kube-state-events` container args to adjust the batch size
(default is 500). This can reduce initial memeory usage, which
may allow you to run a smaller container.

## Sizing

While the default configuration of the observe charts are intended to be appropriate for a variety of use cases,
additional example configurations are also provided for other cases:

- [examples/stack/values-xs.yaml](https://github.com/observeinc/helm-charts/tree/main/examples/stack/values-xs.yaml) and [examples/traces/values-xs.yaml](https://github.com/observeinc/helm-charts/tree/main/examples/traces/values-xs.yaml) - intended to run on small clusters such as development environments, where resources are scarce and reliability is less of a concern
- [examples/stack/values-m.yaml](https://github.com/observeinc/helm-charts/tree/main/examples/stack/values-m.yaml) and [examples/traces/values-m.yaml](https://github.com/observeinc/helm-charts/tree/main/examples/traces/values-m.yaml) - the default sizing, intended to run on clusters with hundreds of pods. Start here and adjust up or down accordingly.
- [examples/stack/values-l.yaml](https://github.com/observeinc/helm-charts/tree/main/examples/stack/values-l.yaml) - used for similar sized clusters as `m`, but with higher throughput in logs, metrics or events. This may be due to verbose logging, high cardinality metrics or frequent cluster reconfiguration.
- [examples/stack/values-xl.yaml](https://github.com/observeinc/helm-charts/tree/main/examples/stack/values-xl.yaml) - intended to run on large clusters with 100+ nodes. Collection is preferentially performed using daemonsets rather than deployments.
- [examples/traces/values-deployment.yaml](https://github.com/observeinc/helm-charts/tree/main/examples/traces/values-deployment.yaml) - a sample configuration of a 10-replica deployment of the traces agent. Adjust the sizing and replica count as needed.

Resource allocations for each example configuration are as follows:

|         |     `xs`     |      `m`      |      `l`      |     `xl`      |
|--------:|:------------:|:-------------:|:-------------:|:-------------:|
|  events | 20m<br>64Mi  | 50m<br>256Mi  |  200m<br>1Gi  |  400m<br>2Gi  |
|    logs | 10m<br>64Mi  | 100m<br>128Mi | 200m<br>192Mi | 500m<br>256Mi |
| metrics | 50m<br>256Mi |  250m<br>2Gi  |  500m<br>4Gi  | 200m *(ds)*<br>1Gi  |


|         |     `xs`     |      `m`      |       `deployment`      |
|--------:|:------------:|:-------------:|:-----------------------:|
|  traces | 50m *(ds)*<br>128Mi | 250m *(ds)*<br>256Mi |  250m *(x10)*<br>256Mi  |

By default, `logs` and `traces` are daemonsets, while `events` and `metrics` are
single-replica deployments. Some use cases may require scaling the `metrics`
agent beyond a single replica; in this case we recommend using a daemonset.

## Advanced Configuration

The subcharts managed by the parent `stack` and `traces` charts can be further configured according
to the upstream charts. Refer to the documentation for these charts directly for advanced configuration:
- [grafana-agent](https://github.com/grafana/agent/tree/helm-chart/0.10.0/operations/helm/charts/grafana-agent)
- [fluent-bit](https://github.com/fluent/helm-charts/tree/fluent-bit-0.25.0/charts/fluent-bit)
- [openetelemetry-collector](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/opentelemetry-collector-0.61.2/charts/opentelemetry-collector)

Keep in mind that these upstream charts are managed by Observe's parent charts, which provide
the default configuration necessary to publish the data to Observe. This means that changes to
the underlying upstream charts must be specified in the appropriate YAML blocks.

Stack:
```
logs:
  fluent-bit:
    # advanced fluent-bit configuration overrides begin at this level of indentation

metrics:
  grafana-agent:
    # advanced grafana-agent configuration overrides begin at this level of indentation
```

Traces:
```
opentelemetry-collector:
  # advanced opentelemetry-collector configuration overrides begin at this level of indentation
```

## Managing Secrets Manually

If you do not wish to have Helm manage your token as a Kubernetes secret (which implies
that it will be stored as a chart value), you can manage it manually. To prevent the chart
from managing the secret, first set `observe.token.create` to `false`.

Then, ensure a secret exists in the observe namespace with the correct name:

## Stack

```bash
kubectl -n observe create secret generic credentials --from-literal='OBSERVE_TOKEN=<kubernetes datastream token>'
```

## Extra configuration files for fluent-bit

You can also add extra fluent-bit configuration files like this:
```
logs:
  fluent-bit:
    config:
      extraFiles:
        systemd.conf: |
          [INPUT]
              Name                systemd
              Tag                 systemd
              Read_From_Tail      on
```

Every file in the `extraFiles` section will be mounted in the `/fluent-bit/etc/custom-configs` directory.
These files will be included in the main `fluent-bit.conf` file by `@INCLUDE` directive which is configured
as part of `outputs` default configuration value (for some reason fluent-bit subchart doesn't include these files by default).

If you're overriding the `outputs` default configuration, you can include the extra files in your custom configuration file like this:

```
logs:
  fluent-bit:
    config:
      outputs: |
        [OUTPUT]
            Name                http
            # other output configuration...

        {{- include "observe.includeExtraFiles" . }}
```

## Traces

```bash
kubectl -n observe create secret generic otel-credentials --from-literal='OBSERVE_TOKEN=<opentelemetry datastream token>'
```

## Uninstall Stack
```helm -n observe uninstall observe-stack```

## Uninstall Traces
```helm -n observe uninstall observe-traces```

# Build

## Dependencies

Kind needs to be installed in order to build and test this repository:

https://kind.sigs.k8s.io/docs/user/quick-start/
