package main

import (
	"context"
	"fmt"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/trace"
)

func initTraceExporter() (trace.Tracer, error) {
	client := otlptracehttp.NewClient(otlptracehttp.WithRetry(otlptracehttp.RetryConfig{
		Enabled:         true,
		InitialInterval: 1 * time.Second,
		MaxInterval:     10 * time.Second,
		MaxElapsedTime:  30 * time.Second,
	}))
	exporter, err := otlptrace.New(context.Background(), client)
	if err != nil {
		return nil, fmt.Errorf("create OTLP trace exporter: %w", err)
	}

	tracerProvider := sdktrace.NewTracerProvider(sdktrace.WithBatcher(exporter))
	otel.SetTracerProvider(tracerProvider)

	return otel.GetTracerProvider().Tracer(""), nil
}
