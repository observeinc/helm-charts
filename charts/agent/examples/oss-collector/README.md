# OpenTelemetry Collector Helm chart values for Kubernetes

These values deploy the upstream [OpenTelemetry Collector Helm chart](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) (`otelcol-contrib`) to send Kubernetes telemetry to Observe, instead of the Observe Agent Helm chart. They run the same processors and pipelines as the Observe Agent chart, so the data arrives in the shape that Observe's explorers expect. For a collector on a single host, see the [host example](https://github.com/observeinc/observe-agent/tree/main/examples/oss-collector) in the `observeinc/observe-agent` repository.

Install one release of the chart per collector:

| Values | Runs as | What it collects |
| :----- | :------ | :--------------- |
| [`forwarder-values.yaml`](forwarder-values.yaml) | DaemonSet | Application traces, logs, and metrics over OTLP, and RED (request rate, error, and duration) metrics generated from traces |
| [`node-values.yaml`](node-values.yaml) | DaemonSet | Container logs, kubelet stats, and node metrics |
| [`cluster-metrics-values.yaml`](cluster-metrics-values.yaml) | Deployment with one replica | Cluster-level Kubernetes metrics |

## Deploy

1. Create the `observe-collector` Secret that the collectors read their settings from:

   ```sh
   kubectl create namespace observe
   kubectl --namespace observe create secret generic observe-collector \
     --from-literal=OBSERVE_COLLECTION_URL=<your collection URL> \
     --from-literal=OBSERVE_TOKEN=<your ingest token> \
     --from-literal=OBSERVE_CLUSTER_NAME=<your cluster name> \
     --from-literal=OBSERVE_CLUSTER_UID=$(kubectl get namespace kube-system -o jsonpath='{.metadata.uid}') \
     --from-literal=DEPLOYMENT_ENVIRONMENT=<your environment>
   ```

   `DEPLOYMENT_ENVIRONMENT` is the fallback `deployment.environment.name`. Telemetry that already sets an environment, for example with `OTEL_RESOURCE_ATTRIBUTES` or a `resource.opentelemetry.io/deployment.environment.name` pod annotation, keeps its own value. See [Set the deployment environment](https://docs.observeinc.com/docs/set-the-deployment-environment#/).

2. Install each collector with the `helm install` command at the top of its values file, which includes the chart version the file is made for:

   ```sh
   helm install observe-forwarder opentelemetry-collector \
     --repo https://open-telemetry.github.io/opentelemetry-helm-charts \
     --version <chart version from the file> --namespace observe --values forwarder-values.yaml
   ```

## What the values set

The collector configuration is in `alternateConfig`, which replaces the chart's default configuration instead of merging into it, so none of the chart's default receivers and exporters are added. The rest of each file sets what the collector needs, as the Observe Agent chart does: downward API variables, feature gates, host volumes, security context, resources, ports, and the Service. Each release's service account gets the same read-only RBAC rules as the Observe Agent chart, which allow reading every resource in the cluster; narrow `clusterRole.rules` if you need to.

The values files are generated from the Observe Agent chart and checked in CI, so don't edit them here. [`scripts/`](scripts/) generates them, and `rendered/` is the Observe Agent chart output they're generated from.
