# OpenTelemetry Collector examples for Kubernetes

These examples show how to send Kubernetes telemetry to Observe with a plain [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) (`otelcol-contrib`) instead of the Observe Agent Helm chart. They use the same processors and pipelines as the chart, so the data arrives in the shape that Observe's explorers expect. For a collector on a single host, see the [host example](https://github.com/observeinc/observe-agent/tree/main/examples/oss-collector) in the `observeinc/observe-agent` repository.

| File | Deploy it as | What it collects |
| :--- | :----------- | :--------------- |
| [`collector/forwarder.yaml`](collector/forwarder.yaml) | DaemonSet | Application traces, logs, and metrics over OTLP, and RED (request rate, error, and duration) metrics generated from traces |
| [`collector/node.yaml`](collector/node.yaml) | DaemonSet | Container logs, kubelet stats, and node metrics |
| [`collector/cluster-metrics.yaml`](collector/cluster-metrics.yaml) | Deployment with one replica | Cluster-level Kubernetes metrics |

## Deploy the collectors

Each collector configuration lists, at the top, the environment variables it reads. Set them on the collector container:

- `OBSERVE_COLLECTION_URL` and `OBSERVE_TOKEN`: your collection URL and an Observe ingest token. Store the token in a Secret.
- `OBSERVE_CLUSTER_NAME` and `OBSERVE_CLUSTER_UID`: the cluster name, and the UID of the `kube-system` namespace (`kubectl get namespace kube-system -o jsonpath='{.metadata.uid}'`).
- `DEPLOYMENT_ENVIRONMENT`: the fallback `deployment.environment.name`. Telemetry that already sets an environment, for example with `OTEL_RESOURCE_ATTRIBUTES` or a `resource.opentelemetry.io/deployment.environment.name` pod annotation, keeps its own value. See [Set the deployment environment](https://docs.observeinc.com/docs/set-the-deployment-environment#/).
- `MY_POD_IP` and `K8S_NODE_NAME`: from the downward API (`status.podIP` and `spec.nodeName`).

Start each collector with the `--feature-gates` argument listed under the variables, as the chart does. Without it the collector still starts, but parts of the configuration behave differently than in the chart.

The collectors also need:

- A service account with read access to pods, namespaces, nodes, ReplicaSets, Deployments, and the other workload resources, for the `k8sattributes` processor and the `k8s_cluster` receiver. `node.yaml` also needs access to the `nodes/stats` and `nodes/proxy` resources for kubelet stats.
- For `node.yaml`: the node's root filesystem mounted read-only at `/hostfs`, `/var/log/pods` mounted read-only, and a writable volume at `/var/lib/otelcol/file_storage` so that log read positions survive restarts.
- For `forwarder.yaml`: ports 4317 (gRPC) and 4318 (HTTP) exposed so applications on the node can send OTLP to the collector.

## How these examples stay up to date

The files in `collector/` are generated, so don't edit them by hand. This directory is a regular chart example: `make generate-examples` renders [`values.yaml`](values.yaml) into `rendered/`, then runs [`generate.sh`](generate.sh). For each entry in [`collectors.yaml`](collectors.yaml), the script:

1. Takes the collector configuration from its rendered ConfigMap and merges [`otel-config.yaml`](otel-config.yaml) on top. That replaces the variables the Observe Agent sets for itself, such as `OBSERVE_OTEL_ENDPOINT`, with the variables above.
2. Keeps only the listed pipelines and extensions, and deletes every component they don't use.
3. Copies the feature gates from the collector's rendered DaemonSet or Deployment into the file's header.
4. Fails, leaving the committed files untouched, if the result reads an environment variable it has no description for.

The script then replaces `collector/` with the new files, so a configuration removed from `collectors.yaml` is deleted too.

These checks run in CI:

- `check-examples` regenerates all examples and fails if the committed files differ, so a chart change that affects the collectors also updates these files.
- The `OSS collector examples` workflow runs [`test/verify_oss_examples.sh`](../../../../test/verify_oss_examples.sh): each configuration must validate with upstream `otelcol-contrib` and the feature gates in its header, and the forwarder must keep the deployment environment that applications set. Pull requests use the collector version of the Observe Agent release that the chart deploys; a weekly run uses the latest `otelcol-contrib` release.

To change what the examples contain, change the chart templates, `values.yaml`, `otel-config.yaml`, or `collectors.yaml`, then run `make generate-examples`.
