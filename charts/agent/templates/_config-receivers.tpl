{{/*
  Prometheus scrape_configs entry for pod-metrics (Kubernetes pod SD + relabel).
  Shared between the non-TA receiver (prometheus/pod_metrics) and the merged receiver (prometheus/k8s_metrics).
*/}}
{{- define "observe.prometheus.pod_metrics.scrape_job" -}}
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

  # Maps all Kubernetes pod labels to Prometheus labels with the prefix removed (e.g., __meta_kubernetes_pod_label_app becomes app).
  - action: labelmap
    regex: __meta_kubernetes_pod_label_(.+)

  # adds new label
  - source_labels: [__meta_kubernetes_namespace]
    action: replace
    target_label: kubernetes_namespace

  # adds new label
  - source_labels: [__meta_kubernetes_pod_name]
    action: replace
    target_label: kubernetes_pod_name

  metric_relabel_configs:
    - action: drop
      regex: {{ .Values.application.prometheusScrape.metricDropRegex }}
      source_labels:
        - __name__
    - action: keep
      regex: {{ .Values.application.prometheusScrape.metricKeepRegex }}
      source_labels:
        - __name__
{{- end -}}

{{/*
  Prometheus scrape_configs entry for cadvisor (Kubernetes node SD via the API-server proxy).
  Used by the parent-rendered TA ConfigMap. Uses $1 (not $$1) — the TA reads this YAML
  directly, no OTel collector config-expansion happens, so Prometheus SD receives the
  literal $1 backreference.
*/}}
{{- define "observe.prometheus.cadvisor.scrape_job" -}}
- job_name: 'kubernetes-nodes-cadvisor'
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    insecure_skip_verify: true
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  kubernetes_sd_configs:
    - role: node
  relabel_configs:
    - target_label: __address__
      replacement: kubernetes.default.svc:443
    - source_labels: [__meta_kubernetes_node_name]
      regex: (.+)
      target_label: __metrics_path__
      replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor
{{- end -}}

{{- define "config.receivers.prometheus.pod_metrics" -}}
prometheus/pod_metrics:
  config:
    scrape_configs:
{{ include "observe.prometheus.pod_metrics.scrape_job" . | nindent 4 }}
{{- end -}}

{{- define "config.receivers.prometheus.cadvisor" -}}
{{- if .Values.node.metrics.cadvisor.enabled }}
prometheus/cadvisor:
  config:
    scrape_configs:
      - job_name: 'kubernetes-nodes-cadvisor'
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          insecure_skip_verify: true
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

        kubernetes_sd_configs:
          - role: node

        relabel_configs:
          - target_label: __address__
            replacement: kubernetes.default.svc:443
          - source_labels: [__meta_kubernetes_node_name]
            regex: (.+)
            target_label: __metrics_path__
            replacement: /api/v1/nodes/$$1/proxy/metrics/cadvisor
{{ end }}
{{ end }}

{{/*
  Merged receiver for the TA-enabled path. Polls the upstream Target Allocator
  (deployed via the opentelemetry-target-allocator subchart) for both pod-metrics
  and cadvisor jobs. Filter processors in the pipelines split the stream by service.name.
  Each scraper pod identifies itself to TA via collector_id (= pod name) for sharding.
*/}}
{{- define "config.receivers.prometheus.k8s_metrics" -}}
prometheus/k8s_metrics:
  target_allocator:
    endpoint: http://{{ .Release.Name }}-prometheus-ta-ta.{{ .Release.Namespace }}.svc.cluster.local
    interval: 30s
    collector_id: ${env:OTEL_K8S_POD_NAME}
{{- end -}}

{{- define "config.receivers.observe.heartbeat" -}}
heartbeat:
    auth_check:
        headers:
            authorization: "${env:OBSERVE_AUTHORIZATION_HEADER}"
        url: "${env:OBSERVE_COLLECTOR_URL}"
    environment: kubernetes
    interval: {{ .Values.agent.config.global.fleet.interval }}
    config_interval: {{ .Values.agent.config.global.fleet.configInterval }}
{{- end }}
