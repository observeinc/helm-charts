{{- define "observe.observe-agent" -}}
observe_url: {{ .Values.observe.collectionEndpoint.value }}
token: {{ .Values.observe.token.value }}

debug: false

self_monitoring:
  enabled: false

host_monitoring:
  enabled: false
  logs:
    enabled: false
  metrics:
    host:
      enabled: false
    process:
      enabled: false
{{- end }}
