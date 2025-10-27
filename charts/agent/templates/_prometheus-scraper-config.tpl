{{- define "observe.deployment.prometheusScraper.config" -}}

exporters:
{{- if eq .Values.application.prometheusScrape.enabled true }}
  {{- include "config.exporters.debug" . | nindent 2 }}
  {{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}
{{- else }}
  nop:
{{- end }}

{{- if .Values.agent.config.global.fleet.heartbeat.enabled }}
{{- include "config.exporters.otlphttp.observe.metrics.agentheartbeat" . | nindent 2 }}
{{- end }}

receivers:
{{- if eq .Values.application.prometheusScrape.enabled true }}
  {{- include "config.receivers.prometheus.pod_metrics" . | nindent 2 }}
  {{- include "config.receivers.prometheus.cadvisor" . | nindent 2 }}
{{- else }}
  nop:
{{- end }}

{{- if .Values.agent.config.global.fleet.heartbeat.enabled }}
{{- include "config.receivers.observe.heartbeat" . | nindent 2 }}
{{- end }}

processors:
{{- if eq .Values.application.prometheusScrape.enabled true }}
  {{- include "config.processors.memory_limiter" . | nindent 2 }}
  {{- include "config.processors.batch" . | nindent 2 }}
  {{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}
  {{- include "config.processors.resource.observe_common" . | nindent 2 }}
  {{- include "config.processors.attributes.pod_metrics" . | nindent 2 }}
  {{- include "config.processors.attributes.cadvisor_metrics" . | nindent 2 }}
  {{- include "config.processors.attributes.drop_service_name" . | nindent 2 }}
{{- else if .Values.agent.config.global.fleet.heartbeat.enabled }}
  # k8sattributes is needed for the heartbeat pipeline even when prometheusScrape is disabled
  {{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}
{{- end }}

{{- if .Values.agent.config.global.fleet.heartbeat.enabled }}
{{- include "config.processors.resource_detection" . | nindent 2 }}
{{- include "config.processors.resource.agent_instance" . | nindent 2 }}
{{- include "config.processors.resource.heartbeat" . | nindent 2 }}
{{- include "config.processors.transform.k8sheartbeat" . | nindent 2 }}
{{- end }}

service:
  pipelines:
    {{- if eq .Values.application.prometheusScrape.enabled true }}
    {{- include "config.pipelines.prometheus_scrapers" . | nindent 4 }}
    {{- else }}
    metrics/pod_metrics:
      receivers: [nop]
      exporters: [nop]
    {{- end }}

    {{- if .Values.agent.config.global.fleet.heartbeat.enabled }}
    {{- include "config.pipelines.heartbeat" . | nindent 4 }}
    {{- end }}
{{- end }}
