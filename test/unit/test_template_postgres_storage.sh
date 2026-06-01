#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

TEMPLATE="$DEVENV_DIR/templates/postgres-storage.yml.template"
PROPS="$SCRIPT_DIR/test.properties.kubeadm"
RENDER="$DEVENV_DIR/bin/template_engine.sh"

echo "=== postgres-storage.yml.template ==="

# This template is only used on the kubeadm path (STORAGE_CLASS unset).
# It requires MOUNTPOINT to be passed as an env var, exactly as devenv-cli.sh does.

test_case "kubeadm: template renders without error"
OUTPUT=$(MOUNTPOINT='"/var/lib/docker/volumes/test-pgdata/_data"' \
    "$RENDER" --template="$TEMPLATE" --config="$PROPS" --project-dir="$DEVENV_DIR" 2>&1)
assert_exit_success "exit code 0" $?

test_case "kubeadm: StorageClass is created"
assert_contains "kind: StorageClass present" "$OUTPUT" "kind: StorageClass"

test_case "kubeadm: PersistentVolume is created"
assert_contains "kind: PersistentVolume present" "$OUTPUT" "kind: PersistentVolume"

test_case "kubeadm: PersistentVolumeClaim is created"
assert_contains "kind: PersistentVolumeClaim present" "$OUTPUT" "kind: PersistentVolumeClaim"

test_case "kubeadm: MOUNTPOINT substituted into local path"
assert_contains "local path contains mountpoint" "$OUTPUT" 'path: "/var/lib/docker/volumes/test-pgdata/_data"'

test_case "kubeadm: StorageClass name is env-scoped"
assert_contains "StorageClass name contains EnvId" "$OUTPUT" "name: test-postgres-storage"

test_case "kubeadm: PV name is env-scoped"
assert_contains "PV name contains EnvId" "$OUTPUT" "name: test-postgres-pv"

test_case "kubeadm: node affinity targets control-plane"
assert_contains "control-plane affinity present" "$OUTPUT" "node-role.kubernetes.io/control-plane"

test_case "kubeadm: no unsubstituted variables"
assert_not_contains "no raw MOUNTPOINT" "$OUTPUT" '${MOUNTPOINT}'
assert_not_contains "no raw EnvId" "$OUTPUT" '${EnvId}'

test_summary
