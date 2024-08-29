{{- define "config.exporters.otlphttp.observe.base" -}}
otlphttp/observe/base:
    endpoint: "{{ .Values.observe.collectionEndpoint.value | toString | trimSuffix "/" }}/v2/otel"
    headers:
        authorization: "${env:OBSERVE_TOKEN}"
{{- end -}}

{{- define "config.exporters.otlphttp.observe.entity" -}}
otlphttp/observe/entity:
    logs_endpoint: "{{ .Values.observe.collectionEndpoint.value | toString | trimSuffix "/" }}/v1/kubernetes/v1/entity"
    headers:
        authorization: "Bearer {env:ENTITY_TOKEN}"
{{- end -}}

{{- define "config.exporters.prometheusremotewrite" -}}
prometheusremotewrite:
    endpoint: "{{ .Values.observe.collectionEndpoint.value | toString | trimSuffix "/" }}/v1/prometheus"
    headers:
        authorization: "${env:OBSERVE_TOKEN}"
    resource_to_telemetry_conversion:
        enabled: true # Convert resource attributes to metric labels
{{- end -}}

{{- define "config.exporters.debug" -}}
debug/override:
    verbosity: {{ .Values.agent.config.global.debug.verbosity }}
    sampling_initial: 2
    sampling_thereafter: 1
{{- end -}}
