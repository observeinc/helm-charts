{{- define "config.connectors.spanmetrics" -}}

{{- $fullDimensions := (concat .Values.application.REDMetrics.resourceDimensions .Values.application.REDMetrics.spanDimensions) -}}
{{/* service.name is added automatically by the connector and errors when specified in the config */}}
{{- $fullDimensions = (without $fullDimensions "service.name" | uniq) -}}

spanmetrics:
  aggregation_temporality: AGGREGATION_TEMPORALITY_DELTA
  histogram:
    exponential:
      max_size: 100
  # Restrict the resource-attribute set used to bucket aggregated metrics so that
  # incidental resource attributes (e.g. k8s.pod.uid, container.id, host.name) do
  # not cause per-pod metric stream fanout. Without this, the connector hashes ALL
  # input span resource attributes and emits one ResourceMetrics envelope per
  # unique combination on every flush.
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/connector/spanmetricsconnector/connector.go#L503-L516
  resource_metrics_key_attributes:
    {{- range $tag := (prepend .Values.application.REDMetrics.resourceDimensions "service.name" | uniq) }}
    - {{ $tag }}
    {{- end }}
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
  # Restrict the resource-attribute set used to bucket aggregated metrics so that
  # incidental resource attributes (e.g. k8s.pod.name, k8s.pod.uid, container.id,
  # host.name) do not cause per-pod metric stream fanout. Without this, the
  # connector hashes ALL input span resource attributes and emits one
  # ResourceMetrics envelope per unique combination on every flush, which the
  # downstream keep_matching_keys relabel cannot merge back together.
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/connector/spanmetricsconnector/connector.go#L503-L516
  resource_metrics_key_attributes:
    {{- range $tag := (prepend .Values.application.REDMetrics.summaryMetrics.resourceDimensions "service.name" | uniq) }}
    - {{ $tag }}
    {{- end }}
  dimensions:
    {{- range $tag := $summaryDimensions }}
    - name: {{ $tag }}
    {{- end }}
{{- end -}}

{{- define "config.connectors.routing.red_metrics_internal" -}}
# Routes RED metric datapoints generated from spans that would have been dropped by
# filter/drop_non_apm_spans (i.e. INTERNAL, UNSPECIFIED, non-DB CLIENT, non-messaging PRODUCER)
# to a dedicated pipeline that renames them with an ".internal" suffix. All other datapoints
# go to the default pipeline.
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
