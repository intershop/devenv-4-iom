#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

TEMPLATE="$DEVENV_DIR/templates/postgres.yml.template"
PROPS="$SCRIPT_DIR/test.properties.default"
RENDER="$DEVENV_DIR/bin/template_engine.sh"

echo "=== postgres.yml.template ==="

test_case "template renders without error"
OUTPUT=$("$RENDER" --template="$TEMPLATE" --config="$PROPS" --project-dir="$DEVENV_DIR" 2>&1)
assert_exit_success "exit code 0" $?

test_case "uses configured postgres image"
assert_contains "postgres image substituted" "$OUTPUT" "image: postgres:17"

test_case "hostPath volume present (POSTGRES_DATA_DIR set)"
assert_contains "hostPath volume defined" "$OUTPUT" "hostPath:"
EXPECTED_PATH="$(mkdir -p /tmp/test-pgdata && realpath /tmp/test-pgdata)"
assert_contains "hostPath path set (absolute)" "$OUTPUT" "path: \"$EXPECTED_PATH\""

test_case "no PVC in output"
assert_not_contains "no PVC kind line" "$OUTPUT" "kind: PersistentVolumeClaim"
assert_not_contains "no storageClassName" "$OUTPUT" "storageClassName:"

test_case "volume mount present"
assert_contains "volume mount included" "$OUTPUT" "mountPath: /var/lib/postgresql"

test_case "service type is LoadBalancer"
assert_contains "LoadBalancer service" "$OUTPUT" "type: LoadBalancer"

test_case "imagePullPolicy is IfNotPresent (default)"
assert_contains "imagePullPolicy substituted" "$OUTPUT" "imagePullPolicy: IfNotPresent"

test_case "no unsubstituted variables"
assert_not_contains "no raw POSTGRES_IMAGE" "$OUTPUT" '${POSTGRES_IMAGE}'
assert_not_contains "no raw PostgresDataDirAbs" "$OUTPUT" '${PostgresDataDirAbs}'
assert_not_contains "no raw IMAGE_PULL_POLICY_POSTGRES" "$OUTPUT" '${IMAGE_PULL_POLICY_POSTGRES}'

# relative path: should be resolved against PROJECT_DIR to an absolute path
test_case "relative POSTGRES_DATA_DIR: resolved to absolute path"
TMPDIR_REL="$(mktemp -d)"
TMPPROPS="$TMPDIR_REL/test.properties"
echo "POSTGRES_DATA_DIR=pgdata" > "$TMPPROPS"
OUTPUT_REL=$("$RENDER" --template="$TEMPLATE" --config="$TMPPROPS" --project-dir="$TMPDIR_REL" 2>&1)
EXPECTED_REL="$(realpath "$TMPDIR_REL/pgdata")"
assert_contains "hostPath present for relative path" "$OUTPUT_REL" "hostPath:"
assert_not_contains "no raw relative path in output" "$OUTPUT_REL" 'path: "pgdata"'
assert_contains "resolved to absolute path" "$OUTPUT_REL" "path: \"$EXPECTED_REL\""
rm -rf "$TMPDIR_REL"

# unset: no hostPath, no volume mount
test_case "no POSTGRES_DATA_DIR: hostPath volume commented out"
OUTPUT_NODATA=$("$RENDER" --template="$TEMPLATE" --config=/dev/null --project-dir="$DEVENV_DIR" 2>&1)
assert_not_contains "no hostPath when unset" "$OUTPUT_NODATA" "hostPath:"
assert_not_contains "no volumeMount when unset" "$OUTPUT_NODATA" "mountPath: /var/lib/postgresql/data"


test_summary
