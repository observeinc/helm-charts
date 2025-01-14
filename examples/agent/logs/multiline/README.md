# Multiline Log Example
The Observe Agent Helm Chart allows users to configure the `multiline` capabilities built into the `filelog` receiver. This allows the user to merge log lines separated by newlines into a single log event.

## Multiline Config Schema
The multiline configuration is located at `node.containers.logs.multiline` and can be provided as a block of yaml. For more details on the available fields, see the [filelog receiver docs](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/filelogreceiver/README.md#multiline-configuration).

## Java Stacktrace Example
Java stacktraces are generally formatted in multiple lines and would get separated by default. In order to group Java stacktraces into a single log line, we need to identify a valid delimiter to use instead of `\n` to split on. The most consistent delimiter prefix that works well is the ISO timestamp at the beginning of the log line. This can be defined by the pattern `/^\d{4}\-\d{2}\-\d{2}/`.
