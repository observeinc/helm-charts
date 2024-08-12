{{- define "config.exporters.otlphttp.observe" -}}
otlphttp/observe:
    endpoint: "{{ .Values.observe.collectionEndpoint }}v2/otel"
    headers:
        authorization: "Bearer {{ .Values.observe.token }}"
{{- end -}}

{{- define "config.exporters.debug" -}}
debug:
    verbosity: basic
    sampling_initial: 2
    sampling_thereafter: 1
{{- end -}}