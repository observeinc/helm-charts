{{- define "observe.deployment.prometheusScraper.config" -}}

extensions:
{{- include "config.extensions.health_check" . | nindent 2 }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}
{{- include "config.exporters.nop" . | nindent 2 }}

receivers:
  nop:
{{- include "config.receivers.prometheus.pod_metrics" . | nindent 2 }}

processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}

{{- include "config.processors.resource.observe_common" . | nindent 2 }}

{{- include "config.processors.attributes.pod_metrics" . | nindent 2 }}

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
  extensions: [health_check]
  pipelines:
    metrics/pod_metrics:
      receivers: [{{ join ", " $podMetricsReceivers }}]
      processors: [memory_limiter, k8sattributes, batch, resource/observe_common, attributes/debug_source_pod_metrics]
      exporters: [{{ join ", " $podMetricsExporters }}]
{{- include "config.service.telemetry" . | nindent 2 }}

 {{- end }}
