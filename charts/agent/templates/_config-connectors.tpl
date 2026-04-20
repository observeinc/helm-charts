{{- define "config.connectors.spanmetrics" -}}

{{- $fullDimensions := (concat .Values.application.REDMetrics.resourceDimensions .Values.application.REDMetrics.spanDimensions) -}}
{{/* service.name is added automatically by the connector and errors when specified in the config */}}
{{- $fullDimensions = (without $fullDimensions "service.name" | uniq) -}}

spanmetrics:
  aggregation_temporality: AGGREGATION_TEMPORALITY_DELTA
  histogram:
    exponential:
      max_size: 100
  dimensions:
    # This connector implicitly adds: service.name, span.name, span.kind, and status.code (which we rename to otel.status_code)
    # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/connector/spanmetricsconnector/connector.go#L528-L540
    {{- range $tag := $fullDimensions }}
    - name: {{ $tag }}
    {{- end }}
{{- end -}}

{{- define "config.connectors.spanmetrics.summary" -}}

{{- $summaryDimensions := (concat .Values.application.REDMetrics.summaryMetrics.resourceDimensions .Values.application.REDMetrics.summaryMetrics.spanDimensions) -}}
{{- $summaryDimensions = (without $summaryDimensions "service.name" | uniq) -}}

spanmetrics/summary:
  aggregation_temporality: AGGREGATION_TEMPORALITY_DELTA
  histogram:
    exponential:
      max_size: 100
  dimensions:
    {{- range $tag := $summaryDimensions }}
    - name: {{ $tag }}
    {{- end }}
{{- end -}}

{{- define "config.connectors.routing.red_metrics_internal" -}}
# Routes RED metric datapoints generated from spans that would have been dropped by
# filter/drop_span_kinds_other_than_server_and_consumer_and_peer_client (i.e. INTERNAL,
# UNSPECIFIED, non-DB CLIENT, non-messaging PRODUCER) to a dedicated pipeline that renames
# them with an ".internal" suffix. All other datapoints go to the default pipeline.
routing/red_metrics_internal:
  error_mode: ignore
  match_once: true
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
{{- end -}}
