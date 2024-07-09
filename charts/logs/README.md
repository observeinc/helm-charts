# logs

![Version: 0.1.27](https://img.shields.io/badge/Version-0.1.27-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Observe logs collection

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Observe | <support@observeinc.com> |  |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../endpoint | endpoint | 0.1.11 |
| https://fluent.github.io/helm-charts | fluent-bit | 0.46.11 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fluent-bit.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"observeinc.com/unschedulable"` |  |
| fluent-bit.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"DoesNotExist"` |  |
| fluent-bit.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key | string | `"kubernetes.io/os"` |  |
| fluent-bit.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator | string | `"NotIn"` |  |
| fluent-bit.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0] | string | `"windows"` |  |
| fluent-bit.config.buffer_chunk_size | string | `"32k"` |  |
| fluent-bit.config.buffer_max_size | string | `"256k"` |  |
| fluent-bit.config.connect_timeout | int | `10` |  |
| fluent-bit.config.customParsers | string | `"[PARSER]\n    Name        kube-custom\n    Format      regex\n    Regex       (?<podName>[a-z0-9](?:[-a-z0-9]*[a-z0-9])?(?:\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*)_(?<namespace>[^_]+)_(?<containerName>.+)-(?<containerId>[a-f0-9]{64})\\.log$\n"` |  |
| fluent-bit.config.dns_mode | string | `"UDP"` |  |
| fluent-bit.config.dns_resolver | string | `"LEGACY"` |  |
| fluent-bit.config.filters | string | `"[FILTER]\n    Name                record_modifier\n    Alias               add_nodename\n    Match               *\n    Record              nodeName ${NODE}\n\n[FILTER]\n    Name                parser\n    Alias               parse_filename\n    Match               k8slogs\n    Key_Name            filename\n    Reserve_Data        True\n    Parser              kube-custom\n\n[FILTER]\n    Name                record_modifier\n    Alias               filter_docker\n    Match               k8slogs\n    Whitelist_key       containerId\n    Whitelist_key       containerName\n    Whitelist_key       log\n    Whitelist_key       podName\n    Whitelist_key       namespace\n    Whitelist_key       nodeName\n\n[FILTER]\n    Name                grep\n    Alias               exclude\n    Match               {{.Values.config.grep_match_tag}}\n    Exclude             {{.Values.config.grep_exclude}}\n"` |  |
| fluent-bit.config.flush | int | `2` |  |
| fluent-bit.config.grace | int | `10` |  |
| fluent-bit.config.grep_exclude | string | `"nomatch ^$"` |  |
| fluent-bit.config.grep_match_tag | string | `"nothing"` |  |
| fluent-bit.config.hc_errors_count | int | `5` |  |
| fluent-bit.config.hc_period | int | `10` |  |
| fluent-bit.config.hc_retry_failure_count | int | `5` |  |
| fluent-bit.config.ignore_older | string | `"2d"` |  |
| fluent-bit.config.inotify_watcher | string | `"true"` |  |
| fluent-bit.config.inputs | string | `"[INPUT]\n    Name                tail\n    Tag                 k8slogs\n    Alias               k8slogs\n    Path                /var/log/containers/*.log\n    Path_Key            filename\n    DB                  /var/log/flb_kube_${NAMESPACE}.db\n    Skip_Long_Lines     On\n    Read_From_Head      {{.Values.config.read_from_head}}\n    Mem_Buf_Limit       {{.Values.config.mem_buf_limit}}\n    Buffer_Chunk_Size   {{.Values.config.buffer_chunk_size}}\n    Buffer_Max_Size     {{.Values.config.buffer_max_size}}\n    Rotate_Wait         {{.Values.config.rotate_wait}}\n    Refresh_Interval    {{.Values.config.refresh_interval}}\n    Inotify_Watcher     {{.Values.config.inotify_watcher}}\n\n[INPUT]\n    Name                tail\n    Tag                 k8snode\n    Alias               k8snode\n    Path                {{.Values.config.node_log_include_path}}\n    Exclude_Path        {{.Values.config.node_log_exclude_path}}\n    Path_Key            filename\n    DB                  /var/log/flb_node_${NAMESPACE}.db\n    Skip_Long_Lines     On\n    Read_From_Head      {{.Values.config.read_from_head}}\n    Ignore_Older        {{.Values.config.ignore_older}}\n    Mem_Buf_Limit       {{.Values.config.mem_buf_limit}}\n    Buffer_Chunk_Size   {{.Values.config.buffer_chunk_size}}\n    Buffer_Max_Size     {{.Values.config.buffer_max_size}}\n    Rotate_Wait         {{.Values.config.rotate_wait}}\n    Inotify_Watcher     {{.Values.config.inotify_watcher}}\n"` |  |
| fluent-bit.config.keepalive | string | `"on"` |  |
| fluent-bit.config.keepalive_idle_timeout | int | `30` |  |
| fluent-bit.config.keepalive_max_recycle | int | `2000` |  |
| fluent-bit.config.log_level | string | `"warning"` |  |
| fluent-bit.config.max_worker_connections | int | `25` |  |
| fluent-bit.config.mem_buf_limit | string | `"10MB"` |  |
| fluent-bit.config.node_log_exclude_path | string | `"nomatch"` |  |
| fluent-bit.config.node_log_include_path | string | `"/var/log/kube-apiserver-audit.log"` |  |
| fluent-bit.config.outputs | string | `"[OUTPUT]\n    Name                http\n    Match               k8slogs*\n    Alias               k8slogs\n    Host                {{ include \"observe.collectorHost\" . }}\n    Port                {{ include \"observe.collectorPort\" . }}\n    TLS                 {{ include \"observe.useTLS\" . }}\n    URI                 /v1/http/kubernetes/logs?clusterUid=${OBSERVE_CLUSTER}\n    Format              msgpack\n    Header              X-Observe-Decoder fluent\n    Header              Authorization Bearer ${OBSERVE_TOKEN}\n    Compress            gzip\n    Retry_Limit         {{.Values.config.retry_limit}}\n    Workers             {{.Values.config.workers}}\n    net.connect_timeout         {{.Values.config.connect_timeout}}\n    net.keepalive               {{.Values.config.keepalive}}\n    net.keepalive_idle_timeout  {{.Values.config.keepalive_idle_timeout}}\n    net.keepalive_max_recycle   {{.Values.config.keepalive_max_recycle}}\n    net.max_worker_connections  {{.Values.config.max_worker_connections}}\n\n[OUTPUT]\n    Name                http\n    Match               k8snode*\n    Alias               k8snode\n    Host                {{ include \"observe.collectorHost\" . }}\n    Port                {{ include \"observe.collectorPort\" . }}\n    TLS                 {{ include \"observe.useTLS\" . }}\n    URI                 /v1/http/kubernetes/node?clusterUid=${OBSERVE_CLUSTER}\n    Format              msgpack\n    Header              X-Observe-Decoder fluent\n    Header              Authorization Bearer ${OBSERVE_TOKEN}\n    Compress            gzip\n    Retry_Limit         {{.Values.config.retry_limit}}\n    Workers             {{.Values.config.workers}}\n    net.connect_timeout         {{.Values.config.connect_timeout}}\n    net.keepalive               {{.Values.config.keepalive}}\n    net.keepalive_idle_timeout  {{.Values.config.keepalive_idle_timeout}}\n    net.keepalive_max_recycle   {{.Values.config.keepalive_max_recycle}}\n    net.max_worker_connections  {{.Values.config.max_worker_connections}}\n\n{{- include \"observe.includeExtraFiles\" . }}\n"` |  |
| fluent-bit.config.read_from_head | string | `"true"` |  |
| fluent-bit.config.refresh_interval | int | `2` |  |
| fluent-bit.config.retry_limit | int | `5` |  |
| fluent-bit.config.rotate_wait | int | `5` |  |
| fluent-bit.config.service | string | `"[SERVICE]\n    Flush                  {{.Values.config.flush}}\n    Grace                  {{.Values.config.grace}}\n    Daemon                 Off\n    Log_Level              {{.Values.config.log_level}}\n    Parsers_File           custom_parsers.conf\n    HTTP_Server            On\n    HTTP_Listen            0.0.0.0\n    HTTP_PORT              2020\n    Health_Check           On\n    HC_Errors_Count        {{.Values.config.hc_errors_count}}\n    HC_Retry_Failure_Count {{.Values.config.hc_retry_failure_count}}\n    HC_Period              {{.Values.config.hc_period}}\n    dns.mode               {{.Values.config.dns_mode}}\n    dns.resolver           {{.Values.config.dns_resolver}}\n    storage.metrics        {{.Values.config.storage_metrics}}\n"` |  |
| fluent-bit.config.storage_metrics | string | `"off"` |  |
| fluent-bit.config.workers | int | `2` |  |
| fluent-bit.env[0].name | string | `"OBSERVE_CLUSTER"` |  |
| fluent-bit.env[0].valueFrom.configMapKeyRef.key | string | `"id"` |  |
| fluent-bit.env[0].valueFrom.configMapKeyRef.name | string | `"cluster-info"` |  |
| fluent-bit.env[1].name | string | `"OBSERVE_TOKEN"` |  |
| fluent-bit.env[1].valueFrom.secretKeyRef.key | string | `"OBSERVE_TOKEN"` |  |
| fluent-bit.env[1].valueFrom.secretKeyRef.name | string | `"credentials"` |  |
| fluent-bit.env[2].name | string | `"NODE"` |  |
| fluent-bit.env[2].valueFrom.fieldRef.fieldPath | string | `"spec.nodeName"` |  |
| fluent-bit.env[3].name | string | `"NAMESPACE"` |  |
| fluent-bit.env[3].valueFrom.fieldRef.fieldPath | string | `"metadata.namespace"` |  |
| fluent-bit.image.repository | string | `"fluent/fluent-bit"` |  |
| fluent-bit.nameOverride | string | `"logs"` |  |
| fluent-bit.resources.limits.cpu | string | `"100m"` |  |
| fluent-bit.resources.limits.memory | string | `"128Mi"` |  |
| fluent-bit.resources.requests.cpu | string | `"100m"` |  |
| fluent-bit.resources.requests.memory | string | `"128Mi"` |  |
| fluent-bit.tolerations[0].operator | string | `"Exists"` |  |
| global.observe | object | `{}` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
