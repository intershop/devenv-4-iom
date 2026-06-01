#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

TEMPLATE="$DEVENV_DIR/templates/postgres.yml.template"
PROPS="$SCRIPT_DIR/test.properties.kubeadm"
PROPS_KIND="$SCRIPT_DIR/test.properties.kind"
RENDER="$DEVENV_DIR/bin/template_engine.sh"

echo "=== postgres.yml.template ==="

# --- kubeadm path (no STORAGE_CLASS) ---

test_case "kubeadm: template renders without error"
OUTPUT=$("$RENDER" --template="$TEMPLATE" --config="$PROPS" --project-dir="$DEVENV_DIR" 2>&1)
assert_exit_success "exit code 0" $?

test_case "kubeadm: uses configured postgres image"
assert_contains "postgres image substituted" "$OUTPUT" "image: postgres:15"

test_case "kubeadm: inline PVC is commented out (managed by postgres-storage.yml)"
assert_contains "inline PVC is commented out" "$OUTPUT" "#kind: PersistentVolumeClaim"
# verify no uncommented PVC kind line exists
TESTS_RUN=$((TESTS_RUN + 1))
if echo "$OUTPUT" | grep -qE '^kind: PersistentVolumeClaim'; then
    echo "  FAIL: active PVC kind line found (should be commented out)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
else
    echo "  PASS: no active PVC kind line (correctly commented out)"
fi

test_case "kubeadm: PVC volume reference present"
assert_contains "PVC claimName present" "$OUTPUT" "claimName: postgres-pvc"

test_case "kubeadm: service type is LoadBalancer"
assert_contains "LoadBalancer service" "$OUTPUT" "type: LoadBalancer"

test_case "kubeadm: volume mount included (KEEP_DATABASE_DATA=true)"
assert_contains "volume mount included" "$OUTPUT" "mountPath: /var/lib/postgresql/data"

test_case "kubeadm: no unsubstituted variables in output"
assert_not_contains "no raw variable references" "$OUTPUT" '${STORAGE_CLASS}'
assert_not_contains "no raw DOCKER_DB_IMAGE" "$OUTPUT" '${DOCKER_DB_IMAGE}'

# --- kind path (STORAGE_CLASS=standard) ---

test_case "kind: template renders without error"
OUTPUT_KIND=$("$RENDER" --template="$TEMPLATE" --config="$PROPS_KIND" --project-dir="$DEVENV_DIR" 2>&1)
assert_exit_success "exit code 0" $?

test_case "kind: inline PVC is present"
assert_contains "inline PVC rendered" "$OUTPUT_KIND" "kind: PersistentVolumeClaim"

test_case "kind: PVC uses standard StorageClass"
assert_contains "storageClassName is standard" "$OUTPUT_KIND" "storageClassName: standard"

test_case "kind: PVC does not reference env-scoped StorageClass"
assert_not_contains "no env-scoped StorageClass in PVC" "$OUTPUT_KIND" "storageClassName: test-postgres-storage"

test_case "kind: postgres image still correct"
assert_contains "postgres image substituted" "$OUTPUT_KIND" "image: postgres:15"

test_summary
