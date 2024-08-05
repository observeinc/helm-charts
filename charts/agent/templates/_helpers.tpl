{{- define "observe-agent.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    "observe"
  {{- end -}}
{{- end -}}
