{{- define "config.processors.resource_detection.cloud" -}}
{{- $detectors := .Values.agent.config.global.processors.cloudResourceDetection.detectors -}}
resourcedetection/cloud:
  detectors:
    {{- range $detectors }}
    - {{ . }}
    {{- end }}
  {{- if has "eks" $detectors }}
  eks:
    node_from_env_var: K8S_NODE_NAME
  {{- end }}
  timeout: 2s
  override: false
{{- end -}}

{{- define "config.processors.resource_detection" -}}
resourcedetection:
  detectors: ["env", "system"]
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

{{- define "config.processors.cumulativetodelta" -}}
cumulativetodelta/observe:
  max_staleness: 5m
{{- end -}}

{{- define "config.processors.attributes.k8sattributes" -}}
k8sattributes:
  {{ if (and (eq .filterToNode true) (eq .Values.agent.config.global.processors.k8sattributesNodeOnlyDaemonset true)) }}
  filter:
    node_from_env_var: K8S_NODE_NAME
  {{ end }}
  wait_for_metadata: {{ .Values.cluster.metadata.waitForInitialPoll }}
  wait_for_metadata_timeout: {{ .Values.cluster.metadata.waitForInitialPollTimeout }}
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
    - key: deployment.environment
      action: upsert
      value: {{ .Values.cluster.deploymentEnvironment.name }}
    {{ end }}
{{- end -}}

{{- define "config.processors.resource.fargate_resource_attributes" -}}
resource/fargate_resource_attributes:
  attributes:
    - key: k8s.pod.uid
      action: upsert
      value: ${env:OTEL_K8S_POD_UID}
    - key: k8s.pod.ip
      action: upsert
      value: ${env:OTEL_K8S_POD_IP}
    {{- if and .Values.nodeless.logs.enabled (not .Values.nodeless.logs.containerNameFromFile) }}
    - key: k8s.container.name
      value: ${file:/applogs/app-container-name.txt}
      action: upsert
    {{- end }}
{{- end -}}

{{- define "config.processors.groupbyattrs.log_file" -}}
groupbyattrs/log_file:
  keys:
    - log.file.path
{{- end -}}

{{- define "config.processors.transform.add_resource_container_name" -}}
transform/add_resource_container_name:
  error_mode: ignore
  log_statements:
    - context: resource
      statements:
      # Extract filename from path (no path, no extension) using regex
      - set(attributes["k8s.container.name"], attributes["log.file.path"])
      - replace_pattern(attributes["k8s.container.name"], "^(?:.*/)?([^/]+)\\..*$", "$$1")
{{- end -}}


{{- define "config.processors.resource.agent_instance" -}}
resource/agent_instance:
    attributes:
        - key: k8s.pod.uid
          value: ${env:OTEL_K8S_POD_UID}
          action: upsert
        - key: k8s.pod.name
          value: ${env:OTEL_K8S_POD_NAME}
          action: upsert
{{- end -}}

{{- define "config.processors.transform.k8sheartbeat" -}}
transform/k8sheartbeat:
  error_mode: ignore
  log_statements:
    - context: log
      statements:
        - set(attributes["observe_transform"]["identifiers"]["host.name"], resource.attributes["k8s.node.name"])
        - set(attributes["observe_transform"]["identifiers"]["k8s.pod.uid"], resource.attributes["k8s.pod.uid"])
        - set(attributes["observe_transform"]["identifiers"]["k8s.pod.name"], resource.attributes["k8s.pod.name"])
        - set(attributes["observe_transform"]["identifiers"]["k8s.deployment.name"], resource.attributes["k8s.deployment.name"])
        - set(attributes["observe_transform"]["identifiers"]["k8s.daemonset.name"], resource.attributes["k8s.daemonset.name"])
        - set(attributes["observe_transform"]["identifiers"]["deployment.environment.name"], resource.attributes["deployment.environment.name"])
        - set(attributes["observe_transform"]["identifiers"]["k8s.cluster.uid"], resource.attributes["k8s.cluster.uid"])
        - set(attributes["observe_transform"]["identifiers"]["k8s.cluster.name"], resource.attributes["k8s.cluster.name"])
        - set(attributes["observe_transform"]["identifiers"]["k8s.namespace.name"], resource.attributes["k8s.namespace.name"])
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

