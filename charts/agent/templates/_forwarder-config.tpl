{{- define "observe.daemonset.forwarder.config" -}}

{{- if .Values.application.REDMetrics.enabled }}
connectors:
{{- include "config.connectors.spanmetrics" . | nindent 2 }}
{{- end }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe.base" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe.trace" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe.metrics.otel" . | nindent 2 }}
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
{{- include "config.processors.filter.drop_long_spans" . | nindent 2 }}
{{- include "config.processors.transform.add_span_status_code" . | nindent 2 }}
{{- include "config.processors.attributes.add_empty_service_attributes" . | nindent 2 }}

{{- if .Values.application.REDMetrics.enabled }}
{{- include "config.processors.RED_metrics" . | nindent 2 }}
{{- end }}

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
{{- $metricsExporters := (list) -}}

{{ if eq .Values.node.forwarder.metrics.outputFormat "prometheus" -}}
  {{- $metricsExporters = concat $metricsExporters ( list "prometheusremotewrite/observe" ) | uniq }}
{{- else if eq .Values.node.forwarder.metrics.outputFormat "otel" -}}
  {{- $metricsExporters = concat $metricsExporters ( list "otlphttp/observe/otel_metrics" ) | uniq }}
{{- end }}

{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $traceExporters = concat $traceExporters ( list "debug/override" ) | uniq }}
  {{- $logsExporters = concat $logsExporters ( list "debug/override" ) | uniq }}
  {{- $metricsExporters = concat $metricsExporters ( list "debug/override" ) | uniq }}
{{- end }}

{{- $metricsProcessors := (list) -}}

{{ if eq .Values.node.forwarder.metrics.outputFormat "prometheus" -}}
  {{- $metricsProcessors = (list "memory_limiter" "k8sattributes" "deltatocumulative/observe" "batch" "resourcedetection/cloud" "resource/observe_common" "attributes/debug_source_app_metrics") }}
{{- else if eq .Values.node.forwarder.metrics.outputFormat "otel" -}}
  {{- $metricsProcessors = (list "memory_limiter" "k8sattributes" "batch" "resourcedetection/cloud" "resource/observe_common" "attributes/debug_source_app_metrics") }}
{{- else }}
{{- fail "Invalid output format for forwarder metrics, valid values are 'prometheus' and 'otel'." }}
{{- end }}

service:
  pipelines:
    traces/observe-forward:
      receivers: [otlp/app-telemetry]
      processors:
        {{- if ne .Values.node.forwarder.traces.maxSpanDuration "none" }}
        - filter/drop_long_spans
        {{- end }}
        - memory_limiter
        - transform/add_span_status_code
        - resource/add_empty_service_attributes
        - k8sattributes
        - batch
        - resourcedetection/cloud
        - resource/observe_common
        - attributes/debug_source_app_traces
      exporters: [{{ join ", " $traceExporters }}]
    logs/observe-forward:
      receivers: [otlp/app-telemetry]
      processors: [memory_limiter, k8sattributes, batch, resourcedetection/cloud, resource/observe_common, attributes/debug_source_app_logs]
      exporters: [{{ join ", " $logsExporters }}]
    metrics/observe-forward:
      receivers: [otlp/app-telemetry]
      processors:  [{{ join ", " $metricsProcessors }}]
      exporters: [{{ join ", " $metricsExporters }}]
    {{- if .Values.application.REDMetrics.enabled }}
    {{- include "config.pipelines.RED_metrics" . | nindent 4 }}
    {{- end }}

{{- end }}
