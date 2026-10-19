# OpenTelemetry Collector examples for Kubernetes

These examples show how to send Kubernetes telemetry to Observe with a plain [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) (`otelcol-contrib`) instead of the Observe Agent Helm chart. They use the same processors and pipelines as the Observe Agent chart, so the data arrives in the shape that Observe's explorers expect. For a collector on a single host, see the [host example](https://github.com/observeinc/observe-agent/tree/main/examples/oss-collector) in the `observeinc/observe-agent` repository.

There are three collectors. Each comes as values for the upstream [OpenTelemetry Collector Helm chart](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) in `helm/`, and as a plain collector configuration in `collector/` for other ways of deploying it:

| OpenTelemetry Collector chart values | Collector configuration | Runs as | What it collects |
| :----------------------------------- | :---------------------- | :------ | :--------------- |
| [`helm/forwarder-values.yaml`](helm/forwarder-values.yaml) | [`collector/forwarder.yaml`](collector/forwarder.yaml) | DaemonSet | Application traces, logs, and metrics over OTLP, and RED (request rate, error, and duration) metrics generated from traces |
| [`helm/node-values.yaml`](helm/node-values.yaml) | [`collector/node.yaml`](collector/node.yaml) | DaemonSet | Container logs, kubelet stats, and node metrics |
| [`helm/cluster-metrics-values.yaml`](helm/cluster-metrics-values.yaml) | [`collector/cluster-metrics.yaml`](collector/cluster-metrics.yaml) | Deployment with one replica | Cluster-level Kubernetes metrics |

The collectors read these environment variables:

- `OBSERVE_COLLECTION_URL` and `OBSERVE_TOKEN`: your collection URL and an Observe ingest token.
- `OBSERVE_CLUSTER_NAME` and `OBSERVE_CLUSTER_UID`: the cluster name, and the UID of the `kube-system` namespace (`kubectl get namespace kube-system -o jsonpath='{.metadata.uid}'`).
- `DEPLOYMENT_ENVIRONMENT`: the fallback `deployment.environment.name`. Telemetry that already sets an environment, for example with `OTEL_RESOURCE_ATTRIBUTES` or a `resource.opentelemetry.io/deployment.environment.name` pod annotation, keeps its own value. See [Set the deployment environment](https://docs.observeinc.com/docs/set-the-deployment-environment#/).
- `MY_POD_IP` and `K8S_NODE_NAME`: from the downward API (`status.podIP` and `spec.nodeName`).

## Deploy with the OpenTelemetry Collector Helm chart

1. Create the `observe-collector` Secret that the chart values read the first five variables from:

   ```sh
   kubectl create namespace observe
   kubectl --namespace observe create secret generic observe-collector \
     --from-literal=OBSERVE_COLLECTION_URL=<your collection URL> \
     --from-literal=OBSERVE_TOKEN=<your ingest token> \
     --from-literal=OBSERVE_CLUSTER_NAME=<your cluster name> \
     --from-literal=OBSERVE_CLUSTER_UID=$(kubectl get namespace kube-system -o jsonpath='{.metadata.uid}') \
     --from-literal=DEPLOYMENT_ENVIRONMENT=<your environment>
   ```

2. Install one release of the chart for each collector. The top of each values file shows its `helm install` command, with the chart version the file is made for:

   ```sh
   helm install observe-forwarder opentelemetry-collector \
     --repo https://open-telemetry.github.io/opentelemetry-helm-charts \
     --version <chart version from the file> --namespace observe --values helm/forwarder-values.yaml
   ```

The values set everything else the collector needs, as the Observe Agent chart does: the downward API variables, feature gates, host volumes, security context, resources, ports, and the Service. They give each release's service account the same read-only RBAC rules as the Observe Agent chart, which allow reading every resource in the cluster; narrow `clusterRole.rules` if you need to.

The collector configuration is in `alternateConfig`, which replaces the chart's default configuration instead of merging into it, so none of the chart's default receivers and exporters are added.

## Deploy the collector configurations yourself

To deploy with your own manifests or the OpenTelemetry Operator, use the files in `collector/`. Each one lists, at the top, the environment variables to set on the collector container and the `--feature-gates` argument to start it with, as the Observe Agent chart does. Without the feature gates the collector still starts, but parts of the configuration behave differently than in the chart.

The collectors also need:

- A service account with read access to pods, namespaces, nodes, ReplicaSets, Deployments, and the other workload resources, for the `k8sattributes` processor and the `k8s_cluster` receiver. `node.yaml` also needs access to the `nodes/stats` and `nodes/proxy` resources for kubelet stats.
- For `node.yaml`: the node's root filesystem mounted read-only at `/hostfs`, `/var/log/pods` mounted read-only, and a writable volume at `/var/lib/otelcol/file_storage` so that log read positions survive restarts.
- For `forwarder.yaml`: ports 4317 (gRPC) and 4318 (HTTP) exposed so applications on the node can send OTLP to the collector.
- A liveness and readiness probe on port 13133, where the `health_check` extension listens.

## Where these files come from

The files in `helm/` and `collector/` are generated from the Observe Agent chart and checked in CI, so don't edit them by hand. `rendered/` is the Observe Agent chart output they're generated from; you don't need it to deploy. See [`scripts/oss-collector`](../../scripts/oss-collector/).
