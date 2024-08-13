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

{{- include "config.processors.attributes.k8sattributes.podcontroller" . | nindent 2 }}

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
        receivers: [kubeletstats]
        processors: [memory_limiter, batch, resourcedetection/cloud, k8sattributes, attributes/observe_common, attributes/observe_kublet_metrics]
        exporters: [prometheusremotewrite, debug]

{{- include "config.service.telemetry" . | nindent 2 }}

 {{- end }}
