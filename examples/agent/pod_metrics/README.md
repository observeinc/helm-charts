# Prometheus pod metrics scrape example
This example deploys a sample container that emits prometheus metrics.  Source is here - https://github.com/brancz/prometheus-example-app/blob/master/README.md

It also creates a service - prometheus-example-app-service - and a cron job that calls the service at / every 10s and /err every 20s for a total of 5 minutes.

You can alter the length of time the cron job runs and sleep time between runs by altering the SLEEP_TIME and LOOP_COUNT environment variables in the sample-pod.yaml file.

The sample-pod-no.yaml demonstrates using the observeinc_com_scrape: 'false' annotation - you can prove it's effectiveness by setting to true and seeing the metrics show up.

## Deploy sample container
```
kubectl apply -f sample-pod.yaml

kubectl apply -f sample-pod-no.yaml

kubectl apply -f sample-pod-prometheus-labels.yaml

kubectl apply -f sample-pod-prometheus-labels-no.yaml

```

## Port forward
You can curl a given service to increment counters from local machine by port forwarding.

These sevices are defined in sample-pod files
```
kubectl port-forward service/prometheus-example-app-service 8080:8080

kubectl port-forward service/prometheus-example-app-no-service 8080:8080

kubectl port-forward service/prometheus-example-app-promlabel-service 8080:8080

kubectl port-forward service/prometheus-example-app-promlabel-no-service 8080:8080
```

## Call service locally
If port forwarded you can use these curl commands
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

kubectl delete -f sample-pod-prometheus-labels.yaml

kubectl delete -f sample-pod-prometheus-labels-no.yaml
```

## Deploy k8s monitoring with pod metrics collection enabled
The sample-pod.yaml is deployed in the default namespace unless you change the provided command.

It has annotations to change the metrics port, metrics path and that this pod should be scraped:
```
      annotations:
        observeinc_com_scrape: 'true'
        observeinc_com_path: '/metrics'
        observeinc_com_port: '8080'
```

The sample-pod-no.yaml sets observeinc_com_scrape: 'false' so no metrics should be collected from this pod.

Pods created by sample-pod-prometheus-labels and sample-pod-prometheus-labels-no yaml files use prometheus annotations to accomplish same functions as pods above:
```
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/path: '/metrics'
        prometheus.io/port: '8080'
```

The pod-metrics-values.yaml file sets the namespace to scrape metrics from to default with namespaceKeepRegex and adds the web port name as valid with portKeepRegex.


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
