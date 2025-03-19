{{- define "observe.deployment.clusterMetrics.config" -}}

extensions:
{{- include "config.extensions.health_check" . | nindent 2 }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{- include "config.exporters.prometheusremotewrite" . | nindent 2 }}

receivers:
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/k8sclusterreceiver/documentation.md
  k8s_cluster:
    collection_interval: {{.Values.cluster.metrics.interval}}
    metadata_collection_interval: 5m
    auth_type: serviceAccount
    node_conditions_to_report:
    - Ready
    - MemoryPressure
    - DiskPressure
    allocatable_types_to_report:
    - cpu
    - memory
    - storage
    - ephemeral-storage
    # defaults and optional - https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/k8sclusterreceiver/documentation.md
    metrics:
      k8s.node.condition:
        enabled: true

  {{- if .Values.application.prometheusScrape.enabled }}
  prometheus/pod_metrics:
    config:
      scrape_configs:
      - job_name: pod-metrics
        scrape_interval: {{.Values.application.prometheusScrape.interval}}
        honor_labels: true
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        # this is defaulted to keep so we start with everything
        - action: keep

        # Drop anything matching the configured namespace.
        - action: 'drop'
          source_labels: ['__meta_kubernetes_namespace']
          regex: {{.Values.application.prometheusScrape.namespaceDropRegex}}

        # Drop anything not matching the configured namespace.
        - action: 'keep'
          source_labels: ['__meta_kubernetes_namespace']
          regex: {{.Values.application.prometheusScrape.namespaceKeepRegex}}

        # Drop endpoints without one of: a port name suffixed with the configured regex, or an explicit prometheus port annotation.
        - action: 'keep'
          source_labels: ['__meta_kubernetes_pod_container_port_name', '__meta_kubernetes_pod_annotation_prometheus_io_port']
          regex: '({{.Values.application.prometheusScrape.portKeepRegex}};|.*;\d+)'

        # Drop pods with phase Succeeded or Failed.
        - action: 'drop'
          regex: 'Succeeded|Failed'
          source_labels: ['__meta_kubernetes_pod_phase']

        ################################################################
        # Drop anything annotated with 'observeinc.com.scrape=false' or 'observeinc_com_scrape=false' .
        - action: 'drop'
          regex: 'false'
          source_labels: ['__meta_kubernetes_pod_annotation_observeinc_com_scrape']

        ################################################################
        # Prometheus Configs
        # Drop anything annotated with 'prometheus.io.scrape=false'.
        - action: 'drop'
          regex: 'false'
          source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_scrape']

        # Allow pods to override the scrape scheme with 'prometheus.io.scheme=https'.
        - action: 'replace'
          regex: '(https?)'
          replacement: '$1'
          source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_scheme']
          target_label: '__scheme__'

        # Allow service to override the scrape path with 'prometheus.io.path=/other_metrics_path'.
        - action: 'replace'
          regex: '(.+)'
          replacement: '$1'
          source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_path']
          target_label: '__metrics_path__'

        # Allow services to override the scrape port with 'prometheus.io.port=1234'.
        - action: 'replace'
          regex: '(.+?)(\:\d+)?;(\d+)'
          replacement: '$1:$3'
          source_labels: ['__address__', '__meta_kubernetes_pod_annotation_prometheus_io_port']
          target_label: '__address__'


        ################################################################

        #podAnnotations: {
        #  observeinc_com_scrape: 'true',
        #  observeinc_com_path: '/metrics',
        #  observeinc_com_port: '8080',
        #}

        # set metrics_path (default is /metrics) to the metrics path specified in "observeinc_com_path: <metric path>" annotation.
        - source_labels: [__meta_kubernetes_pod_annotation_observeinc_com_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)

        # set the scrapping port to the port specified in "observeinc_com_port: <port>" annotation and set address accordingly.
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_observeinc_com_port]
          action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: '$1:$2'
          target_label: __address__
        ################################################################

        metric_relabel_configs:
          - action: drop
            regex: {{.Values.application.prometheusScrape.metricDropRegex}}
            source_labels:
              - __name__
          - action: keep
            regex: {{.Values.application.prometheusScrape.metricKeepRegex}}
            source_labels:
              - __name__
  {{ end }}

processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.k8sattributes" . | nindent 2 }}

{{- include "config.processors.resource.observe_common" . | nindent 2 }}
  resource/drop_additional_pod_metrics_labels:
    attributes:
    - key: http.scheme
      action: delete
    - key: net.host.name
      action: delete
    - key: net.host.port
      action: delete
    - key: server.address
      action: delete
    - key: server.port
      action: delete
    - key: service.instance.id
      action: delete
    - key: url.scheme
      action: delete
    - key: instance
      action: delete
    - key: k8s.pod.uid
      action: delete
    - key: job
      action: delete

  # attributes to append to objects
  attributes/debug_source_cluster_metrics:
    actions:
      - key: debug_source
        action: insert
        value: cluster_metrics
  attributes/debug_source_pod_metrics:
    actions:
      - key: debug_source
        action: insert
        value: pod_metrics

{{- $metricsExporters := (list "prometheusremotewrite/observe") -}}
{{- $podMetricsExporters := (list "prometheusremotewrite/observe") -}}

{{- if eq .Values.agent.config.global.debug.enabled true }}
  {{- $metricsExporters = concat $metricsExporters ( list "debug/override" ) | uniq }}
  {{- $podMetricsExporters = concat $podMetricsExporters ( list "debug/override" ) | uniq }}
{{- end }}

service:
  extensions: [health_check]
  pipelines:
      metrics:
        receivers: [k8s_cluster]
        processors: [memory_limiter, k8sattributes, batch, resource/observe_common, attributes/debug_source_cluster_metrics]
        exporters: [{{ join ", " $metricsExporters }}]
      {{- if .Values.application.prometheusScrape.enabled }}
      metrics/pod_metrics:
        receivers: [prometheus/pod_metrics]
        processors: [memory_limiter, k8sattributes, resource/drop_additional_pod_metrics_labels, batch, resource/observe_common, attributes/debug_source_pod_metrics]
        exporters: [{{ join ", " $podMetricsExporters }}]
      {{ end -}}
{{- include "config.service.telemetry" . | nindent 2 }}

 {{- end }}
