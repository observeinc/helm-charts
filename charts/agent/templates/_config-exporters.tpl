{{- define "config.exporters.otlphttp.observe" -}}
otlphttp/observe:
    endpoint: "{{ .Values.observe.collectionEndpoint }}v2/otel"
    headers:
        authorization: "Bearer {{ .Values.observe.token }}"
{{- end -}}