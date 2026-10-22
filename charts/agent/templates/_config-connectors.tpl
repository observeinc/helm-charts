{{- /*
Emits a spanmetrics connector body. Parameters (passed via dict):
  name         - connector name (e.g. "spanmetrics", "spanmetrics/summary")
  resourceDims - list of resource attribute dimensions (service.name auto-prepended)
  spanDims     - list of span attribute dimensions
*/ -}}
{{- define "config.connectors.spanmetrics.body" -}}
{{- $name := .name -}}
{{- $resourceDims := .resourceDims -}}
{{- $allDims := (concat $resourceDims .spanDims) -}}
{{/* service.name is added automatically by the connector and errors when specified in the config */}}
{{- $allDims = (without $allDims "service.name" | uniq) -}}

{{ $name }}:
  aggregation_temporality: AGGREGATION_TEMPORALITY_DELTA
  histogram:
    exponential:
      max_size: 100
  # Restrict the resource attribute set used to bucket aggregated metrics only to
  # the configured resource attributes.
  resource_metrics_key_attributes:
    {{- range $tag := (prepend $resourceDims "service.name" | uniq) }}
    - {{ $tag }}
    {{- end }}
  dimensions:
    # This connector implicitly adds: service.name, span.name, span.kind, and status.code (which we rename to otel.status_code)
    # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/connector/spanmetricsconnector/connector.go#L528-L540
    {{- range $tag := $allDims }}
    - name: {{ $tag }}
    {{- end }}
{{- end -}}

{{- /*
Emits all connectors needed for the RED metrics pipelines: the full and summary
spanmetrics connectors, plus (when onlyGenerateForAPMSpans is off) the routing
connector that splits "internal" datapoints into a separate pipeline.
*/ -}}
{{- define "config.connectors.RED_metrics" -}}
{{- include "config.connectors.spanmetrics.body" (dict
    "name" "spanmetrics"
    "resourceDims" .Values.application.REDMetrics.resourceDimensions
    "spanDims" .Values.application.REDMetrics.spanDimensions) }}

{{ include "config.connectors.spanmetrics.body" (dict
    "name" "spanmetrics/summary"
    "resourceDims" .Values.application.REDMetrics.summaryMetrics.resourceDimensions
    "spanDims" .Values.application.REDMetrics.summaryMetrics.spanDimensions) }}

{{- if not .Values.application.REDMetrics.onlyGenerateForAPMSpans }}
# Routes RED metric datapoints generated from spans that would have been dropped by
# filter/drop_non_apm_spans (i.e. INTERNAL, UNSPECIFIED, non-DB CLIENT, non-messaging PRODUCER)
# to a dedicated pipeline that renames them with an ".internal" suffix. All other datapoints
# go to the default pipeline.
#
# NB: the route() condition below mirrors the inverse of filter/drop_non_apm_spans.
# Keep the two in sync.
routing/red_metrics_internal:
  error_mode: ignore
  default_pipelines: [metrics/spanmetrics/default]
  table:
    - context: datapoint
      statement: |
        route() where
          attributes["span.kind"] == "SPAN_KIND_INTERNAL"
          or attributes["span.kind"] == "SPAN_KIND_UNSPECIFIED"
          or (attributes["span.kind"] == "SPAN_KIND_CLIENT"
              and attributes["peer.db.name"] == nil)
          or (attributes["span.kind"] == "SPAN_KIND_PRODUCER"
              and attributes["peer.messaging.system"] == nil)
      pipelines: [metrics/spanmetrics/internal]

# Passes spans from the main traces/spanmetrics pipeline into an intermediate
# filter pipeline (traces/spanmetrics/summary/filter) that drops non-APM spans
# before they reach the summary connector.
forward/red_metrics_summary:
{{- end }}
{{- end -}}

{{- define "config.connectors.genai_metrics.resource_attributes" }}
      include_resource_attributes:
        - key: service.name
        - key: service.namespace
        - key: service.version
        - key: deployment.environment.name
        - key: k8s.namespace.name
        - key: k8s.pod.name
{{- end }}

{{- define "config.connectors.genai_metrics.optional_attributes" }}
        {{- range . }}
        - key: {{ . }}
          optional: true
        {{- end }}
{{- end }}

