# Multiline Log Example
The Observe Agent Helm Chart allows users to configure the `multiline` capabilities built into the `filelog` receiver. This allows the user to merge log lines separated by newlines into a single log event.

As multiline log become more complex, additional operators can be added by overriding the Observe Agent Helm Chart by following the example template below.

```
agent:
  config:
    nodeLogsMetrics:
      receivers:
        filelog:
```

## Multiline Config Schema
The multiline configuration is located at `node.containers.logs.multiline` and can be provided as a block of yaml. For more details on the available fields, see the [filelog receiver docs](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/filelogreceiver/README.md#multiline-configuration).

## Java Stacktrace Example
Java stacktraces are generally formatted in multiple lines and would get separated by default. In order to group Java stacktraces into a single log line, we need to identify a valid delimiter to use instead of `\n` to split on. The most consistent delimiter prefix that works well is the ISO timestamp at the beginning of the log line. This can be defined by the pattern `/^\d{4}\-\d{2}\-\d{2}/`.

## Python Log Example
Python log with traceback would typically show a sequence of function calls that follows after an error with timestamp in the format of YYYY-MM-DD HH:MM:SS. To combine the error log with the following traceback, we can leverage a combination of patterns in the form of `/^\[\d{4}\-\d{2}\-\d{2}|^Traceback/`.

```
[2025-01-01 01:00:00] ERROR in app: Exception example
Traceback (most recent call last):
```

## Continuation Line Example
Certain programming languages uses backslash `\` at the end of the line as a continuation indicator. To combine these lines together the pattern to use would be `\\$` with the `recombine` operator. Additional example can be found in the [recombine operator docs](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/pkg/stanza/docs/operators/recombine.md)

## Custom Log Example
There may be logs where you may not have any control over the format, which will require some creativity. For instance, unicode character can present itself in logs when dealing with html outputs. To combine such format we would need to use the first line matching patterns in the form of `^\\u004c` which represent a less than `<`.

```
<head><title>503 Service Temporarily Unavailable</title></head>
<body>
<center>This is an example</center>
</body>
```
