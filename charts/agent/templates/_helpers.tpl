{{- define "observe-agent.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    "observe"
  {{- end -}}
{{- end -}}
{{- define "config.local_host" -}}
${env:MY_POD_IP}
{{- end -}}
