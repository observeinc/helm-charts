# OSS collector examples must match the chart

`charts/agent/examples/oss-collector/collector/` contains OpenTelemetry Collector configurations for customers who run a plain `otelcol-contrib` collector on Kubernetes instead of the Observe Agent Helm chart. The Observe documentation links to them. They must process data the same way the chart does.

## When this rule applies

Check this rule when a pull request changes any of:

- `charts/agent/templates/**` collector configuration: processors, pipelines, receivers, exporters, or the environment variables they read
- `charts/agent/values.yaml` defaults that change the rendered collector configuration
- `charts/agent/Chart.yaml` `appVersion`, which changes the collector version the examples are validated against
- `charts/agent/examples/oss-collector/**` or `charts/agent/examples/oss-collector-kubernetes-explorer/**`
- `test/verify_oss_examples.sh` or `test/lib/deployment_environment.sh`

## What to check

1. **The examples are regenerated.** `make generate-examples` renders `charts/agent/examples/oss-collector/values.yaml` like every other example, then `generate.sh` turns the rendered `forwarder`, `node-logs-metrics`, and `cluster-metrics` ConfigMaps into `collector/{forwarder,node,cluster-metrics}.yaml`, keeping only the pipelines and extensions listed in `collectors.yaml`. If the pull request changes one of those collectors, the generated files must change in the same pull request. Flag hand edits to `collector/*.yaml`.
2. **New chart-only pieces are handled.** If the pull request adds a component or environment variable that only works inside the chart (for example a variable that the observe-agent binary sets at startup, a fleet or self-monitoring component, or an Observe-specific processor) to a listed pipeline, it reaches the examples. Check that `otel-config.yaml` replaces it, or that it validates with upstream `otelcol-contrib`. The generator fails on an environment variable it can't describe; a new variable needs an entry in `describe_env` in `generate.sh`.
3. **The example still covers the change.** If the pull request adds a feature that collector users need, check whether `values.yaml` enables it and whether `collectors.yaml` lists its pipeline. If not, ask whether it should.
4. **Behavior is tested.** Changes to how resource attributes such as `deployment.environment.name` are set or ordered must keep `test/verify_oss_examples.sh` passing, and should extend it when they add new behavior.
5. **No credentials.** Examples must read endpoints and tokens from environment variables (`${env:OBSERVE_COLLECTION_URL}`, `${env:OBSERVE_TOKEN}`), never contain a real collection URL or ingest token.
6. **The host example may need the same change.** The host example lives in `observeinc/observe-agent` under `examples/oss-collector/`. If the change also applies to the agent's bundled configuration, mention that the agent and its example need a matching change.
7. **Documentation.** If the change alters what customers must deploy or configure (environment variables, permissions, mounts, ports), mention that `charts/agent/examples/oss-collector/README.md` and the "Configure your own OTel collector" pages on docs.observeinc.com may need an update.