{{- define "config.connectors.genai_metrics.client_attributes" }}
      attributes:
        - key: gen_ai.operation.name
        {{- template "config.connectors.genai_metrics.optional_attributes" (list "gen_ai.provider.name" "gen_ai.request.model" "gen_ai.response.model" "server.address" "server.port" "gen_ai.agent.name") }}
{{- end }}

{{- define "config.connectors.genai_metrics.conversation_id" }}
        {{- if .Values.application.GenAIMetrics.includeConversationId }}
        - key: gen_ai.conversation.id
          optional: true
        {{- end }}
{{- end }}

{{- define "config.connectors.genai_metrics.user_id" }}
        {{- if .Values.application.GenAIMetrics.includeUserId }}
        - key: user.id
          optional: true
        {{- end }}
{{- end }}

{{- /*
Builds GenAI metrics from spans, following the GenAI semantic conventions on the main branch of
open-telemetry/semantic-conventions-genai. Keep in sync with genai_metrics.yaml.tmpl in observe-agent,
which has the same metrics without the k8s resource attributes.
*/ -}}
{{- define "config.connectors.genai_metrics" -}}
{{- $durationBuckets := list 0.01 0.02 0.04 0.08 0.16 0.32 0.64 1.28 2.56 5.12 10.24 20.48 40.96 81.92 }}
{{- $tokenBuckets := list 1 4 16 64 256 1024 4096 16384 65536 262144 1048576 4194304 16777216 67108864 }}
{{- $agentBuckets := list 0.1 0.2 0.4 0.8 1.6 3.2 6.4 12.8 25.6 51.2 102.4 204.8 409.6 }}
{{- $workflowBuckets := list 1 5 10 30 60 120 300 600 1800 3600 7200 }}

