{{- define "config.pipelines.RED_metrics" -}}

traces/spanmetrics:
  receivers:
    - otlp/app-telemetry
  processors:
    - memory_limiter
    {{- if ne .Values.node.forwarder.traces.maxSpanDuration "none" }}
    - filter/drop_long_spans
    {{- end }}
    {{- if .Values.application.REDMetrics.onlyGenerateForAPMSpans }}
    - filter/drop_non_apm_spans
    {{- end }}
    - k8sattributes
    - transform/shape_spans_for_red_metrics
    - transform/add_span_status_code
    - groupbyattrs/peers
    - transform/promote_peer_to_service
    - transform/add_empty_service_attributes
  exporters:
    - spanmetrics
    {{- if .Values.application.REDMetrics.onlyGenerateForAPMSpans }}
    - spanmetrics/summary
    {{- else }}
    # When onlyGenerateForAPMSpans is off, the main pipeline includes non-APM spans.
    # The summary connector must only see APM spans, so we forward through an intermediate
    # pipeline that applies filter/drop_non_apm_spans before feeding spanmetrics/summary.
    - forward/red_metrics_summary
    {{- end }}
    {{- if eq .Values.agent.config.global.debug.enabled true }}
    - debug/override
    {{- end }}
metrics/spanmetrics:
  receivers:
    - spanmetrics
  processors:
    - memory_limiter
    - transform/remove_service_name_for_peer_metrics
    - transform/fix_red_metrics_resource_attributes
    {{- if not .Values.agent.config.global.exporters.sendingQueue.batch.enabled }}
    - batch
    {{- end }}
    - resource/observe_common
    - attributes/debug_source_span_metrics
  exporters:
    {{- if .Values.application.REDMetrics.onlyGenerateForAPMSpans }}
    - otlphttp/observe/otel_metrics
    {{- else }}
    # When onlyGenerateForAPMSpans is off, RED metrics are generated for span
    # kinds that would otherwise be dropped. Route them so the "internal" kinds can be renamed
    # with an ".internal" suffix; entrypoint kinds pass through the default pipeline unchanged.
    - routing/red_metrics_internal
    {{- end }}
    {{- if eq .Values.agent.config.global.debug.enabled true }}
    - debug/override
    {{- end }}
{{- if not .Values.application.REDMetrics.onlyGenerateForAPMSpans }}
metrics/spanmetrics/default:
  receivers:
    - routing/red_metrics_internal
  processors:
    - memory_limiter
  exporters:
    - otlphttp/observe/otel_metrics
    {{- if eq .Values.agent.config.global.debug.enabled true }}
    - debug/override
    {{- end }}
metrics/spanmetrics/internal:
  receivers:
    - routing/red_metrics_internal
  processors:
    - memory_limiter
    - metricstransform/rename_internal_metrics
  exporters:
    - otlphttp/observe/otel_metrics
    {{- if eq .Values.agent.config.global.debug.enabled true }}
    - debug/override
    {{- end }}
# Intermediate pipeline: filters non-APM spans before feeding the summary connector.
traces/spanmetrics/summary/filter:
  receivers:
    - forward/red_metrics_summary
  processors:
    - memory_limiter
    - filter/drop_non_apm_spans
  exporters:
    - spanmetrics/summary
    {{- if eq .Values.agent.config.global.debug.enabled true }}
    - debug/override
    {{- end }}
{{- end }}
metrics/spanmetrics/summary:
  receivers:
    - spanmetrics/summary
  processors:
    - memory_limiter
    - transform/remove_service_name_for_peer_metrics
    - transform/fix_red_metrics_resource_attributes/summary
    - metricstransform/rename_summary_metrics
    {{- if not .Values.agent.config.global.exporters.sendingQueue.batch.enabled }}
    - batch
    {{- end }}
    - resource/observe_common
  exporters:
    - otlphttp/observe/otel_metrics
    {{- if eq .Values.agent.config.global.debug.enabled true }}
    - debug/override
    {{- end }}
{{- end -}}

{{- define "config.pipelines.prometheus_scrapers" -}}
{{- $merged := not .Values.node.metrics.cadvisor.separate_pipeline }}
{{- if $merged }}

{{- /* Merged path: pod-metrics + cadvisor share one receiver and one
       pipeline; transform/set_debug_source stamps debug_source per
       datapoint by service.name instead of fanning out to two pipelines. */}}
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
