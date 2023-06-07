CHARTS := $(shell dirname `find . -name Chart.yaml`)

.PHONY: deps
deps:
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo add fluent https://fluent.github.io/helm-charts
	helm repo add otel https://open-telemetry.github.io/opentelemetry-helm-charts
	helm repo update
	@for chart in $(CHARTS); do \
		helm dependency update --skip-refresh $$chart; \
	done
