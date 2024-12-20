# Additional OTEL Configuration
This example shows how to inject additional OTEL Config to the Observe Agent(s) that are running in the deployments and daemonsets. The additional config can add new instances of components such as receivers, processors, and exporters as well as to define new pipelines using those components. In addition, new pipelines can also use existing components from the default config.

## Values.yaml
In the helm chart, there are 3 deployments of Observe Agent and 1 daemonset. Each of these can have additional config injected. Each service has a corresponding field `agent.config.<service>` where the additional config can be added. The value of this field is a valid OTEL configuration in yaml format. The example values.yaml provided shows where custom OTEL config can be added for each of the four services.

## Config Overriding
When provided, the custom config for each service will be merged with the existing default config with precedence given to the custom config. This means that if a component is defined in both the default and custom config, the instance defined in the custom config will override the default instance. Otherwise, the two configs are merged and all components and pipelines defined in either will be present in the final resolved config. Generally, the existing default components shouldn't need to be overwritten as they can be disabled from the top level `values.yaml` config as well.

## Workflow
In order to determine what the final config after resolution is, users can run the following helm command to execute the helm chart with their values.yaml.

```
helm template observe/agent -f values.yaml > output.yaml
```

The contents of output.yaml will contain all of the kubernetes entity definitions; to see the final config, users can look at the matching config map for the service they provided custom OTEL configuration for. Users can then make modifications to their `values.yaml` and then rerun the template function to see the effect of their changes. Once the final config is ready, users can then install the helm chart as normal.
