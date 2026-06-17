#!/bin/bash
# Runs the integration test suite against the current Rancher Desktop cluster.
# Prerequisites: setup.sh must have been run first.
#
# Usage:
#   test/run-integration-tests.sh             # run all integration tests
#   test/run-integration-tests.sh lifecycle   # run only test_cluster_lifecycle.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PASSED=0
FAILED=0
ERRORS=()

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

# Verify cluster is reachable before running any tests
kubectl cluster-info --context=rancher-desktop > /dev/null 2>&1 || {
    echo "ERROR: Rancher Desktop cluster not reachable. Start Rancher Desktop with Kubernetes enabled."
    exit 1
}

FILTER="${1:-}"

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
