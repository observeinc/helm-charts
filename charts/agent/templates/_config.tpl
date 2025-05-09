{{- define "observe.deployment.applyClusterEventsConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.deployment.clusterEvents.config" $data |  fromYaml ) ($values.agent.config.clusterEvents) -}}
{{- toYaml $config | indent 2 }}
{{- end }}

{{- define "observe.deployment.applyClusterMetricsConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.deployment.clusterMetrics.config" $data |  fromYaml ) ($values.agent.config.clusterMetrics) -}}
{{- toYaml $config | indent 2 }}
{{- end }}

{{- define "observe.deployment.applyPrometheusScraperConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.deployment.prometheusScraper.config" $data |  fromYaml ) ($values.agent.config.prometheusScraper) -}}
{{- toYaml $config | indent 2 }}
{{- end }}

{{- define "observe.daemonset.applyNodeLogsMetricsConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.daemonset.logsMetrics.config" $data |  fromYaml ) ($values.agent.config.nodeLogsMetrics) -}}
{{- toYaml $config | indent 2 }}
{{- end }}

{{- define "observe.daemonset.applyForwarderConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.daemonset.forwarder.config" $data |  fromYaml ) ($values.agent.config.forwarder) -}}
{{- toYaml $config | indent 2 }}
{{- end }}

{{- define "observe.deployment.applyAgentMonitorConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.deployment.agentMonitor.config" $data |  fromYaml ) ($values.agent.config.monitor) -}}
{{- toYaml $config | indent 2 }}
{{- end }}
