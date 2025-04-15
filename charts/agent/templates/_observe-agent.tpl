{{- define "observe.observe-agent" -}}
observe_url: {{ .Values.observe.collectionEndpoint.value }}
token: {{ .Values.observe.token.value }}

debug: false

health_check:
  enabled: true
  endpoint: "{{ template "config.local_host"}}:13133"
  path: "/status"

internal_telemetry:
  enabled: true
  host: "{{ template "config.local_host"}}"
  port: 8888

forwarding:
  enabled: false

self_monitoring:
  enabled: false

host_monitoring:
  enabled: false
{{- end }}
