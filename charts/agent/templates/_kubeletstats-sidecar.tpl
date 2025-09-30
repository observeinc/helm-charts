{{- define "observe.sidecar.fargateSidecarMetrics.config" -}}

receivers:
  kubeletstats:
    collection_interval: {{.Values.node.containers.metrics.interval}}
    auth_type: 'serviceAccount'
    endpoint: https://kubernetes.default.svc/api/v1/nodes/${env:K8S_NODE_NAME}/proxy
    node: '${env:K8S_NODE_NAME}'
    insecure_skip_verify: true
    k8s_api_config:
        auth_type: serviceAccount
    metric_groups:
      - node
      - pod
      - container
    metrics:
      # The following metrics are optional and must be enabled manually as per:
      # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/kubeletstatsreceiver/documentation.md#optional-metrics
      container.cpu.usage:
        enabled: true
      container.uptime:
        enabled: true
      k8s.container.cpu.node.utilization:
        enabled: true
      k8s.container.cpu_limit_utilization:
        enabled: true
      k8s.container.cpu_request_utilization:
        enabled: true
      k8s.container.memory.node.utilization:
        enabled: true
      k8s.container.memory_limit_utilization:
        enabled: true
      k8s.container.memory_request_utilization:
        enabled: true
      k8s.node.cpu.usage:
        enabled: true
      k8s.node.uptime:
        enabled: true
      k8s.pod.cpu.node.utilization:
        enabled: true
      k8s.pod.cpu.usage:
        enabled: true
      k8s.pod.cpu_limit_utilization:
        enabled: true
      k8s.pod.cpu_request_utilization:
        enabled: true
      k8s.pod.memory.node.utilization:
        enabled: true
      k8s.pod.memory_limit_utilization:
        enabled: true
      k8s.pod.memory_request_utilization:
        enabled: true
      k8s.pod.uptime:
        enabled: true
    extra_metadata_labels:
      - container.id

processors:

{{- include "config.processors.memory_limiter" . | nindent 2 }}
{{- include "config.processors.batch" . | nindent 2 }}
{{- include "config.processors.resource_detection.cloud" . | nindent 2 }}
{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}
{{- include "config.processors.resource.observe_common" . | nindent 2 }}
{{- include "config.processors.deltatocumulative" . | nindent 2 }}
{{- include "config.processors.attributes.add_empty_service_attributes" . | nindent 2 }}
{{- include "config.processors.metricstransform.duplicate_k8s_cpu_metrics" . | nindent 2 }}
{{- include "config.processors.attributes.sidecar_kubeletstats_metrics" . | nindent 2 }}

exporters:
  debug:
    verbosity: detailed
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}

{{ $kubeletstatsExporters := (list "debug" "prometheusremotewrite/observe") -}}

service:
  pipelines:
    {{- if .Values.node.containers.metrics.enabled }}
      metrics/kubeletstats:
        receivers: [kubeletstats]
        processors: [memory_limiter, metricstransform/duplicate_k8s_cpu_metrics, k8sattributes, deltatocumulative/observe, batch, resourcedetection/cloud, resource/observe_common, attributes/debug_source_sidecar_kubeletstats_metrics]
        exporters: [{{ join ", " $kubeletstatsExporters }}]
    {{- else }}
      {{- fail "node.containers.metrics.enabled must be true for Fargate sidecar - otherwise no telemetry will be collected" }}
    {{- end }}
{{- end }}
