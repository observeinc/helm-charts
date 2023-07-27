FROM golang:alpine AS builder
RUN apk update && apk add --no-cache git
RUN mkdir /collector
WORKDIR /collector
COPY . /collector
RUN go mod download
RUN go build -o /collector/out ./collector

FROM scratch
COPY --from=builder /collector/out /collector
ENTRYPOINT ["/collector"]
