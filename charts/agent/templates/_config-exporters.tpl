{{- define "config.exporters.otlphttp.observe.base" -}}
otlphttp/observe/base:
    endpoint: "{{ .Values.observe.collectionEndpoint.value | toString | trimSuffix "/" }}/v2/otel"
    headers:
        authorization: "${env:OBSERVE_TOKEN}"
    sending_queue:
      enabled: {{ .Values.agent.config.global.exporters.sendingQueue.enabled }}
    retry_on_failure:
      enabled: {{ .Values.agent.config.global.exporters.retryOnFailure.enabled }}
      initial_interval: {{ .Values.agent.config.global.exporters.retryOnFailure.initialInterval }}
      max_interval: {{ .Values.agent.config.global.exporters.retryOnFailure.maxInterval }}
      max_elapsed_time: {{ .Values.agent.config.global.exporters.retryOnFailure.maxElapsedTime }}
    compression: zstd
{{- end -}}

{{- define "config.exporters.otlphttp.observe.entity" -}}
otlphttp/observe/entity:
    logs_endpoint: "{{ .Values.observe.collectionEndpoint.value | toString | trimSuffix "/" }}/v1/kubernetes/v1/entity"
    headers:
        authorization: "Bearer ${env:ENTITY_TOKEN}"
    sending_queue:
      enabled: {{ .Values.agent.config.global.exporters.sendingQueue.enabled }}
    retry_on_failure:
      enabled: {{ .Values.agent.config.global.exporters.retryOnFailure.enabled }}
      initial_interval: {{ .Values.agent.config.global.exporters.retryOnFailure.initialInterval }}
      max_interval: {{ .Values.agent.config.global.exporters.retryOnFailure.maxInterval }}
      max_elapsed_time: {{ .Values.agent.config.global.exporters.retryOnFailure.maxElapsedTime }}
    compression: zstd
{{- end -}}

{{- define "config.exporters.prometheusremotewrite" -}}
prometheusremotewrite:
    endpoint: "{{ .Values.observe.collectionEndpoint.value | toString | trimSuffix "/" }}/v1/prometheus"
    headers:
        authorization: "${env:OBSERVE_TOKEN}"
    resource_to_telemetry_conversion:
        enabled: true # Convert resource attributes to metric labels
    send_metadata: true

{{- end -}}

{{- define "config.exporters.debug" -}}
debug/override:
    verbosity: {{ .Values.agent.config.global.debug.verbosity }}
    sampling_initial: 2
    sampling_thereafter: 1
{{- end -}}
