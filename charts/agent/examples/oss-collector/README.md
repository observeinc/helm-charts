# OpenTelemetry Collector examples for Kubernetes

These examples show how to send Kubernetes telemetry to Observe with a plain [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) (`otelcol-contrib`) instead of the Observe Agent Helm chart. They use the same processors and pipelines as the chart, so the data arrives in the shape that Observe's explorers expect. For a collector on a single host, see the [host example](https://github.com/observeinc/observe-agent/tree/main/examples/oss-collector) in the `observeinc/observe-agent` repository.

There are three collectors. Each comes as values for the upstream [OpenTelemetry Collector Helm chart](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) in `upstream-chart/`, and as a plain collector configuration in `collector/` for other ways of deploying it:

| Chart values | Collector configuration | Runs as | What it collects |
| :----------- | :---------------------- | :------ | :--------------- |
| [`forwarder-values.yaml`](upstream-chart/forwarder-values.yaml) | [`forwarder.yaml`](collector/forwarder.yaml) | DaemonSet | Application traces, logs, and metrics over OTLP, and RED (request rate, error, and duration) metrics generated from traces |
| [`node-values.yaml`](upstream-chart/node-values.yaml) | [`node.yaml`](collector/node.yaml) | DaemonSet | Container logs, kubelet stats, and node metrics |
| [`cluster-metrics-values.yaml`](upstream-chart/cluster-metrics-values.yaml) | [`cluster-metrics.yaml`](collector/cluster-metrics.yaml) | Deployment with one replica | Cluster-level Kubernetes metrics |

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

2. Install one release of the chart for each collector, with the chart version in [`upstream-chart.yaml`](upstream-chart.yaml). Each values file shows its command at the top, for example:

   ```sh
   helm install observe-forwarder opentelemetry-collector \
     --repo https://open-telemetry.github.io/opentelemetry-helm-charts \
     --version 0.155.0 --namespace observe --values upstream-chart/forwarder-values.yaml
   ```

The values set everything else the collector needs, as the Observe Agent chart does: the downward API variables, feature gates, host volumes, security context, resources, ports, and the Service. They give the chart's service account the same read-only RBAC rules as the Observe Agent chart, which allow reading every resource in the cluster; narrow `clusterRole.rules` if you need to.

The values set the configuration with `alternateConfig`, which replaces the chart's default configuration instead of merging into it, so none of the chart's default receivers and exporters are added.

## Deploy the collector configurations yourself

To deploy with your own manifests or the OpenTelemetry Operator, use the files in `collector/`. Each one lists, at the top, the environment variables to set on the collector container and the `--feature-gates` argument to start it with, as the chart does. Without the feature gates the collector still starts, but parts of the configuration behave differently than in the chart.

The collectors also need:

- A service account with read access to pods, namespaces, nodes, ReplicaSets, Deployments, and the other workload resources, for the `k8sattributes` processor and the `k8s_cluster` receiver. `node.yaml` also needs access to the `nodes/stats` and `nodes/proxy` resources for kubelet stats.
- For `node.yaml`: the node's root filesystem mounted read-only at `/hostfs`, `/var/log/pods` mounted read-only, and a writable volume at `/var/lib/otelcol/file_storage` so that log read positions survive restarts.
- For `forwarder.yaml`: ports 4317 (gRPC) and 4318 (HTTP) exposed so applications on the node can send OTLP to the collector.
- A liveness and readiness probe on port 13133, where the `health_check` extension listens.

## How these examples stay up to date

The files in `collector/` and `upstream-chart/` are generated, so don't edit them by hand. This directory is a regular chart example: `make generate-examples` renders [`values.yaml`](values.yaml) into `rendered/`, then runs [`generate.sh`](generate.sh). For each entry in [`collectors.yaml`](collectors.yaml), the script:

1. Takes the collector configuration from its rendered ConfigMap and merges [`otel-config.yaml`](otel-config.yaml) on top. That replaces the variables the Observe Agent sets for itself, such as `OBSERVE_OTEL_ENDPOINT`, with the variables above, and adds the health check that the Observe Agent provides itself.
2. Keeps only the listed pipelines and extensions, and deletes every component they don't use.
3. Copies the feature gates from the collector's rendered DaemonSet or Deployment into the file's header.
4. Writes the chart values from the same configuration and the rendered DaemonSet or Deployment.
5. Fails, leaving the committed files untouched, if the result reads an environment variable it has no description for.

The script then replaces `collector/` and `upstream-chart/` with the new files, so a collector removed from `collectors.yaml` is deleted too.

These checks run in CI:

- `check-examples` regenerates all examples and fails if the committed files differ, so a chart change that affects the collectors also updates these files.
- The `OSS collector examples` workflow runs [`test/verify_oss_examples.sh`](../../../../test/verify_oss_examples.sh):
  - Each configuration in `collector/` must validate with upstream `otelcol-contrib` and the feature gates in its header, and the forwarder must keep the deployment environment that applications set. Pull requests use the collector version of the Observe Agent release that the chart deploys; a weekly run uses the latest `otelcol-contrib` release.
  - Each values file in `upstream-chart/` must render, with the pinned chart version, into the same configuration as `collector/`, and must set every variable that configuration reads exactly once, pass its feature gates, open only the ports it listens on, and render no Service without ports.

To change what the examples contain, change the chart templates, `values.yaml`, `otel-config.yaml`, or `collectors.yaml`, then run `make generate-examples`. When the Observe Agent chart's `appVersion` moves to a release with a different collector version, move [`upstream-chart.yaml`](upstream-chart.yaml) to the OpenTelemetry Collector chart version with that `appVersion`.
