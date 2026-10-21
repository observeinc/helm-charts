# OpenTelemetry Collector Helm chart values for Kubernetes

These values deploy the upstream [OpenTelemetry Collector Helm chart](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) (`otelcol-contrib`) to send Kubernetes telemetry to Observe, instead of the Observe Agent Helm chart. They run the same processors and pipelines as the Observe Agent chart, so the data arrives in the shape that Observe's explorers expect. For a collector on a single host, see the [host example](https://github.com/observeinc/observe-agent/tree/main/examples/oss-collector) in the `observeinc/observe-agent` repository.

They enable every collection feature of the Observe Agent chart. Not included: the gateway deployment, an optional forwarding tier that samples traces; collection for nodeless clusters such as EKS Fargate, which replaces the node collectors; and the Prometheus target allocator, which shards scraping and discovers ServiceMonitor and PodMonitor resources.

Install one release of the chart per collector:

| Values | Runs as | What it collects |
| :----- | :------ | :--------------- |
| [`forwarder-values.yaml`](forwarder-values.yaml) | DaemonSet | Application traces, logs, and metrics over OTLP, and RED (request rate, error, and duration) metrics generated from traces |
| [`node-values.yaml`](node-values.yaml) | DaemonSet | Container logs, with multi-line entries such as stack traces kept together, kubelet stats, and node metrics |
| [`cluster-metrics-values.yaml`](cluster-metrics-values.yaml) | Deployment with one replica | Cluster-level Kubernetes metrics, container metrics from each node's cAdvisor, and Prometheus metrics scraped from pods |
| [`cluster-events-values.yaml`](cluster-events-values.yaml) | Deployment with one replica | Kubernetes objects and events for Kubernetes Explorer |
| [`monitor-values.yaml`](monitor-values.yaml) | Deployment with one replica | The other collectors' internal metrics, for monitoring the collectors in Observe |

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

2. Install each collector with the `helm install` command at the top of its values file. Keep the chart version it names: the values are made for that chart version, and they pin the collector image to the `otelcol-contrib` version the Observe Agent is built with, which the header also names.

   ```sh
   helm install observe-forwarder opentelemetry-collector \
     --repo https://open-telemetry.github.io/opentelemetry-helm-charts \
     --version <chart version from the file> --namespace observe --values forwarder-values.yaml
   ```

## Scrape Prometheus metrics from your pods

The cluster-metrics collector scrapes every pod that has a container port whose name ends in `metrics`, or a `prometheus.io/port` annotation, every 60 seconds. Set `prometheus.io/path` or `prometheus.io/scheme` to change the path or scheme, and `prometheus.io/scrape: "false"` to skip a pod. Pods in `kube-system` and in namespaces whose names contain `istio` or `ingress` aren't scraped.

## What the values set

The collector configuration is in `alternateConfig`, which replaces the chart's default configuration instead of merging into it, so none of the chart's default receivers and exporters are added. The rest of each file sets what the collector needs, as the Observe Agent chart does: downward API variables, feature gates, host volumes, security context, resources, ports, the Service, and the pod annotations the monitor collector finds the collectors by. Each collector serves its internal metrics on port 8888 of its pod IP for the monitor collector, as the Observe Agent does. Each release's service account gets the same read-only RBAC rules as the Observe Agent chart, which allow reading every resource in the cluster; narrow `clusterRole.rules` if you need to.

`cluster-events-values.yaml` sends Kubernetes objects, including Secrets, to Observe. Its `transform/redact_secrets` processor replaces Secret values with `REDACTED` and removes the `kubectl.kubernetes.io/last-applied-configuration` annotation, as the Observe Agent does; keep it if you change the configuration. The Observe Agent also adds status and relationship fields to objects with its own `observek8sattributes` processor, which `otelcol-contrib` doesn't include, so parts of Kubernetes Explorer that use those fields stay empty.

The values files are generated from the Observe Agent chart and checked in CI, so don't edit them here. [`scripts/`](scripts/) generates them, and `rendered/` is the Observe Agent chart output they're generated from.
