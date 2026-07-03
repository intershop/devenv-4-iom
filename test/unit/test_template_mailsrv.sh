#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

TEMPLATE="$DEVENV_DIR/templates/mailsrv.yml.template"
PROPS="$SCRIPT_DIR/test.properties.default"
RENDER="$DEVENV_DIR/bin/template_engine.sh"

echo "=== mailsrv.yml.template ==="

test_case "template renders without error"
OUTPUT=$("$RENDER" --template="$TEMPLATE" --config="$PROPS" --project-dir="$DEVENV_DIR" 2>&1)
assert_exit_success "exit code 0" $?

test_case "uses configured mailsrv image"
assert_contains "mailsrv image substituted" "$OUTPUT" "image: axllent/mailpit"

test_case "service type is LoadBalancer"
assert_contains "LoadBalancer service" "$OUTPUT" "type: LoadBalancer"

test_case "UI port present"
assert_contains "UI port present" "$OUTPUT" "targetPort: 8025"

test_case "SMTP port present"
assert_contains "SMTP port present" "$OUTPUT" "targetPort: 1025"

test_case "imagePullPolicy is IfNotPresent (default)"
assert_contains "imagePullPolicy substituted" "$OUTPUT" "imagePullPolicy: IfNotPresent"

test_case "no unsubstituted variables"
assert_not_contains "no raw MAILSRV_IMAGE" "$OUTPUT" '${MAILSRV_IMAGE}'
assert_not_contains "no raw IMAGE_PULL_POLICY_MAILSRV" "$OUTPUT" '${IMAGE_PULL_POLICY_MAILSRV}'

test_summary
