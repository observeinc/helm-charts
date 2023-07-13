CHARTS := $(shell dirname `find . -name Chart.yaml`)

.PHONY: update-deps
update-deps:
	@for chart in $(CHARTS); do \
		helm dependency update $$chart; \
	done

.PHONY: build-deps
build-deps:
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo add fluent https://fluent.github.io/helm-charts
	helm repo add otel https://open-telemetry.github.io/opentelemetry-helm-charts
	helm repo update
	@for chart in $(CHARTS); do \
		helm dependency build --skip-refresh $$chart; \
	done

.PHONY: test
test:
	test/test.sh

.PHONY: test-images
test-images:
	$(MAKE) -C test/cmd client.image collector.image

