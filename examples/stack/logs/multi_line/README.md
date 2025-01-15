# Example

See line 4-19 helm-charts/examples/agent/logs/README.md for instruction on how to deploy sample pods.

## Deploy multiline collection
Assumes metrics pod not deployed

Assumes observe namespace created
```
helm install --namespace=observe observe-stack observe/stack \
    --set global.observe.collectionEndpoint="https://12345678.observeinc.com/v1/http" \
    --set observe.token.value="dsabcdefghijk:qrstuvwzyz" \
    -f ./multiline-values.yaml
```

## Deploy `containerd` runtime collection to combine lines above 16k
`containerd` logs are split into 16KB chunks due to the design of `containerd`’s logging mechanism, the `multiline-containerd-values.yaml` provides an example that combines these multiline log files.

```
helm install --namespace=observe observe-stack observe/stack \
    --set global.observe.collectionEndpoint="https://12345678.observeinc.com/v1/http" \
    --set observe.token.value="dsabcdefghijk:qrstuvwzyz" \
    -f ./multiline-containerd-values.yaml
```

## Deploy `containerd` to combine Java stacktrace
Example uses the default Fluenbit Java parser - https://docs.fluentbit.io/manual/administration/configuring-fluent-bit/multiline-parsing to combine multiline Java stacktraces.

Note: Logs will not show up in the `kubernetes/Container Logs` dataset.

```
helm install --namespace=observe observe-stack observe/stack \
    --set global.observe.collectionEndpoint="https://12345678.observeinc.com/v1/http" \
    --set observe.token.value="dsabcdefghijk:qrstuvwzyz" \
    -f ./multiline-java-values.yaml
```

## Deploy `containerd` to combine lines based on timestamps
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
