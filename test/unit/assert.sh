#!/bin/bash

# Minimal assert library for template unit tests.
# Usage: source this file, then call assert_contains / assert_not_contains.
# Each test script must call test_summary at the end.

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""

test_case() {
    CURRENT_TEST="$1"
}

assert_contains() {
    local description="$1"
    local output="$2"
    local expected="$3"
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
    local description="$1"
    local output="$2"
    local unexpected="$3"
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
    local description="$1"
    local exit_code="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$exit_code" -eq 0 ]; then
        echo "  PASS: $description"
    else
        echo "  FAIL: $description (exit code: $exit_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
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
