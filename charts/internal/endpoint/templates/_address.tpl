# If a collection endpoint is provided, use that.
# Otherwise, generate the endpoint using the legacy values.
{{- define "observe.collectionEndpoint" -}}{{- with .Values.global.observe -}}
    {{- if .collectionEndpoint -}}
        {{- .collectionEndpoint -}}
    {{- else -}}
        {{- $noEndpoint := "One of global.observe.collectionEndpoint or global.observe.customer must be defined" -}}
        {{- printf "%s://%s.%s:%s" .collectorScheme (required $noEndpoint .customer | toString) .collectorHost (.collectorPort | toString) -}}
    {{- end -}}
{{- end -}}{{- end -}}

# Same as "observe.collectionEndpoint", but with the token provided as part of the URL.
{{- define "observe.collectionEndpointWithToken" -}}{{- with .Values.global.observe -}}
    {{- if .collectionEndpoint -}}
        {{- with urlParse .collectionEndpoint -}}
            {{- printf "%s://$(OBSERVE_TOKEN)@%s" .scheme .host -}}
        {{- end -}}
    {{- else -}}
        {{- $noEndpoint := "One of global.observe.collectionEndpoint or global.observe.customer must be defined" -}}
        {{- printf "%s://$(OBSERVE_TOKEN)@%s.%s:%s" .collectorScheme (required $noEndpoint .customer | toString) .collectorHost (.collectorPort | toString) -}}
    {{- end -}}
{{- end -}}{{- end -}}

# If a collection endpoint is provided, parse the scheme from that.
# Otherwise, fall back to legacy collectorScheme value.
{{- define "observe.collectorScheme" -}}{{- with .Values.global.observe -}}
    {{- if .collectionEndpoint -}}
        {{- with urlParse .collectionEndpoint -}}
            {{- .scheme -}}
        {{- end -}}
    {{- else -}}
        {{- .collectorScheme -}}
    {{- end -}}
{{- end -}}{{- end -}}

# If a collection endpoint is provided, parse the host from that and split the host from the port.
# Otherwise, fall back to legacy collectorHost value.
{{- define "observe.collectorHost" -}}{{- with .Values.global.observe -}}
    {{- if .collectionEndpoint -}}
        {{- with urlParse .collectionEndpoint -}}
            {{- (split ":" .host)._0 -}}
        {{- end -}}
    {{- else -}}
        {{- $noEndpoint := "One of global.observe.collectionEndpoint or global.observe.customer must be defined" -}}
        {{- required $noEndpoint .customer | toString -}}.{{- .collectorHost -}}
    {{- end -}}
{{- end -}}{{- end -}}

# If a collection endpoint is provided, look for a provided port and otherwise try to guess
# based on the scheme.
# If an endpoint is not provided, fall back to legacy collectorPort.
{{- define "observe.collectorPort" -}}{{- with .Values.global.observe -}}
    {{- if .collectionEndpoint -}}
        {{- with urlParse .collectionEndpoint -}}
            {{- $parsedPort := (split ":" .host)._1 | toString -}}
            {{- if ne $parsedPort "" -}}
                {{- $parsedPort -}}
            {{- else -}}
                {{- if eq .scheme "https" -}}
                    443
                {{- else -}}
                    80
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- else -}}
        {{- .collectorPort | toString -}}
    {{- end -}}
{{- end -}}{{- end -}}

# Return true if the scheme is "https", as parsed from the collection endpoint.
# If a collection endpoint is not provided, look at the legacy collectorScheme value.
{{- define "observe.useTLS" -}}{{- with .Values.global.observe -}}
    {{- if .collectionEndpoint -}}
       {{- if eq "https" (urlParse .collectionEndpoint).scheme -}}
            true
        {{- else -}}
            false
        {{- end -}}
    {{- else -}}
        {{- if eq "https" .collectorScheme -}}
            true
        {{- else -}}
            false
        {{- end -}}
    {{- end -}}
{{- end -}}{{- end -}}
