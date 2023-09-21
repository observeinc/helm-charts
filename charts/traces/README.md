# traces

![Version: 0.1.13](https://img.shields.io/badge/Version-0.1.13-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Observe OpenTelemetry trace collection

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Observe | <support@observeinc.com> |  |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../endpoint | endpoint | 0.1.5 |
| file://../proxy | proxy | 0.1.2 |
| https://open-telemetry.github.io/opentelemetry-helm-charts | opentelemetry-collector | 0.61.2 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| observe.token.create | bool | `true` |  |
| observe.token.value | string | `""` |  |
| opentelemetry-collector.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"observeinc.com/unschedulable"` |  |
| opentelemetry-collector.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"DoesNotExist"` |  |
| opentelemetry-collector.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key | string | `"kubernetes.io/os"` |  |
| opentelemetry-collector.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator | string | `"NotIn"` |  |
| opentelemetry-collector.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0] | string | `"windows"` |  |
| opentelemetry-collector.clusterRole.create | bool | `true` |  |
| opentelemetry-collector.clusterRole.rules[0].apiGroups[0] | string | `""` |  |
| opentelemetry-collector.clusterRole.rules[0].resources[0] | string | `"pods"` |  |
| opentelemetry-collector.clusterRole.rules[0].verbs[0] | string | `"get"` |  |
| opentelemetry-collector.clusterRole.rules[0].verbs[1] | string | `"list"` |  |
| opentelemetry-collector.clusterRole.rules[0].verbs[2] | string | `"watch"` |  |
| opentelemetry-collector.command.extraArgs[0] | string | `"--set=service.telemetry.metrics.address=:58888"` |  |
| opentelemetry-collector.config.exporters.logging.loglevel | string | `"info"` |  |
| opentelemetry-collector.config.exporters.otlphttp.endpoint | string | `"{{ include \"observe.collectionEndpoint\" . }}/v1/otel"` |  |
| opentelemetry-collector.config.exporters.otlphttp.headers.authorization | string | `"Bearer ${OBSERVE_TOKEN}"` |  |
| opentelemetry-collector.config.exporters.otlphttp.retry_on_failure.enabled | bool | `true` |  |
| opentelemetry-collector.config.exporters.otlphttp.sending_queue.num_consumers | int | `4` |  |
| opentelemetry-collector.config.exporters.otlphttp.sending_queue.queue_size | int | `100` |  |
| opentelemetry-collector.config.exporters.prometheusremotewrite.endpoint | string | `"{{ include \"observe.collectionEndpoint\" . }}/v1/prometheus"` |  |
| opentelemetry-collector.config.exporters.prometheusremotewrite.headers.authorization | string | `"Bearer ${OBSERVE_TOKEN}"` |  |
| opentelemetry-collector.config.extensions.health_check | object | `{}` |  |
| opentelemetry-collector.config.extensions.zpages | object | `{}` |  |
| opentelemetry-collector.config.processors.batch | string | `nil` |  |
| opentelemetry-collector.config.processors.k8sattributes.extract.metadata[0] | string | `"k8s.pod.name"` |  |
| opentelemetry-collector.config.processors.k8sattributes.extract.metadata[1] | string | `"k8s.namespace.name"` |  |
| opentelemetry-collector.config.processors.k8sattributes.passthrough | bool | `false` |  |
| opentelemetry-collector.config.processors.k8sattributes.pod_association[0].from | string | `"resource_attribute"` |  |
| opentelemetry-collector.config.processors.k8sattributes.pod_association[0].name | string | `"k8s.pod.ip"` |  |
| opentelemetry-collector.config.processors.k8sattributes.pod_association[1].from | string | `"connection"` |  |
| opentelemetry-collector.config.processors.memory_limiter.check_interval | string | `"5s"` |  |
| opentelemetry-collector.config.processors.memory_limiter.limit_mib | int | `192` |  |
| opentelemetry-collector.config.processors.memory_limiter.spike_limit_mib | int | `100` |  |
| opentelemetry-collector.config.processors.probabilistic_sampler.hash_seed | int | `22` |  |
| opentelemetry-collector.config.processors.probabilistic_sampler.sampling_percentage | int | `100` |  |
| opentelemetry-collector.config.processors.resource.attributes[0].action | string | `"insert"` |  |
| opentelemetry-collector.config.processors.resource.attributes[0].key | string | `"k8s.cluster.uid"` |  |
| opentelemetry-collector.config.processors.resource.attributes[0].value | string | `"${OBSERVE_CLUSTER}"` |  |
| opentelemetry-collector.config.receivers.otlp.protocols.grpc | string | `nil` |  |
| opentelemetry-collector.config.receivers.otlp.protocols.http | string | `nil` |  |
| opentelemetry-collector.config.receivers.zipkin | string | `nil` |  |
| opentelemetry-collector.config.service.pipelines.metrics.exporters[0] | string | `"prometheusremotewrite"` |  |
| opentelemetry-collector.config.service.pipelines.metrics.exporters[1] | string | `"logging"` |  |
| opentelemetry-collector.config.service.pipelines.metrics.processors[0] | string | `"resource"` |  |
| opentelemetry-collector.config.service.pipelines.metrics.processors[1] | string | `"k8sattributes"` |  |
| opentelemetry-collector.config.service.pipelines.metrics.processors[2] | string | `"memory_limiter"` |  |
| opentelemetry-collector.config.service.pipelines.metrics.processors[3] | string | `"batch"` |  |
| opentelemetry-collector.config.service.pipelines.metrics.receivers[0] | string | `"otlp"` |  |
| opentelemetry-collector.config.service.pipelines.traces.exporters[0] | string | `"otlphttp"` |  |
| opentelemetry-collector.config.service.pipelines.traces.exporters[1] | string | `"logging"` |  |
| opentelemetry-collector.config.service.pipelines.traces.processors[0] | string | `"resource"` |  |
| opentelemetry-collector.config.service.pipelines.traces.processors[1] | string | `"probabilistic_sampler"` |  |
| opentelemetry-collector.config.service.pipelines.traces.processors[2] | string | `"k8sattributes"` |  |
| opentelemetry-collector.config.service.pipelines.traces.processors[3] | string | `"memory_limiter"` |  |
| opentelemetry-collector.config.service.pipelines.traces.processors[4] | string | `"batch"` |  |
| opentelemetry-collector.config.service.pipelines.traces.receivers[0] | string | `"otlp"` |  |
| opentelemetry-collector.config.service.pipelines.traces.receivers[1] | string | `"zipkin"` |  |
| opentelemetry-collector.extraEnvs[0].name | string | `"NODE_NAME"` |  |
| opentelemetry-collector.extraEnvs[0].valueFrom.fieldRef.fieldPath | string | `"spec.nodeName"` |  |
| opentelemetry-collector.extraEnvs[1].name | string | `"OBSERVE_CLUSTER"` |  |
| opentelemetry-collector.extraEnvs[1].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| opentelemetry-collector.extraEnvs[1].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| opentelemetry-collector.extraEnvs[2].name | string | `"OBSERVE_TOKEN"` |  |
| opentelemetry-collector.extraEnvs[2].valueFrom.secretKeyRef.key | string | `"OBSERVE_TOKEN"` |  |
| opentelemetry-collector.extraEnvs[2].valueFrom.secretKeyRef.name | string | `"otel-credentials"` |  |
| opentelemetry-collector.image.tag | string | `"0.62.1"` |  |
| opentelemetry-collector.livenessProbe.initialDelaySeconds | int | `5` |  |
| opentelemetry-collector.mode | string | `"daemonset"` |  |
| opentelemetry-collector.nameOverride | string | `"traces"` |  |
| opentelemetry-collector.ports.jaeger-compact.enabled | bool | `false` |  |
| opentelemetry-collector.ports.jaeger-grpc.enabled | bool | `false` |  |
| opentelemetry-collector.ports.jaeger-thrift.enabled | bool | `false` |  |
| opentelemetry-collector.ports.metrics.containerPort | int | `58888` |  |
| opentelemetry-collector.ports.metrics.enabled | bool | `true` |  |
| opentelemetry-collector.ports.metrics.hostPort | int | `0` |  |
| opentelemetry-collector.ports.metrics.protocol | string | `"TCP"` |  |
| opentelemetry-collector.ports.metrics.servicePort | int | `58888` |  |
| opentelemetry-collector.ports.otlp-http.containerPort | int | `4318` |  |
| opentelemetry-collector.ports.otlp-http.enabled | bool | `true` |  |
| opentelemetry-collector.ports.otlp-http.hostPort | int | `0` |  |
| opentelemetry-collector.ports.otlp-http.protocol | string | `"TCP"` |  |
| opentelemetry-collector.ports.otlp-http.servicePort | int | `4318` |  |
| opentelemetry-collector.ports.otlp.containerPort | int | `4317` |  |
| opentelemetry-collector.ports.otlp.enabled | bool | `true` |  |
| opentelemetry-collector.ports.otlp.hostPort | int | `0` |  |
| opentelemetry-collector.ports.otlp.protocol | string | `"TCP"` |  |
| opentelemetry-collector.ports.otlp.servicePort | int | `4317` |  |
| opentelemetry-collector.ports.zipkin.containerPort | int | `9411` |  |
| opentelemetry-collector.ports.zipkin.enabled | bool | `true` |  |
| opentelemetry-collector.ports.zipkin.hostPort | int | `0` |  |
| opentelemetry-collector.ports.zipkin.protocol | string | `"TCP"` |  |
| opentelemetry-collector.ports.zipkin.servicePort | int | `9411` |  |
| opentelemetry-collector.ports.zpages.containerPort | int | `55679` |  |
| opentelemetry-collector.ports.zpages.enabled | bool | `true` |  |
| opentelemetry-collector.ports.zpages.hostPort | int | `0` |  |
| opentelemetry-collector.ports.zpages.protocol | string | `"TCP"` |  |
| opentelemetry-collector.ports.zpages.servicePort | int | `55679` |  |
| opentelemetry-collector.readinessProbe.initialDelaySeconds | int | `10` |  |
| opentelemetry-collector.replicaCount | int | `10` |  |
| opentelemetry-collector.resources.limits.cpu | string | `"250m"` |  |
| opentelemetry-collector.resources.limits.memory | string | `"256Mi"` |  |
| opentelemetry-collector.resources.requests.cpu | string | `"250m"` |  |
| opentelemetry-collector.resources.requests.memory | string | `"256Mi"` |  |
| opentelemetry-collector.service.enabled | bool | `true` |  |
| proxy.enabled | bool | `false` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.2](https://github.com/norwoodj/helm-docs/releases/v1.11.2)
