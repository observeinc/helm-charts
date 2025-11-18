{{- define "observe.kubeletstats.receiver" -}}
kubeletstats:
  collection_interval: {{.Values.node.containers.metrics.interval}}
  auth_type: 'serviceAccount'
  endpoint: {{ .endpoint }}
  node: '${env:K8S_NODE_NAME}'
  insecure_skip_verify: true
  k8s_api_config:
      auth_type: serviceAccount
  metric_groups:
    - node
    - pod
    - container
  metrics:
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
{{- end }}
