#!/bin/bash
# Tests: create storage / delete storage on kind engine.
# On kind with STORAGE_CLASS=standard, storage is managed by the cluster —
# no docker volume is created.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

CLI="$DEVENV_DIR/bin/devenv-cli.sh"
PROPS="$SCRIPT_DIR/test-component.properties.kind"
CONTEXT="docker-desktop"

echo "=== storage (kind) ==="

# Ensure clean state
"$CLI" "$PROPS" delete storage > /dev/null 2>&1 || true

test_case "create storage succeeds"
"$CLI" "$PROPS" create storage > /dev/null 2>&1
assert_exit_success "exit code 0" $?

test_case "no docker volume created"
TESTS_RUN=$((TESTS_RUN + 1))
if docker volume inspect iomunit-pgdata > /dev/null 2>&1; then
    echo "  FAIL: docker volume iomunit-pgdata was created but should not exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
else
    echo "  PASS: no docker volume created"
fi

test_case "delete storage succeeds (nothing to do)"
"$CLI" "$PROPS" delete storage > /dev/null 2>&1
assert_exit_success "exit code 0" $?

test_summary
