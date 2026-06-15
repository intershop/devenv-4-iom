#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

TEMPLATE="$DEVENV_DIR/templates/postgres.yml.template"
RENDER="$DEVENV_DIR/bin/template_engine.sh"

echo "=== postgres.yml.template ==="

for ENGINE in kubeadm kind; do
    PROPS="$SCRIPT_DIR/test.properties.$ENGINE"

    test_case "$ENGINE: template renders without error"
    OUTPUT=$("$RENDER" --template="$TEMPLATE" --config="$PROPS" --project-dir="$DEVENV_DIR" 2>&1)
    assert_exit_success "exit code 0" $?

    test_case "$ENGINE: uses configured postgres image"
    assert_contains "postgres image substituted" "$OUTPUT" "image: postgres:15"

    test_case "$ENGINE: hostPath volume present (POSTGRES_DATA_DIR set)"
    assert_contains "hostPath volume defined" "$OUTPUT" "hostPath:"
    assert_contains "hostPath path set" "$OUTPUT" "path: \"/tmp/test-pgdata\""

    test_case "$ENGINE: no PVC in output"
    assert_not_contains "no PVC kind line" "$OUTPUT" "kind: PersistentVolumeClaim"
    assert_not_contains "no storageClassName" "$OUTPUT" "storageClassName:"

    test_case "$ENGINE: volume mount present"
    assert_contains "volume mount included" "$OUTPUT" "mountPath: /var/lib/postgresql/data"

    test_case "$ENGINE: service type is LoadBalancer"
    assert_contains "LoadBalancer service" "$OUTPUT" "type: LoadBalancer"

    test_case "$ENGINE: no unsubstituted variables"
    assert_not_contains "no raw DOCKER_DB_IMAGE" "$OUTPUT" '${DOCKER_DB_IMAGE}'
    assert_not_contains "no raw POSTGRES_DATA_DIR" "$OUTPUT" '${POSTGRES_DATA_DIR}'
done

# also test: POSTGRES_DATA_DIR unset → no hostPath, no volume mount
test_case "no POSTGRES_DATA_DIR: hostPath volume commented out"
OUTPUT_NODATA=$("$RENDER" --template="$TEMPLATE" --config=/dev/null --project-dir="$DEVENV_DIR" 2>&1)
assert_not_contains "no hostPath when unset" "$OUTPUT_NODATA" "hostPath:"
assert_not_contains "no volumeMount when unset" "$OUTPUT_NODATA" "mountPath: /var/lib/postgresql/data"

test_summary
