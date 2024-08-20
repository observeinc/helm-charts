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


{{- define "observe-agent.clusterRoleName" -}}
  {{- if .Values.cluster.role.name -}}
    {{- .Values.cluster.role.name -}}
  {{- else -}}
    "observe-agent-cluster-role"
  {{- end -}}
{{- end -}}


{{- define "observe-agent.clusterRoleBindingName" -}}
  {{- if .Values.cluster.roleBinding.name -}}
    {{- .Values.cluster.roleBinding.name -}}
  {{- else -}}
    "observe-agent-cluster-role-binding"
  {{- end -}}
{{- end -}}
