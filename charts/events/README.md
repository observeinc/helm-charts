# events

> **:exclamation: This Helm Chart is deprecated!**

![Version: 0.4.0](https://img.shields.io/badge/Version-0.4.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.11.1](https://img.shields.io/badge/AppVersion-v0.11.1-informational?style=flat-square)

DEPRECATED Observe kubernetes event collection

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../endpoint | endpoint | 0.2.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"observeinc.com/unschedulable"` |  |
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"DoesNotExist"` |  |
| containerOverrides.excludeTargets | list | `[]` |  |
| containerOverrides.includeTargets | list | `[]` |  |
| customLabels | object | `{}` |  |
| global.observe | object | `{}` |  |
| image.kube_cluster_info.pullPolicy | string | `"Always"` |  |
| image.kube_cluster_info.repository | string | `"observeinc/kube-cluster-info"` |  |
| image.kube_cluster_info.tag | string | `""` |  |
| image.kube_state_events.pullPolicy | string | `"Always"` |  |
| image.kube_state_events.repository | string | `"observeinc/kube-state-events"` |  |
| image.kube_state_events.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| rbac.create | bool | `true` |  |
| resources.limits.cpu | string | `"50m"` |  |
| resources.limits.memory | string | `"256Mi"` |  |
| resources.requests.cpu | string | `"50m"` |  |
| resources.requests.memory | string | `"256Mi"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `nil` |  |
| tolerations | object | `{}` |  |
