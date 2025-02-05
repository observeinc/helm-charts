# Example

See line 4-19 helm-charts/examples/agent/logs/README.md for instruction on how to deploy sample pods.

## Deploy multiline collection for combining Java stack traces.
This example provides a template for combining Java stack traces.
* Assumes metrics pod not deployed,
* Assumes observe namespace created
```
helm install --namespace=observe observe-stack observe/stack \
    --set global.observe.collectionEndpoint="https://12345678.observeinc.com/v1/http" \
    --set observe.token.value="dsabcdefghijk:qrstuvwzyz" \
    -f ./multiline-values.yaml
```

## Deploy for `containerd` runtime collection to combine lines above 16k
`containerd` logs are split into 16KB chunks due to the design of `containerd`’s logging mechanism, the `multiline-containerd-values.yaml` provides an example that combines these multiline log files.

```
helm install --namespace=observe observe-stack observe/stack \
    --set global.observe.collectionEndpoint="https://12345678.observeinc.com/v1/http" \
    --set observe.token.value="dsabcdefghijk:qrstuvwzyz" \
    -f ./multiline-containerd-values.yaml
```

## Deploy for `containerd` runtime to combine Java stacktrace
Example uses the default Fluenbit Java parser - https://docs.fluentbit.io/manual/administration/configuring-fluent-bit/multiline-parsing to combine multiline Java stacktraces.

Note: Logs will NOT show up in the `kubernetes/Container Logs` dataset.

```
helm install --namespace=observe observe-stack observe/stack \
    --set global.observe.collectionEndpoint="https://12345678.observeinc.com/v1/http" \
    --set observe.token.value="dsabcdefghijk:qrstuvwzyz" \
    -f ./multiline-java-values.yaml
```

## Deploy for `containerd` runtime to combine lines based on timestamps
Example will combine multiline logs that begin with any of the following timestamps:
 `2024-12-03 07:31:12,563`
 `07:31:20,550`
 `[2024-12-03 07:31:28.353]`

```
helm install --namespace=observe observe-stack observe/stack \
    --set global.observe.collectionEndpoint="https://12345678.observeinc.com/v1/http" \
    --set observe.token.value="dsabcdefghijk:qrstuvwzyz" \
    -f ./multiline-containerd-timestamps-values.yaml
```

## Deploy for `containerd` runtime to combine lines beginning with `[INFO]` OR `[WARN]` OR `[ERROR]`
Example will combine multiline logs that begin with any of the following `[INFO]` OR `[WARN]` OR `[ERROR]`:
```bash
[WARN] 2023-02-05 11:25:34,567 - Unable to process user request due to invalid input
java.lang.IllegalArgumentException: User ID cannot be null or empty
   at com.example.service.UserService.validateUserId(UserService.java:45)
   at org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61)
   at java.base/java.lang.Thread.run(Thread.java:829)
```
Installation command:
```
helm install --namespace=observe observe-stack observe/stack \
    --set global.observe.collectionEndpoint="https://12345678.observeinc.com/v1/http" \
    --set observe.token.value="dsabcdefghijk:qrstuvwzyz" \
    -f ./multiline-containerd-combine-java-stacktrace.yaml
```
