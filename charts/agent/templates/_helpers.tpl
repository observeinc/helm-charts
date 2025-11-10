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

{{/*
Validate that OTEL_K8S_POD_UID is defined in extraEnvs when fleet is enabled.
This helper should be called for each deployment/daemonset.
Usage: {{ include "observe-agent.validateOtelPodUid" (dict "componentName" "cluster-events" "extraEnvs" .Values.cluster-events.extraEnvs "fleetEnabled" .Values.agent.config.global.fleet.enabled) }}
*/}}
{{- define "observe-agent.validateOtelPodUid" -}}
{{- if .fleetEnabled -}}
  {{- $hasOtelPodUid := false -}}
  {{- range .extraEnvs -}}
    {{- if eq .name "OTEL_K8S_POD_UID" -}}
      {{- $hasOtelPodUid = true -}}
    {{- end -}}
  {{- end -}}
  {{- if not $hasOtelPodUid -}}
    {{- fail (printf "ERROR: Fleet is enabled (agent.config.global.fleet.enabled=true) but OTEL_K8S_POD_UID environment variable is not defined in %s.extraEnvs. Please add OTEL_K8S_POD_UID to the extraEnvs list in values.yaml or via --set. The fieldRef.fieldPath value should be set to metadata.uid." .componentName) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
