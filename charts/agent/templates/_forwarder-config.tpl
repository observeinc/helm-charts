{{- define "observe.daemonset.forwarder.config" -}}

extensions:
{{- include "config.extensions.health_check" . | nindent 2 }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe.base" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe.trace" . | nindent 2 }}
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}

receivers:
  otlp/app-telemetry:
    protocols:
      grpc:
        endpoint: ${env:MY_POD_IP}:4317
      http:
        endpoint: ${env:MY_POD_IP}:4318
processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.resource_detection.cloud" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}

{{- include "config.processors.deltatocumulative" . | nindent 2 }}

{{- include "config.processors.resource.observe_common" . | nindent 2 }}
  # attributes to append to objects
  attributes/debug_source_app_traces:
    actions:
    - action: insert
      key: debug_source
      value: app_traces
  attributes/debug_source_app_logs:
    actions:
    - action: insert
      key: debug_source
      value: app_logs
  attributes/debug_source_app_metrics:
    actions:
    - action: insert
      key: debug_source
      value: app_metrics

{{- $traceExporters := (list "otlphttp/observe/forward/trace") -}}
{{- $logsExporters := (list "otlphttp/observe/base") -}}
{{- $metricsExporters := (list "prometheusremotewrite/observe") -}}

{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $traceExporters = concat $traceExporters ( list "debug/override" ) | uniq }}
  {{- $logsExporters = concat $logsExporters ( list "debug/override" ) | uniq }}
  {{- $metricsExporters = concat $metricsExporters ( list "debug/override" ) | uniq }}
{{- end }}

service:
  extensions: [health_check]
  pipelines:
    traces/observe-forward:
      receivers: [otlp/app-telemetry]
      processors: [memory_limiter, k8sattributes, batch, resourcedetection/cloud, resource/observe_common, attributes/debug_source_app_traces]
      exporters: [{{ join ", " $traceExporters }}]
    logs/observe-forward:
      receivers: [otlp/app-telemetry]
      processors: [memory_limiter, k8sattributes, batch, resourcedetection/cloud, resource/observe_common, attributes/debug_source_app_logs]
      exporters: [{{ join ", " $logsExporters }}]
    metrics/observe-forward:
      receivers: [otlp/app-telemetry]
      processors: [memory_limiter, k8sattributes, deltatocumulative/observe, batch, resourcedetection/cloud, resource/observe_common, attributes/debug_source_app_metrics]
      exporters: [{{ join ", " $metricsExporters }}]

{{- include "config.service.telemetry" . | nindent 2 }}

{{- end }}
