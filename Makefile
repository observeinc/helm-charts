CHARTS := $(shell dirname `find . -name Chart.yaml`)

.PHONY: update-deps
update-deps:
	helm repo up
	@for chart in $(CHARTS); do \
		helm dependency update --skip-refresh $$chart; \
	done

.PHONY: build-deps
build-deps: 
	@helm repo add grafana https://grafana.github.io/helm-charts >/dev/null
	@helm repo add fluent https://fluent.github.io/helm-charts >/dev/null
	@helm repo add otel https://open-telemetry.github.io/opentelemetry-helm-charts >/dev/null
	@helm repo up >/dev/null
	@for chart in $(CHARTS); do \
		helm dependency build --skip-refresh $$chart; \
	done

.PHONY: test
test: load-test-images
	test/test.sh

.PHONY: lint
lint: build-deps
	ct lint --all --helm-dependency-extra-args='--skip-refresh'

.PHONY: clean
clean:
	test/clean.sh

.PHONY: build-test-images
build-test-images:
	make -C test/cmd client.image collector.image

.PHONY: load-test-images
load-test-images: build-test-images
	kind load docker-image -n chart-testing test-client:latest
	kind load docker-image -n chart-testing test-collector:latest
