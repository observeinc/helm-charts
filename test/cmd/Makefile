client.image: client.Dockerfile client.out
	docker build -q -t test-client:latest -f client.Dockerfile . >client.image

client.out:  client/*.go go.mod
	go build -o client.out client

collector.image: collector.Dockerfile collector.out
	docker build -q -t test-collector:latest -f collector.Dockerfile . >collector.image

collector.out:  collector/*.go go.mod
	go build -o collector.out collector

.PHONY: build
build: client.image collector.image

.PHONY: clean
clean:
	rm -f {client,collector}.{out,image}
