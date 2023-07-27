
{{- /*
If a collection endpoint is provided, parse the scheme from that.
Otherwise, fall back to legacy collectorScheme value.
*/}}
{{- define "observe.collectorScheme" -}}{{- with .Values.global.observe -}}
    {{- if .collectionEndpoint -}}
        {{- with urlParse .collectionEndpoint -}}
            {{- .scheme -}}
        {{- end -}}
    {{- else -}}
        {{- .collectorScheme | default "https" -}}
    {{- end -}}
{{- end -}}{{- end -}}

{{- /*
If a collection endpoint is provided, parse the host from that and split the host from the port.
Otherwise, use the legacy collectorHost value, the the customer part of the hostname prepended:
<customer_id>.<collectorHost>
*/}}
{{- define "observe.collectorHost" -}}{{- with .Values.global.observe -}}
    {{- if .collectionEndpoint -}}
        {{- with urlParse .collectionEndpoint -}}
            {{- (split ":" .host)._0 -}}
        {{- end -}}
    {{- else -}}
        {{- $noEndpoint := "One of global.observe.collectionEndpoint or global.observe.customer must be defined" -}}
        {{- required $noEndpoint .customer | toString -}}.{{- .collectorHost | default "collect.observeinc.com" -}}
    {{- end -}}
{{- end -}}{{- end -}}

{{- /*
If a collection endpoint is provided, look for a provided port and otherwise try to guess
based on the scheme.
If an endpoint is not provided, fall back to legacy collectorPort.
*/}}
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
        {{- (.collectorPort | default 443) | toString -}}
    {{- end -}}
{{- end -}}{{- end -}}

{{- /*
Return true if the scheme is "https", as parsed from the collection endpoint.
If a collection endpoint is not provided, look at the legacy collectorScheme value.
*/}}
{{- define "observe.useTLS" -}}{{- with .Values.global.observe -}}
    {{- if .collectionEndpoint -}}
       {{- if eq "http" (urlParse .collectionEndpoint).scheme -}}
            false
        {{- else -}}
            true
        {{- end -}}
    {{- else -}}
        {{- if eq "http" .collectorScheme -}}
            false
        {{- else -}}
            true
        {{- end -}}
    {{- end -}}
{{- end -}}{{- end -}}

{{- /*
If a collection endpoint is provided, use that.
Otherwise, generate the endpoint using the legacy values.
Re-constructing the parsed URL eliminates any path that was included in the value.
*/}}
{{- define "observe.collectionEndpoint" -}}
    {{- if .Values.global.observe.collectionEndpoint -}}
        {{- with urlParse .Values.global.observe.collectionEndpoint -}}
            {{- printf "%s://%s" .scheme .host -}}
        {{- end -}}
    {{- else -}}
        {{- printf "%s://%s:%s" (include "observe.collectorScheme" .) (include "observe.collectorHost" .) (include "observe.collectorPort" .) -}}
    {{- end -}}
{{- end -}}

{{- /*
mychart.shortname provides a 6 char truncated version of the release name.
*/}}
{{- define "observe.collectionEndpointWithToken" -}}
    {{- if .Values.global.observe.collectionEndpoint -}}
        {{- with urlParse .Values.global.observe.collectionEndpoint -}}
            {{- printf "%s://$(OBSERVE_TOKEN)@%s" .scheme .host -}}
        {{- end -}}
    {{- else -}}
        {{- printf "%s://$(OBSERVE_TOKEN)@%s:%s" (include "observe.collectorScheme" .) (include "observe.collectorHost" .) (include "observe.collectorPort" .) -}}
    {{- end -}}
{{- end -}}
