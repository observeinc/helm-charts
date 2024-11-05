# Example

See line 4-19 helm-charts/examples/agent/logs/README.md for instruction on how to deploy sample pods.

## Deploy collection 
Assumes metrics pod not deployed

Assumes observe namespace created
```
helm install --namespace=observe observe-stack observe/stack \
    --set global.observe.collectionEndpoint="https://161011529721.collect.observe-eng.com/v1/http" \
    --set observe.token.value="ds1sk8qOomExaE9NcCV1:qtm6HgQ_mRuX5lYx7EaSIuAUrnalPDhx" \
    -f ./multiline-values.yaml
```