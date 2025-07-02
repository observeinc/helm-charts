{{- if .Values.node.containers.logs.multiline }}
{{- if .Values.node.containers.logs.autoMultilineDetection }}
{{- fail "multiline configuration and autoMultilineDetection cannot both be provided. Please choose one or the other." }}
{{- end }}
{{- end }}

{{- define "observe.daemonset.logsMetrics.config.filelog.multiline" -}}
multiline:
  {{- toYaml .Values.node.containers.logs.multiline | nindent 2 }}
{{- end }}

{{- define "observe.daemonset.logsMetrics.config" -}}

extensions:
{{- include "config.extensions.file_storage" . | nindent 2 }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{ if .Values.node.containers.logs.enabled -}}
{{- include "config.exporters.otlphttp.observe.base" . | nindent 2 }}
{{ end -}}
{{ if or .Values.node.containers.metrics.enabled .Values.node.metrics.enabled -}}
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}
{{ end }}
receivers:
  {{- if .Values.node.metrics.enabled }}
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/hostmetricsreceiver
  hostmetrics:
    collection_interval: {{.Values.node.metrics.interval}}
    root_path: {{.Values.node.metrics.fileSystem.rootPath}}
    scrapers:
      cpu: null
      disk: null
      filesystem:
        exclude_fs_types:
          fs_types:
          - autofs
          - binfmt_misc
          - bpf
          - cgroup2
          - configfs
          - debugfs
          - devpts
          - devtmpfs
          - fusectl
          - hugetlbfs
          - iso9660
          - mqueue
          - nsfs
          - overlay
          - proc
          - procfs
          - pstore
          - rpc_pipefs
          - securityfs
          - selinuxfs
          - squashfs
          - sysfs
          - tracefs
          match_type: strict
        exclude_mount_points:
          match_type: regexp
          mount_points: {{.Values.node.metrics.fileSystem.excludeMountPoints}}
      load: null
      memory: null
      network: null
  {{ end -}}
  {{- if .Values.node.containers.metrics.enabled }}
  kubeletstats:
    collection_interval: {{.Values.node.containers.metrics.interval}}
    auth_type: 'serviceAccount'
    endpoint: {{ if .Values.node.kubeletstats.useNodeIp }}"${env:K8S_NODE_IP}:10250"{{ else }}"${env:K8S_NODE_NAME}:10250"{{ end }}
    node: '${env:K8S_NODE_NAME}'
    insecure_skip_verify: true
    k8s_api_config:
        auth_type: serviceAccount
    metric_groups:
      - node
      - pod
      - container
    metrics:
      # Disable deprecated metrics
      k8s.node.cpu.utilization:
        enabled: false
      k8s.pod.cpu.utilization:
        enabled: false
      container.cpu.utilization:
        enabled: false
      # The following metrics are optional and must be enabled manually as per:
      # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/kubeletstatsreceiver/documentation.md#optional-metrics
      container.cpu.usage:
        enabled: true
      container.uptime:
        enabled: true
      k8s.container.cpu.node.utilization:
        enabled: true
      k8s.container.cpu_limit_utilization:
        enabled: true
      k8s.container.cpu_request_utilization:
        enabled: true
      k8s.container.memory.node.utilization:
        enabled: true
      k8s.container.memory_limit_utilization:
        enabled: true
      k8s.container.memory_request_utilization:
        enabled: true
      k8s.node.cpu.usage:
        enabled: true
      k8s.node.uptime:
        enabled: true
      k8s.pod.cpu.node.utilization:
        enabled: true
      k8s.pod.cpu.usage:
        enabled: true
      k8s.pod.cpu_limit_utilization:
        enabled: true
      k8s.pod.cpu_request_utilization:
        enabled: true
      k8s.pod.memory.node.utilization:
        enabled: true
      k8s.pod.memory_limit_utilization:
        enabled: true
      k8s.pod.memory_request_utilization:
        enabled: true
      k8s.pod.uptime:
        enabled: true
    extra_metadata_labels:
      - container.id
  {{ end -}}
  {{- if .Values.node.containers.logs.enabled }}
  filelog:
    poll_interval: 20ms
    exclude: {{ .Values.node.containers.logs.exclude }}
    include: {{ .Values.node.containers.logs.include }}
    include_file_name: false
    include_file_path: true
    exclude_older_than: {{ .Values.node.containers.logs.lookbackPeriod }}
    operators:
    - id: container-parser
      max_log_size: 102400
      type: container
    {{- if .Values.node.containers.logs.autoMultilineDetection }}
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
    start_at: {{ .Values.node.containers.logs.startAt }}
    storage: file_storage
    {{- if .Values.node.containers.logs.multiline }}
    {{- include "observe.daemonset.logsMetrics.config.filelog.multiline" . | nindent 4 }}
    {{ end }}
  {{ end }}

processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.resource_detection.cloud" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}

{{- include "config.processors.resource.observe_common" . | nindent 2 }}
  # attributes to append to objects
  attributes/debug_source_pod_logs:
    actions:
      - key: debug_source
        action: insert
        value: pod_logs
  attributes/debug_source_hostmetrics:
    actions:
      - key: debug_source
        action: insert
        value: hostmetrics
  attributes/debug_source_kubeletstats_metrics:
    actions:
      - key: debug_source
        action: insert
        value: kubeletstats_metrics

# Create intermediate lists for pipeline arrays to then modify based on values.yaml
{{- $logsExporters := (list "otlphttp/observe/base") -}}
{{- $hostmetricsExporters := (list "prometheusremotewrite/observe") -}}
{{- $kubeletstatsExporters := (list "prometheusremotewrite/observe") -}}

{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $logsExporters = concat $logsExporters ( list "debug/override" ) | uniq }}
  {{- $hostmetricsExporters = concat $hostmetricsExporters ( list "debug/override" ) | uniq }}
  {{- $kubeletstatsExporters = concat $kubeletstatsExporters ( list "debug/override" ) | uniq }}
{{- end }}

service:
  pipelines:
      {{- if .Values.node.containers.logs.enabled }}
      logs:
        receivers: [filelog]
        processors: [memory_limiter, k8sattributes, batch, resourcedetection/cloud, resource/observe_common, attributes/debug_source_pod_logs]
        exporters: [{{ join ", " $logsExporters }}]
      {{- end -}}
      {{- if .Values.node.metrics.enabled }}
      metrics/hostmetrics:
        receivers: [hostmetrics]
        processors: [memory_limiter, k8sattributes, batch, resourcedetection/cloud, resource/observe_common, attributes/debug_source_hostmetrics]
        exporters: [{{ join ", " $hostmetricsExporters }}]
      {{- end -}}
      {{- if .Values.node.containers.metrics.enabled }}
      metrics/kubeletstats:
        receivers: [kubeletstats]
        processors: [memory_limiter, k8sattributes, batch, resourcedetection/cloud, resource/observe_common, attributes/debug_source_kubeletstats_metrics]
        exporters: [{{ join ", " $kubeletstatsExporters }}]
      {{- end -}}
{{- include "config.service.telemetry" . | nindent 2 }}

{{- end }}
