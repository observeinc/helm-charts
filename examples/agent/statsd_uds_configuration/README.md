# Statsd uds(unix domain socket) metrics scrape example
[Link to StatsD Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/statsdreceiver/README.md)

Once you deployed our agent by following kubernetes explorer add data portal instructions into your eks cluster. You can upgrade it using the below command to add statsd uds required configuration to forwarder component of observe agent.

```
helm upgrade --reuse-values observe-agent observe/agent -n observe -f statsd-uds-values.yaml \
--set observe.collectionEndpoint.value="https://your_tenant_id.collect.observe-staging.com/" \
--set cluster.name="cluster_name" \
--set node.containers.logs.enabled="true" \
--set application.prometheusScrape.enabled="false"
```

# Deploy a sample metrics pod
Deploy a simple metrics generator pod which generates metrics and sends to the statsd receiver socket. Make sure to update correct node where your forwarder got deployed in affinity section of metrics-generator.yaml. You can deploy with below command. 

```
kubectl apply -f metrics-writer.yaml
```

## Validate metrics in Observe tenant 
You can validate by going into prometheus metrics dataset and filtering down to labels.debug_source ~ statsd since we added a processor that will include this attribute to the metrics flowing in through our pipeline. 


### Manual way of testing
After logging into the agent pod(forwarder) or host, you can test our configuration with the below command.

```
echo "example.counter:1|c" | socat - UNIX-SENDTO:/var/run/statsd-receiver.sock
```

### Cleanup
To clean up and reset to default agent configuration, use the below 
```
helm upgrade observe-agent observe -n observe --reset-values
```

To delete the agent entirely, we can use the below command. 
```
helm delete observe-agent -n observe
```