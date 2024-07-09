# metrics

![Version: 0.3.22](https://img.shields.io/badge/Version-0.3.22-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Observe metrics collection

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Observe | <support@observeinc.com> |  |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../endpoint | endpoint | 0.1.11 |
| https://grafana.github.io/helm-charts | grafana-agent | 0.41.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.observe | object | `{}` |  |
| grafana-agent.agent.configMap.content | string | `"{{- $endpoint := include \"observe.collectionEndpoint\" . }}\n{{- with .Values.prom_config}}\nserver:\n  log_level: {{.log_level}}\n\n{{ if .statsd_exporter.enabled -}}\nintegrations:\n  statsd_exporter:\n    enabled: true\n    scrape_integration: true\n    listen_{{ .statsd_exporter.protocol }}: \":{{ .statsd_exporter.port }}\"\n  prometheus_remote_write:\n  - url: {{ print $endpoint }}/v1/prometheus?clusterUid=${OBSERVE_CLUSTER}\n    authorization:\n      credentials: ${OBSERVE_TOKEN}\n    remote_timeout: {{.remote_timeout}}\n    queue_config:\n      batch_send_deadline: {{.batch_send_deadline}}\n      min_backoff: {{.min_backoff}}\n      max_backoff: {{.max_backoff}}\n      max_shards: {{.max_shards}}\n      max_samples_per_send: {{.max_samples_per_send}}\n      capacity: {{.capacity}}\n    tls_config:\n      insecure_skip_verify: {{.observe_collector_insecure}}\n{{ end -}}\n\nmetrics:\n  wal_directory: /tmp/grafana-agent-wal\n  global:\n    scrape_interval: {{.scrape_interval}}\n    scrape_timeout: {{.scrape_timeout}}\n  configs:\n    - name: integrations\n      host_filter: {{.host_filter}}\n      min_wal_time: {{.min_wal_time}}\n      max_wal_time: {{.max_wal_time}}\n      wal_truncate_frequency: {{.wal_truncate_frequency}}\n      remote_flush_deadline: {{.remote_flush_deadline}}\n      remote_write:\n        - url: {{ print $endpoint }}/v1/prometheus?clusterUid=${OBSERVE_CLUSTER}\n          authorization:\n            credentials: ${OBSERVE_TOKEN}\n          remote_timeout: {{.remote_timeout}}\n          queue_config:\n            batch_send_deadline: {{.batch_send_deadline}}\n            min_backoff: {{.min_backoff}}\n            max_backoff: {{.max_backoff}}\n            max_shards: {{.max_shards}}\n            max_samples_per_send: {{.max_samples_per_send}}\n            capacity: {{.capacity}}\n          tls_config:\n            insecure_skip_verify: {{.observe_collector_insecure}}\n\n      scrape_configs:\n      {{- with .scrape_configs }}\n        - job_name: \"integrations/kubernetes/pods\"\n          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n          scrape_interval: {{.pod_interval}}\n          sample_limit: {{.sample_limit}}\n          body_size_limit: {{.body_size_limit}}\n          kubernetes_sd_configs:\n            - role: pod\n          relabel_configs:\n            - action: {{.pod_action}}\n            # Drop anything matching the configured namespace.\n            - action: 'drop'\n              source_labels: ['__meta_kubernetes_namespace']\n              regex: {{.pod_namespace_drop_regex}}\n            # Drop anything not matching the configured namespace.\n            - action: 'keep'\n              source_labels: ['__meta_kubernetes_namespace']\n              regex: {{.pod_namespace_keep_regex}}\n            # Drop endpoints without one of: a port name suffixed with the configured regex, or an explicit prometheus port annotation.\n            - action: 'keep'\n              source_labels: ['__meta_kubernetes_pod_container_port_name', '__meta_kubernetes_pod_annotation_prometheus_io_port']\n              regex: '({{.pod_port_keep_regex}};|.*;\\d+)'\n            # Drop pods without a name label.\n            # - action: 'drop'\n            #   regex: ''\n            #   source_labels: ['__meta_kubernetes_pod_label_name']\n            # Drop pods with phase Succeeded or Failed.\n            - action: 'drop'\n              regex: 'Succeeded|Failed'\n              source_labels: ['__meta_kubernetes_pod_phase']\n            # Drop anything annotated with 'prometheus.io.scrape=false'.\n            - action: 'drop'\n              regex: 'false'\n              source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_scrape']\n            # Drop anything annotated with 'observeinc.com.scrape=false'.\n            - action: 'drop'\n              regex: 'false'\n              source_labels: ['__meta_kubernetes_pod_annotation_observeinc_com_scrape']\n            # Allow pods to override the scrape scheme with 'prometheus.io.scheme=https'.\n            - action: 'replace'\n              regex: '(https?)'\n              replacement: '$1'\n              source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_scheme']\n              target_label: '__scheme__'\n            # Allow service to override the scrape path with 'prometheus.io.path=/other_metrics_path'.\n            - action: 'replace'\n              regex: '(.+)'\n              replacement: '$1'\n              source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_path']\n              target_label: '__metrics_path__'\n            # Allow services to override the scrape port with 'prometheus.io.port=1234'.\n            - action: 'replace'\n              regex: '(.+?)(\\:\\d+)?;(\\d+)'\n              replacement: '$1:$3'\n              source_labels: ['__address__', '__meta_kubernetes_pod_annotation_prometheus_io_port']\n              target_label: '__address__'\n            # Map all K8s labels/annotations starting with\n            # 'prometheus.io/param-' to URL params for Prometheus scraping.\n            - action: 'labelmap'\n              regex: '__meta_kubernetes_pod_annotation_prometheus_io_param_(.+)'\n              replacement: '__param_$1'\n            # Map all K8s labels/annotations starting with\n            # 'prometheus.io/label-' to Prometheus labels.\n            - action: 'labelmap'\n              regex: '__meta_kubernetes_pod_label_prometheus_io_label_(.+)'\n            - action: 'labelmap'\n              regex: '__meta_kubernetes_pod_annotation_prometheus_io_label_(.+)'\n            # Rename jobs to be <namespace>/<name, from pod name label>.\n            # - action: 'replace'\n            #   separator: '/'\n            #   source_labels: ['__meta_kubernetes_namespace', '__meta_kubernetes_pod_label_name']\n            #   target_label: 'job'\n            #   replacement: '$1'\n            # But also include the namespace, container, pod as separate labels,\n            # for routing alerts and joining with cAdvisor metrics.\n            - action: 'replace'\n              source_labels: ['__meta_kubernetes_namespace']\n              target_label: 'namespace'\n            - action: 'replace'\n              source_labels: ['__meta_kubernetes_pod_name']\n              # Not 'pod_name', which disappeared in K8s 1.16.\n              target_label: 'pod'\n            - action: 'replace'\n              source_labels: ['__meta_kubernetes_pod_container_name']\n              # Not 'container_name', which disappeared in K8s 1.16.\n              target_label: 'container'\n            - action: 'replace'\n              source_labels: ['__meta_kubernetes_pod_node_name']\n              target_label: 'node'\n          metric_relabel_configs:\n            - action: drop\n              regex: {{.pod_metric_drop_regex}}\n              source_labels:\n                - __name__\n            - action: keep\n              regex: {{.pod_metric_keep_regex}}\n              source_labels:\n                - __name__\n          tls_config:\n            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n            insecure_skip_verify: false\n            server_name: kubernetes\n\n        - job_name: \"integrations/kubernetes/kubelet\"\n          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n          scrape_interval: {{.kubelet_interval}}\n          sample_limit: {{.sample_limit}}\n          body_size_limit: {{.body_size_limit}}\n          kubernetes_sd_configs:\n            - role: node\n          relabel_configs:\n            - action: {{.kubelet_action}}\n            - replacement: kubernetes.default.svc:443\n              target_label: __address__\n            - regex: (.+)\n              replacement: /api/v1/nodes/$1/proxy/metrics\n              source_labels:\n                - __meta_kubernetes_node_name\n              target_label: __metrics_path__\n          metric_relabel_configs:\n            - action: drop\n              regex: {{.kubelet_metric_drop_regex}}\n              source_labels:\n                - __name__\n            - action: keep\n              regex: {{.kubelet_metric_keep_regex}}\n              source_labels:\n                - __name__\n          scheme: https\n          tls_config:\n            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n            insecure_skip_verify: false\n            server_name: kubernetes\n\n        - job_name: \"integrations/kubernetes/resource\"\n          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n          scrape_interval: {{.resource_interval}}\n          sample_limit: {{.sample_limit}}\n          body_size_limit: {{.body_size_limit}}\n          kubernetes_sd_configs:\n            - role: node\n          relabel_configs:\n            - action: {{.resource_action}}\n            - replacement: kubernetes.default.svc:443\n              target_label: __address__\n            - regex: (.+)\n              replacement: /api/v1/nodes/$1/proxy/metrics/resource\n              source_labels:\n                - __meta_kubernetes_node_name\n              target_label: __metrics_path__\n          metric_relabel_configs:\n            - action: drop\n              regex: {{.resource_metric_drop_regex}}\n              source_labels:\n                - __name__\n            - action: keep\n              regex: {{.resource_metric_keep_regex}}\n              source_labels:\n                - __name__\n          scheme: https\n          tls_config:\n            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n            insecure_skip_verify: false\n            server_name: kubernetes\n\n        - job_name: \"integrations/kubernetes/cadvisor\"\n          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n          scrape_interval: {{.cadvisor_interval}}\n          sample_limit: {{.sample_limit}}\n          body_size_limit: {{.body_size_limit}}\n          kubernetes_sd_configs:\n            - role: node\n          relabel_configs:\n            - action: {{.cadvisor_action}}\n            - replacement: kubernetes.default.svc:443\n              target_label: __address__\n            - regex: (.+)\n              replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor\n              source_labels:\n                - __meta_kubernetes_node_name\n              target_label: __metrics_path__\n          metric_relabel_configs:\n            # drop \"pod\" level aggregates, identified by absence of image\n            - action: drop\n              regex: container_([a-z_]+);\n              source_labels:\n                - __name__\n                - image\n            - action: drop\n              regex: {{.cadvisor_metric_drop_regex}}\n              source_labels:\n                - __name__\n            - action: keep\n              regex: {{.cadvisor_metric_keep_regex}}\n              source_labels:\n                - __name__\n          scheme: https\n          tls_config:\n            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n            insecure_skip_verify: false\n            server_name: kubernetes\n      {{- end }}\n{{- end }}\n"` |  |
| grafana-agent.agent.enableReporting | bool | `false` |  |
| grafana-agent.agent.extraArgs[0] | string | `"-config.expand-env"` |  |
| grafana-agent.agent.extraEnv[0].name | string | `"OBSERVE_CLUSTER"` |  |
| grafana-agent.agent.extraEnv[0].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| grafana-agent.agent.extraEnv[0].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| grafana-agent.agent.extraEnv[1].name | string | `"OBSERVE_TOKEN"` |  |
| grafana-agent.agent.extraEnv[1].valueFrom.secretKeyRef.key | string | `"OBSERVE_TOKEN"` |  |
| grafana-agent.agent.extraEnv[1].valueFrom.secretKeyRef.name | string | `"credentials"` |  |
| grafana-agent.agent.extraPorts[0].name | string | `"statsd"` |  |
| grafana-agent.agent.extraPorts[0].port | int | `9125` |  |
| grafana-agent.agent.extraPorts[0].protocol | string | `"UDP"` |  |
| grafana-agent.agent.extraPorts[0].targetPort | int | `9125` |  |
| grafana-agent.agent.listenPort | int | `12345` |  |
| grafana-agent.agent.mode | string | `"static"` |  |
| grafana-agent.agent.resources.limits.cpu | string | `"250m"` |  |
| grafana-agent.agent.resources.limits.memory | string | `"2Gi"` |  |
| grafana-agent.agent.resources.requests.cpu | string | `"250m"` |  |
| grafana-agent.agent.resources.requests.memory | string | `"2Gi"` |  |
| grafana-agent.agent.securityContext.capabilities.add[0] | string | `"NET_BIND_SERVICE"` |  |
| grafana-agent.agent.securityContext.capabilities.drop[0] | string | `"all"` |  |
| grafana-agent.agent.securityContext.runAsNonRoot | bool | `true` |  |
| grafana-agent.agent.securityContext.runAsUser | int | `65534` |  |
| grafana-agent.controller.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"observeinc.com/unschedulable"` |  |
| grafana-agent.controller.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"DoesNotExist"` |  |
| grafana-agent.controller.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key | string | `"kubernetes.io/os"` |  |
| grafana-agent.controller.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator | string | `"NotIn"` |  |
| grafana-agent.controller.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0] | string | `"windows"` |  |
| grafana-agent.controller.podLabels.name | string | `"metrics"` |  |
| grafana-agent.controller.replicas | int | `1` |  |
| grafana-agent.controller.type | string | `"deployment"` |  |
| grafana-agent.crds.create | bool | `false` |  |
| grafana-agent.nameOverride | string | `"metrics"` |  |
| grafana-agent.prom_config.batch_send_deadline | string | `"5s"` |  |
| grafana-agent.prom_config.capacity | int | `15000` |  |
| grafana-agent.prom_config.host_filter | string | `"false"` |  |
| grafana-agent.prom_config.log_level | string | `"info"` |  |
| grafana-agent.prom_config.max_backoff | string | `"30s"` |  |
| grafana-agent.prom_config.max_samples_per_send | int | `5000` |  |
| grafana-agent.prom_config.max_shards | int | `10` |  |
| grafana-agent.prom_config.max_wal_time | string | `"30m"` |  |
| grafana-agent.prom_config.min_backoff | string | `"1s"` |  |
| grafana-agent.prom_config.min_wal_time | string | `"15s"` |  |
| grafana-agent.prom_config.observe_collector_insecure | bool | `false` |  |
| grafana-agent.prom_config.remote_flush_deadline | string | `"1m"` |  |
| grafana-agent.prom_config.remote_timeout | string | `"30s"` |  |
| grafana-agent.prom_config.scrape_configs.body_size_limit | string | `"50MB"` |  |
| grafana-agent.prom_config.scrape_configs.cadvisor_action | string | `"keep"` |  |
| grafana-agent.prom_config.scrape_configs.cadvisor_interval | string | `nil` |  |
| grafana-agent.prom_config.scrape_configs.cadvisor_metric_drop_regex | string | `"container_(network_tcp_usage_total|network_udp_usage_total|tasks_state|cpu_load_average_10s)"` |  |
| grafana-agent.prom_config.scrape_configs.cadvisor_metric_keep_regex | string | `"container_(cpu_.*|spec_.*|memory_.*|network_.*|file_descriptors)|machine_(cpu_cores|memory_bytes)"` |  |
| grafana-agent.prom_config.scrape_configs.kubelet_action | string | `"drop"` |  |
| grafana-agent.prom_config.scrape_configs.kubelet_interval | string | `nil` |  |
| grafana-agent.prom_config.scrape_configs.kubelet_metric_drop_regex | string | `nil` |  |
| grafana-agent.prom_config.scrape_configs.kubelet_metric_keep_regex | string | `"(.*)"` |  |
| grafana-agent.prom_config.scrape_configs.pod_action | string | `"drop"` |  |
| grafana-agent.prom_config.scrape_configs.pod_interval | string | `nil` |  |
| grafana-agent.prom_config.scrape_configs.pod_metric_drop_regex | string | `".*bucket"` |  |
| grafana-agent.prom_config.scrape_configs.pod_metric_keep_regex | string | `"(.*)"` |  |
| grafana-agent.prom_config.scrape_configs.pod_namespace_drop_regex | string | `"(.*istio.*|.*ingress.*|kube-system)"` |  |
| grafana-agent.prom_config.scrape_configs.pod_namespace_keep_regex | string | `"(.*)"` |  |
| grafana-agent.prom_config.scrape_configs.pod_port_keep_regex | string | `".*metrics"` |  |
| grafana-agent.prom_config.scrape_configs.resource_action | string | `"keep"` |  |
| grafana-agent.prom_config.scrape_configs.resource_interval | string | `nil` |  |
| grafana-agent.prom_config.scrape_configs.resource_metric_drop_regex | string | `nil` |  |
| grafana-agent.prom_config.scrape_configs.resource_metric_keep_regex | string | `"(.*)"` |  |
| grafana-agent.prom_config.scrape_configs.sample_limit | int | `100000` |  |
| grafana-agent.prom_config.scrape_interval | string | `"60s"` |  |
| grafana-agent.prom_config.scrape_timeout | string | `"10s"` |  |
| grafana-agent.prom_config.statsd_exporter.enabled | bool | `false` |  |
| grafana-agent.prom_config.statsd_exporter.port | int | `9125` |  |
| grafana-agent.prom_config.statsd_exporter.protocol | string | `"udp"` |  |
| grafana-agent.prom_config.wal_truncate_frequency | string | `"30m"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
