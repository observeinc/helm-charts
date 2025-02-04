# Statsd uds(unix domain socket) metrics scrape example
Once we deploy our agent with updated yaml to support statsd receiver, you can test our configuration with below command by logging into host or the agent pod. Install the socat command by using respective package manager. 

## Deploy our agent with latest image
Once you deployed the agent with Add data portal in your kubernetes cluster, you can use this command to re-utilize existing values and add the additional configuration. Update the clusterName and collection endpoint while deploying.

```
helm upgrade --reuse-values observe-agent observe/agent -n observe -f agent-values-latest.yaml \
--set observe.collectionEndpoint.value="https://155863311937.collect.observe-staging.com/" \
--set cluster.name="eks" \
--set node.containers.logs.enabled="true" \
--set application.prometheusScrape.enabled="false"
```

### Testing the configuration 
After logging into the agent pod or host, you can test our configuration with the below command.

```
echo "example.counter:1|c" | socat - UNIX-SENDTO:/var/run/statsd-receiver.sock
```

### Cleanup
```
helm delete observe-agent -n observe
```
