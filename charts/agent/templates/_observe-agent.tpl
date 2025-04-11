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
  metrics:
    enabled: true
    host: "{{ template "config.local_host"}}"
    port: 8888
    level: {{ .Values.agent.config.global.service.telemetry.metricsLevel }}
  logs:
    enabled: true
    level: {{ .Values.agent.config.global.service.telemetry.loggingLevel }}


forwarding:
  enabled: false

self_monitoring:
  enabled: false

host_monitoring:
  enabled: false
{{- end }}
