{{- define "config.exporters.otlphttp.observe.base" -}}
otlphttp/observe/base:
    # These environment variables are provided by the observe-agent:
    # https://github.com/observeinc/observe-agent/blob/v2.0.1/internal/connections/confighandler.go#L91-L102
    endpoint: "${env:OBSERVE_OTEL_ENDPOINT}"
    headers:
        authorization: "${env:OBSERVE_AUTHORIZATION_HEADER}"
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
    # These environment variables are provided by the observe-agent:
    # https://github.com/observeinc/observe-agent/blob/v2.0.1/internal/connections/confighandler.go#L91-L102
    logs_endpoint: "${env:OBSERVE_COLLECTOR_URL}/v1/kubernetes/v1/entity"
    headers:
      authorization: "${env:OBSERVE_AUTHORIZATION_HEADER}"
    sending_queue:
      enabled: {{ .Values.agent.config.global.exporters.sendingQueue.enabled }}
    retry_on_failure:
      enabled: {{ .Values.agent.config.global.exporters.retryOnFailure.enabled }}
      initial_interval: {{ .Values.agent.config.global.exporters.retryOnFailure.initialInterval }}
      max_interval: {{ .Values.agent.config.global.exporters.retryOnFailure.maxInterval }}
      max_elapsed_time: {{ .Values.agent.config.global.exporters.retryOnFailure.maxElapsedTime }}
    compression: zstd
{{- end -}}

{{- define "config.exporters.otlphttp.observe.trace" -}}
otlphttp/observe/forward/trace:
    # These environment variables are provided by the observe-agent:
    # https://github.com/observeinc/observe-agent/blob/v2.0.1/internal/connections/confighandler.go#L91-L102
    endpoint: "${env:OBSERVE_OTEL_ENDPOINT}"
    headers:
        authorization: "Bearer ${env:TRACE_TOKEN}"
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
prometheusremotewrite/observe:
    # These environment variables are provided by the observe-agent:
    # https://github.com/observeinc/observe-agent/blob/v2.0.1/internal/connections/confighandler.go#L91-L102
    endpoint: "${env:OBSERVE_PROMETHEUS_ENDPOINT}"
    headers:
        authorization: "${env:OBSERVE_AUTHORIZATION_HEADER}"
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
