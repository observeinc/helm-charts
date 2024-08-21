# agent

![Version: 0.6.0](https://img.shields.io/badge/Version-0.6.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

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
| https://open-telemetry.github.io/opentelemetry-helm-charts | deployment-cluster-events(opentelemetry-collector) | 0.101.1 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | deployment-cluster-metrics(opentelemetry-collector) | 0.101.1 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | daemonset-logs-metrics(opentelemetry-collector) | 0.101.1 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | deployment-agent-monitor(opentelemetry-collector) | 0.101.1 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cluster.events.pullInterval | string | `"20m"` |  |
| cluster.name | string | `"observe-agent-monitored-cluster"` |  |
| config.global.debug.verbosity | string | `"basic"` |  |
| config.global.processors.batch.send_batch_max_size | int | `100` |  |
| config.global.processors.batch.send_batch_size | int | `100` |  |
| config.global.service.telemetry.logging_level | string | `"WARN"` |  |
| config.global.service.telemetry.metrics_level | string | `"normal"` |  |
| daemonset-logs-metrics.clusterRole.create | bool | `false` |  |
| daemonset-logs-metrics.clusterRole.name | string | `"observe-agent-cluster-role"` |  |
| daemonset-logs-metrics.command.extraArgs[0] | string | `"start"` |  |
| daemonset-logs-metrics.command.extraArgs[1] | string | `"--config=/observe-agent-conf/observe-agent.yaml"` |  |
| daemonset-logs-metrics.command.extraArgs[2] | string | `"--otel-config=/conf/relay.yaml"` |  |
| daemonset-logs-metrics.command.name | string | `"observe-agent"` |  |
| daemonset-logs-metrics.configMap.create | bool | `false` |  |
| daemonset-logs-metrics.configMap.existingName | string | `"daemonset-logs-metrics"` |  |
| daemonset-logs-metrics.extraEnvsFrom | list | `[]` |  |
| daemonset-logs-metrics.extraEnvs[0].name | string | `"OBSERVE_CLUSTER_NAME"` |  |
| daemonset-logs-metrics.extraEnvs[0].valueFrom.configMapKeyRef.key | string | `"name"` |  |
| daemonset-logs-metrics.extraEnvs[0].valueFrom.configMapKeyRef.name | string | `"cluster-name"` |  |
| daemonset-logs-metrics.extraEnvs[1].name | string | `"OBSERVE_CLUSTER_UID"` |  |
| daemonset-logs-metrics.extraEnvs[1].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| daemonset-logs-metrics.extraEnvs[1].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| daemonset-logs-metrics.extraEnvs[2].name | string | `"K8S_NODE_NAME"` |  |
| daemonset-logs-metrics.extraEnvs[2].valueFrom.fieldRef.fieldPath | string | `"spec.nodeName"` |  |
| daemonset-logs-metrics.extraVolumeMounts[0].mountPath | string | `"/observe-agent-conf"` |  |
| daemonset-logs-metrics.extraVolumeMounts[0].name | string | `"observe-agent-deployment-config"` |  |
| daemonset-logs-metrics.extraVolumeMounts[1].mountPath | string | `"/var/log/pods"` |  |
| daemonset-logs-metrics.extraVolumeMounts[1].name | string | `"varlogpods"` |  |
| daemonset-logs-metrics.extraVolumeMounts[1].readOnly | bool | `true` |  |
| daemonset-logs-metrics.extraVolumeMounts[2].mountPath | string | `"/var/lib/docker/containers"` |  |
| daemonset-logs-metrics.extraVolumeMounts[2].name | string | `"varlibdockercontainers"` |  |
| daemonset-logs-metrics.extraVolumeMounts[2].readOnly | bool | `true` |  |
| daemonset-logs-metrics.extraVolumeMounts[3].mountPath | string | `"/var/lib/otelcol"` |  |
| daemonset-logs-metrics.extraVolumeMounts[3].name | string | `"varlibotelcol"` |  |
| daemonset-logs-metrics.extraVolumeMounts[4].mountPath | string | `"/hostfs"` |  |
| daemonset-logs-metrics.extraVolumeMounts[4].mountPropagation | string | `"HostToContainer"` |  |
| daemonset-logs-metrics.extraVolumeMounts[4].name | string | `"hostfs"` |  |
| daemonset-logs-metrics.extraVolumeMounts[4].readOnly | bool | `true` |  |
| daemonset-logs-metrics.extraVolumes[0].configMap.defaultMode | int | `420` |  |
| daemonset-logs-metrics.extraVolumes[0].configMap.items[0].key | string | `"relay"` |  |
| daemonset-logs-metrics.extraVolumes[0].configMap.items[0].path | string | `"observe-agent.yaml"` |  |
| daemonset-logs-metrics.extraVolumes[0].configMap.name | string | `"observe-agent"` |  |
| daemonset-logs-metrics.extraVolumes[0].name | string | `"observe-agent-deployment-config"` |  |
| daemonset-logs-metrics.extraVolumes[1].hostPath.path | string | `"/var/log/pods"` |  |
| daemonset-logs-metrics.extraVolumes[1].name | string | `"varlogpods"` |  |
| daemonset-logs-metrics.extraVolumes[2].hostPath.path | string | `"/var/lib/docker/containers"` |  |
| daemonset-logs-metrics.extraVolumes[2].name | string | `"varlibdockercontainers"` |  |
| daemonset-logs-metrics.extraVolumes[3].hostPath.path | string | `"/var/lib/otelcol"` |  |
| daemonset-logs-metrics.extraVolumes[3].hostPath.type | string | `"DirectoryOrCreate"` |  |
| daemonset-logs-metrics.extraVolumes[3].name | string | `"varlibotelcol"` |  |
| daemonset-logs-metrics.extraVolumes[4].hostPath.path | string | `"/"` |  |
| daemonset-logs-metrics.extraVolumes[4].name | string | `"hostfs"` |  |
| daemonset-logs-metrics.image.pullPolicy | string | `"IfNotPresent"` |  |
| daemonset-logs-metrics.image.repository | string | `"observeinc/observe-agent"` |  |
| daemonset-logs-metrics.image.tag | string | `"1.0.0"` |  |
| daemonset-logs-metrics.initContainers[0].env[0].name | string | `"NAMESPACE"` |  |
| daemonset-logs-metrics.initContainers[0].env[0].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| daemonset-logs-metrics.initContainers[0].image | string | `"observeinc/kube-cluster-info:v0.11.1"` |  |
| daemonset-logs-metrics.initContainers[0].imagePullPolicy | string | `"Always"` |  |
| daemonset-logs-metrics.initContainers[0].name | string | `"kube-cluster-info"` |  |
| daemonset-logs-metrics.livenessProbe.httpGet.path | string | `"/status"` |  |
| daemonset-logs-metrics.livenessProbe.httpGet.port | int | `13133` |  |
| daemonset-logs-metrics.livenessProbe.initialDelaySeconds | int | `30` |  |
| daemonset-logs-metrics.livenessProbe.periodSeconds | int | `5` |  |
| daemonset-logs-metrics.mode | string | `"daemonset"` |  |
| daemonset-logs-metrics.nameOverride | string | `"daemonset-logs-metrics"` | --------------------------------------- # Different for each deployment/daemonset # |
| daemonset-logs-metrics.namespaceOverride | string | `"observe"` |  |
| daemonset-logs-metrics.networkPolicy.egressRules[0] | object | `{}` |  |
| daemonset-logs-metrics.networkPolicy.enabled | bool | `true` |  |
| daemonset-logs-metrics.podAnnotations.observe_monitor_path | string | `"/metrics"` |  |
| daemonset-logs-metrics.podAnnotations.observe_monitor_port | string | `"8888"` |  |
| daemonset-logs-metrics.podAnnotations.observe_monitor_purpose | string | `"observecollection"` |  |
| daemonset-logs-metrics.podAnnotations.observe_monitor_scrape | string | `"true"` |  |
| daemonset-logs-metrics.ports.metrics.containerPort | int | `8888` |  |
| daemonset-logs-metrics.ports.metrics.enabled | bool | `true` |  |
| daemonset-logs-metrics.ports.metrics.protocol | string | `"TCP"` |  |
| daemonset-logs-metrics.ports.metrics.servicePort | int | `8888` |  |
| daemonset-logs-metrics.readinessProbe.httpGet.path | string | `"/status"` |  |
| daemonset-logs-metrics.readinessProbe.httpGet.port | int | `13133` |  |
| daemonset-logs-metrics.readinessProbe.initialDelaySeconds | int | `30` |  |
| daemonset-logs-metrics.readinessProbe.periodSeconds | int | `5` |  |
| daemonset-logs-metrics.resources | object | `{"requests":{"cpu":"250m","memory":"256Mi"}}` | --------------------------------------- # Same for each deployment/daemonset      # |
| daemonset-logs-metrics.securityContext.runAsGroup | int | `0` |  |
| daemonset-logs-metrics.securityContext.runAsUser | int | `0` |  |
| daemonset-logs-metrics.serviceAccount.create | bool | `false` |  |
| daemonset-logs-metrics.serviceAccount.name | string | `"observe-agent-service-account"` |  |
| deployment-agent-monitor.clusterRole.create | bool | `false` |  |
| deployment-agent-monitor.clusterRole.name | string | `"observe-agent-cluster-role"` |  |
| deployment-agent-monitor.command.extraArgs[0] | string | `"start"` |  |
| deployment-agent-monitor.command.extraArgs[1] | string | `"--config=/observe-agent-conf/observe-agent.yaml"` |  |
| deployment-agent-monitor.command.extraArgs[2] | string | `"--otel-config=/conf/relay.yaml"` |  |
| deployment-agent-monitor.command.name | string | `"observe-agent"` |  |
| deployment-agent-monitor.configMap.create | bool | `false` |  |
| deployment-agent-monitor.configMap.existingName | string | `"deployment-agent-monitor"` |  |
| deployment-agent-monitor.extraEnvsFrom | list | `[]` |  |
| deployment-agent-monitor.extraEnvs[0].name | string | `"OBSERVE_CLUSTER_NAME"` |  |
| deployment-agent-monitor.extraEnvs[0].valueFrom.configMapKeyRef.key | string | `"name"` |  |
| deployment-agent-monitor.extraEnvs[0].valueFrom.configMapKeyRef.name | string | `"cluster-name"` |  |
| deployment-agent-monitor.extraEnvs[1].name | string | `"OBSERVE_CLUSTER_UID"` |  |
| deployment-agent-monitor.extraEnvs[1].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| deployment-agent-monitor.extraEnvs[1].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| deployment-agent-monitor.extraVolumeMounts[0].mountPath | string | `"/observe-agent-conf"` |  |
| deployment-agent-monitor.extraVolumeMounts[0].name | string | `"observe-agent-deployment-config"` |  |
| deployment-agent-monitor.extraVolumes[0].configMap.defaultMode | int | `420` |  |
| deployment-agent-monitor.extraVolumes[0].configMap.items[0].key | string | `"relay"` |  |
| deployment-agent-monitor.extraVolumes[0].configMap.items[0].path | string | `"observe-agent.yaml"` |  |
| deployment-agent-monitor.extraVolumes[0].configMap.name | string | `"observe-agent"` |  |
| deployment-agent-monitor.extraVolumes[0].name | string | `"observe-agent-deployment-config"` |  |
| deployment-agent-monitor.image.pullPolicy | string | `"IfNotPresent"` |  |
| deployment-agent-monitor.image.repository | string | `"observeinc/observe-agent"` |  |
| deployment-agent-monitor.image.tag | string | `"1.0.0"` |  |
| deployment-agent-monitor.initContainers[0].env[0].name | string | `"NAMESPACE"` |  |
| deployment-agent-monitor.initContainers[0].env[0].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| deployment-agent-monitor.initContainers[0].image | string | `"observeinc/kube-cluster-info:v0.11.1"` |  |
| deployment-agent-monitor.initContainers[0].imagePullPolicy | string | `"Always"` |  |
| deployment-agent-monitor.initContainers[0].name | string | `"kube-cluster-info"` |  |
| deployment-agent-monitor.livenessProbe.httpGet.path | string | `"/status"` |  |
| deployment-agent-monitor.livenessProbe.httpGet.port | int | `13133` |  |
| deployment-agent-monitor.livenessProbe.initialDelaySeconds | int | `30` |  |
| deployment-agent-monitor.livenessProbe.periodSeconds | int | `5` |  |
| deployment-agent-monitor.mode | string | `"deployment"` |  |
| deployment-agent-monitor.nameOverride | string | `"deployment-agent-monitor"` | --------------------------------------- # Different for each deployment/daemonset # |
| deployment-agent-monitor.namespaceOverride | string | `"observe"` |  |
| deployment-agent-monitor.networkPolicy.egressRules[0] | object | `{}` |  |
| deployment-agent-monitor.networkPolicy.enabled | bool | `true` |  |
| deployment-agent-monitor.podAnnotations.observe_monitor_path | string | `"/metrics"` |  |
| deployment-agent-monitor.podAnnotations.observe_monitor_port | string | `"8888"` |  |
| deployment-agent-monitor.podAnnotations.observe_monitor_purpose | string | `"observecollection"` |  |
| deployment-agent-monitor.podAnnotations.observe_monitor_scrape | string | `"false"` |  |
| deployment-agent-monitor.ports.metrics.containerPort | int | `8888` |  |
| deployment-agent-monitor.ports.metrics.enabled | bool | `true` |  |
| deployment-agent-monitor.ports.metrics.protocol | string | `"TCP"` |  |
| deployment-agent-monitor.ports.metrics.servicePort | int | `8888` |  |
| deployment-agent-monitor.readinessProbe.httpGet.path | string | `"/status"` |  |
| deployment-agent-monitor.readinessProbe.httpGet.port | int | `13133` |  |
| deployment-agent-monitor.readinessProbe.initialDelaySeconds | int | `30` |  |
| deployment-agent-monitor.readinessProbe.periodSeconds | int | `5` |  |
| deployment-agent-monitor.resources | object | `{"requests":{"cpu":"250m","memory":"256Mi"}}` | --------------------------------------- # Same for each deployment/daemonset      # |
| deployment-agent-monitor.serviceAccount.create | bool | `false` |  |
| deployment-agent-monitor.serviceAccount.name | string | `"observe-agent-service-account"` |  |
| deployment-cluster-events.clusterRole.create | bool | `false` |  |
| deployment-cluster-events.clusterRole.name | string | `"observe-agent-cluster-role"` |  |
| deployment-cluster-events.command.extraArgs[0] | string | `"start"` |  |
| deployment-cluster-events.command.extraArgs[1] | string | `"--config=/observe-agent-conf/observe-agent.yaml"` |  |
| deployment-cluster-events.command.extraArgs[2] | string | `"--otel-config=/conf/relay.yaml"` |  |
| deployment-cluster-events.command.name | string | `"observe-agent"` |  |
| deployment-cluster-events.configMap.create | bool | `false` |  |
| deployment-cluster-events.configMap.existingName | string | `"deployment-cluster-events"` |  |
| deployment-cluster-events.extraEnvsFrom | list | `[]` |  |
| deployment-cluster-events.extraEnvs[0].name | string | `"OBSERVE_CLUSTER_NAME"` |  |
| deployment-cluster-events.extraEnvs[0].valueFrom.configMapKeyRef.key | string | `"name"` |  |
| deployment-cluster-events.extraEnvs[0].valueFrom.configMapKeyRef.name | string | `"cluster-name"` |  |
| deployment-cluster-events.extraEnvs[1].name | string | `"OBSERVE_CLUSTER_UID"` |  |
| deployment-cluster-events.extraEnvs[1].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| deployment-cluster-events.extraEnvs[1].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| deployment-cluster-events.extraVolumeMounts[0].mountPath | string | `"/observe-agent-conf"` |  |
| deployment-cluster-events.extraVolumeMounts[0].name | string | `"observe-agent-deployment-config"` |  |
| deployment-cluster-events.extraVolumes[0].configMap.defaultMode | int | `420` |  |
| deployment-cluster-events.extraVolumes[0].configMap.items[0].key | string | `"relay"` |  |
| deployment-cluster-events.extraVolumes[0].configMap.items[0].path | string | `"observe-agent.yaml"` |  |
| deployment-cluster-events.extraVolumes[0].configMap.name | string | `"observe-agent"` |  |
| deployment-cluster-events.extraVolumes[0].name | string | `"observe-agent-deployment-config"` |  |
| deployment-cluster-events.image.pullPolicy | string | `"IfNotPresent"` |  |
| deployment-cluster-events.image.repository | string | `"observeinc/observe-agent"` |  |
| deployment-cluster-events.image.tag | string | `"1.0.0"` |  |
| deployment-cluster-events.initContainers[0].env[0].name | string | `"NAMESPACE"` |  |
| deployment-cluster-events.initContainers[0].env[0].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| deployment-cluster-events.initContainers[0].image | string | `"observeinc/kube-cluster-info:v0.11.1"` |  |
| deployment-cluster-events.initContainers[0].imagePullPolicy | string | `"Always"` |  |
| deployment-cluster-events.initContainers[0].name | string | `"kube-cluster-info"` |  |
| deployment-cluster-events.livenessProbe.httpGet.path | string | `"/status"` |  |
| deployment-cluster-events.livenessProbe.httpGet.port | int | `13133` |  |
| deployment-cluster-events.livenessProbe.initialDelaySeconds | int | `30` |  |
| deployment-cluster-events.livenessProbe.periodSeconds | int | `5` |  |
| deployment-cluster-events.mode | string | `"deployment"` |  |
| deployment-cluster-events.nameOverride | string | `"deployment-cluster-events"` | --------------------------------------- # Different for each deployment/daemonset # |
| deployment-cluster-events.namespaceOverride | string | `"observe"` |  |
| deployment-cluster-events.networkPolicy.egressRules[0] | object | `{}` |  |
| deployment-cluster-events.networkPolicy.enabled | bool | `true` |  |
| deployment-cluster-events.podAnnotations.observe_monitor_path | string | `"/metrics"` |  |
| deployment-cluster-events.podAnnotations.observe_monitor_port | string | `"8888"` |  |
| deployment-cluster-events.podAnnotations.observe_monitor_purpose | string | `"observecollection"` |  |
| deployment-cluster-events.podAnnotations.observe_monitor_scrape | string | `"true"` |  |
| deployment-cluster-events.ports.metrics.containerPort | int | `8888` |  |
| deployment-cluster-events.ports.metrics.enabled | bool | `true` |  |
| deployment-cluster-events.ports.metrics.protocol | string | `"TCP"` |  |
| deployment-cluster-events.ports.metrics.servicePort | int | `8888` |  |
| deployment-cluster-events.readinessProbe.httpGet.path | string | `"/status"` |  |
| deployment-cluster-events.readinessProbe.httpGet.port | int | `13133` |  |
| deployment-cluster-events.readinessProbe.initialDelaySeconds | int | `30` |  |
| deployment-cluster-events.readinessProbe.periodSeconds | int | `5` |  |
| deployment-cluster-events.resources | object | `{"requests":{"cpu":"250m","memory":"256Mi"}}` | --------------------------------------- # Same for each deployment/daemonset      # |
| deployment-cluster-events.serviceAccount.create | bool | `false` |  |
| deployment-cluster-events.serviceAccount.name | string | `"observe-agent-service-account"` |  |
| deployment-cluster-metrics.clusterRole.create | bool | `false` |  |
| deployment-cluster-metrics.clusterRole.name | string | `"observe-agent-cluster-role"` |  |
| deployment-cluster-metrics.command.extraArgs[0] | string | `"start"` |  |
| deployment-cluster-metrics.command.extraArgs[1] | string | `"--config=/observe-agent-conf/observe-agent.yaml"` |  |
| deployment-cluster-metrics.command.extraArgs[2] | string | `"--otel-config=/conf/relay.yaml"` |  |
| deployment-cluster-metrics.command.name | string | `"observe-agent"` |  |
| deployment-cluster-metrics.configMap.create | bool | `false` |  |
| deployment-cluster-metrics.configMap.existingName | string | `"deployment-cluster-metrics"` |  |
| deployment-cluster-metrics.extraEnvsFrom | list | `[]` |  |
| deployment-cluster-metrics.extraEnvs[0].name | string | `"OBSERVE_CLUSTER_NAME"` |  |
| deployment-cluster-metrics.extraEnvs[0].valueFrom.configMapKeyRef.key | string | `"name"` |  |
| deployment-cluster-metrics.extraEnvs[0].valueFrom.configMapKeyRef.name | string | `"cluster-name"` |  |
| deployment-cluster-metrics.extraEnvs[1].name | string | `"OBSERVE_CLUSTER_UID"` |  |
| deployment-cluster-metrics.extraEnvs[1].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| deployment-cluster-metrics.extraEnvs[1].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| deployment-cluster-metrics.extraVolumeMounts[0].mountPath | string | `"/observe-agent-conf"` |  |
| deployment-cluster-metrics.extraVolumeMounts[0].name | string | `"observe-agent-deployment-config"` |  |
| deployment-cluster-metrics.extraVolumes[0].configMap.defaultMode | int | `420` |  |
| deployment-cluster-metrics.extraVolumes[0].configMap.items[0].key | string | `"relay"` |  |
| deployment-cluster-metrics.extraVolumes[0].configMap.items[0].path | string | `"observe-agent.yaml"` |  |
| deployment-cluster-metrics.extraVolumes[0].configMap.name | string | `"observe-agent"` |  |
| deployment-cluster-metrics.extraVolumes[0].name | string | `"observe-agent-deployment-config"` |  |
| deployment-cluster-metrics.image.pullPolicy | string | `"IfNotPresent"` |  |
| deployment-cluster-metrics.image.repository | string | `"observeinc/observe-agent"` |  |
| deployment-cluster-metrics.image.tag | string | `"1.0.0"` |  |
| deployment-cluster-metrics.initContainers[0].env[0].name | string | `"NAMESPACE"` |  |
| deployment-cluster-metrics.initContainers[0].env[0].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| deployment-cluster-metrics.initContainers[0].image | string | `"observeinc/kube-cluster-info:v0.11.1"` |  |
| deployment-cluster-metrics.initContainers[0].imagePullPolicy | string | `"Always"` |  |
| deployment-cluster-metrics.initContainers[0].name | string | `"kube-cluster-info"` |  |
| deployment-cluster-metrics.livenessProbe.httpGet.path | string | `"/status"` |  |
| deployment-cluster-metrics.livenessProbe.httpGet.port | int | `13133` |  |
| deployment-cluster-metrics.livenessProbe.initialDelaySeconds | int | `30` |  |
| deployment-cluster-metrics.livenessProbe.periodSeconds | int | `5` |  |
| deployment-cluster-metrics.mode | string | `"deployment"` |  |
| deployment-cluster-metrics.nameOverride | string | `"deployment-cluster-metrics"` | --------------------------------------- # Different for each deployment/daemonset # |
| deployment-cluster-metrics.namespaceOverride | string | `"observe"` |  |
| deployment-cluster-metrics.networkPolicy.egressRules[0] | object | `{}` |  |
| deployment-cluster-metrics.networkPolicy.enabled | bool | `true` |  |
| deployment-cluster-metrics.podAnnotations.observe_monitor_path | string | `"/metrics"` |  |
| deployment-cluster-metrics.podAnnotations.observe_monitor_port | string | `"8888"` |  |
| deployment-cluster-metrics.podAnnotations.observe_monitor_purpose | string | `"observecollection"` |  |
| deployment-cluster-metrics.podAnnotations.observe_monitor_scrape | string | `"true"` |  |
| deployment-cluster-metrics.ports.metrics.containerPort | int | `8888` |  |
| deployment-cluster-metrics.ports.metrics.enabled | bool | `true` |  |
| deployment-cluster-metrics.ports.metrics.protocol | string | `"TCP"` |  |
| deployment-cluster-metrics.ports.metrics.servicePort | int | `8888` |  |
| deployment-cluster-metrics.readinessProbe.httpGet.path | string | `"/status"` |  |
| deployment-cluster-metrics.readinessProbe.httpGet.port | int | `13133` |  |
| deployment-cluster-metrics.readinessProbe.initialDelaySeconds | int | `30` |  |
| deployment-cluster-metrics.readinessProbe.periodSeconds | int | `5` |  |
| deployment-cluster-metrics.resources | object | `{"requests":{"cpu":"250m","memory":"256Mi"}}` | --------------------------------------- # Same for each deployment/daemonset      # |
| deployment-cluster-metrics.serviceAccount.create | bool | `false` |  |
| deployment-cluster-metrics.serviceAccount.name | string | `"observe-agent-service-account"` |  |
| namespaceOverride | string | `nil` |  |
| observe.collectionEndpoint | string | `nil` |  |
| observe.entityToken | string | `nil` |  |
| observe.token | string | `nil` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
