{{- define "observe.observe-agent" -}}
observe_url: {{ .Values.observe.collectionEndpoint.value }}
{{- /*
The agent resolves `token` from the TOKEN env var (viper AutomaticEnv), which every
collector gets from the agent-credentials secret and which takes precedence over this
file. Writing it here too would put the ingest token in a plain ConfigMap, so it is only
emitted when the chart is not managing the secret and the value would otherwise be lost.
*/}}
{{- if and (not .Values.observe.token.create) .Values.observe.token.value }}
token: {{ .Values.observe.token.value }}
{{- end }}

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
    encoding: {{ .Values.agent.config.global.service.telemetry.loggingEncoding }}


forwarding:
  enabled: false

self_monitoring:
  enabled: false
  fleet:
    enabled: false

host_monitoring:
  enabled: false
{{- end }}
