#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

TEMPLATE="$DEVENV_DIR/templates/mailsrv.yml.template"
PROPS="$SCRIPT_DIR/test.properties.kubeadm"
PROPS_KIND="$SCRIPT_DIR/test.properties.kind"
RENDER="$DEVENV_DIR/bin/template_engine.sh"

echo "=== mailsrv.yml.template ==="

test_case "kubeadm: template renders without error"
OUTPUT=$("$RENDER" --template="$TEMPLATE" --config="$PROPS" --project-dir="$DEVENV_DIR" 2>&1)
assert_exit_success "exit code 0" $?

test_case "kubeadm: uses configured mailsrv image"
assert_contains "mailsrv image substituted" "$OUTPUT" "image: axllent/mailpit"

test_case "kubeadm: service type is LoadBalancer"
assert_contains "LoadBalancer service" "$OUTPUT" "type: LoadBalancer"

test_case "kubeadm: UI port present"
assert_contains "UI port present" "$OUTPUT" "targetPort: 8025"

test_case "kubeadm: SMTP port present"
assert_contains "SMTP port present" "$OUTPUT" "targetPort: 1025"

test_case "kubeadm: no unsubstituted variables"
assert_not_contains "no raw variable references" "$OUTPUT" '${MAILSRV_IMAGE}'

test_case "kind: template renders identically (mailsrv is not storage-dependent)"
OUTPUT_KIND=$("$RENDER" --template="$TEMPLATE" --config="$PROPS_KIND" --project-dir="$DEVENV_DIR" 2>&1)
assert_exit_success "exit code 0" $?
assert_contains "mailsrv image substituted" "$OUTPUT_KIND" "image: axllent/mailpit"
assert_contains "LoadBalancer service" "$OUTPUT_KIND" "type: LoadBalancer"

test_summary
