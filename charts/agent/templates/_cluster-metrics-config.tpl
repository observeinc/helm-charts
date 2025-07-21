{{- define "observe.deployment.clusterMetrics.config" -}}

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

{{- if and (eq .Values.application.prometheusScrape.enabled true) (eq .Values.application.prometheusScrape.independentDeployment false) }}
{{- include "config.receivers.prometheus.pod_metrics" . | nindent 2 }}
{{- end }}

processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" (merge . (dict "target" "cluster_metrics")) | nindent 2 }}
{{- include "config.processors.attributes.drop_container_info" . | nindent 2 }}
{{- include "config.processors.attributes.drop_service_name" . | nindent 2 }}

{{- include "config.processors.resource.observe_common" . | nindent 2 }}

{{- if and (eq .Values.application.prometheusScrape.enabled true) (eq .Values.application.prometheusScrape.independentDeployment false) }}
{{- include "config.processors.attributes.pod_metrics" . | nindent 2 }}
{{- end }}

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
  pipelines:
      metrics:
        receivers: [k8s_cluster]
        processors: [memory_limiter, k8sattributes, batch, resource/observe_common, resource/drop_container_info, attributes/debug_source_cluster_metrics]
        exporters: [{{ join ", " $metricsExporters }}]
{{- if and (eq .Values.application.prometheusScrape.enabled true) (eq .Values.application.prometheusScrape.independentDeployment false) }}
      metrics/pod_metrics:
        receivers: [prometheus/pod_metrics]
        # Drop the service.name resource attribute (which is set to the prom scrape job name) before the k8sattributes processor
        processors: [memory_limiter, resource/drop_service_name, k8sattributes, batch, resource/observe_common, attributes/debug_source_pod_metrics]
        exporters: [{{ join ", " $metricsExporters }}]
{{- end }}
{{- include "config.service.telemetry" . | nindent 2 }}

 {{- end }}
