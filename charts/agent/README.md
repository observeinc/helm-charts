# agent

![Version: 0.56.0](https://img.shields.io/badge/Version-0.56.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.3.0](https://img.shields.io/badge/AppVersion-2.3.0-informational?style=flat-square)

Chart to install K8s collection stack based on Observe Agent

# Components

## node-logs-metrics

This service is a *daemonset* which means it runs on every node in the cluster. It is responsible for collecting logs from pods that are running on the node. In addition, it scrapes the API of the kubelet running on the node for metrics about the node and the pods running on the node.

## cluster-events

This service is a *single-instance deployment*. It's critical that this service is only a single instance since otherwise it would produce duplicate data. It is responsible for both scraping for Kubernetes events on startup as well as registering as a listener for any new Kubernetes events produced by the cluster. These events are then transformed and become the basis for the representation of all the resources in your Kubernetes cluster as well as any events that happen on those resources.

## cluster-metrics

This service is a *single-instance deployment*. It's critical that this service is only a single instance since otherwise it would produce duplicate data. It is responsible for pulling metrics from the Kubernetes API server and sending them to Observe.

## prometheus-scraper

This service is a *single-instance deployment*. It's critical that this service is only a single instance since otherwise it would produce duplicate data. It is responsible for scraping pods for Prometheus metrics is configured and runs.

## forwarder

This service is a *daemonset* which means it runs on every node in the cluster. It is responsible for receiving telemetry from the other services, specifically via an OTLP receiver and forwarding it to Observe. It can be used as the target for various instrumentation SDK's and clients as well. See [here](https://docs.observeinc.com/en/latest/content/observe-agent/ConfigureApplicationInstrumentation.html) for more details.

## monitor

This service is a *single-instance deployment*. It's critical that this service is only a single instance since otherwise it would produce duplicate data. It is responsible for monitoring the other containers of Observe Agent running by scraping the exposed Prometheus metrics of those agents. It's best practice to separate the monitoring of the agents from the agents themselves since if problems develop in those pipelines, we would need the agent telemetry to keep flowing in order to diagnose.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Observe | <support@observeinc.com> |  |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://open-telemetry.github.io/opentelemetry-helm-charts | cluster-events(opentelemetry-collector) | 0.101.1 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | cluster-metrics(opentelemetry-collector) | 0.101.1 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | prometheus-scraper(opentelemetry-collector) | 0.101.1 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | node-logs-metrics(opentelemetry-collector) | 0.101.1 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | monitor(opentelemetry-collector) | 0.101.1 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | forwarder(opentelemetry-collector) | 0.101.1 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| agent.config.clusterEvents | string | `nil` |  |
| agent.config.clusterMetrics | string | `nil` |  |
| agent.config.forwarder | string | `nil` |  |
| agent.config.global.debug.enabled | bool | `false` |  |
| agent.config.global.debug.verbosity | string | `"basic"` |  |
| agent.config.global.exporters.retryOnFailure.enabled | bool | `true` |  |
| agent.config.global.exporters.retryOnFailure.initialInterval | string | `"1s"` |  |
| agent.config.global.exporters.retryOnFailure.maxElapsedTime | string | `"5m"` |  |
| agent.config.global.exporters.retryOnFailure.maxInterval | string | `"30s"` |  |
| agent.config.global.exporters.sendingQueue.enabled | bool | `true` |  |
| agent.config.global.overrides | string | `nil` |  |
| agent.config.global.processors.batch.sendBatchMaxSize | int | `4096` |  |
| agent.config.global.processors.batch.sendBatchSize | int | `4096` |  |
| agent.config.global.processors.batch.timeout | string | `"5s"` |  |
| agent.config.global.service.telemetry.loggingEncoding | string | `"console"` |  |
| agent.config.global.service.telemetry.loggingLevel | string | `"WARN"` |  |
| agent.config.global.service.telemetry.metricsLevel | string | `"normal"` |  |
| agent.config.monitor | string | `nil` |  |
| agent.config.nodeLogsMetrics | string | `nil` |  |
| agent.config.prometheusScraper | string | `nil` |  |
| agent.selfMonitor.enabled | bool | `true` |  |
| agent.selfMonitor.metrics.scrapeInterval | string | `"60s"` |  |
| application.prometheusScrape.enabled | bool | `false` |  |
| application.prometheusScrape.independentDeployment | bool | `false` |  |
| application.prometheusScrape.interval | string | `"60s"` |  |
| application.prometheusScrape.metricDropRegex | string | `".*bucket"` |  |
| application.prometheusScrape.metricKeepRegex | string | `"(.*)"` |  |
| application.prometheusScrape.namespaceDropRegex | string | `"(.*istio.*|.*ingress.*|kube-system)"` |  |
| application.prometheusScrape.namespaceKeepRegex | string | `"(.*)"` |  |
| application.prometheusScrape.portKeepRegex | string | `".*metrics"` |  |
| cluster-events.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"observeinc.com/unschedulable"` |  |
| cluster-events.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"DoesNotExist"` |  |
| cluster-events.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key | string | `"kubernetes.io/os"` |  |
| cluster-events.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator | string | `"NotIn"` |  |
| cluster-events.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0] | string | `"windows"` |  |
| cluster-events.clusterRole.create | bool | `false` |  |
| cluster-events.clusterRole.name | string | `"observe-agent-cluster-role"` |  |
| cluster-events.command.extraArgs[0] | string | `"start"` |  |
| cluster-events.command.extraArgs[1] | string | `"--observe-config=/observe-agent-conf/observe-agent.yaml"` |  |
| cluster-events.command.extraArgs[2] | string | `"--config=/conf/relay.yaml"` |  |
| cluster-events.command.name | string | `"observe-agent"` |  |
| cluster-events.configMap.create | bool | `false` |  |
| cluster-events.configMap.existingName | string | `"cluster-events"` |  |
| cluster-events.extraEnvsFrom | list | `[]` |  |
| cluster-events.extraEnvs[0].name | string | `"OBSERVE_CLUSTER_NAME"` |  |
| cluster-events.extraEnvs[0].valueFrom.configMapKeyRef.key | string | `"name"` |  |
| cluster-events.extraEnvs[0].valueFrom.configMapKeyRef.name | string | `"cluster-name"` |  |
| cluster-events.extraEnvs[1].name | string | `"OBSERVE_CLUSTER_UID"` |  |
| cluster-events.extraEnvs[1].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| cluster-events.extraEnvs[1].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| cluster-events.extraEnvs[2].name | string | `"TOKEN"` |  |
| cluster-events.extraEnvs[2].valueFrom.secretKeyRef.key | string | `"OBSERVE_TOKEN"` |  |
| cluster-events.extraEnvs[2].valueFrom.secretKeyRef.name | string | `"agent-credentials"` |  |
| cluster-events.extraEnvs[2].valueFrom.secretKeyRef.optional | bool | `true` |  |
| cluster-events.extraVolumeMounts[0].mountPath | string | `"/observe-agent-conf"` |  |
| cluster-events.extraVolumeMounts[0].name | string | `"observe-agent-deployment-config"` |  |
| cluster-events.extraVolumes[0].configMap.defaultMode | int | `420` |  |
| cluster-events.extraVolumes[0].configMap.items[0].key | string | `"relay"` |  |
| cluster-events.extraVolumes[0].configMap.items[0].path | string | `"observe-agent.yaml"` |  |
| cluster-events.extraVolumes[0].configMap.name | string | `"observe-agent"` |  |
| cluster-events.extraVolumes[0].name | string | `"observe-agent-deployment-config"` |  |
| cluster-events.image | object | `{"pullPolicy":"IfNotPresent","repository":"observeinc/observe-agent","tag":"2.3.0"}` | --------------------------------------- # Same for each deployment/daemonset      # |
| cluster-events.initContainers[0].env[0].name | string | `"NAMESPACE"` |  |
| cluster-events.initContainers[0].env[0].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| cluster-events.initContainers[0].image | string | `"observeinc/kube-cluster-info:v0.11.1"` |  |
| cluster-events.initContainers[0].imagePullPolicy | string | `"Always"` |  |
| cluster-events.initContainers[0].name | string | `"kube-cluster-info"` |  |
| cluster-events.livenessProbe.httpGet.path | string | `"/status"` |  |
| cluster-events.livenessProbe.httpGet.port | int | `13133` |  |
| cluster-events.livenessProbe.initialDelaySeconds | int | `30` |  |
| cluster-events.livenessProbe.periodSeconds | int | `5` |  |
| cluster-events.mode | string | `"deployment"` |  |
| cluster-events.nameOverride | string | `"cluster-events"` | --------------------------------------- # Different for each deployment/daemonset # |
| cluster-events.namespaceOverride | string | `"observe"` |  |
| cluster-events.networkPolicy.egressRules[0] | object | `{}` |  |
| cluster-events.networkPolicy.enabled | bool | `true` |  |
| cluster-events.podAnnotations.observe_monitor_path | string | `"/metrics"` |  |
| cluster-events.podAnnotations.observe_monitor_port | string | `"8888"` |  |
| cluster-events.podAnnotations.observe_monitor_purpose | string | `"observecollection"` |  |
| cluster-events.podAnnotations.observe_monitor_scrape | string | `"true"` |  |
| cluster-events.podAnnotations.observeinc_com_scrape | string | `"false"` |  |
| cluster-events.ports.metrics.containerPort | int | `8888` |  |
| cluster-events.ports.metrics.enabled | bool | `true` |  |
| cluster-events.ports.metrics.protocol | string | `"TCP"` |  |
| cluster-events.ports.metrics.servicePort | int | `8888` |  |
| cluster-events.readinessProbe.httpGet.path | string | `"/status"` |  |
| cluster-events.readinessProbe.httpGet.port | int | `13133` |  |
| cluster-events.readinessProbe.initialDelaySeconds | int | `30` |  |
| cluster-events.readinessProbe.periodSeconds | int | `5` |  |
| cluster-events.resources.limits.memory | string | `"256Mi"` |  |
| cluster-events.resources.requests.cpu | string | `"150m"` |  |
| cluster-events.resources.requests.memory | string | `"256Mi"` |  |
| cluster-events.serviceAccount.create | bool | `false` |  |
| cluster-events.serviceAccount.name | string | `"observe-agent-service-account"` |  |
| cluster-events.tolerations | list | `[]` |  |
| cluster-metrics.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"observeinc.com/unschedulable"` |  |
| cluster-metrics.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"DoesNotExist"` |  |
| cluster-metrics.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key | string | `"kubernetes.io/os"` |  |
| cluster-metrics.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator | string | `"NotIn"` |  |
| cluster-metrics.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0] | string | `"windows"` |  |
| cluster-metrics.clusterRole.create | bool | `false` |  |
| cluster-metrics.clusterRole.name | string | `"observe-agent-cluster-role"` |  |
| cluster-metrics.command.extraArgs[0] | string | `"start"` |  |
| cluster-metrics.command.extraArgs[1] | string | `"--observe-config=/observe-agent-conf/observe-agent.yaml"` |  |
| cluster-metrics.command.extraArgs[2] | string | `"--config=/conf/relay.yaml"` |  |
| cluster-metrics.command.extraArgs[3] | string | `"--feature-gates=+exporter.prometheusremotewritexporter.EnableMultipleWorkers"` |  |
| cluster-metrics.command.name | string | `"observe-agent"` |  |
| cluster-metrics.configMap.create | bool | `false` |  |
| cluster-metrics.configMap.existingName | string | `"cluster-metrics"` |  |
| cluster-metrics.extraEnvsFrom | list | `[]` |  |
| cluster-metrics.extraEnvs[0].name | string | `"OBSERVE_CLUSTER_NAME"` |  |
| cluster-metrics.extraEnvs[0].valueFrom.configMapKeyRef.key | string | `"name"` |  |
| cluster-metrics.extraEnvs[0].valueFrom.configMapKeyRef.name | string | `"cluster-name"` |  |
| cluster-metrics.extraEnvs[1].name | string | `"OBSERVE_CLUSTER_UID"` |  |
| cluster-metrics.extraEnvs[1].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| cluster-metrics.extraEnvs[1].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| cluster-metrics.extraEnvs[2].name | string | `"TOKEN"` |  |
| cluster-metrics.extraEnvs[2].valueFrom.secretKeyRef.key | string | `"OBSERVE_TOKEN"` |  |
| cluster-metrics.extraEnvs[2].valueFrom.secretKeyRef.name | string | `"agent-credentials"` |  |
| cluster-metrics.extraEnvs[2].valueFrom.secretKeyRef.optional | bool | `true` |  |
| cluster-metrics.extraVolumeMounts[0].mountPath | string | `"/observe-agent-conf"` |  |
| cluster-metrics.extraVolumeMounts[0].name | string | `"observe-agent-deployment-config"` |  |
| cluster-metrics.extraVolumes[0].configMap.defaultMode | int | `420` |  |
| cluster-metrics.extraVolumes[0].configMap.items[0].key | string | `"relay"` |  |
| cluster-metrics.extraVolumes[0].configMap.items[0].path | string | `"observe-agent.yaml"` |  |
| cluster-metrics.extraVolumes[0].configMap.name | string | `"observe-agent"` |  |
| cluster-metrics.extraVolumes[0].name | string | `"observe-agent-deployment-config"` |  |
| cluster-metrics.image | object | `{"pullPolicy":"IfNotPresent","repository":"observeinc/observe-agent","tag":"2.3.0"}` | --------------------------------------- # Same for each deployment/daemonset      # |
| cluster-metrics.initContainers[0].env[0].name | string | `"NAMESPACE"` |  |
| cluster-metrics.initContainers[0].env[0].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| cluster-metrics.initContainers[0].image | string | `"observeinc/kube-cluster-info:v0.11.1"` |  |
| cluster-metrics.initContainers[0].imagePullPolicy | string | `"Always"` |  |
| cluster-metrics.initContainers[0].name | string | `"kube-cluster-info"` |  |
| cluster-metrics.livenessProbe.httpGet.path | string | `"/status"` |  |
| cluster-metrics.livenessProbe.httpGet.port | int | `13133` |  |
| cluster-metrics.livenessProbe.initialDelaySeconds | int | `30` |  |
| cluster-metrics.livenessProbe.periodSeconds | int | `5` |  |
| cluster-metrics.mode | string | `"deployment"` |  |
| cluster-metrics.nameOverride | string | `"cluster-metrics"` | --------------------------------------- # Different for each deployment/daemonset # |
| cluster-metrics.namespaceOverride | string | `"observe"` |  |
| cluster-metrics.networkPolicy.egressRules[0] | object | `{}` |  |
| cluster-metrics.networkPolicy.enabled | bool | `true` |  |
| cluster-metrics.podAnnotations.observe_monitor_path | string | `"/metrics"` |  |
| cluster-metrics.podAnnotations.observe_monitor_port | string | `"8888"` |  |
| cluster-metrics.podAnnotations.observe_monitor_purpose | string | `"observecollection"` |  |
| cluster-metrics.podAnnotations.observe_monitor_scrape | string | `"true"` |  |
| cluster-metrics.podAnnotations.observeinc_com_scrape | string | `"false"` |  |
| cluster-metrics.ports.metrics.containerPort | int | `8888` |  |
| cluster-metrics.ports.metrics.enabled | bool | `true` |  |
| cluster-metrics.ports.metrics.protocol | string | `"TCP"` |  |
| cluster-metrics.ports.metrics.servicePort | int | `8888` |  |
| cluster-metrics.readinessProbe.httpGet.path | string | `"/status"` |  |
| cluster-metrics.readinessProbe.httpGet.port | int | `13133` |  |
| cluster-metrics.readinessProbe.initialDelaySeconds | int | `30` |  |
| cluster-metrics.readinessProbe.periodSeconds | int | `5` |  |
| cluster-metrics.resources.limits.memory | string | `"512Mi"` |  |
| cluster-metrics.resources.requests.cpu | string | `"250m"` |  |
| cluster-metrics.resources.requests.memory | string | `"512Mi"` |  |
| cluster-metrics.serviceAccount.create | bool | `false` |  |
| cluster-metrics.serviceAccount.name | string | `"observe-agent-service-account"` |  |
| cluster-metrics.tolerations | list | `[]` |  |
| cluster.events.enabled | bool | `true` |  |
| cluster.events.pullInterval | string | `"20m"` |  |
| cluster.metrics.enabled | bool | `true` |  |
| cluster.metrics.interval | string | `"60s"` |  |
| cluster.name | string | `"observe-agent-monitored-cluster"` |  |
| cluster.namespaceOverride.value | string | `"observe"` |  |
| cluster.uidOverride.value | string | `""` |  |
| forwarder.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"observeinc.com/unschedulable"` |  |
| forwarder.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"DoesNotExist"` |  |
| forwarder.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key | string | `"kubernetes.io/os"` |  |
| forwarder.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator | string | `"NotIn"` |  |
| forwarder.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0] | string | `"windows"` |  |
| forwarder.clusterRole.create | bool | `false` |  |
| forwarder.clusterRole.name | string | `"observe-agent-cluster-role"` |  |
| forwarder.command.extraArgs[0] | string | `"start"` |  |
| forwarder.command.extraArgs[1] | string | `"--observe-config=/observe-agent-conf/observe-agent.yaml"` |  |
| forwarder.command.extraArgs[2] | string | `"--config=/conf/relay.yaml"` |  |
| forwarder.command.name | string | `"observe-agent"` |  |
| forwarder.configMap.create | bool | `false` |  |
| forwarder.configMap.existingName | string | `"forwarder"` |  |
| forwarder.extraEnvsFrom | list | `[]` |  |
| forwarder.extraEnvs[0].name | string | `"OBSERVE_CLUSTER_NAME"` |  |
| forwarder.extraEnvs[0].valueFrom.configMapKeyRef.key | string | `"name"` |  |
| forwarder.extraEnvs[0].valueFrom.configMapKeyRef.name | string | `"cluster-name"` |  |
| forwarder.extraEnvs[1].name | string | `"OBSERVE_CLUSTER_UID"` |  |
| forwarder.extraEnvs[1].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| forwarder.extraEnvs[1].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| forwarder.extraEnvs[2].name | string | `"K8S_NODE_NAME"` |  |
| forwarder.extraEnvs[2].valueFrom.fieldRef.fieldPath | string | `"spec.nodeName"` |  |
| forwarder.extraEnvs[3].name | string | `"TOKEN"` |  |
| forwarder.extraEnvs[3].valueFrom.secretKeyRef.key | string | `"OBSERVE_TOKEN"` |  |
| forwarder.extraEnvs[3].valueFrom.secretKeyRef.name | string | `"agent-credentials"` |  |
| forwarder.extraEnvs[3].valueFrom.secretKeyRef.optional | bool | `true` |  |
| forwarder.extraEnvs[4].name | string | `"TRACE_TOKEN"` |  |
| forwarder.extraEnvs[4].valueFrom.secretKeyRef.key | string | `"TRACE_TOKEN"` |  |
| forwarder.extraEnvs[4].valueFrom.secretKeyRef.name | string | `"agent-credentials"` |  |
| forwarder.extraEnvs[4].valueFrom.secretKeyRef.optional | bool | `true` |  |
| forwarder.extraVolumeMounts[0].mountPath | string | `"/observe-agent-conf"` |  |
| forwarder.extraVolumeMounts[0].name | string | `"observe-agent-deployment-config"` |  |
| forwarder.extraVolumes[0].configMap.defaultMode | int | `420` |  |
| forwarder.extraVolumes[0].configMap.items[0].key | string | `"relay"` |  |
| forwarder.extraVolumes[0].configMap.items[0].path | string | `"observe-agent.yaml"` |  |
| forwarder.extraVolumes[0].configMap.name | string | `"observe-agent"` |  |
| forwarder.extraVolumes[0].name | string | `"observe-agent-deployment-config"` |  |
| forwarder.image | object | `{"pullPolicy":"IfNotPresent","repository":"observeinc/observe-agent","tag":"2.3.0"}` | --------------------------------------- # Same for each deployment/daemonset      # |
| forwarder.initContainers[0].env[0].name | string | `"NAMESPACE"` |  |
| forwarder.initContainers[0].env[0].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| forwarder.initContainers[0].image | string | `"observeinc/kube-cluster-info:v0.11.1"` |  |
| forwarder.initContainers[0].imagePullPolicy | string | `"Always"` |  |
| forwarder.initContainers[0].name | string | `"kube-cluster-info"` |  |
| forwarder.livenessProbe.httpGet.path | string | `"/status"` |  |
| forwarder.livenessProbe.httpGet.port | int | `13133` |  |
| forwarder.livenessProbe.initialDelaySeconds | int | `30` |  |
| forwarder.livenessProbe.periodSeconds | int | `5` |  |
| forwarder.mode | string | `"daemonset"` |  |
| forwarder.nameOverride | string | `"forwarder"` | --------------------------------------- # Different for each deployment/daemonset # |
| forwarder.namespaceOverride | string | `"observe"` |  |
| forwarder.networkPolicy.egressRules[0] | object | `{}` |  |
| forwarder.networkPolicy.enabled | bool | `true` |  |
| forwarder.podAnnotations.observe_monitor_path | string | `"/metrics"` |  |
| forwarder.podAnnotations.observe_monitor_port | string | `"8888"` |  |
| forwarder.podAnnotations.observe_monitor_purpose | string | `"observecollection"` |  |
| forwarder.podAnnotations.observe_monitor_scrape | string | `"true"` |  |
| forwarder.podAnnotations.observeinc_com_scrape | string | `"false"` |  |
| forwarder.ports.metrics.containerPort | int | `8888` |  |
| forwarder.ports.metrics.enabled | bool | `true` |  |
| forwarder.ports.metrics.protocol | string | `"TCP"` |  |
| forwarder.ports.metrics.servicePort | int | `8888` |  |
| forwarder.readinessProbe.httpGet.path | string | `"/status"` |  |
| forwarder.readinessProbe.httpGet.port | int | `13133` |  |
| forwarder.readinessProbe.initialDelaySeconds | int | `30` |  |
| forwarder.readinessProbe.periodSeconds | int | `5` |  |
| forwarder.resources.limits.memory | string | `"512Mi"` |  |
| forwarder.resources.requests.cpu | string | `"300m"` |  |
| forwarder.resources.requests.memory | string | `"512Mi"` |  |
| forwarder.service.enabled | bool | `true` |  |
| forwarder.service.type | string | `"ClusterIP"` |  |
| forwarder.serviceAccount.create | bool | `false` |  |
| forwarder.serviceAccount.name | string | `"observe-agent-service-account"` |  |
| forwarder.tolerations | list | `[]` |  |
| monitor.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"observeinc.com/unschedulable"` |  |
| monitor.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"DoesNotExist"` |  |
| monitor.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key | string | `"kubernetes.io/os"` |  |
| monitor.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator | string | `"NotIn"` |  |
| monitor.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0] | string | `"windows"` |  |
| monitor.clusterRole.create | bool | `false` |  |
| monitor.clusterRole.name | string | `"observe-agent-cluster-role"` |  |
| monitor.command.extraArgs[0] | string | `"start"` |  |
| monitor.command.extraArgs[1] | string | `"--observe-config=/observe-agent-conf/observe-agent.yaml"` |  |
| monitor.command.extraArgs[2] | string | `"--config=/conf/relay.yaml"` |  |
| monitor.command.extraArgs[3] | string | `"--feature-gates=+exporter.prometheusremotewritexporter.EnableMultipleWorkers"` |  |
| monitor.command.name | string | `"observe-agent"` |  |
| monitor.configMap.create | bool | `false` |  |
| monitor.configMap.existingName | string | `"monitor"` |  |
| monitor.extraEnvsFrom | list | `[]` |  |
| monitor.extraEnvs[0].name | string | `"OBSERVE_CLUSTER_NAME"` |  |
| monitor.extraEnvs[0].valueFrom.configMapKeyRef.key | string | `"name"` |  |
| monitor.extraEnvs[0].valueFrom.configMapKeyRef.name | string | `"cluster-name"` |  |
| monitor.extraEnvs[1].name | string | `"OBSERVE_CLUSTER_UID"` |  |
| monitor.extraEnvs[1].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| monitor.extraEnvs[1].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| monitor.extraEnvs[2].name | string | `"TOKEN"` |  |
| monitor.extraEnvs[2].valueFrom.secretKeyRef.key | string | `"OBSERVE_TOKEN"` |  |
| monitor.extraEnvs[2].valueFrom.secretKeyRef.name | string | `"agent-credentials"` |  |
| monitor.extraEnvs[2].valueFrom.secretKeyRef.optional | bool | `true` |  |
| monitor.extraVolumeMounts[0].mountPath | string | `"/observe-agent-conf"` |  |
| monitor.extraVolumeMounts[0].name | string | `"observe-agent-deployment-config"` |  |
| monitor.extraVolumes[0].configMap.defaultMode | int | `420` |  |
| monitor.extraVolumes[0].configMap.items[0].key | string | `"relay"` |  |
| monitor.extraVolumes[0].configMap.items[0].path | string | `"observe-agent.yaml"` |  |
| monitor.extraVolumes[0].configMap.name | string | `"observe-agent"` |  |
| monitor.extraVolumes[0].name | string | `"observe-agent-deployment-config"` |  |
| monitor.image | object | `{"pullPolicy":"IfNotPresent","repository":"observeinc/observe-agent","tag":"2.3.0"}` | --------------------------------------- # Same for each deployment/daemonset      # |
| monitor.initContainers[0].env[0].name | string | `"NAMESPACE"` |  |
| monitor.initContainers[0].env[0].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| monitor.initContainers[0].image | string | `"observeinc/kube-cluster-info:v0.11.1"` |  |
| monitor.initContainers[0].imagePullPolicy | string | `"Always"` |  |
| monitor.initContainers[0].name | string | `"kube-cluster-info"` |  |
| monitor.livenessProbe.httpGet.path | string | `"/status"` |  |
| monitor.livenessProbe.httpGet.port | int | `13133` |  |
| monitor.livenessProbe.initialDelaySeconds | int | `30` |  |
| monitor.livenessProbe.periodSeconds | int | `5` |  |
| monitor.mode | string | `"deployment"` |  |
| monitor.nameOverride | string | `"monitor"` | --------------------------------------- # Different for each deployment/daemonset # |
| monitor.namespaceOverride | string | `"observe"` |  |
| monitor.networkPolicy.egressRules[0] | object | `{}` |  |
| monitor.networkPolicy.enabled | bool | `true` |  |
| monitor.podAnnotations.observe_monitor_path | string | `"/metrics"` |  |
| monitor.podAnnotations.observe_monitor_port | string | `"8888"` |  |
| monitor.podAnnotations.observe_monitor_purpose | string | `"observecollection"` |  |
| monitor.podAnnotations.observe_monitor_scrape | string | `"false"` |  |
| monitor.podAnnotations.observeinc_com_scrape | string | `"false"` |  |
| monitor.ports.metrics.containerPort | int | `8888` |  |
| monitor.ports.metrics.enabled | bool | `true` |  |
| monitor.ports.metrics.protocol | string | `"TCP"` |  |
| monitor.ports.metrics.servicePort | int | `8888` |  |
| monitor.readinessProbe.httpGet.path | string | `"/status"` |  |
| monitor.readinessProbe.httpGet.port | int | `13133` |  |
| monitor.readinessProbe.initialDelaySeconds | int | `30` |  |
| monitor.readinessProbe.periodSeconds | int | `5` |  |
| monitor.resources.limits.memory | string | `"256Mi"` |  |
| monitor.resources.requests.cpu | string | `"150m"` |  |
| monitor.resources.requests.memory | string | `"256Mi"` |  |
| monitor.serviceAccount.create | bool | `false` |  |
| monitor.serviceAccount.name | string | `"observe-agent-service-account"` |  |
| monitor.tolerations | list | `[]` |  |
| node-logs-metrics.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"observeinc.com/unschedulable"` |  |
| node-logs-metrics.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"DoesNotExist"` |  |
| node-logs-metrics.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key | string | `"kubernetes.io/os"` |  |
| node-logs-metrics.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator | string | `"NotIn"` |  |
| node-logs-metrics.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0] | string | `"windows"` |  |
| node-logs-metrics.clusterRole.create | bool | `false` |  |
| node-logs-metrics.clusterRole.name | string | `"observe-agent-cluster-role"` |  |
| node-logs-metrics.command.extraArgs[0] | string | `"start"` |  |
| node-logs-metrics.command.extraArgs[1] | string | `"--observe-config=/observe-agent-conf/observe-agent.yaml"` |  |
| node-logs-metrics.command.extraArgs[2] | string | `"--config=/conf/relay.yaml"` |  |
| node-logs-metrics.command.extraArgs[3] | string | `"--feature-gates=+exporter.prometheusremotewritexporter.EnableMultipleWorkers"` |  |
| node-logs-metrics.command.name | string | `"observe-agent"` |  |
| node-logs-metrics.configMap.create | bool | `false` |  |
| node-logs-metrics.configMap.existingName | string | `"node-logs-metrics"` |  |
| node-logs-metrics.extraEnvsFrom | list | `[]` |  |
| node-logs-metrics.extraEnvs[0].name | string | `"OBSERVE_CLUSTER_NAME"` |  |
| node-logs-metrics.extraEnvs[0].valueFrom.configMapKeyRef.key | string | `"name"` |  |
| node-logs-metrics.extraEnvs[0].valueFrom.configMapKeyRef.name | string | `"cluster-name"` |  |
| node-logs-metrics.extraEnvs[1].name | string | `"OBSERVE_CLUSTER_UID"` |  |
| node-logs-metrics.extraEnvs[1].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| node-logs-metrics.extraEnvs[1].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| node-logs-metrics.extraEnvs[2].name | string | `"K8S_NODE_NAME"` |  |
| node-logs-metrics.extraEnvs[2].valueFrom.fieldRef.fieldPath | string | `"spec.nodeName"` |  |
| node-logs-metrics.extraEnvs[3].name | string | `"K8S_NODE_IP"` |  |
| node-logs-metrics.extraEnvs[3].valueFrom.fieldRef.fieldPath | string | `"status.hostIP"` |  |
| node-logs-metrics.extraEnvs[4].name | string | `"TOKEN"` |  |
| node-logs-metrics.extraEnvs[4].valueFrom.secretKeyRef.key | string | `"OBSERVE_TOKEN"` |  |
| node-logs-metrics.extraEnvs[4].valueFrom.secretKeyRef.name | string | `"agent-credentials"` |  |
| node-logs-metrics.extraEnvs[4].valueFrom.secretKeyRef.optional | bool | `true` |  |
| node-logs-metrics.extraEnvs[5].name | string | `"TRACES_TOKEN"` |  |
| node-logs-metrics.extraEnvs[5].valueFrom.secretKeyRef.key | string | `"TRACES_TOKEN"` |  |
| node-logs-metrics.extraEnvs[5].valueFrom.secretKeyRef.name | string | `"agent-credentials"` |  |
| node-logs-metrics.extraEnvs[5].valueFrom.secretKeyRef.optional | bool | `true` |  |
| node-logs-metrics.extraVolumeMounts[0].mountPath | string | `"/observe-agent-conf"` |  |
| node-logs-metrics.extraVolumeMounts[0].name | string | `"observe-agent-deployment-config"` |  |
| node-logs-metrics.extraVolumeMounts[1].mountPath | string | `"/var/log/pods"` |  |
| node-logs-metrics.extraVolumeMounts[1].name | string | `"varlogpods"` |  |
| node-logs-metrics.extraVolumeMounts[1].readOnly | bool | `true` |  |
| node-logs-metrics.extraVolumeMounts[2].mountPath | string | `"/var/lib/docker/containers"` |  |
| node-logs-metrics.extraVolumeMounts[2].name | string | `"varlibdockercontainers"` |  |
| node-logs-metrics.extraVolumeMounts[2].readOnly | bool | `true` |  |
| node-logs-metrics.extraVolumeMounts[3].mountPath | string | `"/var/lib/otelcol"` |  |
| node-logs-metrics.extraVolumeMounts[3].name | string | `"varlibotelcol"` |  |
| node-logs-metrics.extraVolumeMounts[4].mountPath | string | `"/hostfs"` |  |
| node-logs-metrics.extraVolumeMounts[4].mountPropagation | string | `"HostToContainer"` |  |
| node-logs-metrics.extraVolumeMounts[4].name | string | `"hostfs"` |  |
| node-logs-metrics.extraVolumeMounts[4].readOnly | bool | `true` |  |
| node-logs-metrics.extraVolumes[0].configMap.defaultMode | int | `420` |  |
| node-logs-metrics.extraVolumes[0].configMap.items[0].key | string | `"relay"` |  |
| node-logs-metrics.extraVolumes[0].configMap.items[0].path | string | `"observe-agent.yaml"` |  |
| node-logs-metrics.extraVolumes[0].configMap.name | string | `"observe-agent"` |  |
| node-logs-metrics.extraVolumes[0].name | string | `"observe-agent-deployment-config"` |  |
| node-logs-metrics.extraVolumes[1].hostPath.path | string | `"/var/log/pods"` |  |
| node-logs-metrics.extraVolumes[1].name | string | `"varlogpods"` |  |
| node-logs-metrics.extraVolumes[2].hostPath.path | string | `"/var/lib/docker/containers"` |  |
| node-logs-metrics.extraVolumes[2].name | string | `"varlibdockercontainers"` |  |
| node-logs-metrics.extraVolumes[3].hostPath.path | string | `"/var/lib/otelcol"` |  |
| node-logs-metrics.extraVolumes[3].hostPath.type | string | `"DirectoryOrCreate"` |  |
| node-logs-metrics.extraVolumes[3].name | string | `"varlibotelcol"` |  |
| node-logs-metrics.extraVolumes[4].hostPath.path | string | `"/"` |  |
| node-logs-metrics.extraVolumes[4].name | string | `"hostfs"` |  |
| node-logs-metrics.image | object | `{"pullPolicy":"IfNotPresent","repository":"observeinc/observe-agent","tag":"2.3.0"}` | --------------------------------------- # Same for each deployment/daemonset      # |
| node-logs-metrics.initContainers[0].env[0].name | string | `"NAMESPACE"` |  |
| node-logs-metrics.initContainers[0].env[0].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| node-logs-metrics.initContainers[0].image | string | `"observeinc/kube-cluster-info:v0.11.1"` |  |
| node-logs-metrics.initContainers[0].imagePullPolicy | string | `"Always"` |  |
| node-logs-metrics.initContainers[0].name | string | `"kube-cluster-info"` |  |
| node-logs-metrics.livenessProbe.httpGet.path | string | `"/status"` |  |
| node-logs-metrics.livenessProbe.httpGet.port | int | `13133` |  |
| node-logs-metrics.livenessProbe.initialDelaySeconds | int | `30` |  |
| node-logs-metrics.livenessProbe.periodSeconds | int | `5` |  |
| node-logs-metrics.mode | string | `"daemonset"` |  |
| node-logs-metrics.nameOverride | string | `"node-logs-metrics"` | --------------------------------------- # Different for each deployment/daemonset # |
| node-logs-metrics.namespaceOverride | string | `"observe"` |  |
| node-logs-metrics.podAnnotations.observe_monitor_path | string | `"/metrics"` |  |
| node-logs-metrics.podAnnotations.observe_monitor_port | string | `"8888"` |  |
| node-logs-metrics.podAnnotations.observe_monitor_purpose | string | `"observecollection"` |  |
| node-logs-metrics.podAnnotations.observe_monitor_scrape | string | `"true"` |  |
| node-logs-metrics.podAnnotations.observeinc_com_scrape | string | `"false"` |  |
| node-logs-metrics.ports.jaeger-compact.enabled | bool | `false` |  |
| node-logs-metrics.ports.jaeger-grpc.enabled | bool | `false` |  |
| node-logs-metrics.ports.jaeger-thrift.enabled | bool | `false` |  |
| node-logs-metrics.ports.metrics.containerPort | int | `8888` |  |
| node-logs-metrics.ports.metrics.enabled | bool | `true` |  |
| node-logs-metrics.ports.metrics.protocol | string | `"TCP"` |  |
| node-logs-metrics.ports.metrics.servicePort | int | `8888` |  |
| node-logs-metrics.ports.otlp-http.enabled | bool | `false` |  |
| node-logs-metrics.ports.otlp.enabled | bool | `false` |  |
| node-logs-metrics.ports.zipkin.enabled | bool | `false` |  |
| node-logs-metrics.readinessProbe.httpGet.path | string | `"/status"` |  |
| node-logs-metrics.readinessProbe.httpGet.port | int | `13133` |  |
| node-logs-metrics.readinessProbe.initialDelaySeconds | int | `30` |  |
| node-logs-metrics.readinessProbe.periodSeconds | int | `5` |  |
| node-logs-metrics.resources.limits.memory | string | `"512Mi"` |  |
| node-logs-metrics.resources.requests.cpu | string | `"250m"` |  |
| node-logs-metrics.resources.requests.memory | string | `"512Mi"` |  |
| node-logs-metrics.securityContext.runAsGroup | int | `0` |  |
| node-logs-metrics.securityContext.runAsUser | int | `0` |  |
| node-logs-metrics.serviceAccount.create | bool | `false` |  |
| node-logs-metrics.serviceAccount.name | string | `"observe-agent-service-account"` |  |
| node-logs-metrics.tolerations | list | `[]` |  |
| node.containers.logs.enabled | bool | `true` |  |
| node.containers.logs.exclude | string | `"[\"**/*.gz\", \"**/*.tmp\"]"` |  |
| node.containers.logs.include | string | `"[\"/var/log/pods/*/*/*.log\", \"/var/log/pods/*/*/*.log.*\", \"/var/log/kube-apiserver-audit.log\"]"` |  |
| node.containers.logs.lookbackPeriod | string | `"24h"` |  |
| node.containers.logs.maxLogSize | string | `"512kb"` |  |
| node.containers.logs.multiline | string | `nil` |  |
| node.containers.logs.retryOnFailure.enabled | bool | `true` |  |
| node.containers.logs.retryOnFailure.initialInterval | string | `"1s"` |  |
| node.containers.logs.retryOnFailure.maxElapsedTime | string | `"5m"` |  |
| node.containers.logs.retryOnFailure.maxInterval | string | `"30s"` |  |
| node.containers.logs.startAt | string | `"end"` |  |
| node.containers.metrics.enabled | bool | `true` |  |
| node.containers.metrics.interval | string | `"60s"` |  |
| node.enabled | bool | `true` |  |
| node.forwarder.enabled | bool | `true` |  |
| node.forwarder.logs.enabled | bool | `true` |  |
| node.forwarder.metrics.enabled | bool | `true` |  |
| node.forwarder.traces.enabled | bool | `true` |  |
| node.kubeletstats.useNodeIp | bool | `false` |  |
| node.metrics.enabled | bool | `true` |  |
| node.metrics.fileSystem.excludeMountPoints | string | `"[\"/dev/*\",\"/proc/*\",\"/sys/*\",\"/run/k3s/containerd/*\",\"/var/lib/docker/*\",\"/var/lib/kubelet/*\",\"/snap/*\"]"` |  |
| node.metrics.fileSystem.rootPath | string | `"/hostfs"` |  |
| node.metrics.interval | string | `"60s"` |  |
| observe.collectionEndpoint.value | string | `""` |  |
| observe.entityToken.create | bool | `false` |  |
| observe.entityToken.use | bool | `false` |  |
| observe.entityToken.value | string | `""` |  |
| observe.token.create | bool | `false` |  |
| observe.token.value | string | `""` |  |
| observe.traceToken.create | bool | `false` |  |
| observe.traceToken.value | string | `""` |  |
| prometheus-scraper.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"observeinc.com/unschedulable"` |  |
| prometheus-scraper.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"DoesNotExist"` |  |
| prometheus-scraper.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key | string | `"kubernetes.io/os"` |  |
| prometheus-scraper.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator | string | `"NotIn"` |  |
| prometheus-scraper.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0] | string | `"windows"` |  |
| prometheus-scraper.clusterRole.create | bool | `false` |  |
| prometheus-scraper.clusterRole.name | string | `"observe-agent-cluster-role"` |  |
| prometheus-scraper.command.extraArgs[0] | string | `"start"` |  |
| prometheus-scraper.command.extraArgs[1] | string | `"--observe-config=/observe-agent-conf/observe-agent.yaml"` |  |
| prometheus-scraper.command.extraArgs[2] | string | `"--config=/conf/relay.yaml"` |  |
| prometheus-scraper.command.extraArgs[3] | string | `"--feature-gates=+exporter.prometheusremotewritexporter.EnableMultipleWorkers"` |  |
| prometheus-scraper.command.name | string | `"observe-agent"` |  |
| prometheus-scraper.configMap.create | bool | `false` |  |
| prometheus-scraper.configMap.existingName | string | `"prometheus-scraper"` |  |
| prometheus-scraper.extraEnvsFrom | list | `[]` |  |
| prometheus-scraper.extraEnvs[0].name | string | `"OBSERVE_CLUSTER_NAME"` |  |
| prometheus-scraper.extraEnvs[0].valueFrom.configMapKeyRef.key | string | `"name"` |  |
| prometheus-scraper.extraEnvs[0].valueFrom.configMapKeyRef.name | string | `"cluster-name"` |  |
| prometheus-scraper.extraEnvs[1].name | string | `"OBSERVE_CLUSTER_UID"` |  |
| prometheus-scraper.extraEnvs[1].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| prometheus-scraper.extraEnvs[1].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| prometheus-scraper.extraEnvs[2].name | string | `"TOKEN"` |  |
| prometheus-scraper.extraEnvs[2].valueFrom.secretKeyRef.key | string | `"OBSERVE_TOKEN"` |  |
| prometheus-scraper.extraEnvs[2].valueFrom.secretKeyRef.name | string | `"agent-credentials"` |  |
| prometheus-scraper.extraEnvs[2].valueFrom.secretKeyRef.optional | bool | `true` |  |
| prometheus-scraper.extraVolumeMounts[0].mountPath | string | `"/observe-agent-conf"` |  |
| prometheus-scraper.extraVolumeMounts[0].name | string | `"observe-agent-deployment-config"` |  |
| prometheus-scraper.extraVolumes[0].configMap.defaultMode | int | `420` |  |
| prometheus-scraper.extraVolumes[0].configMap.items[0].key | string | `"relay"` |  |
| prometheus-scraper.extraVolumes[0].configMap.items[0].path | string | `"observe-agent.yaml"` |  |
| prometheus-scraper.extraVolumes[0].configMap.name | string | `"observe-agent"` |  |
| prometheus-scraper.extraVolumes[0].name | string | `"observe-agent-deployment-config"` |  |
| prometheus-scraper.image | object | `{"pullPolicy":"IfNotPresent","repository":"observeinc/observe-agent","tag":"2.3.0"}` | --------------------------------------- # Same for each deployment/daemonset      # |
| prometheus-scraper.initContainers[0].env[0].name | string | `"NAMESPACE"` |  |
| prometheus-scraper.initContainers[0].env[0].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| prometheus-scraper.initContainers[0].image | string | `"observeinc/kube-cluster-info:v0.11.1"` |  |
| prometheus-scraper.initContainers[0].imagePullPolicy | string | `"Always"` |  |
| prometheus-scraper.initContainers[0].name | string | `"kube-cluster-info"` |  |
| prometheus-scraper.livenessProbe.httpGet.path | string | `"/status"` |  |
| prometheus-scraper.livenessProbe.httpGet.port | int | `13133` |  |
| prometheus-scraper.livenessProbe.initialDelaySeconds | int | `30` |  |
| prometheus-scraper.livenessProbe.periodSeconds | int | `5` |  |
| prometheus-scraper.mode | string | `"deployment"` |  |
| prometheus-scraper.nameOverride | string | `"prometheus-scraper"` | --------------------------------------- # Different for each deployment/daemonset # |
| prometheus-scraper.namespaceOverride | string | `"observe"` |  |
| prometheus-scraper.networkPolicy.egressRules[0] | object | `{}` |  |
| prometheus-scraper.networkPolicy.enabled | bool | `true` |  |
| prometheus-scraper.podAnnotations.observe_monitor_path | string | `"/metrics"` |  |
| prometheus-scraper.podAnnotations.observe_monitor_port | string | `"8888"` |  |
| prometheus-scraper.podAnnotations.observe_monitor_purpose | string | `"observecollection"` |  |
| prometheus-scraper.podAnnotations.observe_monitor_scrape | string | `"true"` |  |
| prometheus-scraper.podAnnotations.observeinc_com_scrape | string | `"false"` |  |
| prometheus-scraper.ports.metrics.containerPort | int | `8888` |  |
| prometheus-scraper.ports.metrics.enabled | bool | `true` |  |
| prometheus-scraper.ports.metrics.protocol | string | `"TCP"` |  |
| prometheus-scraper.ports.metrics.servicePort | int | `8888` |  |
| prometheus-scraper.readinessProbe.httpGet.path | string | `"/status"` |  |
| prometheus-scraper.readinessProbe.httpGet.port | int | `13133` |  |
| prometheus-scraper.readinessProbe.initialDelaySeconds | int | `30` |  |
| prometheus-scraper.readinessProbe.periodSeconds | int | `5` |  |
| prometheus-scraper.resources.limits.memory | string | `"512Mi"` |  |
| prometheus-scraper.resources.requests.cpu | string | `"250m"` |  |
| prometheus-scraper.resources.requests.memory | string | `"512Mi"` |  |
| prometheus-scraper.serviceAccount.create | bool | `false` |  |
| prometheus-scraper.serviceAccount.name | string | `"observe-agent-service-account"` |  |
| prometheus-scraper.tolerations | list | `[]` |  |
