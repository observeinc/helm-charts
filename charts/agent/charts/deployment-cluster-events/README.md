# deployment-cluster-events

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.7.0](https://img.shields.io/badge/AppVersion-0.7.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://open-telemetry.github.io/opentelemetry-helm-charts | deployment-cluster-events(opentelemetry-collector) | 0.97.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| deployment-cluster-events.clusterRole.annotations | object | `{}` |  |
| deployment-cluster-events.clusterRole.clusterRoleBinding.annotations | object | `{}` |  |
| deployment-cluster-events.clusterRole.clusterRoleBinding.name | string | `""` |  |
| deployment-cluster-events.clusterRole.create | bool | `true` |  |
| deployment-cluster-events.clusterRole.name | string | `""` |  |
| deployment-cluster-events.clusterRole.rules[0].apiGroups[0] | string | `""` |  |
| deployment-cluster-events.clusterRole.rules[0].resources[0] | string | `"configmaps"` |  |
| deployment-cluster-events.clusterRole.rules[0].verbs[0] | string | `"create"` |  |
| deployment-cluster-events.clusterRole.rules[0].verbs[1] | string | `"get"` |  |
| deployment-cluster-events.clusterRole.rules[1].apiGroups[0] | string | `""` |  |
| deployment-cluster-events.clusterRole.rules[1].apiGroups[10] | string | `"vpcresources.k8s.aws"` |  |
| deployment-cluster-events.clusterRole.rules[1].apiGroups[1] | string | `"*"` |  |
| deployment-cluster-events.clusterRole.rules[1].apiGroups[2] | string | `"apps"` |  |
| deployment-cluster-events.clusterRole.rules[1].apiGroups[3] | string | `"authorization.k8s.io"` |  |
| deployment-cluster-events.clusterRole.rules[1].apiGroups[4] | string | `"autoscaling"` |  |
| deployment-cluster-events.clusterRole.rules[1].apiGroups[5] | string | `"batch"` |  |
| deployment-cluster-events.clusterRole.rules[1].apiGroups[6] | string | `"networking.k8s.io"` |  |
| deployment-cluster-events.clusterRole.rules[1].apiGroups[7] | string | `"events.k8s.io"` |  |
| deployment-cluster-events.clusterRole.rules[1].apiGroups[8] | string | `"rbac.authorization.k8s.io"` |  |
| deployment-cluster-events.clusterRole.rules[1].apiGroups[9] | string | `"storage.k8s.io"` |  |
| deployment-cluster-events.clusterRole.rules[1].resources[0] | string | `"*"` |  |
| deployment-cluster-events.clusterRole.rules[1].verbs[0] | string | `"get"` |  |
| deployment-cluster-events.clusterRole.rules[1].verbs[1] | string | `"list"` |  |
| deployment-cluster-events.clusterRole.rules[1].verbs[2] | string | `"watch"` |  |
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
| deployment-cluster-events.image.tag | string | `"0.9.0"` |  |
| deployment-cluster-events.initContainers[0].env[0].name | string | `"NAMESPACE"` |  |
| deployment-cluster-events.initContainers[0].env[0].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| deployment-cluster-events.initContainers[0].image | string | `"observeinc/kube-cluster-info:v0.11.1"` |  |
| deployment-cluster-events.initContainers[0].imagePullPolicy | string | `"Always"` |  |
| deployment-cluster-events.initContainers[0].name | string | `"kube-cluster-info"` |  |
| deployment-cluster-events.livenessProbe.httpGet.path | string | `"/status"` |  |
| deployment-cluster-events.livenessProbe.httpGet.port | int | `13133` |  |
| deployment-cluster-events.livenessProbe.initialDelaySeconds | int | `10` |  |
| deployment-cluster-events.livenessProbe.periodSeconds | int | `5` |  |
| deployment-cluster-events.mode | string | `"deployment"` |  |
| deployment-cluster-events.nameOverride | string | `"deployment-cluster-events"` |  |
| deployment-cluster-events.namespaceOverride | string | `"k8sexplorer"` |  |
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
| deployment-cluster-events.readinessProbe.initialDelaySeconds | int | `10` |  |
| deployment-cluster-events.readinessProbe.periodSeconds | int | `5` |  |
| deployment-cluster-events.resources.requests.cpu | string | `"250m"` |  |
| deployment-cluster-events.resources.requests.memory | string | `"256Mi"` |  |
| deployment-cluster-events.serviceAccount.create | bool | `false` |  |
| deployment-cluster-events.serviceAccount.name | string | `"observe-agent-service-account"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
