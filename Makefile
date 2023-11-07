# Charts will have their dependencies built in the order defined here. Endpoint is
# a dependency of all charts, and should thus always be first in the list. Stack
# and traces are umbrella charts and should always be at the end of the list.
CHARTS := endpoint proxy events logs metrics stack traces

.PHONY: all
all: build-deps lint test

.PHONY: updatecli/all
updatecli/all: updatecli/external updatecli/internal

.PHONY: updatecli/external
updatecli/external:
	@for file in updatecli/external/*.yml; do \
		echo "Running updatecli for $$file..."; \
		updatecli apply --config $$file; \
	done
	$(MAKE) update-deps

.PHONY: updatecli/internal
updatecli/internal:
	@for file in updatecli/internal/*.yml; do \
		echo "Running updatecli for $$file..."; \
		updatecli apply --config $$file; \
	done
	$(MAKE) update-deps

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

# we need to re-run add-repos inside the docker container to lint correctly
# also see https://github.com/helm/chart-testing/issues/464 about git safe.directory
.PHONY: lint
lint: build-deps
	docker run --rm -v "$$(pwd):/workdir:cached" -w "/workdir/." quay.io/helmpack/chart-testing:latest /bin/bash -c "\
		helm repo add observe https://observeinc.github.io/helm-charts ; \
		helm repo add grafana https://grafana.github.io/helm-charts ; \
		helm repo add fluent https://fluent.github.io/helm-charts ; \
		helm repo add otel https://open-telemetry.github.io/opentelemetry-helm-charts ; \
		helm repo up ; \
		git config --global --add safe.directory /workdir ; \
		ct lint --all --helm-dependency-extra-args='--skip-refresh' \
		"

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

.PHONY: bump-version
bump-version:
	@for chart in $(CHARTS); do \
		CHANGED_FILES=$$(git diff --name-only main...HEAD charts/$$chart/); \
		if [ ! -z "$$CHANGED_FILES" ]; then \
			echo "Files changed in charts/$$chart. Bumping version..."; \
			./bump_version.sh charts/$$chart; \
		fi; \
	done

.PHONY: validate-chart-version
validate-chart-version:
	@for chart in $(CHARTS); do \
		CHANGED_FILES=$$(git diff --name-only origin/main...HEAD charts/$$chart/ | grep -v README.md); \
		if [ ! -z "$$CHANGED_FILES" ]; then \
			CHART_VERSION_LINE=$$(git diff origin/main...HEAD charts/$$chart/Chart.yaml | grep '^+version:' | head -n 1); \
			if [ -z "$$CHART_VERSION_LINE" ]; then \
				echo "Error: charts/$$chart has changed, but Chart.yaml version has not been updated."; \
				exit 1; \
			fi; \
		fi; \
	done
