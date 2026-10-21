# OSS collector values generator

[`generate.sh`](generate.sh) generates the OpenTelemetry Collector Helm chart values in the parent directory, one `<name>-values.yaml` per collector. Customers use those files; this directory is only how they're made.

`make generate-examples` runs it after the chart examples. It renders the Observe Agent chart with [`values.yaml`](values.yaml) into `../rendered/`, the same way `make generate-examples` renders the chart examples. Then, for each entry in [`collectors.yaml`](collectors.yaml), it:

1. Takes the collector configuration from its rendered ConfigMap and merges [`otel-config.yaml`](otel-config.yaml) on top. That replaces the variables the Observe Agent sets for itself, such as `OBSERVE_OTEL_ENDPOINT`, with `OBSERVE_COLLECTION_URL` and `OBSERVE_TOKEN`, and adds the health check that the Observe Agent provides itself.
2. Replaces the processors in `replace_processors` with ones `otel-config.yaml` defines, such as the Observe-specific `observek8sattributes` with `transform/redact_secrets`, which redacts Secrets the same way. Then it keeps only the listed pipelines and extensions, and deletes every component they don't use.
3. Writes the values for the chart version in [`upstream-chart.yaml`](upstream-chart.yaml), with the image pinned to its `collectorVersion`: the configuration in `alternateConfig`, and the feature gates, downward API variables, volumes, security context, resources, ports, Service, and read-only RBAC rules of the collector's rendered DaemonSet or Deployment.
4. Fails, leaving the committed files untouched, if the result reads an environment variable it has no description for.

Before any of that, it fails if the chart renders a collector, or a pipeline in one, that `collectors.yaml` doesn't keep, so a collector or pipeline the chart adds can't be left out of the values unnoticed.

The script then replaces the values files and `rendered/`, so a collector removed from `collectors.yaml` is deleted too.

These checks run in CI:

- `check-examples` regenerates all examples and fails if the committed files differ, so a chart change that affects the collectors also updates the values.
- The `OSS collector examples` workflow runs [`test/verify_oss_examples.sh`](../../../../../test/verify_oss_examples.sh). For each values file:
  - The configuration in `alternateConfig` must validate with upstream `otelcol-contrib` and the values' feature gates. Pull requests use the collector version of the Observe Agent release that the chart deploys; a weekly run uses the latest `otelcol-contrib` release.
  - The values must render, with the pinned chart version, into exactly that configuration, set every variable it reads exactly once, pass the feature gates, open only the ports it listens on, and render no Service without ports.
  - The forwarder must keep the deployment environment that applications set, and fall back to `DEPLOYMENT_ENVIRONMENT` otherwise.
  - Every pipeline that receives Kubernetes Secrets must contain `transform/redact_secrets`, and pulled and watched Secrets sent through the cluster-events processors must come out redacted.

To change what the values contain, change the chart templates, `values.yaml`, `otel-config.yaml`, or `collectors.yaml`, then run `make generate-examples`.

`upstream-chart.yaml` pins two versions: `collectorVersion`, the collector version of the Observe Agent release that `charts/agent` deploys (`go.opentelemetry.io/collector/otelcol` in that release's `go.mod`), and `version`, the OpenTelemetry Collector chart release whose `appVersion` is that collector version. When the Observe Agent chart's `appVersion` moves to a release with a different collector version, update both and run `make generate-examples`. The `OSS collector examples` workflow fails until they match: it checks that the pinned chart's `appVersion` is `collectorVersion`, that every values file pins the image to it, and that it is the collector version of the agent release in `appVersion`.
