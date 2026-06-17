#!/bin/bash
# Runs the integration test suite against a live Kubernetes cluster.
# Prerequisites: setup.sh must have been run first.
#
# Usage:
#   test/run-integration-tests.sh [--config=<file>] [filter]
#
# --config=<file>   Override properties file — values in this file take
#                   precedence over the defaults in test.properties.rancher-desktop
#                   and test-component.properties.rancher-desktop.  Use this to
#                   supply image names and the Kubernetes context for CI environments.
#
# filter            Only run scripts whose name contains this string.
#                   Example: lifecycle  →  runs only test_cluster_lifecycle.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PASSED=0
FAILED=0
ERRORS=()

# Parse arguments
CONFIG_OVERRIDE=""
FILTER=""
for ARG in "$@"; do
    case "$ARG" in
        --config=*) CONFIG_OVERRIDE="${ARG#--config=}" ;;
        *) FILTER="$ARG" ;;
    esac
done

if [ -n "$CONFIG_OVERRIDE" ] && [ ! -f "$CONFIG_OVERRIDE" ]; then
    echo "ERROR: config file not found: $CONFIG_OVERRIDE"
    exit 1
fi

export INTEGRATION_TEST_CONFIG="$CONFIG_OVERRIDE"

# Determine Kubernetes context for the reachability check.
# Read from override file first, fall back to the base properties file, then
# fall back to rancher-desktop.
KUBERNETES_CONTEXT="rancher-desktop"
for PROPS_FILE in "$SCRIPT_DIR/integration/test.properties.rancher-desktop" "$CONFIG_OVERRIDE"; do
    if [ -n "$PROPS_FILE" ] && [ -f "$PROPS_FILE" ]; then
        VAL=$(grep '^KUBERNETES_CONTEXT=' "$PROPS_FILE" 2>/dev/null | tail -1 | cut -d= -f2-)
        [ -n "$VAL" ] && KUBERNETES_CONTEXT="$VAL"
    fi
done

run_test() {
    local TEST_FILE="$1"
    local TEST_NAME
    TEST_NAME="$(basename "$TEST_FILE")"
    echo ""
    OUTPUT=$(bash "$TEST_FILE" 2>&1)
    EXIT_CODE=$?
    echo "$OUTPUT"
    if [ $EXIT_CODE -eq 0 ]; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
        ERRORS+=("$TEST_NAME")
    fi
}

echo "=============================="
echo " devenv-4-iom integration tests"
echo "=============================="

kubectl cluster-info --context="$KUBERNETES_CONTEXT" > /dev/null 2>&1 || {
    echo "ERROR: Kubernetes context '$KUBERNETES_CONTEXT' is not reachable."
    echo "       Start your cluster or pass --config=<file> with KUBERNETES_CONTEXT set."
    exit 1
}

if [ -n "$FILTER" ]; then
    for TEST in "$SCRIPT_DIR/integration"/test_*"$FILTER"*.sh; do
        run_test "$TEST"
    done
else
    for TEST in \
        "$SCRIPT_DIR/integration/test_postgres.sh" \
        "$SCRIPT_DIR/integration/test_mailserver.sh" \
        "$SCRIPT_DIR/integration/test_cluster_lifecycle.sh"; do
        run_test "$TEST"
    done
fi

echo ""
echo "=============================="
TOTAL=$((PASSED + FAILED))
if [ $FAILED -eq 0 ]; then
    echo " ALL PASSED ($PASSED/$TOTAL test scripts)"
else
    echo " FAILED: $FAILED/$TOTAL test scripts"
    for ERR in "${ERRORS[@]}"; do
        echo "   - $ERR"
    done
fi
echo "=============================="

[ $FAILED -eq 0 ]
