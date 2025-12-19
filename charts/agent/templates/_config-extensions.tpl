{{- define "config.extensions.file_storage" -}}
file_storage:
  create_directory: true
{{- end -}}

{{- define "config.extensions.file_storage_fargate" -}}
file_storage/fargate:
  directory: /applogs/.file_storage
  create_directory: true
{{- end -}}
