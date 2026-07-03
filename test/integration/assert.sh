#!/bin/bash
# Integration test assert library.
# Same interface as unit/assert.sh but with a wait helper for Kubernetes resources.

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""

test_case() { CURRENT_TEST="$1"; }

assert_contains() {
    local description="$1" output="$2" expected="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if echo "$output" | grep -qF "$expected"; then
        echo "  PASS: $description"
    else
        echo "  FAIL: $description"
        echo "        expected to find: $expected"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_not_contains() {
    local description="$1" output="$2" unexpected="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if echo "$output" | grep -qF "$unexpected"; then
        echo "  FAIL: $description"
        echo "        expected NOT to find: $unexpected"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo "  PASS: $description"
    fi
}

assert_exit_success() {
    local description="$1" exit_code="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$exit_code" -eq 0 ]; then
        echo "  PASS: $description"
    else
        echo "  FAIL: $description (exit code: $exit_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Wait until a kubectl condition is met or timeout is reached.
# $1: description
# $2: timeout in seconds
# $3+: kubectl command (without --context, that is added by wait_for)
# Usage: wait_for "PVC bound" 60 get pvc postgres-pvc -n iom-test -o jsonpath=...
wait_for() {
    local description="$1"
    local timeout="$2"
    shift 2
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if eval "$@" > /dev/null 2>&1; then
            return 0
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    echo "  TIMEOUT: $description (waited ${timeout}s)"
    return 1
}

# Wait until a LoadBalancer service has an external IP or hostname assigned.
# $1: service name
# $2: namespace
# $3: context
# $4: timeout in seconds
wait_for_external_ip() {
    local svc="$1" namespace="$2" context="$3" timeout="$4"
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        local ip
        ip=$(kubectl get service "$svc" -n "$namespace" --context="$context" \
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        [ -n "$ip" ] && echo "$ip" && return 0
        sleep 5
        elapsed=$((elapsed + 5))
    done
    return 1
}

# Wait until a pod with the given label reaches Running phase.
# $1: app label value
# $2: namespace
# $3: context
# $4: timeout in seconds
wait_for_pod_running() {
    local app="$1" namespace="$2" context="$3" timeout="$4"
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        local phase
        phase=$(kubectl get pods -n "$namespace" --context="$context" \
            -l app="$app" -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
        [ "$phase" = "Running" ] && return 0
        sleep 5
        elapsed=$((elapsed + 5))
    done
    return 1
}

test_summary() {
    echo ""
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo "PASSED: $TESTS_RUN/$TESTS_RUN tests passed"
    else
        echo "FAILED: $TESTS_FAILED/$TESTS_RUN tests failed"
    fi
    [ "$TESTS_FAILED" -eq 0 ]
}