{{- define "config.processors.attributes.fargate_pod_logs" -}}
  attributes/debug_source_fargate_pod_logs:
    actions:
      - key: debug_source
        action: insert
        value: fargate_pod_logs
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

{{/*
  Merged-pipeline replacement for the legacy attributes/debug_source_* +
  drop_service_name pair. One OTTL pass:
    1. Stamp debug_source by service.name (rewrite-safe — cadvisor emits
       no target_info series, so service.name isn't overwritten).
    2. Drop service.name on non-cadvisor jobs so k8sattributes re-populates
       it from pod labels. Cadvisor has no pod_association source, so its
       service.name survives as "kubernetes-nodes-cadvisor" (matching the
       legacy cadvisor pipeline, which never ran drop_service_name).
*/}}
{{- define "config.processors.transform.set_debug_source" -}}
transform/set_debug_source:
  error_mode: ignore
  metric_statements:
    - context: resource
      statements:
        - set(attributes["debug_source"], "cadvisor_metrics") where attributes["service.name"] == "kubernetes-nodes-cadvisor"
        - set(attributes["debug_source"], "pod_metrics") where attributes["service.name"] != "kubernetes-nodes-cadvisor"
        - delete_key(attributes, "service.name") where attributes["service.name"] != "kubernetes-nodes-cadvisor"
{{- end -}}

{{- define "config.processors.attributes.sidecar_kubeletstats_metrics" -}}
attributes/debug_source_sidecar_kubeletstats_metrics:
  actions:
    - key: debug_source
      action: insert
      value: sidecar_kubeletstats_metrics
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

{{- define "config.processors.metricstransform.duplicate_k8s_cpu_metrics" -}}
# convert new k8s metric names to the names our Kubernetes Explorer relies on
metricstransform/duplicate_k8s_cpu_metrics:
  transforms:
    - include: container.cpu.usage
      action: insert
      new_name: container.cpu.utilization
    - include: k8s.pod.cpu.usage
      action: insert
      new_name: k8s.pod.cpu.utilization
    - include: k8s.node.cpu.usage
      action: insert
      new_name: k8s.node.cpu.utilization
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

{{- define "config.processors.transform.add_empty_service_attributes" -}}
# Normalizes deployment environment (coalescing from the deprecated `deployment.environment`
# onto `deployment.environment.name` and vice versa) and defaults the service / environment resource
# attributes so they can be referenced as spanmetrics dimensions and in Observe even when the instrumentation
# did not supply them.
transform/add_empty_service_attributes:
  error_mode: ignore
  trace_statements:
    - set(resource.attributes["deployment.environment.name"], Coalesce([resource.attributes["deployment.environment.name"], resource.attributes["deployment.environment"]]))
    - set(resource.attributes["deployment.environment"], Coalesce([resource.attributes["deployment.environment"], resource.attributes["deployment.environment.name"]]))
    # Default any still-missing attributes to an empty string.
    - set(resource.attributes["service.name"], "") where resource.attributes["service.name"] == nil
    - set(resource.attributes["service.namespace"], "") where resource.attributes["service.namespace"] == nil
    - set(resource.attributes["deployment.environment.name"], "") where resource.attributes["deployment.environment.name"] == nil
    - set(resource.attributes["deployment.environment"], "") where resource.attributes["deployment.environment"] == nil
{{- end -}}

