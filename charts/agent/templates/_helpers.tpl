{{- define "observe-agent.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    "observe"
  {{- end -}}
{{- end -}}
{{- define "config.local_host" -}}
0.0.0.0
{{- end -}}