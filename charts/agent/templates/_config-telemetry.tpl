{{- define "config.service.telemetry" -}}
telemetry:
    metrics:
      level: {{ .Values.agent.config.global.service.telemetry.metricsLevel }}
      address: {{ template "config.local_host"}}:8888
    logs:
      level: {{ .Values.agent.config.global.service.telemetry.loggingLevel }}
      encoding: {{ .Values.agent.config.global.service.telemetry.loggingEncoding }}
{{- end -}}
