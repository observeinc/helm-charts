{{- define "config.pipelines.RED_metrics" -}}
{{- $tracesSpanmetricsExporters := (list "spanmetrics") -}}
{{- $metricsSpanmetricsExporters := (list "otlphttp/observe/otel_metrics") -}}
{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $tracesSpanmetricsExporters = concat $tracesSpanmetricsExporters ( list "debug/override" ) | uniq }}
  {{- $metricsSpanmetricsExporters = concat $metricsSpanmetricsExporters ( list "debug/override" ) | uniq }}
{{- end }}

traces/spanmetrics:
  receivers:
    - otlp/app-telemetry
  processors:
    - memory_limiter
    {{- if ne .Values.node.forwarder.traces.maxSpanDuration "none" }}
    - filter/drop_long_spans
    {{- end }}
    {{- if .Values.application.REDMetrics.onlyGenerateForServiceEntrypointSpans }}
    # See comment on filter definition.
    - filter/drop_span_kinds_other_than_server_and_consumer_and_peer_client
    {{- end }}
    - transform/shape_spans_for_red_metrics
    - transform/add_span_status_code
    - resource/add_empty_service_attributes
    - k8sattributes
  exporters: [{{ join ", " $tracesSpanmetricsExporters }}]
metrics/spanmetrics:
  receivers:
    - spanmetrics
  processors:
    - memory_limiter
    - groupbyattrs/peers
    - transform/fix_peer_attributes
    - transform/remove_service_name_for_peer_metrics
    - transform/fix_red_metrics_resource_attributes
    {{- if not .Values.agent.config.global.exporters.sendingQueue.batch.enabled }}
    - batch
    {{- end }}
    - resource/observe_common
    - attributes/debug_source_span_metrics
  exporters: [{{ join ", " $metricsSpanmetricsExporters }}]
{{- end -}}

{{- define "config.pipelines.prometheus_scrapers" -}}
{{- $merged := not .Values.node.metrics.cadvisor.separate_pipeline }}
{{- if $merged }}

{{- /* Merged-pipeline path: pod-metrics and cadvisor scrape jobs share a
       single receiver AND a single downstream pipeline. debug_source is set
       per-datapoint by transform/set_debug_source based on the datapoint's
       resource.service.name, eliminating the fan-out cost of routing through
       two parallel pipelines. */}}
metrics/k8s_metrics:
  receivers: [prometheus/k8s_metrics]
  processors:
    - memory_limiter
    - transform/set_debug_source
    - k8sattributes
    {{- if not .Values.agent.config.global.exporters.sendingQueue.batch.enabled }}
    - batch
    {{- end }}
    - resource/observe_common
  exporters:
    - prometheusremotewrite/observe
    {{- if eq .Values.agent.config.global.debug.enabled true }}
    - debug/override
    {{- end }}

{{- else }}

metrics/pod_metrics:
  receivers: [prometheus/pod_metrics]
  # Drop the service.name resource attribute (which is set to the prom scrape job name) before the k8sattributes processor
  processors:
    - memory_limiter
    - resource/drop_service_name
    - k8sattributes
    {{- if not .Values.agent.config.global.exporters.sendingQueue.batch.enabled }}
    - batch
    {{- end }}
    - resource/observe_common
    {{- if not .Values.cluster.deploymentEnvironment.name }}
    - transform/deployment_environment_compatability
    {{- end }}
    - attributes/debug_source_pod_metrics
  exporters:
    - prometheusremotewrite/observe
    {{- if eq .Values.agent.config.global.debug.enabled true }}
    - debug/override
    {{- end }}

{{- if .Values.node.metrics.cadvisor.enabled }}
metrics/cadvisor:
  receivers: [prometheus/cadvisor]
  processors:
    - memory_limiter
    - k8sattributes
    {{- if not .Values.agent.config.global.exporters.sendingQueue.batch.enabled }}
    - batch
    {{- end }}
    - resource/observe_common
    - attributes/debug_source_cadvisor_metrics
  exporters:
    - prometheusremotewrite/observe
    {{- if eq .Values.agent.config.global.debug.enabled true }}
    - debug/override
    {{- end }}
{{- end }}

{{- end }}

{{- end }}

{{- define "config.pipelines.heartbeat" -}}
logs/heartbeat:
    exporters:
      - otlphttp/observe/agentheartbeat
      {{- if .Values.agent.config.global.debug.enabled }}
      - debug/override
      {{- end }}
    processors:
        - resourcedetection
        - resource/agent_instance
        - k8sattributes
        - resource/observe_common
        - transform/k8sheartbeat
    receivers:
        - heartbeat
{{- end }}