{{- /* Model calls that produce a response, i.e. the `gen_ai.client.inference` span. */}}
{{- $inferenceCall := `(attributes["gen_ai.operation.name"] == "chat" or attributes["gen_ai.operation.name"] == "generate_content" or attributes["gen_ai.operation.name"] == "text_completion")` }}
{{- /* Other client operations, such as embeddings, retrieval and remote agents. Local agents, tools and workflows have their own metrics. */}}
{{- $otherClientOperation := printf `attributes["gen_ai.operation.name"] != nil and not %s and attributes["gen_ai.operation.name"] != "execute_tool" and attributes["gen_ai.operation.name"] != "invoke_workflow" and not (attributes["gen_ai.operation.name"] == "invoke_agent" and kind == SPAN_KIND_INTERNAL)` $inferenceCall }}
signal_to_metrics/genai:
  error_mode: ignore
  spans:
    - name: gen_ai.client.inference.duration
      description: GenAI client inference operation duration.
      unit: s
      conditions:
        - {{ $inferenceCall }}
      {{- template "config.connectors.genai_metrics.resource_attributes" }}
      {{- template "config.connectors.genai_metrics.client_attributes" }}
        {{- template "config.connectors.genai_metrics.optional_attributes" (list "error.type") }}
      {{- template "config.connectors.genai_metrics.conversation_id" $ }}
      {{- template "config.connectors.genai_metrics.user_id" $ }}
      histogram:
        buckets: {{ $durationBuckets | toJson }}
        value: Seconds(end_time - start_time)

    - name: gen_ai.client.operation.duration
      description: GenAI operation duration.
      unit: s
      conditions:
        - {{ $otherClientOperation }}
      {{- template "config.connectors.genai_metrics.resource_attributes" }}
      {{- template "config.connectors.genai_metrics.client_attributes" }}
        {{- template "config.connectors.genai_metrics.optional_attributes" (list "error.type") }}
      {{- template "config.connectors.genai_metrics.conversation_id" $ }}
      {{- template "config.connectors.genai_metrics.user_id" $ }}
      histogram:
        buckets: {{ $durationBuckets | toJson }}
        value: Seconds(end_time - start_time)

    {{- /* Token metrics are recorded for every inference call, with 0 when the span has no usage. */}}
    {{- range (list
          (list "input_tokens" "The number of input (prompt) tokens used, including cached tokens.")
          (list "output_tokens" "The number of output (completion) tokens used, including reasoning tokens.")
          (list "cache_read.input_tokens" "The number of input tokens served from a provider-managed cache.")
          (list "cache_write.input_tokens" "The number of input tokens written to a provider-managed cache.")
          (list "reasoning.output_tokens" "The number of output tokens used for reasoning (e.g. chain-of-thought, extended thinking).")) }}
    - name: gen_ai.client.inference.usage.{{ index . 0 }}
      description: {{ index . 1 }}
      unit: "{token}"
      conditions:
        - {{ $inferenceCall }}
      {{- template "config.connectors.genai_metrics.resource_attributes" }}
      {{- template "config.connectors.genai_metrics.client_attributes" }}
      {{- template "config.connectors.genai_metrics.conversation_id" $ }}
        # Spans don't split usage by modality, so this is always `unknown`.
        - key: gen_ai.token.modality
          default_value: unknown
      sum:
        value: Int(Coalesce([attributes["gen_ai.usage.{{ index . 0 }}"], 0]))
        monotonic: true
    {{- end }}

    {{- range (list
          (list "input_tokens" "The number of input (prompt) tokens used per inference operation.")
          (list "output_tokens" "The number of output (completion) tokens used per inference operation.")) }}
    - name: gen_ai.client.inference.operation.{{ index . 0 }}
      description: {{ index . 1 }}
      unit: "{token}"
      conditions:
        - {{ $inferenceCall }}
      {{- template "config.connectors.genai_metrics.resource_attributes" }}
      {{- template "config.connectors.genai_metrics.client_attributes" }}
        {{- template "config.connectors.genai_metrics.optional_attributes" (list "error.type") }}
      {{- template "config.connectors.genai_metrics.conversation_id" $ }}
      histogram:
        buckets: {{ $tokenBuckets | toJson }}
        value: Int(Coalesce([attributes["gen_ai.usage.{{ index . 0 }}"], 0]))
    {{- end }}

    - name: gen_ai.execute_tool.duration
      description: Measures the duration of a tool execution.
      unit: s
      conditions:
        - attributes["gen_ai.operation.name"] == "execute_tool"
      {{- template "config.connectors.genai_metrics.resource_attributes" }}
      attributes:
        {{- template "config.connectors.genai_metrics.optional_attributes" (list "gen_ai.tool.name" "gen_ai.tool.type" "gen_ai.agent.name" "error.type") }}
      {{- template "config.connectors.genai_metrics.conversation_id" $ }}
      {{- template "config.connectors.genai_metrics.user_id" $ }}
      histogram:
        buckets: {{ $durationBuckets | toJson }}
        value: Seconds(end_time - start_time)

    - name: gen_ai.invoke_agent.duration
      description: Measures the duration of an in-process agent invocation.
      unit: s
      conditions:
        - attributes["gen_ai.operation.name"] == "invoke_agent" and kind == SPAN_KIND_INTERNAL
      {{- template "config.connectors.genai_metrics.resource_attributes" }}
      attributes:
        {{- template "config.connectors.genai_metrics.optional_attributes" (list "gen_ai.agent.name" "gen_ai.request.model" "error.type") }}
      {{- template "config.connectors.genai_metrics.conversation_id" $ }}
      {{- template "config.connectors.genai_metrics.user_id" $ }}
      histogram:
        buckets: {{ $agentBuckets | toJson }}
        value: Seconds(end_time - start_time)

    - name: gen_ai.invoke_workflow.duration
      description: Measures the duration of a workflow execution.
      unit: s
      conditions:
        - attributes["gen_ai.operation.name"] == "invoke_workflow"
      {{- template "config.connectors.genai_metrics.resource_attributes" }}
      attributes:
        {{- template "config.connectors.genai_metrics.optional_attributes" (list "gen_ai.workflow.name" "error.type") }}
      {{- template "config.connectors.genai_metrics.conversation_id" $ }}
      {{- template "config.connectors.genai_metrics.user_id" $ }}
      histogram:
        buckets: {{ $workflowBuckets | toJson }}
        value: Seconds(end_time - start_time)
{{- end -}}
