{{- define "observe.observe-agent" -}}
token: {{ .Values.observe.token }}

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
