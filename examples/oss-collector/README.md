# OpenTelemetry Collector examples for Kubernetes

These examples show how to send Kubernetes telemetry to Observe with a plain [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) (`otelcol-contrib`) instead of the Observe Agent Helm chart. They use the same processors and pipelines as the chart, so the data arrives in the shape that Observe's explorers expect. For a collector on a single host, see the [host example](https://github.com/observeinc/observe-agent/tree/main/examples/oss-collector) in the `observeinc/observe-agent` repository.

| File | Deploy it as | What it collects |
| :--- | :----------- | :--------------- |
| [`kubernetes/forwarder.yaml`](kubernetes/forwarder.yaml) | DaemonSet | Application traces, logs, and metrics over OTLP, and RED (request rate, error, and duration) metrics generated from traces |
| [`kubernetes/node.yaml`](kubernetes/node.yaml) | DaemonSet | Container logs, kubelet stats, and node metrics |
| [`kubernetes/cluster-metrics.yaml`](kubernetes/cluster-metrics.yaml) | Deployment with one replica | Cluster-level Kubernetes metrics |
| [`kubernetes/kubernetes-explorer-values.yaml`](kubernetes/kubernetes-explorer-values.yaml) | Values for the `observe/agent` Helm chart | Kubernetes objects for Kubernetes Explorer (see below) |

## Deploy the collectors

Each collector configuration lists, at the top, the environment variables it reads. Set them on the collector container:

- `OBSERVE_COLLECTION_URL` and `OBSERVE_TOKEN`: your collection URL and an Observe ingest token. Store the token in a Secret.
- `OBSERVE_CLUSTER_NAME` and `OBSERVE_CLUSTER_UID`: the cluster name, and the UID of the `kube-system` namespace (`kubectl get namespace kube-system -o jsonpath='{.metadata.uid}'`).
- `DEPLOYMENT_ENVIRONMENT`: the fallback `deployment.environment.name`. Telemetry that already sets an environment, for example with `OTEL_RESOURCE_ATTRIBUTES` or a `resource.opentelemetry.io/deployment.environment.name` pod annotation, keeps its own value. See [Set the deployment environment](https://docs.observeinc.com/docs/set-the-deployment-environment#/).
- `MY_POD_IP` and `K8S_NODE_NAME`: from the downward API (`status.podIP` and `spec.nodeName`).

The collectors also need:

- A service account with read access to pods, namespaces, nodes, ReplicaSets, Deployments, and the other workload resources, for the `k8sattributes` processor and the `k8s_cluster` receiver. `node.yaml` also needs access to the `nodes/stats` and `nodes/proxy` resources for kubelet stats.
- For `node.yaml`: the node's root filesystem mounted read-only at `/hostfs`, `/var/log/pods` mounted read-only, and a writable volume at `/var/lib/otelcol/file_storage` so that log read positions survive restarts.
- For `forwarder.yaml`: ports 4317 (gRPC) and 4318 (HTTP) exposed so applications on the node can send OTLP to the collector.

## Kubernetes Explorer

Kubernetes Explorer needs Kubernetes object data, which the Observe-specific `observek8sattributes` processor produces. Upstream collector distributions don't include it. Deploy the `observe/agent` Helm chart with only object collection enabled, using [`kubernetes/kubernetes-explorer-values.yaml`](kubernetes/kubernetes-explorer-values.yaml). Set the cluster name and deployment environment in those values to the same values as `OBSERVE_CLUSTER_NAME` and `DEPLOYMENT_ENVIRONMENT`, so that Kubernetes Explorer can line up objects with metrics and logs.

## How these examples stay up to date

The collector configurations are generated, so don't edit them by hand. `make generate-oss-examples` (also run by `make generate-examples`) renders the `observe/agent` chart with [`kubernetes/reference-values.yaml`](kubernetes/reference-values.yaml), takes the configuration of each collector, removes debug-only exporters, and replaces the variables that the Observe Agent sets for itself with the variables above. See [`generate.sh`](generate.sh).

These checks run in CI:

- `check-examples` regenerates the examples and fails if the committed files differ, so a chart change that affects the collectors also updates the examples.
- The `OSS collector examples` workflow runs [`test/verify_oss_examples.sh`](../../test/verify_oss_examples.sh): each example must validate with upstream `otelcol-contrib`, and the forwarder example must keep the deployment environment that applications set. Pull requests use the collector version of the Observe Agent release that the chart deploys; a weekly run uses the latest `otelcol-contrib` release.

To change what the examples contain, change the chart templates or `reference-values.yaml`, then run `make generate-oss-examples`.
