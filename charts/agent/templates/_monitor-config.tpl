{{- define "observe.deployment.agentMonitor.config" -}}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}

receivers:
  prometheus/collector:
        config:
          scrape_configs:
          - job_name: opentelemetry-collector-self
            scrape_interval: {{ .Values.agent.selfMonitor.metrics.scrapeInterval }}
            static_configs:
            - targets:
              - ${env:MY_POD_IP}:8888
          - job_name: opentelemetry-collector-other
            scrape_interval: {{ .Values.agent.selfMonitor.metrics.scrapeInterval }}
            honor_labels: true
            kubernetes_sd_configs:
            - role: pod
            relabel_configs:
            # select only those pods that has "observe_monitor_purpose: observecollection" annotation
            - source_labels: [__meta_kubernetes_pod_annotation_observe_monitor_purpose]
              action: keep
              regex: observecollection
            # select only those pods that has "observe_monitor_scrape: true" annotation
            - source_labels: [__meta_kubernetes_pod_annotation_observe_monitor_scrape]
              action: keep
              regex: true
              # set metrics_path (default is /metrics) to the metrics path specified in "prometheus.io/path: <metric path>" annotation.
            - source_labels: [__meta_kubernetes_pod_annotation_observe_monitor_path]
              action: replace
              target_label: __metrics_path__
              regex: (.+)
              # set the scrapping port to the port specified in "prometheus.io/port: <port>" annotation and set address accordingly.
            - source_labels: [__address__, __meta_kubernetes_pod_annotation_observe_monitor_port]
              action: replace
              regex: ([^:]+)(?::\d+)?;(\d+)
              replacement: $$1:$$2
              target_label: __address__
            - action: labelmap
              regex: __meta_kubernetes_pod_label_(.+)
            - source_labels: [__meta_kubernetes_namespace]
              action: replace
              target_label: kubernetes_namespace
            - source_labels: [__meta_kubernetes_pod_name]
              action: replace
              target_label: kubernetes_pod_name


processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}

{{- include "config.processors.resource.observe_common" . | nindent 2 }}

  # attributes to append to objects
  attributes/debug_source_agent_monitor:
    actions:
      - key: debug_source
        action: insert
        value: agent_monitor

{{- $metricsExporters := (list "prometheusremotewrite/observe") -}}

{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $metricsExporters = concat $metricsExporters ( list "debug/override" ) | uniq }}
{{- end }}

service:
  pipelines:
      metrics:
        receivers: [prometheus/collector]
        processors: [memory_limiter, k8sattributes, batch, resource/observe_common, attributes/debug_source_agent_monitor]
        exporters: [{{ join ", " $metricsExporters }}]
{{- include "config.service.telemetry" . | nindent 2 }}

 {{- end }}
