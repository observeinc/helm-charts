# stack

> **:exclamation: This Helm Chart is deprecated!**

![Version: 1.3.0](https://img.shields.io/badge/Version-1.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

DEPRECATED Observe Kubernetes agent stack

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../events | events | 0.4.0 |
| file://../logs | logs | 0.2.0 |
| file://../metrics | metrics | 0.4.0 |
| file://../proxy | proxy | 0.1.8 |
| file://../traces | traces | 1.1.0 |

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