{{- define "config.processors.transform.deployment_environment_compatibility" -}}
{{- if not .Values.cluster.deploymentEnvironment.name }}
transform/deployment_environment_compatability:
  error_mode: ignore
  trace_statements:
    - set(resource.attributes["deployment.environment.name"], Coalesce([resource.attributes["deployment.environment.name"], resource.attributes["deployment.environment"]]))
    - set(resource.attributes["deployment.environment"], Coalesce([resource.attributes["deployment.environment"], resource.attributes["deployment.environment.name"]]))
  log_statements:
    - set(resource.attributes["deployment.environment.name"], Coalesce([resource.attributes["deployment.environment.name"], resource.attributes["deployment.environment"]]))
    - set(resource.attributes["deployment.environment"], Coalesce([resource.attributes["deployment.environment"], resource.attributes["deployment.environment.name"]]))
  metric_statements:
    - set(resource.attributes["deployment.environment.name"], Coalesce([resource.attributes["deployment.environment.name"], resource.attributes["deployment.environment"]]))
    - set(resource.attributes["deployment.environment"], Coalesce([resource.attributes["deployment.environment"], resource.attributes["deployment.environment.name"]]))
{{- end }}
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
    - set(span.attributes["peer.db.name"], Coalesce([span.attributes["peer.db.name"], span.attributes["db.system.name"], span.attributes["db.system"]]))
    - set(span.attributes["peer.messaging.system"], Coalesce([span.attributes["peer.messaging.system"], span.attributes["messaging.system"]]))
    # Needed because `spanmetrics` connector can only operate on attributes or resource attributes.
    - set(span.attributes["otel.status_description"], span.status.message) where span.status.message != ""

# Regroups spans by the peer attributes (moving them from span attributes onto the resource) so that
# transform/promote_peer_to_service can override the resource-level service.name once per peer system.
# transform/promote_peer_to_service moves them back onto each span afterwards.
groupbyattrs/peers:
  keys:
    - peer.db.name
    - peer.messaging.system

# Sets `service.name` to `peer.db.name` (or `peer.messaging.system`) when present, then moves
# the peer attributes back from the resource onto each span. Explicit `context:` blocks ensure
# resource-scoped statements run once per resource (not once per span).
transform/promote_peer_to_service:
  error_mode: ignore
  trace_statements:
    - context: resource
      statements:
        # service.name = peer.db.name if peer.db.name != nil
        - set(attributes["service.name"], attributes["peer.db.name"]) where attributes["peer.db.name"] != nil
        # service.name = peer.messaging.system if peer.messaging.system != nil and peer.db.name == nil
        - set(attributes["service.name"], attributes["peer.messaging.system"]) where attributes["peer.messaging.system"] != nil and attributes["peer.db.name"] == nil
    - context: span
      statements:
        # Move peer.* back onto each span's own attributes.
        - set(attributes["peer.db.name"], resource.attributes["peer.db.name"]) where resource.attributes["peer.db.name"] != nil
        - set(attributes["peer.messaging.system"], resource.attributes["peer.messaging.system"]) where resource.attributes["peer.messaging.system"] != nil
    - context: resource
      statements:
        # Delete peer.* from the resource AFTER all spans have copied them locally.
        - delete_key(attributes, "peer.db.name")
        - delete_key(attributes, "peer.messaging.system")

# This removes service.name for generated RED metrics associated with peer systems.
transform/remove_service_name_for_peer_metrics:
  error_mode: ignore
  metric_statements:
    - delete_key(resource.attributes, "service.name") where datapoint.attributes["peer.db.name"] != nil or datapoint.attributes["peer.messaging.system"] != nil

# This drops spans (and thus RED metric data) for span kinds that are not relevant to the Observe APM offering. If you use RED metrics outside of APM,
# then we recommend disabling this filter and generating RED metrics for all span kinds.
# NB: connectors/routing/red_metrics_internal encodes the inverse of this filter on the metrics side. Keep the two in sync.
filter/drop_non_apm_spans:
  error_mode: ignore
  traces:
    span:
      # We are keeping: all SERVER spans, all CONSUMER spans, CLIENT spans with a peer db, and PRODUCER spans with a peer messaging system.
      - span.kind == SPAN_KIND_CLIENT and span.attributes["peer.db.name"] == nil and span.attributes["db.system.name"] == nil and span.attributes["db.system"] == nil
      - span.kind == SPAN_KIND_PRODUCER and span.attributes["peer.messaging.system"] == nil and span.attributes["messaging.system"] == nil
      - span.kind == SPAN_KIND_UNSPECIFIED
      - span.kind == SPAN_KIND_INTERNAL

