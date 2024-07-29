{{- define "observe.observe-agent" -}}
token: {{ .Values.observe.token }}

observe_url: {{ .Values.observe.collectionEndpoint }}

debug: false

self_monitoring:
  enabled: false

host_monitoring:
  enabled: false
  logs:
    enabled: false
  metrics:
    enabled: false
{{- end }}
