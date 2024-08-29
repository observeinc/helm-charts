{{- define "observe-agent.namespace" -}}
  {{- if .Values.cluster.namespaceOverride.value -}}
    {{- .Values.cluster.namespaceOverride.value -}}
  {{- else -}}
    "observe"
  {{- end -}}
{{- end -}}
{{- define "config.local_host" -}}
${env:MY_POD_IP}
{{- end -}}
