{{- define "observe.daemonset.logsMetrics.config" -}}

extensions:
{{- include "config.extensions.health_check" . | nindent 2 }}
  file_storage:
    directory: /var/lib/otelcol

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
  hostmetrics:
    collection_interval: 10s
    root_path: /hostfs
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
          mount_points:
          - /dev/*
          - /proc/*
          - /sys/*
          - /run/k3s/containerd/*
          - /var/lib/docker/*
          - /var/lib/kubelet/*
          - /snap/*
      load: null
      memory: null
      network: null
  {{ end -}}
  {{- if .Values.node.containers.metrics.enabled }}
  kubeletstats:
    collection_interval: 10s
    auth_type: 'serviceAccount'
    endpoint: '${env:K8S_NODE_NAME}:10250'
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
  {{ end -}}
  {{- if .Values.node.containers.logs.enabled }}
  filelog:
    exclude: []
    include:
    - /var/log/pods/*/*/*.log
    - /var/log/kube-apiserver-audit.log
    include_file_name: false
    include_file_path: true
    operators:
    - id: container-parser
      max_log_size: 102400
      type: container
    retry_on_failure:
      enabled: true
    start_at: end
    storage: file_storage
  {{ end }}
processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.resource_detection.cloud" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}

{{- include "config.processors.attributes.observe_common" . | nindent 2 }}
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
  attributes/debug_source_kubletstats_metrics:
    actions:
      - key: debug_source
        action: insert
        value: kubeletstats_metrics

service:
  extensions: [health_check, file_storage]
  pipelines:
      {{- if .Values.node.containers.logs.enabled }}
      logs:
        receivers: [filelog]
        processors: [memory_limiter, batch, resourcedetection/cloud, k8sattributes, attributes/observe_common, attributes/debug_source_pod_logs]
        exporters: [otlphttp/observe/base, debug/override]
      {{- end -}}
      {{- if .Values.node.metrics.enabled }}
      metrics/hostmetrics:
        receivers: [hostmetrics]
        processors: [memory_limiter, batch, resourcedetection/cloud, k8sattributes, attributes/observe_common, attributes/debug_source_hostmetrics]
        exporters: [prometheusremotewrite, debug/override]
      {{- end -}}
      {{- if .Values.node.containers.metrics.enabled }}
      metrics/kubeletstats:
        receivers: [kubeletstats]
        processors: [memory_limiter, batch, resourcedetection/cloud, k8sattributes, attributes/observe_common, attributes/debug_source_kubletstats_metrics]
        exporters: [prometheusremotewrite, debug/override]
      {{- end -}}
{{- include "config.service.telemetry" . | nindent 2 }}

{{- end }}
