#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

PROPS="$SCRIPT_DIR/test.properties.default"
RENDER="$DEVENV_DIR/bin/template_engine.sh"

echo "=== playwright.properties.template ==="

TEMPLATE="$DEVENV_DIR/templates/playwright.properties.template"

test_case "template renders without error"
OUTPUT=$("$RENDER" --template="$TEMPLATE" --config="$PROPS" --project-dir="$DEVENV_DIR" 2>&1)
assert_exit_success "exit code 0" $?

test_case "app host substituted"
assert_contains "is.oms.app.host present" "$OUTPUT" "is.oms.app.host"

test_case "http port substituted"
assert_contains "is.oms.app.http.port present" "$OUTPUT" "is.oms.app.http.port"

test_case "db hostlist substituted"
assert_contains "is.oms.db.hostlist present" "$OUTPUT" "is.oms.db.hostlist"

test_case "db name substituted"
assert_contains "is.oms.db.name present" "$OUTPUT" "is.oms.db.name"

test_case "db user substituted"
assert_contains "is.oms.db.user present" "$OUTPUT" "is.oms.db.user"

test_case "db pass substituted"
assert_contains "is.oms.db.pass present" "$OUTPUT" "is.oms.db.pass"

test_case "no unsubstituted variables"
assert_not_contains "no raw HostIom" "$OUTPUT" '${HostIom}'
assert_not_contains "no raw PORT_IOM_SERVICE" "$OUTPUT" '${PORT_IOM_SERVICE}'
assert_not_contains "no raw PgHostExtern" "$OUTPUT" '${PgHostExtern}'
assert_not_contains "no raw PgPortExtern" "$OUTPUT" '${PgPortExtern}'
assert_not_contains "no raw OMS_DB_NAME" "$OUTPUT" '${OMS_DB_NAME}'
assert_not_contains "no raw OMS_DB_USER" "$OUTPUT" '${OMS_DB_USER}'
assert_not_contains "no raw OMS_DB_PASS" "$OUTPUT" '${OMS_DB_PASS}'

test_summary
