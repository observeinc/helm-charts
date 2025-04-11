{{- define "config.service.telemetry" -}}
telemetry:
    logs:
      encoding: {{ .Values.agent.config.global.service.telemetry.loggingEncoding }}
{{- end -}}
