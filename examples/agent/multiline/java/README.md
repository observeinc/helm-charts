# Java Multiline Exception example
This example demonstrates the deployment of a Java multiline exception generator app into kubernetes cluster and onboard those logs to Observe and how to fix the multines with updated multiline values.yaml using our Observe agent. This example multiline values.yaml assumes the app is running on kubernetes with runtime log-format being one of these (Containerd, CRI or Docker). Basically, with app being deployed in Kubernetes, the app logs will be wrapped around with one of these formats. So our values.yaml will have the fix for merging the multiline logs into single line. And adding this an example for our future multiline dragons. Follow the below steps to continue. 

# Pre-requisites
I have built the docker image with the java app and put into public repository so you don't have to worry about building docker image and pushing it to repository and then deploying it. I have just added all files for clarity. You just have to follow the instructions below. 

# Deploy a Java Multiline Exception Generator pod
Deploy the java multiline app into your k8s lab. You can deploy with below command.

```
kubectl apply -f java-multiline-geneerator.yaml
```

# Deploy our Observe agent through add data portal from your test tenant.
Once you deployed our agent by following kubernetes explorer add data portal instructions into your eks cluster. You can upgrade it using the below command to add multiline required configuration to merge multilines exceptions into single lines.

```
helm upgrade --reuse-values observe-agent observe/agent -n observe -f multiline-fix-values.yaml \
--set observe.collectionEndpoint.value="https://your_tenant_id.collect.observe-staging.com/" \
--set cluster.name="cluster_name" \
--set node.containers.logs.enabled="true" \
--set application.prometheusScrape.enabled="false"
```

# Do rolling restart of our Observe agent after upgrading the configuration

```
kubectl rollout restart daemonset -n observe
```

## Validate metrics in Observe tenant
You can validate by going into your observe test tenant and filter on exception-generator-java logs to see if it fixed the multilines. 

### Cleanup
To clean up and reset to default agent configuration, use the below

```
helm upgrade observe-agent observe -n observe --reset-values
```

To delete the agent entirely, we can use the below command.
```
helm delete observe-agent -n observe
```

```
kubectl delete deployment exception-generator-java -n default 
```
