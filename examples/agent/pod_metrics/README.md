# Prometheus pod metrics scrape example
This example deploys a sample container that emits prometheus metrics.  Source is here - https://github.com/brancz/prometheus-example-app/blob/master/README.md

It also creates a service - prometheus-example-app-service - and a cron job that calls the service at / every 10s and /err every 20s for a total of 5 minutes.

You can alter the length of time the cron job runs and sleep time between runs by altering the SLEEP_TIME and LOOP_COUNT environment variables in the sample-pod.yaml file.

The sample-pod-no.yaml demonstrates using the observeinc_com_scrape: 'false' annotation - you can prove it's effectiveness by setting to true and seeing the metrics show up.

## Deploy sample container
```
kubectl apply -f sample-pod.yaml

kubectl apply -f sample-pod-no.yaml

```

## Port forward
```
kubectl port-forward service/prometheus-example-app-service 8080:8080

kubectl port-forward service/prometheus-example-app-no-service 8080:8080
```

## Call service locally
```
# Get metrics
curl localhost:8080/metrics

# Generate 200 count for metrics
curl localhost:8080/

# Generate error count for metrics
curl localhost:8080/err

```

### Cleanup
```
kubectl delete -f sample-pod.yaml

kubectl delete -f sample-pod-no.yaml
```

## Deploy k8s monitoring with pod metrics collection enabled
The sample-pod.yaml is deployed in the default namespace unless you change the provided command.

It has annotations to change the metrics port to 8080 (observeinc_com_port: '8080') which will tell the scrape config to not use the default port of 8888.

The pod-metrics-values.yaml file sets the namespace to scrape metrics from to default with namespace_keep_regex and adds the web port name as valid with port_keep_regex.

```
helm install pod-metrics-example -n k8smonitoring \
    --set observe.token.value=$TOKEN \
    --set observe.collectionEndpoint.value=$ENDPOINT \
     -f ./pod-metrics-values.yaml ../../../charts/agent

helm upgrade pod-metrics-example -n k8smonitoring -f ./pod-metrics-values.yaml ../../../charts/agent
```

### Opal validation
Create a worksheet from your datastream and token then use following opal
```
make_col debug_source:string(EXTRA.debug_source)
filter OBSERVATION_KIND = "prometheus"
filter debug_source = "pod_metrics"
make_col metric:string(EXTRA.__name__)
make_col k8s_namespace_name:string(EXTRA.k8s_namespace_name)
make_col app_kubernetes_io_name:string(EXTRA.app_kubernetes_io_name)
```
