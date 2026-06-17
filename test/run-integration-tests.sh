#!/bin/bash
# Runs the integration test suite against a live Kubernetes cluster.
# Prerequisites: setup.sh must have been run first.
#
# Usage:
#   test/run-integration-tests.sh [filter]
#
# filter   Only run scripts whose name contains this string.
#          Example: lifecycle  →  runs only test_cluster_lifecycle.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PASSED=0
FAILED=0
ERRORS=()

FILTER="${1:-}"

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

CONTEXT=$(grep '^KUBERNETES_CONTEXT=' "$SCRIPT_DIR/integration/devenv.project.properties" 2>/dev/null | tail -1 | cut -d= -f2-)
CONTEXT="${CONTEXT:-rancher-desktop}"

kubectl cluster-info --context="$CONTEXT" > /dev/null 2>&1 || {
    echo "ERROR: Kubernetes context '$CONTEXT' is not reachable."
    echo "       Check KUBERNETES_CONTEXT in test/integration/devenv.project.properties."
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
