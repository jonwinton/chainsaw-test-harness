#!/bin/sh
# This script is used to run chainsaw tests as either a Helm test or a Kuberhealthy check.

# kuberhealthy_request sends a request to the Kuberhealthy reporting endpoint.
# Endpoint address is automatically injected as env var KH_REPORTING_URL.
kuberhealthy_request() {
  curl -X POST -d "$1" \
    -H 'Content-Type: application/json' \
    -H "kh-run-uuid: $KH_RUN_UUID" \
    "$KH_REPORTING_URL" -s
}

# kuberhealthy_report_error sends an error message to Kuberhealthy and exits
kuberhealthy_report_error() {
  kuberhealthy_request '{"ok": false, "errors":["'"${1}"'"]}'
}

# kuberhealthy_report_success sends a success status to
kuberhealthy_report_success() {
  kuberhealthy_request '{"ok": true, "errors":[]}'
}

# handle_error is a function that is called when a test fails. It reports the error
# to Kuberhealthy if it is running in a Kuberhealthy check, and exits with a non-zero
handle_error() {
  if [ -n "$KH_RUN_UUID" ]; then
    kuberhealthy_report_error "done with failures"
  fi
  exit 1
}

# handle_success is a function that is called when a test passes
handle_success() {
  if [ -n "$KH_RUN_UUID" ]; then
    kuberhealthy_report_success
  fi
  exit 0
}

chainsaw test --no-color "$@" "..data/" && handle_success || handle_error