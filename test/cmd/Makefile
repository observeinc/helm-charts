GOBUILD ?= true

# Allows us to skip go build in CI, where the images will always be built anyway.
# Locally, it's nice to skip rebuilding when there's been no changes, and having
# the docker images depend on the go binaries means Make's incremental build
# calculations work nicely.
ifeq ($(GOBUILD), true)
CLIENT_OUT = client.out
COLLECTOR_OUT = collector.out
endif

.PHONY: all
all: client.image collector.image

client.image: client.Dockerfile $(CLIENT_OUT)
	docker build -q -t test-client:latest -f client.Dockerfile . >client.image

client.out:  client/*.go go.mod
	go build -o client.out ./client

collector.image: collector.Dockerfile $(COLLECTOR_OUT)
	docker build -q -t test-collector:latest -f collector.Dockerfile . >collector.image

collector.out:  collector/*.go go.mod
	go build -o collector.out ./collector

.PHONY: clean
clean:
	rm -f {client,collector}.{out,image}
