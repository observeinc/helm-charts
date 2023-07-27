package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"regexp"

	"github.com/jmespath/go-jmespath"
	"github.com/spf13/cobra"
)

func main() {
	clientCmd := &cobra.Command{
		Use: "client",
	}
	checkCmd := &cobra.Command{
		Use:   "check [-f queryfile] URL",
		Short: "run queries from standard input against the response from the given URL",
		Long:  "run queries from standard input against the response from the given URL",
		Args:  cobra.MatchAll(cobra.ExactArgs(1)),
		Run:   check,
	}
	checkCmd.Flags().StringP("queryfile", "f", "", "Read queries from the given file (if unset, queries will be read from stdin)")
	clientCmd.AddCommand(checkCmd)

	if err := clientCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}

type request struct {
	Path   string
	Header http.Header
}

func check(cmd *cobra.Command, args []string) {
	url := args[0]
	res, err := http.Get(url)
	if err != nil {
		fmt.Fprintf(os.Stderr, "check: %v\n", err)
		os.Exit(2)
	}

	var requests []request

	reqScanner := bufio.NewScanner(res.Body)
	for reqScanner.Scan() {
		var req request
		if err := json.Unmarshal(reqScanner.Bytes(), &req); err != nil {
			fmt.Fprintf(os.Stderr, "check: unmarshal request: %v\n", err)
			os.Exit(2)
		}
		requests = append(requests, req)
	}
	if err := reqScanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "check: scan requests: %v\n", err)
		os.Exit(2)
	}

	f := os.Stdin
	if fname, _ := cmd.Flags().GetString("queryfile"); fname != "" {
		f, err = os.Open(fname)
		if err != nil {
			fmt.Fprintf(os.Stderr, "check: queryfile: %v\n", err)
			os.Exit(2)
		}
	}

	queryScanner := bufio.NewScanner(f)
	status := 0
	for queryScanner.Scan() {
		query, err := newQuery(queryScanner.Text())
		if err != nil {
			fmt.Fprintf(os.Stderr, "check: failed to compile query %s: %v\n", query, err)
			os.Exit(2)
		}
		if matches := query.run(requests); matches < 1 {
			fmt.Printf("FAIL: 0 matches for %s\n", query)
			status = 1
		} else {
			fmt.Printf("PASS: %d matches for %s\n", matches, query)
		}
	}
	if err := queryScanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "check: scan queries: %v\n", err)
		os.Exit(2)
	}
	os.Exit(status)
}

type query struct {
	path            string
	pathCompiled    *jmespath.JMESPath
	pattern         string
	patternCompiled *regexp.Regexp
}

func newQuery(s string) (*query, error) {
	var path, pattern string
	n, err := fmt.Sscanf(s, "%s -> %s", &path, &pattern)
	if err != nil {
		return nil, fmt.Errorf("scan query: %w", err)
	}
	if n != 2 {
		return nil, fmt.Errorf("invalid query syntax %q", s)
	}

	pathCompiled, err := jmespath.Compile(path)
	if err != nil {
		return nil, fmt.Errorf("compile path: %w", err)
	}

	patternCompiled, err := regexp.Compile(pattern)
	if err != nil {
		return nil, fmt.Errorf("compile pattern: %w", err)
	}

	return &query{
		path:            path,
		pathCompiled:    pathCompiled,
		pattern:         pattern,
		patternCompiled: patternCompiled,
	}, nil
}

func (q *query) String() string {
	return fmt.Sprintf("%s -> %s", q.path, q.pattern)
}

func (q *query) match(v any) bool {
	v, err := q.pathCompiled.Search(v)
	if err != nil {
		return false
	}
	return q.patternCompiled.MatchString(fmt.Sprintf("%s", v))
}

func (q *query) run(requests []request) int {
	matches := 0
	for _, req := range requests {
		if q.match(req) {
			matches++
		}
	}
	return matches
}
