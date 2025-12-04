{{- if .Values.nodeless.logs.multiline }}
{{- if .Values.nodeless.logs.autoMultilineDetection }}
{{- fail "multiline configuration and autoMultilineDetection cannot both be provided. Please choose one or the other." }}
{{- end }}
{{- end }}

{{- define "fargate_logs.processors" -}}
processors:
  - memory_limiter
  {{- if .Values.nodeless.logs.containerNameFromFile }}
  - groupbyattrs/log_file
  - transform/add_resource_container_name
  {{- end }}
  - resource/fargate_resource_attributes
  - k8sattributes
  - batch
  - resourcedetection/cloud
  - resource/observe_common
  - attributes/debug_source_fargate_pod_logs
{{- end }}

{{- define "observe.sidecar.FargateSidecar.config" -}}

extensions:
{{- include "config.extensions.file_storage_fargate" . | nindent 2 }}

receivers:
{{- if .Values.nodeless.metrics.enabled }}
{{- include "observe.kubeletstats.receiver" (dict "Values" .Values "endpoint" "https://kubernetes.default.svc/api/v1/nodes/${env:K8S_NODE_NAME}/proxy") | nindent 2 }}
{{ end }}

{{- if .Values.nodeless.logs.enabled }}
  filelog/fargate-container-logs:
    poll_interval: 20ms
    exclude: {{ .Values.nodeless.logs.exclude }}
    include: {{ .Values.nodeless.logs.include }}
    include_file_name: false
    include_file_path: true
    exclude_older_than: {{ .Values.node.containers.logs.lookbackPeriod }}
    {{ if .Values.nodeless.logs.autoMultilineDetection }}
    storage: file_storage/fargate
    operators:
    - id: multiline-recombine
      type: recombine
      combine_field: body
      # Regex is just 3 different pattern's OR'd together to match the 4 timestamp formats `2021-03-28 13:45:30`, `2023-03-28T14:33:53.743350Z`, `Jun 14 15:16:01`, `2024/05/16 19:46:15`
      is_first_entry: body matches "^(\\d{4}[-/]\\d{2}[-/]\\d{2} \\d{2}:\\d{2}:\\d{2}|\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?Z?|[A-Za-z]+ \\d{1,2} \\d{2}:\\d{2}:\\d{2})"
    {{- end }}
    retry_on_failure:
      enabled: {{ .Values.node.containers.logs.retryOnFailure.enabled }}
      initial_interval: {{ .Values.node.containers.logs.retryOnFailure.initialInterval }}
      max_interval: {{ .Values.node.containers.logs.retryOnFailure.maxInterval }}
      max_elapsed_time: {{ .Values.node.containers.logs.retryOnFailure.maxElapsedTime }}
    start_at: {{  .Values.nodeless.logs.startAt }}
    {{- if .Values.nodeless.logs.multiline }}
    multiline:
      {{- toYaml .Values.nodeless.logs.multiline | nindent 6 }}
    {{ end }}
{{ end }}

processors:
# common processors
{{- include "config.processors.memory_limiter" . | nindent 2 }}
{{- include "config.processors.batch" . | nindent 2 }}
{{- include "config.processors.resource_detection.cloud" . | nindent 2 }}
{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}
{{- include "config.processors.resource.observe_common" . | nindent 2 }}

# metrics specific processors
{{- include "config.processors.deltatocumulative" . | nindent 2 }}
{{- include "config.processors.metricstransform.duplicate_k8s_cpu_metrics" . | nindent 2 }}
{{- include "config.processors.attributes.sidecar_kubeletstats_metrics" . | nindent 2 }}

# logs specific processors
{{- include "config.processors.resource.fargate_resource_attributes" . | nindent 2 }}
{{- include "config.processors.attributes.fargate_pod_logs" . | nindent 2 }}

{{- if .Values.nodeless.logs.containerNameFromFile }}
  {{- include "config.processors.groupbyattrs.log_file" . | nindent 2 }}
  {{- include "config.processors.transform.add_resource_container_name" . | nindent 2 }}
{{- end }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe.base" . | nindent 2 }}

{{- $kubeletstatsExporters := (list "prometheusremotewrite/observe") -}}
{{- $logsExporters := (list "otlphttp/observe/base") -}}

{{- if  .Values.agent.config.global.debug.enabled }}
  {{- $logsExporters = concat $logsExporters ( list "debug/override" ) | uniq }}
  {{- $kubeletstatsExporters = concat $kubeletstatsExporters ( list "debug/override" ) | uniq }}
{{- end }}

service:
  {{- if .Values.nodeless.logs.enabled }}
  extensions: [file_storage/fargate]
  {{- end }}
  pipelines:
    {{- if .Values.nodeless.metrics.enabled }}
    metrics/kubeletstats:
      receivers: [kubeletstats]
      processors: [memory_limiter, metricstransform/duplicate_k8s_cpu_metrics, k8sattributes, deltatocumulative/observe, batch, resourcedetection/cloud, resource/observe_common, attributes/debug_source_sidecar_kubeletstats_metrics]
      exporters: [{{ join ", " $kubeletstatsExporters }}]

    {{- end }}
    {{- if .Values.nodeless.logs.enabled }}
    logs/filelog:
      receivers: [filelog/fargate-container-logs]
      {{- include "fargate_logs.processors" . | nindent 6 }}
      exporters: [{{ join ", " $logsExporters }}]
    {{- end }}
    {{- if and (not .Values.nodeless.metrics.enabled) (not .Values.nodeless.logs.enabled) }}
      {{- fail "nodeless.metrics.enabled or nodeless.logs.enabled must be true for Fargate sidecar, or no telemetry will be collected" }}
    {{- end }}
{{- end }}
