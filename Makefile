# Charts will have their dependencies built in the order defined here. Endpoint is
# a dependency of all charts, and should thus always be first in the list. Stack
# and traces are umbrella charts and should always be at the end of the list.
CHARTS := endpoint proxy events logs metrics stack traces

.PHONY: all
all: build-deps lint test

add-repos:
	@helm repo add observe https://observeinc.github.io/helm-charts
	@helm repo add grafana https://grafana.github.io/helm-charts
	@helm repo add fluent https://fluent.github.io/helm-charts
	@helm repo add otel https://open-telemetry.github.io/opentelemetry-helm-charts
	helm repo up

.PHONY: update-deps
update-deps: add-repos
	@for chart in $(CHARTS); do \
		helm dependency update --skip-refresh charts/$$chart; \
	done

.PHONY: build-deps
build-deps: add-repos
	@for chart in $(CHARTS); do \
		echo building chart dependencies for charts/$$chart...; \
		helm dependency build --skip-refresh charts/$$chart; \
		echo ; \
	done

.PHONY: test
test: build-deps build-test-images
	test/test.sh stack traces

.PHONY: lint
lint: build-deps
	ct lint --all --helm-dependency-extra-args='--skip-refresh'

.PHONY: clean
clean:
	test/clean.sh
	@for chart in $(CHARTS); do \
		echo rm -f charts/$$chart/charts/*.tgz; \
		rm -f charts/$$chart/charts/*.tgz; \
	done
	make -C test/cmd clean

.PHONY: build-test-images
build-test-images:
	make -C test/cmd all
