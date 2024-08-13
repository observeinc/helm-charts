{{- define "config.exporters.otlphttp.observe" -}}
otlphttp/observe:
    endpoint: "{{ .Values.observe.collectionEndpoint }}v2/otel"
    headers:
        authorization: "Bearer {{ .Values.observe.token }}"
{{- end -}}

{{- define "config.exporters.prometheusremotewrite" -}}
prometheusremotewrite:
    endpoint: "{{ .Values.observe.collectionEndpoint }}v1/prometheus"
    headers:
        authorization: "Bearer {{ .Values.observe.token }}"
    resource_to_telemetry_conversion:
        enabled: true # Convert resource attributes to metric labels

{{- end -}}

{{- define "config.exporters.debug" -}}
debug:
    verbosity: basic
    sampling_initial: 2
    sampling_thereafter: 1
{{- end -}}
