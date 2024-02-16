{{/*
Use @INCLUDE command to include the content of the files specified in extraFiles
*/}}
{{- define "observe.includeExtraFiles" -}}
{{- range $key, $value := .Values.config.extraFiles }}
@INCLUDE {{ $key }}
{{- end }}
{{- end }}
