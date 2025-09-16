{{- define "observe.daemonset.forwarder.config" -}}

{{- $redMetrics := (and .Values.application.REDMetrics.enabled (not .Values.gatewayDeployment.enabled)) }}
{{- if $redMetrics }}
connectors:
{{- include "config.connectors.spanmetrics" . | nindent 2 }}
{{- end }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}

{{- if .Values.gatewayDeployment.enabled }}
  loadbalancing/observe-gateway:
    routing_key: "traceID"
    protocol:
      otlp:
        tls:
          insecure: true
        compression: snappy
    resolver:
      # use k8s service resolver, if collector runs in kubernetes environment
      k8s:
        service: {{ include "otelcol-service-name" (merge . (dict "collector" .Values.gateway)) }}.{{ .Values.gateway.namespaceOverride }}

  otlp/gateway-service:
    endpoint: {{ include "otelcol-service-name" (merge . (dict "collector" .Values.gateway)) }}.{{ .Values.gateway.namespaceOverride }}.svc.cluster.local:4317
    tls:
      insecure: true
    compression: snappy

{{- else }}
  {{- include "config.exporters.otlphttp.observe.base" . | nindent 2 }}
  {{- include "config.exporters.otlphttp.observe.trace" . | nindent 2 }}
  {{- include "config.exporters.otlphttp.observe.metrics.otel" . | nindent 2 }}
  {{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}
{{- end }}

{{- if .Values.agent.config.global.fleet.heartbeat.enabled }}
{{- include "config.exporters.otlphttp.observe.metrics.agentheartbeat" . | nindent 2 }}
{{- end }}

receivers:
  otlp/app-telemetry:
    protocols:
      grpc:
        endpoint: ${env:MY_POD_IP}:4317
      http:
        endpoint: ${env:MY_POD_IP}:4318

{{- if .Values.agent.config.global.fleet.heartbeat.enabled }}
{{- include "config.receivers.observe.heartbeat" . | nindent 2 }}
{{- end }}

processors:

{{- include "config.processors.memory_limiter" . | nindent 2 }}
{{- include "config.processors.batch" . | nindent 2 }}
{{- include "config.processors.resource_detection.cloud" . | nindent 2 }}
{{- include "config.processors.filter.drop_long_spans" . | nindent 2 }}

{{- if .Values.gatewayDeployment.enabled }}
  # Use passthrough mode to reduce forwarder compute and push the lookup to the gateway whenever it is enabled.
  k8sattributes/passthrough:
    passthrough: true
{{- else }}
  {{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}
  {{- include "config.processors.resource.observe_common" . | nindent 2 }}
  {{- include "config.processors.deltatocumulative" . | nindent 2 }}
  {{- include "config.processors.transform.add_span_status_code" . | nindent 2 }}
  {{- include "config.processors.attributes.add_empty_service_attributes" . | nindent 2 }}

  {{- if .Values.node.forwarder.metrics.convertCumulativeToDelta }}
    {{- if eq .Values.node.forwarder.metrics.outputFormat "prometheus" }}
      {{- fail "Forwarder metric format 'prometheus' cannot be used with convertCumulativeToDelta; prometheus metrics must be cumulative." }}
    {{- end }}
    {{- include "config.processors.cumulativetodelta" . | nindent 2 }}
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
{{- end }}

{{- if $redMetrics }}
{{- include "config.processors.RED_metrics" . | nindent 2 }}
{{- end }}

{{- if .Values.agent.config.global.fleet.heartbeat.enabled }}
{{- include "config.processors.resource.agent_instance" . | nindent 2 }}
{{- include "config.processors.resource.heartbeat" . | nindent 2 }}
{{- end }}

{{- $traceExporters := (list) -}}
{{- $logsExporters := (list) -}}
{{- $metricsExporters := (list) -}}

{{ if .Values.gatewayDeployment.enabled }}
  {{- $traceExporters = concat $traceExporters (list "loadbalancing/observe-gateway") }}
  {{- $logsExporters = concat $logsExporters (list "otlp/gateway-service") }}
  {{- $metricsExporters = concat $metricsExporters (list "otlp/gateway-service") }}
{{- else }}
  {{- $traceExporters = concat $traceExporters (list "otlphttp/observe/forward/trace") }}
  {{- $logsExporters = concat $logsExporters (list "otlphttp/observe/base") -}}
  {{ if eq .Values.node.forwarder.metrics.outputFormat "prometheus" -}}
    {{- $metricsExporters = concat $metricsExporters ( list "prometheusremotewrite/observe" ) | uniq }}
  {{- else if eq .Values.node.forwarder.metrics.outputFormat "otel" -}}
    {{- $metricsExporters = concat $metricsExporters ( list "otlphttp/observe/otel_metrics" ) | uniq }}
  {{- end }}
{{- end }}


{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $traceExporters = concat $traceExporters ( list "debug/override" ) | uniq }}
  {{- $logsExporters = concat $logsExporters ( list "debug/override" ) | uniq }}
  {{- $metricsExporters = concat $metricsExporters ( list "debug/override" ) | uniq }}
{{- end }}

{{- $metricsProcessors := (list) -}}

{{ if .Values.gatewayDeployment.enabled -}}
  {{/* Separate handling when gateway is enabled, since we do minimal processing on the forwarder in that case */}}
  {{- $metricsProcessors = (list "memory_limiter" "k8sattributes/passthrough" "batch" "resourcedetection/cloud") }}
{{- else }}
  {{- $metricsProcessors = (list "memory_limiter" "k8sattributes") }}

  {{/* Handle metrics format related temporality processors */}}
  {{- if eq .Values.node.forwarder.metrics.outputFormat "prometheus" -}}
    {{- $metricsProcessors = concat $metricsProcessors (list "deltatocumulative/observe") }}
  {{- else if ne .Values.node.forwarder.metrics.outputFormat "otel" -}}
    {{- fail "Invalid output format for forwarder metrics, valid values are 'prometheus' and 'otel'." }}
  {{- end }}

  {{/* Handle other temporality processors */}}
  {{- if .Values.node.forwarder.metrics.convertCumulativeToDelta }}
    {{- $metricsProcessors = concat $metricsProcessors (list "cumulativetodelta/observe") }}
  {{- end }}

  {{- $metricsProcessors = concat $metricsProcessors (list "batch" "resourcedetection/cloud" "resource/observe_common" "attributes/debug_source_app_metrics") }}
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
        {{- if .Values.gatewayDeployment.enabled }}
        - k8sattributes/passthrough
        {{- else }}
        - transform/add_span_status_code
        - resource/add_empty_service_attributes
        - k8sattributes
        {{- end }}
        - batch
        - resourcedetection/cloud
        {{- if not .Values.gatewayDeployment.enabled }}
        - resource/observe_common
        - attributes/debug_source_app_traces
        {{- end }}
      exporters: [{{ join ", " $traceExporters }}]
    logs/observe-forward:
      receivers: [otlp/app-telemetry]
      processors:
        - memory_limiter
        {{- if .Values.gatewayDeployment.enabled }}
        - k8sattributes/passthrough
        {{- else }}
        - k8sattributes
        {{- end }}
        - batch
        - resourcedetection/cloud
        {{- if not .Values.gatewayDeployment.enabled }}
        - resource/observe_common
        - attributes/debug_source_app_logs
        {{- end }}
      exporters: [{{ join ", " $logsExporters }}]
    metrics/observe-forward:
      receivers: [otlp/app-telemetry]
      processors:  [{{ join ", " $metricsProcessors }}]
      exporters: [{{ join ", " $metricsExporters }}]
    {{- if $redMetrics }}
    {{- include "config.pipelines.RED_metrics" . | nindent 4 }}
    {{- end }}

    {{- if .Values.agent.config.global.fleet.heartbeat.enabled }}
    {{- include "config.pipelines.heartbeat" . | nindent 4 }}
    {{- end }}

{{- end }}
