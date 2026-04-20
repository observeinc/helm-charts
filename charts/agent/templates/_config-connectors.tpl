{{- /*
Emits a spanmetrics connector body. Parameters (passed via dict):
  name         - connector name (e.g. "spanmetrics", "spanmetrics/summary")
  resourceDims - list of resource attribute dimensions (service.name auto-prepended)
  spanDims     - list of span attribute dimensions
*/ -}}
{{- define "config.connectors.spanmetrics.body" -}}
{{- $name := .name -}}
{{- $resourceDims := .resourceDims -}}
{{- $allDims := (concat $resourceDims .spanDims) -}}
{{/* service.name is added automatically by the connector and errors when specified in the config */}}
{{- $allDims = (without $allDims "service.name" | uniq) -}}

{{ $name }}:
  aggregation_temporality: AGGREGATION_TEMPORALITY_DELTA
  histogram:
    exponential:
      max_size: 100
  # Restrict the resource attribute set used to bucket aggregated metrics only to
  # the configured resource attributes.
  resource_metrics_key_attributes:
    {{- range $tag := (prepend $resourceDims "service.name" | uniq) }}
    - {{ $tag }}
    {{- end }}
  dimensions:
    # This connector implicitly adds: service.name, span.name, span.kind, and status.code (which we rename to otel.status_code)
    # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/connector/spanmetricsconnector/connector.go#L528-L540
    {{- range $tag := $allDims }}
    - name: {{ $tag }}
    {{- end }}
{{- end -}}

{{- /*
Emits all connectors needed for the RED metrics pipelines: the full and summary
spanmetrics connectors, plus (when onlyGenerateForAPMSpans is off) the routing
connector that splits "internal" datapoints into a separate pipeline.
*/ -}}
{{- define "config.connectors.RED_metrics" -}}
{{- include "config.connectors.spanmetrics.body" (dict
    "name" "spanmetrics"
    "resourceDims" .Values.application.REDMetrics.resourceDimensions
    "spanDims" .Values.application.REDMetrics.spanDimensions) }}

{{ include "config.connectors.spanmetrics.body" (dict
    "name" "spanmetrics/summary"
    "resourceDims" .Values.application.REDMetrics.summaryMetrics.resourceDimensions
    "spanDims" .Values.application.REDMetrics.summaryMetrics.spanDimensions) }}

{{- if not .Values.application.REDMetrics.onlyGenerateForAPMSpans }}
# Routes RED metric datapoints generated from spans that would have been dropped by
# filter/drop_non_apm_spans (i.e. INTERNAL, UNSPECIFIED, non-DB CLIENT, non-messaging PRODUCER)
# to a dedicated pipeline that renames them with an ".internal" suffix. All other datapoints
# go to the default pipeline.
#
# NB: the route() condition below mirrors the inverse of filter/drop_non_apm_spans.
# Keep the two in sync.
routing/red_metrics_internal:
  error_mode: ignore
  default_pipelines: [metrics/spanmetrics/default]
  table:
    - context: datapoint
      statement: |
        route() where
          attributes["span.kind"] == "SPAN_KIND_INTERNAL"
          or attributes["span.kind"] == "SPAN_KIND_UNSPECIFIED"
          or (attributes["span.kind"] == "SPAN_KIND_CLIENT"
              and attributes["peer.db.name"] == nil)
          or (attributes["span.kind"] == "SPAN_KIND_PRODUCER"
              and attributes["peer.messaging.system"] == nil)
      pipelines: [metrics/spanmetrics/internal]

# Passes spans from the main traces/spanmetrics pipeline into an intermediate
# filter pipeline (traces/spanmetrics/summary/filter) that drops non-APM spans
# before they reach the summary connector.
forward/red_metrics_summary:
{{- end }}
{{- end -}}
