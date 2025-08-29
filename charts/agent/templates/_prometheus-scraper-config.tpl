{{- define "observe.deployment.prometheusScraper.config" -}}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}
{{- include "config.exporters.nop" . | nindent 2 }}

receivers:
  nop:
{{- include "config.receivers.prometheus.pod_metrics" . | nindent 2 }}
{{- include "config.receivers.prometheus.cadvisor" . | nindent 2 }}

processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}

{{- include "config.processors.resource.observe_common" . | nindent 2 }}

{{- include "config.processors.attributes.pod_metrics" . | nindent 2 }}

{{- include "config.processors.attributes.drop_service_name" . | nindent 2 }}

  attributes/debug_source_cadvisor_metrics:
    actions:
      - key: debug_source
        action: insert
        value: cadvisor_metrics

# Set up receivers
{{- $podMetricsReceivers := (list "prometheus/pod_metrics") -}}
{{- if eq .Values.application.prometheusScrape.enabled false}}
  {{- $podMetricsReceivers = ( list "nop" ) }}
{{- end }}

# Set up exporters
{{- $podMetricsExporters := (list "prometheusremotewrite/observe") -}}
{{- if eq .Values.application.prometheusScrape.enabled false}}
  {{- $podMetricsExporters = ( list "nop" ) }}
{{- end }}
{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $podMetricsExporters = concat $podMetricsExporters ( list "debug/override" ) | uniq }}
{{- end }}

service:
  pipelines:
    metrics/pod_metrics:
      receivers: [{{ join ", " $podMetricsReceivers }}]
      # Drop the service.name resource attribute (which is set to the prom scrape job name) before the k8sattributes processor
      processors: [memory_limiter, resource/drop_service_name, k8sattributes, batch, resource/observe_common, attributes/debug_source_pod_metrics]
      exporters: [{{ join ", " $podMetricsExporters }}]
    {{- if .Values.node.metrics.cadvisor.enabled }}
    metrics/cadvisor:
      receivers: [prometheus/cadvisor]
      processors: [memory_limiter, k8sattributes, batch, resource/observe_common, attributes/debug_source_cadvisor_metrics]
      exporters: [{{ join ", " $podMetricsExporters }}]
    {{- end -}}

{{- end }}
