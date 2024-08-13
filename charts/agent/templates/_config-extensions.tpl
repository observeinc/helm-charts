{{- define "config.extensions.health_check" -}}
# https://github.com/open-telemetry/opentelemetry-helm-charts/issues/816
# 0.0.0.0 is hack for ipv6 on eks clusters
health_check:
  endpoint: "{{ template "config.local_host"}}:13133"
{{- end -}}
