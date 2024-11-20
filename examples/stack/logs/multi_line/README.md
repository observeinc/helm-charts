# Example

See line 4-19 helm-charts/examples/agent/logs/README.md for instruction on how to deploy sample pods.

## Deploy collection
Assumes metrics pod not deployed

Assumes observe namespace created
```
helm install --namespace=observe observe-stack observe/stack \
    --set global.observe.collectionEndpoint="https://12345678.observeinc.com/v1/http" \
    --set observe.token.value="dsabcdefghijk:qrstuvwzyz" \
    -f ./multiline-values.yaml
```

## Deploy containerd runtime collection to combine lines above 16k
`containerd` logs are split into 16KB chunks due to the design of `containerd`’s logging mechanism, the `containerd-multiline.yaml` will combine the multiline log files. 

```
helm install --namespace=observe observe-stack observe/stack \
    --set global.observe.collectionEndpoint="https://12345678.observeinc.com/v1/http" \
    --set observe.token.value="dsabcdefghijk:qrstuvwzyz" \
    -f ./containerd-multiline.yaml
```