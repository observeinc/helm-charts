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
      {{- if ne .target "cluster_metrics" }}
      - container.id
      {{- end }}
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
    {{ if .Values.cluster.deploymentEnvironment.name }}
    - key: deployment.environment.name
      action: upsert
      value: {{ .Values.cluster.deploymentEnvironment.name }}
    {{ end }}
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

{{- define "config.processors.attributes.cadvisor_metrics" -}}
{{- if .Values.node.metrics.cadvisor.enabled }}
attributes/debug_source_cadvisor_metrics:
  actions:
    - key: debug_source
      action: insert
      value: cadvisor_metrics
{{- end -}}
{{- end -}}

{{- define "config.processors.attributes.drop_container_info" -}}
resource/drop_container_info:
  attributes:
    - key: container.id
      action: delete
{{- end -}}

{{- define "config.processors.attributes.drop_service_name" -}}
resource/drop_service_name:
  attributes:
    - action: delete
      key: service.name
{{- end -}}

{{- define "config.processors.filter.drop_long_spans" -}}
{{- if eq .Values.node.forwarder.traces.maxSpanDuration "none" }}
{{- else if (regexMatch "^[0-9]+(ns|us|ms|s|m|h)$" .Values.node.forwarder.traces.maxSpanDuration) }}
# This drops spans that are longer than the configured time (default 1hr) to match service explorer behavior.
filter/drop_long_spans:
  error_mode: ignore
  traces:
    span:
      - (span.end_time - span.start_time) > Duration("{{ .Values.node.forwarder.traces.maxSpanDuration }}")
{{- else }}
{{- fail "Invalid maxSpanDuration for forwarder red metrics, valid values are 'none' or a number with a valid time unit: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/pkg/ottl/ottlfuncs/README.md#duration" }}
{{- end }}
{{- end -}}

{{- define "config.processors.attributes.add_empty_service_attributes" -}}
resource/add_empty_service_attributes:
    attributes:
        - action: insert
          key: service.name
          value: ""
        - action: insert
          key: service.namespace
          value: ""
        - action: insert
          key: deployment.environment
          value: ""
{{- end -}}

{{- define "config.processors.transform.add_span_status_code" -}}
transform/add_span_status_code:
  error_mode: ignore
  trace_statements:
    - set(span.attributes["observe.status_code"], Int(span.attributes["rpc.grpc.status_code"])) where span.attributes["observe.status_code"] == nil and span.attributes["rpc.grpc.status_code"] != nil
    - set(span.attributes["observe.status_code"], Int(span.attributes["grpc.status_code"])) where span.attributes["observe.status_code"] == nil and span.attributes["grpc.status_code"] != nil
    - set(span.attributes["observe.status_code"], Int(span.attributes["rpc.status_code"])) where span.attributes["observe.status_code"] == nil and span.attributes["rpc.status_code"] != nil
    - set(span.attributes["observe.status_code"], Int(span.attributes["http.status_code"])) where span.attributes["observe.status_code"] == nil and span.attributes["http.status_code"] != nil
    - set(span.attributes["observe.status_code"], Int(span.attributes["http.response.status_code"])) where span.attributes["observe.status_code"] == nil and span.attributes["http.response.status_code"] != nil
{{- end -}}

{{- define "config.processors.RED_metrics" -}}

attributes/debug_source_span_metrics:
  actions:
    - action: insert
      key: debug_source
      value: span_metrics

# This handles schema normalization as well as moving status to attributes so it can be a dimension in spanmetrics
transform/shape_spans_for_red_metrics:
  error_mode: ignore
  trace_statements:
    # peer.db.name = coalesce(peer.db.name, db.system.name, db.system)
    - set(span.attributes["peer.db.name"], span.attributes["db.system.name"]) where span.attributes["peer.db.name"] == nil and span.attributes["db.system.name"] != nil
    - set(span.attributes["peer.db.name"], span.attributes["db.system"]) where span.attributes["peer.db.name"] == nil and span.attributes["db.system"] != nil
    # deployment.environment = coalesce(deployment.environment, deployment.environment.name)
    - set(resource.attributes["deployment.environment"], resource.attributes["deployment.environment.name"]) where resource.attributes["deployment.environment"] == nil and resource.attributes["deployment.environment.name"] != nil
    # Needed because `spanmetrics` connector can only operate on attributes or resource attributes.
    - set(span.attributes["otel.status_description"], span.status.message) where span.status.message != ""

# This regroups the metrics by the peer attributes so we can remove `service.name` from the resource when these metric attributes are present
# NB: these will be deleted from the metric attributes and added to the resource.
groupbyattrs/peers:
  keys:
    - peer.db.name
    - peer.messaging.system

# This puts moves the peer attributes from the resource back to the datapoint after we have regrouped the metrics.
transform/fix_peer_attributes:
  error_mode: ignore
  metric_statements:
    - set(datapoint.attributes["peer.db.name"], resource.attributes["peer.db.name"]) where resource.attributes["peer.db.name"] != nil
    - set(datapoint.attributes["peer.messaging.system"], resource.attributes["peer.messaging.system"]) where resource.attributes["peer.messaging.system"] != nil

# This removes service.name for generated RED metrics associated with peer systems.
transform/remove_service_name_for_peer_metrics:
  error_mode: ignore
  metric_statements:
    - delete_key(resource.attributes, "service.name") where datapoint.attributes["peer.db.name"] != nil or datapoint.attributes["peer.messaging.system"] != nil

{{- if .Values.application.REDMetrics.onlyGenerateForServiceEntrypointSpans }}
# This drops spans (and thus RED metric data) for span kinds that are not relevant to the Observe APM offering. If you use RED metrics outside of APM,
# then we recommend disabling this filter and generating RED metrics for all span kinds.
filter/drop_span_kinds_other_than_server_and_consumer_and_peer_client:
  error_mode: ignore
  traces:
    span:
      - span.kind == SPAN_KIND_CLIENT and span.attributes["peer.messaging.system"] == nil and span.attributes["peer.db.name"] == nil and span.attributes["db.system.name"] == nil and span.attributes["db.system"] == nil
      - span.kind == SPAN_KIND_UNSPECIFIED
      - span.kind == SPAN_KIND_INTERNAL
      - span.kind == SPAN_KIND_PRODUCER
{{- end }}

{{- $resourceDims := (prepend .Values.application.REDMetrics.resourceDimensions "service.name" | uniq) }}

# The spanmetrics connector puts all dimensions as attributes on the datapoint, and copies the resource attributes from an arbitrary span's resource. This cleans that up as well as handling any other renaming.
transform/fix_red_metrics_resource_attributes:
  error_mode: ignore
  metric_statements:
    # Drop all resource attributes that aren't dimensions in the spanmetrics connector.
    - keep_matching_keys(resource.attributes, "^({{ join "|" $resourceDims }})")

    # Drop all datapoint attributes that are resource attributes in the spans.
    - delete_matching_keys(datapoint.attributes, "^({{ join "|" $resourceDims }})")

    # Rename status.code to response_status to be consistent with Trace Explorer and disambiguate from status_code (with an underscore).
    - set(datapoint.attributes["otel.status_code"], "OK") where datapoint.attributes["status.code"] == "STATUS_CODE_OK"
    - set(datapoint.attributes["otel.status_code"], "ERROR") where datapoint.attributes["status.code"] == "STATUS_CODE_ERROR"
    - delete_key(datapoint.attributes, "status.code")
{{- end -}}
