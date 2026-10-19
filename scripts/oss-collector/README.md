# OSS collector example generator

[`generate.sh`](generate.sh) generates the OpenTelemetry Collector examples in [`examples/oss-collector`](../../examples/oss-collector/): plain collector configurations in `collector/`, and values for the upstream OpenTelemetry Collector Helm chart in `helm/`. Customers use those files; this directory is only how they're made.

`make generate-examples` runs it after the chart examples. It renders the Observe Agent chart with [`values.yaml`](values.yaml) into `examples/oss-collector/rendered/`, the same way `make generate-examples` renders the chart examples. Then, for each entry in [`collectors.yaml`](collectors.yaml), it:

1. Takes the collector configuration from its rendered ConfigMap and merges [`otel-config.yaml`](otel-config.yaml) on top. That replaces the variables the Observe Agent sets for itself, such as `OBSERVE_OTEL_ENDPOINT`, with `OBSERVE_COLLECTION_URL` and `OBSERVE_TOKEN`, and adds the health check that the Observe Agent provides itself.
2. Keeps only the listed pipelines and extensions, and deletes every component they don't use.
3. Copies the feature gates from the collector's rendered DaemonSet or Deployment into the file's header.
4. Writes the chart values from the same configuration and the rendered DaemonSet or Deployment, for the chart version in [`upstream-chart.yaml`](upstream-chart.yaml).
5. Fails, leaving the committed files untouched, if the result reads an environment variable it has no description for.

The script then replaces `collector/`, `helm/`, and `rendered/` in `examples/oss-collector/` with the new files, so a collector removed from `collectors.yaml` is deleted too.

These checks run in CI:

- `check-examples` regenerates all examples and fails if the committed files differ, so a chart change that affects the collectors also updates the examples.
- The `OSS collector examples` workflow runs [`test/verify_oss_examples.sh`](../../test/verify_oss_examples.sh):
  - Each configuration in `collector/` must validate with upstream `otelcol-contrib` and the feature gates in its header, and the forwarder must keep the deployment environment that applications set. Pull requests use the collector version of the Observe Agent release that the chart deploys; a weekly run uses the latest `otelcol-contrib` release.
  - Each values file in `helm/` must render, with the pinned chart version, into the same configuration as `collector/`, and must set every variable that configuration reads exactly once, pass its feature gates, open only the ports it listens on, and render no Service without ports.

To change what the examples contain, change the chart templates, `values.yaml`, `otel-config.yaml`, or `collectors.yaml`, then run `make generate-examples`. When the Observe Agent chart's `appVersion` moves to a release with a different collector version, move `upstream-chart.yaml` to the OpenTelemetry Collector chart version with that `appVersion`.
