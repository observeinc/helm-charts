{{- define "observe.deployment.applyClusterEventsConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.deployment.clusterEvents.config" $data |  fromYaml ) ($values.agent.config.clusterEvents) ($values.agent.config.global.overrides) -}}
{{- toYaml $config | indent 2 }}
{{- end }}

{{- define "observe.deployment.applyClusterMetricsConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.deployment.clusterMetrics.config" $data |  fromYaml ) ($values.agent.config.clusterMetrics) ($values.agent.config.global.overrides) -}}
{{- toYaml $config | indent 2 }}
{{- end }}

{{- define "observe.deployment.applyPrometheusScraperConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.deployment.prometheusScraper.config" $data |  fromYaml ) ($values.agent.config.prometheusScraper) ($values.agent.config.global.overrides) -}}
{{- toYaml $config | indent 2 }}
{{- end }}

{{- define "observe.daemonset.applyNodeLogsMetricsConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.daemonset.logsMetrics.config" $data |  fromYaml ) ($values.agent.config.nodeLogsMetrics) ($values.agent.config.global.overrides) -}}
{{- toYaml $config | indent 2 }}
{{- end }}

{{- define "observe.daemonset.applyForwarderConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.daemonset.forwarder.config" $data |  fromYaml ) ($values.agent.config.forwarder) ($values.agent.config.global.overrides) -}}
{{- toYaml $config | indent 2 }}
{{- end }}

{{- define "observe.deployment.applyGatewayConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.deployment.gateway.config" $data |  fromYaml ) ($values.agent.config.gateway) ($values.agent.config.global.overrides) -}}
{{- toYaml $config | indent 2 }}
{{- end }}

{{- define "observe.deployment.applyAgentMonitorConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := mustMergeOverwrite ( include "observe.deployment.agentMonitor.config" $data |  fromYaml ) ($values.agent.config.monitor) ($values.agent.config.global.overrides) -}}
{{- toYaml $config | indent 2 }}
{{- end }}
