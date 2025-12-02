{{- define "observe.deployment.gateway.config" -}}

{{- if .Values.application.REDMetrics.enabled }}
connectors:
{{- include "config.connectors.spanmetrics" . | nindent 2 }}
{{- end }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe.base" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe.trace" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe.metrics.otel" . | nindent 2 }}

{{- if .Values.agent.config.global.fleet.enabled }}
{{- include "config.exporters.otlphttp.observe.metrics.agentheartbeat" . | nindent 2 }}
{{- end }}

receivers:
  otlp/app-telemetry:
    protocols:
      grpc:
        endpoint: ${env:MY_POD_IP}:4317
      http:
        endpoint: ${env:MY_POD_IP}:4318

{{- if .Values.agent.config.global.fleet.enabled }}
{{- include "config.receivers.observe.heartbeat" . | nindent 2 }}
{{- end }}

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

{{- if .Values.node.forwarder.metrics.convertCumulativeToDelta }}
  {{- if eq .Values.node.forwarder.metrics.outputFormat "prometheus" }}
    {{- fail "Forwarder metric format 'prometheus' cannot be used with convertCumulativeToDelta; prometheus metrics must be cumulative." }}
  {{- end }}
  {{- include "config.processors.cumulativetodelta" . | nindent 2 }}
{{- end }}

{{- if .Values.agent.config.global.fleet.enabled }}
{{- include "config.processors.resource_detection" . | nindent 2 }}
{{- include "config.processors.resource.agent_instance" . | nindent 2 }}
{{- include "config.processors.transform.k8sheartbeat" . | nindent 2 }}
{{- end }}

  attributes/debug_source_gateway:
    actions:
    - action: upsert
      key: debug_source
      value: gateway

{{- if .Values.gatewayDeployment.traceSampling.enabled }}
  tail_sampling/observe:
{{ toYaml .Values.gatewayDeployment.traceSampling.config | nindent 4 }}
{{- end }}

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
        {{- if .Values.gatewayDeployment.traceSampling.enabled }}
        - tail_sampling/observe
        {{- end }}
        {{- if not .Values.agent.config.global.exporters.sendingQueue.batch.enabled }}
        - batch
        {{- end }}
        - resource/observe_common
      exporters: [{{ join ", " $traceExporters }}]
    logs/observe-forward:
      receivers: [otlp/app-telemetry]
      processors:
        - memory_limiter
        - k8sattributes
        {{- if not .Values.agent.config.global.exporters.sendingQueue.batch.enabled }}
        - batch
        {{- end }}
        - resource/observe_common
        - attributes/debug_source_gateway
      exporters: [{{ join ", " $logsExporters }}]
    metrics/observe-forward:
      receivers: [otlp/app-telemetry]
      processors:
        - memory_limiter
        - k8sattributes
        {{- if eq .Values.node.forwarder.metrics.outputFormat "prometheus" }}
        - deltatocumulative/observe
        {{- end }}
        {{- if .Values.node.forwarder.metrics.convertCumulativeToDelta }}
        - cumulativetodelta/observe
        {{- end }}
        {{- if not .Values.agent.config.global.exporters.sendingQueue.batch.enabled }}
        - batch
        {{- end }}
        - resource/observe_common
        - attributes/debug_source_gateway
      exporters: [{{ join ", " $metricsExporters }}]
    {{- if .Values.application.REDMetrics.enabled }}
    {{- include "config.pipelines.RED_metrics" . | nindent 4 }}
    {{- end }}

    {{- if .Values.agent.config.global.fleet.enabled }}
    {{- include "config.pipelines.heartbeat" . | nindent 4 }}
    {{- end }}

{{- end }}
