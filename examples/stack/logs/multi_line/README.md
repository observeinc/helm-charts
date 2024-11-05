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