# Understanding logs helm chart and how to modify

[Helpful primer on Helm Values Files](https://helm.sh/docs/chart_template_guide/values_files/_)

This assumes you have a k8s cluster that you can deploy the stack helm chart to and know how to get a kube config entry.  This example was created on an AWS EKS cluster but should work on other k8s clusters.

AWS provides [examples and terraform modules](https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/eks-managed-node-group/README.md)  on how to deploy an EKS clusters.

Observe's stack helm chart references several subcharts.

Looking at the [stack Chart.yaml file](../../../charts/stack/Chart.yaml) you can see that all of the subcharts referenced are also in this git repository.  You can also see that each chart has a condition for whether or not it is enabled.  If you look at the [stack values file](../../../charts/stack/values.yaml) you can see a section for each subchart with a default value set for the enabled property.

Based on the [stack Chart.yaml file](../../../charts/stack/Chart.yaml) we know the logs subchart and it's corresponding [values file](../../../charts/logs/values.yaml) and [Chart.yaml](../../../charts/logs/Chart.yaml) are located in the charts/logs directory. If we look at the [Chart.yaml](../../../charts/logs/Chart.yaml) file we can see that it lists the official [fluent-bit chart](https://github.com/fluent/helm-charts/tree/main/charts/fluent-bit) as a dependency.  The [logs chart values file](../../../charts/logs/values.yaml) then has a fluent-bit: section where we pass override values (the values we want to change) to the [fluent-bit chart values file](https://github.com/fluent/helm-charts/blob/main/charts/fluent-bit/values.yaml).

It's important to understand that there are many more options that can be set then we set by default for the fluent-bit chart and that you - with your own values file - can override any of the values set in the logs values file or the fluent-bit values file.

Let's look at an example for how to do this:

Scenario: We want to annotate and label our fluent-bit pods and daemonset and then include the pod annotations and labels in the log information shipped to Observe.

The Observe repo main [README.md](../../../README.md) gives us the basic commands for installing the stack chart which we can combine with our own [custom-values.yaml file](./custom-values.yaml).

The sections:
- \# Add labels and annotations to fluent-bit daemonset
- \# Add labels and annotations to fluent-bit pod

show how to add labels and annotations to the daemonset and pods.

The section \# Add your own configuration to fluent-bit shows how we can override the default configuration present in the [logs chart values file](../../../charts/logs/values.yaml).

To add additional k8s metadata we need to make several changes to the default configuration which are called out in the file with following comments:
- \# CHANGE tag for tail input
- \# ADD kubernetes filter
- \# ADD lift filter
- \# ADD record_modifier filter
- \# ADD Whitelist_key for annotations and labels to existing record_modifier filter

More information on the [Fluentbit Kubernetes filter](https://docs.fluentbit.io/manual/pipeline/filters/kubernetes)

To install the stack chart with the modification to logs chart run the following command:

```
helm install --namespace=observe observe-stack observe/stack -f custom-values.yaml
```

Assuming you have created a worksheet off of your raw datastream in Observe you can see your added labels and annotations on your pod and daemonset specs with the following opal:
```
make_col namespace:string(FIELDS.object.metadata.namespace)
filter namespace = "observe"

make_col kind:string(FIELDS.object.kind)
filter kind = "DaemonSet" or kind = "Pod"

make_col generateName:string(FIELDS.object.metadata.generateName)
filter generateName ~ "observe-stack-logs"
make_col annotations:FIELDS.object.metadata.annotations
make_col labels:FIELDS.object.metadata.labels
```

To see the annotations and labels properties added to your logs use the following opal:
```
make_col fluentTimestamp:int64(FIELDS.fluentTimestamp)
filter not is_null(fluentTimestamp)
make_col containerName:string(FIELDS.containerName)
make_col namespace:string(FIELDS.namespace)
filter namespace = "observe"
filter containerName = "fluent-bit"
make_col annotations:FIELDS.annotations
make_col labels:FIELDS.labels
```


To see the logs of the fluentbit pod in a terminal you can uncomment the \# Output section to send the logs to the destination and then run the following command:
```
pod=$(kubectl get pods -n observe --no-headers -o custom-columns=":metadata.name" | grep ^observe-stack-logs); kubectl logs $pod -n observe
```
