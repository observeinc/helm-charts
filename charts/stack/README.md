# stack

![Version: 1.0.5](https://img.shields.io/badge/Version-1.0.5-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Observe Kubernetes agent stack

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Observe | <support@observeinc.com> |  |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../events | events | 0.1.26 |
| file://../logs | logs | 0.1.33 |
| file://../metrics | metrics | 0.3.25 |
| file://../proxy | proxy | 0.1.8 |
| file://../traces | traces | 1.0.5 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| events.enabled | bool | `true` |  |
| logs.enabled | bool | `true` |  |
| metrics.enabled | bool | `true` |  |
| observe.token.create | bool | `true` |  |
| observe.token.value | string | `""` |  |
| proxy.enabled | bool | `false` |  |
| traces.enabled | bool | `false` |  |
