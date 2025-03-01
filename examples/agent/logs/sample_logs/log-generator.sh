#!/bin/sh

# Set locale to use UTF-8 encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Default values
LOG_TYPE=${LOG_TYPE:-"apache"}   # Default to 'apache' logs if LOG_TYPE is not set
LOG_LENGTH=${LOG_LENGTH:-5}    # Default to 100 lines if LOG_LENGTH is not set
LINE_LENGTH=${LINE_LENGTH:-50}    # Default to 50 characters if LINE_LENGTH is not set
SLEEP_LENGTH=${SLEEP_LENGTH:-2}    # Default to 2s if SLEEP_LENGTH is not set

echo  "LOG_TYPE = $LOG_TYPE"
echo  "LOG_LENGTH = $LOG_LENGTH"
echo  "LINE_LENGTH = $LINE_LENGTH"
echo  "SLEEP_LENGTH = $SLEEP_LENGTH"

# Function to generate a random string of specified length
generate_random_string() {
  local length=$1
  < /dev/urandom tr -dc 'A-Za-z0-9' | head -c "$length"
}

# Function to generate Apache logs
generate_apache_logs() {
  for i in $(seq 1 $LOG_LENGTH); do
    echo "127.0.0.1 - - [$(date +%d/%b/%Y:%H:%M:%S)] \"GET /index.html HTTP/1.1\" 200 $(generate_random_string $LINE_LENGTH)"
  done
}

# Function to generate Nginx logs
generate_nginx_logs() {
  for i in $(seq 1 $LOG_LENGTH); do
    echo "$(date +%d/%b/%Y:%H:%M:%S) | 127.0.0.1 | GET /home | HTTP/1.1 | 200 | $(generate_random_string $LINE_LENGTH)"
  done
}

# Function to generate JSON logs
generate_json_logs() {
  for i in $(seq 1 $LOG_LENGTH); do
    echo "{\"timestamp\": \"$(date +%Y-%m-%dT%H:%M:%S)\", \"level\": \"info\", \"message\": \"$(generate_random_string $LINE_LENGTH)\"}"
  done
}

# Function to generate CSV logs
generate_csv_logs() {
  echo "timestamp, level, message"
  for i in $(seq 1 $LOG_LENGTH); do
    echo "$(date +%Y-%m-%dT%H:%M:%S), info, $(generate_random_string $LINE_LENGTH)"
  done
}

# Function to generate Custom logs
generate_custom_logs() {
  for i in $(seq 1 $LOG_LENGTH); do
    echo "CUSTOM_LOG | $(date +%Y-%m-%dT%H:%M:%S) | $(generate_random_string $LINE_LENGTH)"
  done
}

generate_custom_multiline_logs() {
  for i in $(seq 1 $LOG_LENGTH); do
    echo "$(date +%Y-%m-%dT%H:%M:%S) | CUSTOM_LOG | $(generate_random_string $LINE_LENGTH)"
    echo "  This is the first line of the log message."
    echo "  This is the second line."
    echo "  And this is the third line."
  done
}

# Function to generate Java logs
generate_java_multiline_logs() {
  for i in $(seq 1 $LOG_LENGTH); do
    echo "$(date +%Y-%m-%dT%H:%M:%S) Exception in thread 1 main java.lang.NullPointerException"
    echo "     at com.example.myproject.Book.getTitle(Book.java:16)"
    echo "     at com.example.myproject.Author.getBookTitles(Author.java:25)"
    echo "     at com.example.myproject.Bootstrap.main(Bootstrap.java:14)"
  done
}

# Function to generate Python logs
generate_python_multiline_logs() {
  for i in $(seq 1 $LOG_LENGTH); do
    echo "$(date +%Y-%m-%dT%H:%M:%S) ERROR in app: Exception example"
    echo "Traceback (most recent call last):"
    echo "     This is an example of python traceback"
    echo "     This is the end of the traceback example"
  done
}

# Logic to select the log type
case "$LOG_TYPE" in
  apache)
    while true; do
        generate_apache_logs
        sleep $SLEEP_LENGTH
    done
    ;;
  nginx)
    while true; do
        generate_nginx_logs
        sleep $SLEEP_LENGTH
    done
    ;;
  json)
    while true; do
        generate_json_logs
        sleep $SLEEP_LENGTH
    done
    ;;
  csv)
    while true; do
        generate_csv_logs
        sleep $SLEEP_LENGTH
    done
    ;;
  custom)
    while true; do
        generate_custom_logs
        sleep $SLEEP_LENGTH
    done
    ;;
  custom-multiline)
    while true; do
        generate_custom_multiline_logs
        sleep $SLEEP_LENGTH
    done
    ;;
  java-multiline)
    while true; do
        generate_custom_multiline_logs
        sleep $SLEEP_LENGTH
    done
    ;;
  python-multiline)
    while true; do
        generate_custom_multiline_logs
        sleep $SLEEP_LENGTH
    done
    ;;
  *)
    echo "Unknown log type: $LOG_TYPE"
    ;;
esac
