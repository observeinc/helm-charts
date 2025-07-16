{{- define "observe.deployment.gateway.config" -}}

{{- if .Values.application.REDMetrics.enabled }}
connectors:
{{- include "config.connectors.spanmetrics" . | nindent 2 }}
{{- end }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe.trace" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe.metrics.otel" . | nindent 2 }}

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

  attributes/debug_source_gateway:
    actions:
    - action: upsert
      key: debug_source
      value: gateway

{{- if .Values.observeGateway.traceSampling.enabled }}
  tail_sampling/observe:
{{ toYaml .Values.observeGateway.traceSampling.config | nindent 4 }}
{{- end }}

{{- $traceExporters := (list "otlphttp/observe/forward/trace") -}}

{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $traceExporters = concat $traceExporters ( list "debug/override" ) | uniq }}
{{- end }}

service:
  pipelines:
    traces/observe-forward:
      receivers: [otlp/app-telemetry]
      processors:
        - memory_limiter
        - k8sattributes
        - transform/add_span_status_code
        - resource/add_empty_service_attributes
        - attributes/debug_source_gateway
       {{- if .Values.observeGateway.traceSampling.enabled }}
        - tail_sampling/observe
        {{- end }}
        - batch
        - resource/observe_common
      exporters: [{{ join ", " $traceExporters }}]
    {{- if .Values.application.REDMetrics.enabled }}
    {{- include "config.pipelines.RED_metrics" . | nindent 4 }}
    {{- end }}

{{- include "config.service.telemetry" . | nindent 2 }}

{{- end }}
