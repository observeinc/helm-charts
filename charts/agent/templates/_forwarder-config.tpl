{{- define "observe.daemonset.forwarder.config" -}}

{{- $spanmetricsResourceAttributes := (list "service.namespace" "service.version" "deployment.environment" "k8s.pod.name" "k8s.namespace.name") -}}

{{- if .Values.application.REDMetrics.enabled }}
connectors:
  spanmetrics:
    aggregation_temporality: AGGREGATION_TEMPORALITY_DELTA
    histogram:
      exponential:
        max_size: 100
    dimensions:
      # This connector implicitly adds: service.name, span.name, span.kind, and status.code (which we rename to response_status)
      # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/connector/spanmetricsconnector/connector.go#L528-L540
      {{- range $tag := $spanmetricsResourceAttributes }}
      - name: {{ $tag }}
      {{- end }}
      - name: peer.db.name
      - name: peer.messaging.system
      - name: status.message
      - name: status_code
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

{{- if eq .Values.node.forwarder.traces.maxSpanDuration "none" }}
{{- else if (regexMatch "^[0-9]+(ns|us|ms|s|m|h)$" .Values.node.forwarder.traces.maxSpanDuration) }}
  # This drops spans that are longer than the configured time (default 1hr) to match service explorer behavior.
  filter/drop_long_spans:
    error_mode: ignore
    traces:
      span:
        - (span.end_time - span.start_time) > Duration("{{ .Values.node.forwarder.traces.maxSpanDuration }}")
{{- else }}
{{- fail "Invalid maxSpanDuration for forwarder red metrics, valid values are 'none' or a number with a valid time unit: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/pkg/ottl/ottlfuncs/README.md#duration" }}
{{- end }}

{{- if .Values.application.REDMetrics.enabled }}
  attributes/debug_source_span_metrics:
    actions:
      - action: insert
        key: debug_source
        value: span_metrics

  # This handles schema normalization as well as moving status to attributes so it can be a dimension in spanmetrics
  transform/shape_spans_for_red_metrics:
    error_mode: ignore
    trace_statements:
      - set(span.attributes["peer.db.name"], span.attributes["db.system.name"]) where span.attributes["peer.db.name"] == nil and span.attributes["db.system.name"] != nil
      - set(span.attributes["peer.db.name"], span.attributes["db.system"]) where span.attributes["peer.db.name"] == nil and span.attributes["db.system"] != nil
      # Needed because `spanmetrics` connector can only operate on attributes or resource attributes.
      - set(span.attributes["status.message"], span.status.message) where span.status.message != ""

  # This regroups the metrics by the peer attributes so we can remove `service.name` from the resource when these metric attributes are present
  # NB: these will be deleted from the metric attributes and added to the resource.
  groupbyattrs/peers:
    keys:
      - peer.db.name
      - peer.messaging.system

  # This puts moves the peer attributes from the resource back to the datapoint after we have regrouped the metrics.
  transform/fix_peer_attributes:
    error_mode: ignore
    metric_statements:
      - set(datapoint.attributes["peer.db.name"], resource.attributes["peer.db.name"]) where resource.attributes["peer.db.name"] != nil
      - set(datapoint.attributes["peer.messaging.system"], resource.attributes["peer.messaging.system"]) where resource.attributes["peer.messaging.system"] != nil

  # This removes service.name for generated RED metrics associated with peer systems.
  transform/remove_service_name_for_peer_metrics:
    error_mode: ignore
    metric_statements:
      - delete_key(resource.attributes, "service.name") where datapoint.attributes["peer.db.name"] != nil or datapoint.attributes["peer.messaging.system"] != nil

  # This drops spans that are not relevant for Service Explorer RED metrics.
  filter/drop_span_kinds_other_than_server_and_consumer_and_peer_client:
    error_mode: ignore
    traces:
      span:
        - span.kind == SPAN_KIND_CLIENT and span.attributes["peer.messaging.system"] == nil and span.attributes["peer.db.name"] == nil and span.attributes["db.system.name"] == nil and span.attributes["db.system"] == nil
        - span.kind == SPAN_KIND_UNSPECIFIED
        - span.kind == SPAN_KIND_INTERNAL
        - span.kind == SPAN_KIND_PRODUCER

  # The spanmetrics connector puts all dimensions as attributes on the datapoint, and copies the resource attributes from an arbitrary span's resource. This cleans that up as well as handling any other renaming.
  transform/fix_red_metrics_resource_attributes:
    error_mode: ignore
    metric_statements:
      # Drop all resource attributes that aren't dimensions in the spanmetrics connector.
      {{/* The service.name is implicit in the spanmetrics connector, so we can't include it in spanmetricsResourceAttributes and need to list it here. */}}
      - keep_matching_keys(resource.attributes, "^(service.name|{{ join "|" $spanmetricsResourceAttributes }})")

      # Drop all datapoint attributes that are resource attributes in the spans.
      - delete_matching_keys(datapoint.attributes, "^(service.name|{{ join "|" $spanmetricsResourceAttributes }})")

      # Rename status.code to response_status to be consistent with Trace Explorer and disambiguate from status_code (with an underscore).
      - set(datapoint.attributes["response_status"], datapoint.attributes["status.code"])
      - delete_key(datapoint.attributes, "status.code")
{{- end }}

