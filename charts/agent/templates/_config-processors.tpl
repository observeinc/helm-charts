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
  timeout: {{ .Values.agent.config.global.processors.batch.timeout }}
{{- end -}}

{{- define "config.processors.deltatocumulative" -}}
deltatocumulative/observe:
  max_stale: 5m
{{- end -}}

{{- define "config.processors.attributes.k8sattributes" -}}
k8sattributes:
  extract:
    otel_annotations: true
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
      - service.namespace
      - service.name
      - service.version
      - service.instance.id
    labels:
      # Extract app.kubernetes.io/* labels from the pod as the full tag.
      - tag_name: $1
        key_regex: (app\.kubernetes\.io/.+)
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
  check_interval: 5s
  # GOMEMLIMIT gets automatically set to 80% of the Kube resources so this should be 80% total as well
  limit_percentage: 80
  spike_limit_percentage: 15
{{- end -}}

{{- define "config.processors.attributes.observek8sattributes" -}}
# This processor might edit the log body in-place, which might affect the output of transform/object.
# Therefore, this processor must always be placed before transform/object in the pipeline.
observek8sattributes:
{{- end -}}

{{- define "config.processors.attributes.pod_metrics" -}}
attributes/debug_source_pod_metrics:
  actions:
    - key: debug_source
      action: insert
      value: pod_metrics
{{- end -}}
