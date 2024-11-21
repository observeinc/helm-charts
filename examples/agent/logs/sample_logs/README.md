# Generating sample logs
This creates a number of pods that will generate different types of sample logs so we can test various logging scenarios and confirm our switches work as expected.

## Create config map with script in it
```
kubectl create configmap -n default log-generator-script --from-file=log-generator.sh
```

## Deploy pods that use script and pas env variables to set type, length, etc.
```
kubectl apply  -n default -f sample-log-pods.yaml
```

### Cleanup
```
kubectl delete  -n default configmap log-generator-script

kubectl delete  -n default -f sample-log-pods.yaml
```

## Deploy k8s monitoring with log collection enabled
The node-logs-values.yaml file has an include and exclude option set.  The exclude pattern will eliminate all logs with path starting with "/var/log/pods/default_log-generator-csv".  you can experiment with different patterns to see how to exclude/include.
```
helm install logs-example -n k8smonitoring \
    --set observe.token.value=$TOKEN \
    --set observe.collectionEndpoint.value=$ENDPOINT \
     -f ./node-logs-values.yaml ../../../charts/agent

helm upgrade logs-example -n k8smonitoring -f ./node-logs-values.yaml ../../../charts/agent
```

### Opal validation
```
filter OBSERVATION_KIND = "otellogs"

make_col debug_source:string(FIELDS.logs.attributes.debug_source)
filter debug_source = "pod_logs"
make_col logfilepath:string(FIELDS.logs.attributes['log.file.path'])
make_col k8spodname:string(FIELDS.resource.attributes['k8s.pod.name'])

make_col k8snamespacename:string(FIELDS.resource.attributes['k8s.namespace.name'])

filter contains(k8spodname, "log-generator")
```
### Cleanup

```
helm delete logs-example -n k8smonitoring
```
