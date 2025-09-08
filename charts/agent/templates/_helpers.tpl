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

{{/*
Copyied from the opentelemetry-collector chart; we need to match the name of the gateway service

Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "otelcol-service-name" -}}
{{- if .collector.fullnameOverride }}
{{- .collector.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .collector.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}
