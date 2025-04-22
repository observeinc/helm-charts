{{- define "observe.deployment.clusterMetrics.config" -}}

extensions:
{{- include "config.extensions.health_check" . | nindent 2 }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}

receivers:
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/k8sclusterreceiver/documentation.md
  k8s_cluster:
    collection_interval: {{.Values.cluster.metrics.interval}}
    metadata_collection_interval: 5m
    auth_type: serviceAccount
    node_conditions_to_report:
    - Ready
    - MemoryPressure
    - DiskPressure
    allocatable_types_to_report:
    - cpu
    - memory
    - storage
    - ephemeral-storage
    # defaults and optional - https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/k8sclusterreceiver/documentation.md
    metrics:
      k8s.node.condition:
        enabled: true

processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}

{{- include "config.processors.resource.observe_common" . | nindent 2 }}

  # attributes to append to objects
  attributes/debug_source_cluster_metrics:
    actions:
      - key: debug_source
        action: insert
        value: cluster_metrics

{{- $metricsExporters := (list "prometheusremotewrite/observe") -}}

{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $metricsExporters = concat $metricsExporters ( list "debug/override" ) | uniq }}
{{- end }}

service:
  extensions: [health_check]
  pipelines:
      metrics:
        receivers: [k8s_cluster]
        processors: [memory_limiter, k8sattributes, batch, resource/observe_common, attributes/debug_source_cluster_metrics]
        exporters: [{{ join ", " $metricsExporters }}]
{{- include "config.service.telemetry" . | nindent 2 }}

 {{- end }}
