#!/bin/bash

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
echo " devenv-4-iom unit tests"
echo "=============================="

for TEST in "$SCRIPT_DIR/unit"/test_*.sh; do
    run_test "$TEST"
done

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
