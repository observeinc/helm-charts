{{- define "config.processors.resource_detection.cloud" -}}
resourcedetection/cloud:
  detectors: ["eks", "gcp", "ecs", "ec2", "azure"]
  timeout: 2s
  override: false
{{- end -}}

{{- define "config.processors.batch" -}}
batch:
  send_batch_size: {{ .Values.agent.config.global.processors.batch.sendBatchSize }}
  send_batch_max_size: {{ .Values.agent.config.global.processors.batch.sendBatchMaxSize }}
{{- end -}}

{{- define "config.processors.deltatocumulative" -}}
deltatocumulative/observe:
  max_stale: 5m
{{- end -}}

{{- define "config.processors.attributes.k8sattributes" -}}
k8sattributes:
  extract:
    metadata:
      - k8s.namespace.name
      - k8s.deployment.name
      - k8s.replicaset.name
      - k8s.statefulset.name
      - k8s.daemonset.name
      - k8s.cronjob.name
      - k8s.job.name
      - k8s.node.name
      - k8s.node.uid
      - k8s.pod.name
      - k8s.pod.uid
      - k8s.cluster.uid
      - k8s.container.name
      - container.id
    labels:
      # Extract app.kubernetes.io/* labels from the pod as the full tag.
      - tag_name: $1
        key_regex: (app\.kubernetes\.io/.+)
        from: pod
      # Extract service.name from the pod's app.kubernetes.io/name label
      # TODO remove this when the `service_attributes.enabled` config is released
      # https://github.com/open-telemetry/opentelemetry-collector-contrib/pull/39335
      - tag_name: service.name
        key: app.kubernetes.io/name
        from: pod
    annotations:
      # TODO remove this when the `otel_annotations` config is released
      # https://github.com/open-telemetry/opentelemetry-collector-contrib/commit/6682df519bd87b8ce33afa83bc09e345f2f4fc6b
      - tag_name: $1
        key_regex: resource\.opentelemetry\.io/(.+)
        from: pod
  passthrough: false
  pod_association:
  - sources:
    - from: resource_attribute
      name: k8s.pod.ip
  - sources:
    - from: resource_attribute
      name: k8s.pod.uid
  - sources:
    - from: connection
{{- end -}}

{{- define "config.processors.resource.observe_common" -}}
resource/observe_common:
  attributes:
    - key: k8s.cluster.name
      action: upsert
      value: ${env:OBSERVE_CLUSTER_NAME}
    - key: k8s.cluster.uid
      action: upsert
      {{ if .Values.cluster.uidOverride.value -}}
      value:  {{ .Values.cluster.uidOverride.value }}
      {{ else -}}
      value:  ${env:OBSERVE_CLUSTER_UID}
      {{ end -}}
{{- end -}}

{{- define "config.processors.memory_limiter" -}}
# https://github.com/open-telemetry/opentelemetry-collector/blob/main/processor/memorylimiterprocessor/README.md
memory_limiter:
  # check_interval is the time between measurements of memory usage for the
  # purposes of avoiding going over the limits. Defaults to zero, so no
  # checks will be performed. Values below 1 second are not recommended since
  # it can result in unnecessary CPU consumption.
  check_interval: 5s
  # limit_percentage (default = 0): Maximum amount of total memory targeted to be allocated by the process heap.
  # This configuration is supported on Linux systems with cgroups and it's intended to be used in dynamic platforms like docker.
  # This option is used to calculate memory_limit from the total available memory.
  # For instance setting of 75% with the total memory of 1GiB will result in the limit of 750 MiB.
  # The fixed memory setting (limit_mib) takes precedence over the percentage configuration.
  limit_percentage: 90
  # spike_limit_percentage (default = 0): Maximum spike expected between the measurements of memory usage.
  # The value must be less than limit_percentage.
  # This option is used to calculate spike_limit_mib from the total available memory.
  # For instance setting of 25% with the total memory of 1GiB will result in the spike limit of 250MiB.
  # This option is intended to be used only with limit_percentage.
  spike_limit_percentage: 15
{{- end -}}

# This processor might edit the log body in-place, which might affect the output of transform/object.
# Therefore, this processor must always be placed before transform/object in the pipeline.
{{- define "config.processors.attributes.observek8sattributes" -}}
observek8sattributes:
{{- end -}}
