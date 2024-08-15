{{- define "observe.daemonset.logsMetrics.config" -}}

extensions:
{{- include "config.extensions.health_check" . | nindent 2 }}
  file_storage:
    directory: /var/lib/otelcol

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.otlphttp.observe" . | nindent 2 }}
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}

receivers:
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

  kubeletstats:
    collection_interval: 10s
    auth_type: 'serviceAccount'
    endpoint: '${env:K8S_NODE_NAME}:10250'
    insecure_skip_verify: true
    metric_groups:
      - node
      - pod
      - container

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

processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.resource_detection.cloud" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}

{{- include "config.processors.attributes.observe_common" . | nindent 2 }}

  # attributes to append to objects
  attributes/observe_pod_logs:
    actions:
      - key: observe_filter
        action: insert
        value: pod_logs
  attributes/observe_kublet_metrics:
    actions:
      - key: observe_filter
        action: insert
        value: kubeletstats_metrics

service:
  extensions: [health_check, file_storage]
  pipelines:
      logs:
        receivers: [filelog]
        processors: [memory_limiter, batch, resourcedetection/cloud, k8sattributes, attributes/observe_common, attributes/observe_pod_logs]
        exporters: [otlphttp/observe, debug]
      metrics:
        receivers: [hostmetrics, kubeletstats]
        processors: [memory_limiter, batch, resourcedetection/cloud, k8sattributes, attributes/observe_common, attributes/observe_kublet_metrics]
        exporters: [prometheusremotewrite, debug]

{{- include "config.service.telemetry" . | nindent 2 }}

 {{- end }}
