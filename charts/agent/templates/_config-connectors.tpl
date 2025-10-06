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