# The spanmetrics connector puts all dimensions as attributes on the datapoint, and copies the resource attributes from an arbitrary span's resource. This cleans that up as well as handling any other renaming.
{{ include "config.processors.RED_metrics.fix_resource_attributes" (dict
    "name" "transform/fix_red_metrics_resource_attributes"
    "resourceDims" .Values.application.REDMetrics.resourceDimensions) }}

{{ include "config.processors.RED_metrics.fix_resource_attributes" (dict
    "name" "transform/fix_red_metrics_resource_attributes/summary"
    "resourceDims" .Values.application.REDMetrics.summaryMetrics.resourceDimensions) }}

{{ include "config.processors.RED_metrics.rename_metrics" (dict
    "name" "metricstransform/rename_summary_metrics"
    "suffix" "summary") }}

{{- if not .Values.application.REDMetrics.onlyGenerateForAPMSpans }}
# Renames RED metrics from non-entrypoint (would-have-been-dropped) spans with an ".internal"
# suffix. This processor lives on the metrics/spanmetrics/internal pipeline, downstream of
# routing/red_metrics_internal, so every datapoint it sees is already known to be "internal".
{{ include "config.processors.RED_metrics.rename_metrics" (dict
    "name" "metricstransform/rename_internal_metrics"
    "suffix" "internal") }}
{{- end }}
{{- end -}}

{{- /*
Emits a transform processor that prunes spanmetrics resource/datapoint attributes
to the configured dimension set and normalizes status.code -> otel.status_code.
Parameters (passed via dict):
  name         - processor name (e.g. "transform/fix_red_metrics_resource_attributes")
  resourceDims - list of resource attribute dimensions (service.name auto-prepended)
*/ -}}
{{- define "config.processors.RED_metrics.fix_resource_attributes" -}}
{{- $name := .name -}}
{{- $dims := (prepend .resourceDims "service.name" | uniq) -}}
{{ $name }}:
  error_mode: ignore
  metric_statements:
    # Drop all resource attributes that aren't dimensions in the spanmetrics connector.
    - keep_matching_keys(resource.attributes, "^({{ join "|" $dims }})")

    # Drop all datapoint attributes that are resource attributes in the spans.
    - delete_matching_keys(datapoint.attributes, "^({{ join "|" $dims }})")

    # Rename status.code to otel.status_code for updated semantic conventions.
    - set(datapoint.attributes["otel.status_code"], "OK") where datapoint.attributes["status.code"] == "STATUS_CODE_OK"
    - set(datapoint.attributes["otel.status_code"], "ERROR") where datapoint.attributes["status.code"] == "STATUS_CODE_ERROR"
    - delete_key(datapoint.attributes, "status.code")
{{- end -}}

{{- /*
Emits a metricstransform processor that renames the spanmetrics call+duration metrics
with a configurable suffix (e.g. "summary", "internal").
Parameters (passed via dict):
  name   - processor name (e.g. "metricstransform/rename_summary_metrics")
  suffix - suffix appended to the metric names (e.g. "summary")
*/ -}}
{{- define "config.processors.RED_metrics.rename_metrics" -}}
{{- $name := .name -}}
{{- $suffix := .suffix -}}
{{ $name }}:
  transforms:
    - include: traces.span.metrics.calls
      action: update
      new_name: traces.span.metrics.calls.{{ $suffix }}
    - include: traces.span.metrics.duration
      action: update
      new_name: traces.span.metrics.duration.{{ $suffix }}
{{- end -}}
