#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

PROPS="$SCRIPT_DIR/test.properties.kubeadm"
PROPS_KIND="$SCRIPT_DIR/test.properties.kind"
RENDER="$DEVENV_DIR/bin/template_engine.sh"

echo "=== iom-single.yml.template ==="

# IOM_IMAGE is set in test.properties → iom-single.yml.template is used
TEMPLATE="$DEVENV_DIR/templates/iom-single.yml.template"

test_case "kubeadm: template renders without error"
OUTPUT=$("$RENDER" --template="$TEMPLATE" --config="$PROPS" --project-dir="$DEVENV_DIR" 2>&1)
assert_exit_success "exit code 0" $?

test_case "kubeadm: IOM image substituted"
assert_contains "IOM image present" "$OUTPUT" "image: ci-iom:5.1.0-1.0.0-SNAPSHOT"

test_case "kubeadm: dbaccount image substituted"
assert_contains "dbaccount image present" "$OUTPUT" "image: iom-dbaccount:1.5.0"

test_case "kubeadm: imagePullPolicy is IfNotPresent"
assert_contains "imagePullPolicy substituted" "$OUTPUT" "imagePullPolicy: IfNotPresent"

test_case "kubeadm: service type is LoadBalancer"
assert_contains "LoadBalancer service" "$OUTPUT" "type: LoadBalancer"

test_case "kubeadm: DB host points to postgres-service"
assert_contains "DB host is postgres-service" "$OUTPUT" "value: postgres-service"

test_case "kubeadm: no unsubstituted variables"
assert_not_contains "no raw IOM_IMAGE" "$OUTPUT" '${IOM_IMAGE}'
assert_not_contains "no raw IOM_DBACCOUNT_IMAGE" "$OUTPUT" '${IOM_DBACCOUNT_IMAGE}'
assert_not_contains "no raw IMAGE_PULL_POLICY" "$OUTPUT" '${IMAGE_PULL_POLICY}'

test_case "kubeadm: custom dir volumes commented out when CUSTOM_*_DIR unset"
assert_contains "application-dev volume commented out" "$OUTPUT" "#      - name: application-dev"
assert_contains "templates-dev volume commented out" "$OUTPUT" "#      - name: templates-dev"

test_case "kind: template renders identically (IOM template is not storage-dependent)"
OUTPUT_KIND=$("$RENDER" --template="$TEMPLATE" --config="$PROPS_KIND" --project-dir="$DEVENV_DIR" 2>&1)
assert_exit_success "exit code 0" $?
assert_contains "IOM image present" "$OUTPUT_KIND" "image: ci-iom:5.1.0-1.0.0-SNAPSHOT"
assert_contains "imagePullPolicy substituted" "$OUTPUT_KIND" "imagePullPolicy: IfNotPresent"

test_summary
