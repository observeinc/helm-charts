package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"strings"
	"sync"

	"go.opentelemetry.io/otel/trace"
)

type requestBuffer struct {
	tracer   trace.Tracer
	requests []request
	size     int
	maxSize  int
	full     sync.Once
}

type request struct {
	Path   string
	Header http.Header
	Body   []string
}

func formatHeader(h http.Header) string {
	var headers []string
	for k, v := range h {
		vals := strings.Join(v, ",")
		headers = append(headers, fmt.Sprintf("%s:%s", k, vals))
	}
	return fmt.Sprint(headers)
}

func (buf *requestBuffer) collect(w http.ResponseWriter, req *http.Request) {
	if buf.tracer != nil {
		_, span := buf.tracer.Start(req.Context(), "collect")
		defer span.End()
	}

	if buf.size >= buf.maxSize {
		w.WriteHeader(http.StatusTooManyRequests)
		fmt.Fprintln(w, "buffer full")
		buf.full.Do(func() {
			log.Println("buffer full")
		})
		return
	}
	buf.size++

	h := req.Header
	log.Printf("%q %s", req.URL.Path, formatHeader(h))

	buf.requests = append(buf.requests, request{
		Path:   req.URL.Path,
		Header: req.Header,
	})
	fmt.Fprintf(w, "ok\n")
}

func (req request) String() string {
	b, _ := json.Marshal(req)
	return string(b)
}

func (buf *requestBuffer) dump(w http.ResponseWriter, req *http.Request) {
	if buf.tracer != nil {
		_, span := buf.tracer.Start(req.Context(), "dump")
		defer span.End()
	}

	for _, req := range buf.requests {
		fmt.Fprintln(w, req.String())
	}
}

func (buf *requestBuffer) healthz(w http.ResponseWriter, req *http.Request) {
	if buf.tracer != nil {
		_, span := buf.tracer.Start(req.Context(), "healthz")
		defer span.End()
	}

	fmt.Fprintln(w, "ok")
}

func main() {
	buf := new(requestBuffer)

	var listen string
	var tracing bool
	flag.StringVar(&listen, "listen", ":8080", "HTTP listen address")
	flag.IntVar(&buf.maxSize, "max-size", 1000, "Maximum number of requests to record")
	flag.BoolVar(&tracing, "enable-tracing", false, "enable tracing")
	flag.Parse()

	if tracing {
		tracer, err := initTraceExporter()
		if err != nil {
			log.Fatal(err)
		}
		buf.tracer = tracer

		_, span := tracer.Start(context.Background(), "test-span")
		span.End()
	}

	http.HandleFunc("/", buf.collect)
	http.HandleFunc("/dump", buf.dump)
	http.HandleFunc("/healthz", buf.healthz)
	log.Printf("listening on %v", listen)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
