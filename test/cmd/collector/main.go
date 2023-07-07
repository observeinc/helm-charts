package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"strings"
	"sync"
)

type requestBuffer struct {
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
	for _, req := range buf.requests {
		fmt.Fprintln(w, req.String())
	}
}

func main() {
	buf := new(requestBuffer)

	var listen string
	flag.StringVar(&listen, "listen", ":8080", "HTTP listen address")
	flag.IntVar(&buf.maxSize, "max-size", 1000, "Maximum number of requests to record")
	flag.Parse()

	http.HandleFunc("/dump", buf.dump)
	http.HandleFunc("/", buf.collect)
	log.Printf("listening on %v", listen)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
