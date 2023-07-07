client.image: client.Dockerfile client/*.go go.mod 
	docker build -q -t test-client:latest -f client.Dockerfile . >client.image

collector.image: collector.Dockerfile collector/*.go go.mod 
	docker build -q -t test-collector:latest -f collector.Dockerfile . >collector.image

.PHONY: build
build: client.image collector.image

.PHONY: clean
clean:
	rm -f client.image collector.image