{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.resource_detection.cloud" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}

{{- include "config.processors.deltatocumulative" . | nindent 2 }}

{{- include "config.processors.resource.observe_common" . | nindent 2 }}

  transform/add_span_status_code:
    error_mode: ignore
    trace_statements:
      - set(span.attributes["status_code"], Int(span.attributes["rpc.grpc.status_code"])) where span.attributes["status_code"] == nil and span.attributes["rpc.grpc.status_code"] != nil
      - set(span.attributes["status_code"], Int(span.attributes["grpc.status_code"])) where span.attributes["status_code"] == nil and span.attributes["grpc.status_code"] != nil
      - set(span.attributes["status_code"], Int(span.attributes["rpc.status_code"])) where span.attributes["status_code"] == nil and span.attributes["rpc.status_code"] != nil
      - set(span.attributes["status_code"], Int(span.attributes["http.status_code"])) where span.attributes["status_code"] == nil and span.attributes["http.status_code"] != nil
      - set(span.attributes["status_code"], Int(span.attributes["http.response.status_code"])) where span.attributes["status_code"] == nil and span.attributes["http.response.status_code"] != nil

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
{{- $tracesSpanmetricsExporters := (list "spanmetrics") -}}
{{- $metricsSpanmetricsExporters := (list "otlphttp/observe/otel_metrics") -}}

{{ if eq .Values.node.forwarder.metrics.outputFormat "prometheus" -}}
  {{- $metricsExporters = concat $metricsExporters ( list "prometheusremotewrite/observe" ) | uniq }}
{{- else if eq .Values.node.forwarder.metrics.outputFormat "otel" -}}
  {{- $metricsExporters = concat $metricsExporters ( list "otlphttp/observe/otel_metrics" ) | uniq }}
{{- end }}

{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $traceExporters = concat $traceExporters ( list "debug/override" ) | uniq }}
  {{- $logsExporters = concat $logsExporters ( list "debug/override" ) | uniq }}
  {{- $metricsExporters = concat $metricsExporters ( list "debug/override" ) | uniq }}
  {{- $tracesSpanmetricsExporters = concat $tracesSpanmetricsExporters ( list "debug/override" ) | uniq }}
  {{- $metricsSpanmetricsExporters = concat $metricsSpanmetricsExporters ( list "debug/override" ) | uniq }}
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
    traces/spanmetrics:
      receivers:
        - otlp/app-telemetry
      processors:
        - memory_limiter
        {{- if ne .Values.node.forwarder.traces.maxSpanDuration "none" }}
        - filter/drop_long_spans
        {{- end }}
        - filter/drop_span_kinds_other_than_server_and_consumer_and_peer_client
        - transform/shape_spans_for_red_metrics
        - transform/add_span_status_code
        - k8sattributes
      exporters: [{{ join ", " $tracesSpanmetricsExporters }}]
    metrics/spanmetrics:
      receivers:
        - spanmetrics
      processors:
        - memory_limiter
        - groupbyattrs/peers
        - transform/fix_peer_attributes
        - transform/remove_service_name_for_peer_metrics
        - transform/fix_red_metrics_resource_attributes
        - batch
        - resource/observe_common
        - resourcedetection/cloud
        - attributes/debug_source_span_metrics
      exporters: [{{ join ", " $metricsSpanmetricsExporters }}]
    {{- end }}

{{- include "config.service.telemetry" . | nindent 2 }}

{{- end }}
