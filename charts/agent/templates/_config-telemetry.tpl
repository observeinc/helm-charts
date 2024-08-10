{{- define "config.service.telemetry" -}}
telemetry:
    metrics:
      level: {{ .Values.config.global.service.telemetry.metrics_level }}
      address: {{ template "config.local_host"}}:8888
    logs:
      level: {{ .Values.config.global.service.telemetry.logging_level }}
{{- end -}}