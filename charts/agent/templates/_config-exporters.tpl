{{- define "config.exporters.otlphttp.observe" -}}
otlphttp/observe:
    endpoint: "{{ .Values.observe.collectionEndpoint }}"
    headers:
        authorization: "Bearer {{ .Values.observe.token }}"
{{- end -}}