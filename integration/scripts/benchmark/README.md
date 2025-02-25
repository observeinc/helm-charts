# `observe-agent` helm chart benchmarking

## Usage

This package is designed to benchmark the `observe-agent` helm chart. To run the benchmarking tests, you will need to:

1. Create / connect to a kubernetes cluster
    * The benchmarking script will automatically connect to the current kubernetes context. View the current context via `kubectl config current-context`, set this via `kubectl config use-context <context>`.
2. Install the `observe-agent` helm chart
3. Run the tests via: `HELM_NAMESPACE=observe-test pytest ./integration/scripts/test_benchmark.py`
    * This will take ~15 minutes and will log updates along the way
    * When this finishes, it will create a results file: `agent_benchmark.csv`
4. Anaylze the results. Run `python ./integration/scripts/benchmark/spreadsheet_helpers.py` to create a TSV file that can be imported into a Google Sheet. Import the analysis TSV file and results CSV file as two tabs in the same spreadsheet, and the results will be computed via the formulas.

## Contents

This package contains utilities to help query kubernetes, create spreadsheets to analyze the benchmark data, and generate load in a kubernetes cluster. There are four types of load generators contained in this package:

1. Cluster events
2. Traces
3. App Metrics
4. Logs

Each of these load generators follow a similar interface of `start_load_generation` and `stop_load_generation`. The full use of these tools can be seen in `test_benchmark.py` (function `test_benchmark`).

## Cluster Events

This uses the [OpenTelemetry Astronomy Shop demo](https://github.com/open-telemetry/opentelemetry-demo) to create general usage in the cluster. The full demo is installed multiple times in the cluster, each in its own namespace.

## Traces, App Metrics, and Logs

All three of these generator function in very similar ways. They each rely on a single image to generate load, and they do this by creating a daemonset to ensure load is uniform across nodes (which corresponds with the `observe-agent` daemonsets used to collect this data). The rate of data generation for each of these options is configurable.

## Volume Level

Currently, volume for each generator configured via the `VolumeLevel` enum. Though this enum only has a few values, it is easy to tune the generators to different precise values if needed; see the generator code for examples.
