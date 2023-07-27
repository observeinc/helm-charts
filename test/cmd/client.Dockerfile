FROM golang:alpine AS builder
RUN apk update && apk add --no-cache git
RUN mkdir /client
WORKDIR /client
COPY . /client
RUN go mod download
RUN go build -o /client/out ./client

FROM alpine:latest
COPY --from=builder /client/out /client
ENTRYPOINT ["/client"]
