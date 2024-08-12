{{- define "observe.deployment.clusterMetrics.config" -}}

extensions:
{{- include "config.extensions.health_check" . | nindent 2 }}

exporters:
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}

receivers:
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/k8sclusterreceiver/documentation.md
  k8s_cluster:
    auth_type: serviceAccount
    node_conditions_to_report:
    - Ready
    - MemoryPressure
    - DiskPressure
    metrics:
      k8s.node.condition:
        enabled: true

processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.resource_detection.cloud" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}

{{- include "config.processors.attributes.observe_common" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes.podcontroller" . | nindent 2 }}

  # attributes to append to objects
  attributes/observe_cluster_metrics:
    actions:
      - key: observe_filter
        action: insert
        value: cluster_metrics

service:
  extensions: [health_check]
  pipelines:
      metrics:
        receivers: [k8s_cluster]
        processors: [memory_limiter, batch, resourcedetection/cloud, k8sattributes, attributes/observe_common, attributes/observe_cluster_metrics]
        exporters: [prometheusremotewrite]
{{- include "config.service.telemetry" . | nindent 2 }}

 {{- end }}
