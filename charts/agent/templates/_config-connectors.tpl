{{- define "config.connectors.spanmetrics" -}}
{{/* Note: this must be kept in sync with the same variable in config.processors.RED_metrics */}}
{{- $spanmetricsResourceAttributes := (list "service.namespace" "service.version" "deployment.environment" "k8s.pod.name" "k8s.namespace.name") -}}

spanmetrics:
  aggregation_temporality: AGGREGATION_TEMPORALITY_DELTA
  histogram:
    exponential:
      max_size: 100
  dimensions:
    # This connector implicitly adds: service.name, span.name, span.kind, and status.code (which we rename to otel.status_code)
    # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/connector/spanmetricsconnector/connector.go#L528-L540
    {{- range $tag := $spanmetricsResourceAttributes }}
    - name: {{ $tag }}
    {{- end }}
    - name: peer.db.name
    - name: peer.messaging.system
    - name: otel.status_description
    - name: observe.status_code
{{- end -}}
