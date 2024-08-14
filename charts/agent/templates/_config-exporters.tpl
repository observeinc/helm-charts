{{- define "config.exporters.otlphttp.observe.base" -}}
otlphttp/observe/base:
    endpoint: "{{ trimSuffix "/" .Values.observe.collectionEndpoint }}/v2/otel"
    headers:
        authorization: "Bearer {{ .Values.observe.token }}"
{{- end -}}

{{- define "config.exporters.otlphttp.observe.entity" -}}
otlphttp/observe/entity:
    logs_endpoint: "{{ trimSuffix "/" .Values.observe.collectionEndpoint }}/v1/kubernetes/v1/entity"
    headers:
        authorization: "Bearer {{ .Values.observe.entityToken }}"
{{- end -}}

{{- define "config.exporters.prometheusremotewrite" -}}
prometheusremotewrite:
    endpoint: "{{  trimSuffix "/" .Values.observe.collectionEndpoint }}/v1/prometheus"
    headers:
        authorization: "Bearer {{ .Values.observe.token }}"
    resource_to_telemetry_conversion:
        enabled: true # Convert resource attributes to metric labels

{{- end -}}

{{- define "config.exporters.debug" -}}
debug/override:
    verbosity: {{ .Values.config.global.debug.verbosity }}
    sampling_initial: 2
    sampling_thereafter: 1
{{- end -}}
