{{- define "observe.sidecar.FargateSidecar.config" -}}

receivers:
{{- include "observe.kubeletstats.receiver" (dict "Values" .Values "endpoint" "https://kubernetes.default.svc/api/v1/nodes/${env:K8S_NODE_NAME}/proxy") | nindent 2 }}

processors:

{{- include "config.processors.memory_limiter" . | nindent 2 }}
{{- include "config.processors.batch" . | nindent 2 }}
{{- include "config.processors.resource_detection.cloud" . | nindent 2 }}
{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}
{{- include "config.processors.resource.observe_common" . | nindent 2 }}
{{- include "config.processors.deltatocumulative" . | nindent 2 }}
{{- include "config.processors.attributes.add_empty_service_attributes" . | nindent 2 }}
{{- include "config.processors.metricstransform.duplicate_k8s_cpu_metrics" . | nindent 2 }}
{{- include "config.processors.attributes.sidecar_kubeletstats_metrics" . | nindent 2 }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}

{{ $kubeletstatsExporters := (list "prometheusremotewrite/observe") -}}

{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $kubeletstatsExporters = concat $kubeletstatsExporters ( list "debug/override" ) | uniq }}
{{- end }}

# in the future, we may add other pipelines, and the failure condition should change to
# being that no telemetry collection was enabled
service:
  pipelines:
    {{- if .Values.nodeless.metrics.enabled }}
      metrics/kubeletstats:
        receivers: [kubeletstats]
        processors: [memory_limiter, metricstransform/duplicate_k8s_cpu_metrics, k8sattributes, deltatocumulative/observe, batch, resourcedetection/cloud, resource/observe_common, attributes/debug_source_sidecar_kubeletstats_metrics]
        exporters: [{{ join ", " $kubeletstatsExporters }}]
    {{- else }}
      {{- fail "nodeless.metrics.enabled must be true for Fargate sidecar - otherwise no telemetry will be collected" }}
    {{- end }}
{{- end }}
