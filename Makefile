CHARTS := $(shell dirname `find . -name Chart.yaml`)

.PHONY: deps
deps:
	@for chart in $(CHARTS); do \
		helm dependency update $$chart; \
	done
