# agent

![Version: 0.30.3](https://img.shields.io/badge/Version-0.30.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.1.0](https://img.shields.io/badge/AppVersion-1.1.0-informational?style=flat-square)

> [!CAUTION]
> This chart is under active development and is not meant to be installed yet.

Chart to install K8s collection stack based on Observe Agent

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Observe | <support@observeinc.com> |  |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://open-telemetry.github.io/opentelemetry-helm-charts | cluster-events(opentelemetry-collector) | 0.101.1 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | cluster-metrics(opentelemetry-collector) | 0.101.1 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | node-logs-metrics(opentelemetry-collector) | 0.101.1 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | monitor(opentelemetry-collector) | 0.101.1 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| agent.config.global.debug.verbosity | string | `"basic"` |  |
| agent.config.global.exporters.retryOnFailure.enabled | bool | `true` |  |
| agent.config.global.exporters.retryOnFailure.initialInterval | string | `"1s"` |  |
| agent.config.global.exporters.retryOnFailure.maxElapsedTime | string | `"5m"` |  |
| agent.config.global.exporters.retryOnFailure.maxInterval | string | `"30s"` |  |
| agent.config.global.exporters.sendingQueue.enabled | bool | `true` |  |
| agent.config.global.processors.batch.sendBatchMaxSize | int | `4096` |  |
| agent.config.global.processors.batch.sendBatchSize | int | `4096` |  |
| agent.config.global.service.telemetry.loggingEncoding | string | `"console"` |  |
| agent.config.global.service.telemetry.loggingLevel | string | `"WARN"` |  |
| agent.config.global.service.telemetry.metricsLevel | string | `"normal"` |  |
| agent.selfMonitor.enabled | bool | `true` |  |
| application.prometheusScrape.enabled | bool | `false` |  |
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
| cluster-events.command.extraArgs[1] | string | `"--config=/observe-agent-conf/observe-agent.yaml"` |  |
| cluster-events.command.extraArgs[2] | string | `"--otel-config=/conf/relay.yaml"` |  |
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
| cluster-events.extraEnvs[3].name | string | `"ENTITY_TOKEN"` |  |
| cluster-events.extraEnvs[3].valueFrom.secretKeyRef.key | string | `"ENTITY_TOKEN"` |  |
| cluster-events.extraEnvs[3].valueFrom.secretKeyRef.name | string | `"agent-credentials"` |  |
| cluster-events.extraEnvs[3].valueFrom.secretKeyRef.optional | bool | `true` |  |
| cluster-events.extraVolumeMounts[0].mountPath | string | `"/observe-agent-conf"` |  |
| cluster-events.extraVolumeMounts[0].name | string | `"observe-agent-deployment-config"` |  |
| cluster-events.extraVolumes[0].configMap.defaultMode | int | `420` |  |
| cluster-events.extraVolumes[0].configMap.items[0].key | string | `"relay"` |  |
| cluster-events.extraVolumes[0].configMap.items[0].path | string | `"observe-agent.yaml"` |  |
| cluster-events.extraVolumes[0].configMap.name | string | `"observe-agent"` |  |
| cluster-events.extraVolumes[0].name | string | `"observe-agent-deployment-config"` |  |
| cluster-events.image.pullPolicy | string | `"IfNotPresent"` |  |
| cluster-events.image.repository | string | `"observeinc/observe-agent"` |  |
| cluster-events.image.tag | string | `"1.4.0"` |  |
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
| cluster-events.resources | object | `{"requests":{"cpu":"250m","memory":"256Mi"}}` | --------------------------------------- # Same for each deployment/daemonset      # |
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
| cluster-metrics.command.extraArgs[1] | string | `"--config=/observe-agent-conf/observe-agent.yaml"` |  |
| cluster-metrics.command.extraArgs[2] | string | `"--otel-config=/conf/relay.yaml"` |  |
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
| cluster-metrics.image.pullPolicy | string | `"IfNotPresent"` |  |
| cluster-metrics.image.repository | string | `"observeinc/observe-agent"` |  |
| cluster-metrics.image.tag | string | `"1.4.0"` |  |
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
| cluster-metrics.resources | object | `{"requests":{"cpu":"250m","memory":"256Mi"}}` | --------------------------------------- # Same for each deployment/daemonset      # |
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
| monitor.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"observeinc.com/unschedulable"` |  |
| monitor.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"DoesNotExist"` |  |
| monitor.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key | string | `"kubernetes.io/os"` |  |
| monitor.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator | string | `"NotIn"` |  |
| monitor.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0] | string | `"windows"` |  |
| monitor.clusterRole.create | bool | `false` |  |
| monitor.clusterRole.name | string | `"observe-agent-cluster-role"` |  |
| monitor.command.extraArgs[0] | string | `"start"` |  |
| monitor.command.extraArgs[1] | string | `"--config=/observe-agent-conf/observe-agent.yaml"` |  |
| monitor.command.extraArgs[2] | string | `"--otel-config=/conf/relay.yaml"` |  |
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
| monitor.image.pullPolicy | string | `"IfNotPresent"` |  |
| monitor.image.repository | string | `"observeinc/observe-agent"` |  |
| monitor.image.tag | string | `"1.4.0"` |  |
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
| monitor.resources | object | `{"requests":{"cpu":"250m","memory":"256Mi"}}` | --------------------------------------- # Same for each deployment/daemonset      # |
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
| node-logs-metrics.command.extraArgs[1] | string | `"--config=/observe-agent-conf/observe-agent.yaml"` |  |
| node-logs-metrics.command.extraArgs[2] | string | `"--otel-config=/conf/relay.yaml"` |  |
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
| node-logs-metrics.extraEnvs[3].name | string | `"TOKEN"` |  |
| node-logs-metrics.extraEnvs[3].valueFrom.secretKeyRef.key | string | `"OBSERVE_TOKEN"` |  |
| node-logs-metrics.extraEnvs[3].valueFrom.secretKeyRef.name | string | `"agent-credentials"` |  |
| node-logs-metrics.extraEnvs[3].valueFrom.secretKeyRef.optional | bool | `true` |  |
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
| node-logs-metrics.image.pullPolicy | string | `"IfNotPresent"` |  |
| node-logs-metrics.image.repository | string | `"observeinc/observe-agent"` |  |
| node-logs-metrics.image.tag | string | `"1.4.0"` |  |
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
| node-logs-metrics.networkPolicy.egressRules[0] | object | `{}` |  |
| node-logs-metrics.networkPolicy.enabled | bool | `true` |  |
| node-logs-metrics.podAnnotations.observe_monitor_path | string | `"/metrics"` |  |
| node-logs-metrics.podAnnotations.observe_monitor_port | string | `"8888"` |  |
| node-logs-metrics.podAnnotations.observe_monitor_purpose | string | `"observecollection"` |  |
| node-logs-metrics.podAnnotations.observe_monitor_scrape | string | `"true"` |  |
| node-logs-metrics.podAnnotations.observeinc_com_scrape | string | `"false"` |  |
| node-logs-metrics.ports.metrics.containerPort | int | `8888` |  |
| node-logs-metrics.ports.metrics.enabled | bool | `true` |  |
| node-logs-metrics.ports.metrics.protocol | string | `"TCP"` |  |
| node-logs-metrics.ports.metrics.servicePort | int | `8888` |  |
| node-logs-metrics.readinessProbe.httpGet.path | string | `"/status"` |  |
| node-logs-metrics.readinessProbe.httpGet.port | int | `13133` |  |
| node-logs-metrics.readinessProbe.initialDelaySeconds | int | `30` |  |
| node-logs-metrics.readinessProbe.periodSeconds | int | `5` |  |
| node-logs-metrics.resources | object | `{"requests":{"cpu":"250m","memory":"256Mi"}}` | --------------------------------------- # Same for each deployment/daemonset      # |
| node-logs-metrics.securityContext.runAsGroup | int | `0` |  |
| node-logs-metrics.securityContext.runAsUser | int | `0` |  |
| node-logs-metrics.serviceAccount.create | bool | `false` |  |
| node-logs-metrics.serviceAccount.name | string | `"observe-agent-service-account"` |  |
| node-logs-metrics.tolerations | list | `[]` |  |
| node.containers.logs.enabled | bool | `true` |  |
| node.containers.logs.exclude | string | `"[\"/var/log/pods/*/*/*.log.*.gz\"]"` |  |
| node.containers.logs.include | string | `"[\"/var/log/pods/*/*/*.log\", \"/var/log/pods/*/*/*.log.*\", \"/var/log/kube-apiserver-audit.log\"]"` |  |
| node.containers.logs.lookbackPeriod | string | `"24h"` |  |
| node.containers.logs.maxLogSize | string | `"512kb"` |  |
| node.containers.logs.retryOnFailure.enabled | bool | `true` |  |
| node.containers.logs.retryOnFailure.initialInterval | string | `"1s"` |  |
| node.containers.logs.retryOnFailure.maxElapsedTime | string | `"5m"` |  |
| node.containers.logs.retryOnFailure.maxInterval | string | `"30s"` |  |
| node.containers.logs.startAt | string | `"end"` |  |
| node.containers.metrics.enabled | bool | `true` |  |
| node.containers.metrics.interval | string | `"60s"` |  |
| node.enabled | bool | `true` |  |
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
