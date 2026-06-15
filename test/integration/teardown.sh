#!/bin/bash
# Removes all resources created by integration tests.
# Safe to run even if tests failed partway through.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLI="$DEVENV_DIR/bin/devenv-cli.sh"
PROPS="$SCRIPT_DIR/test.properties.kind"

log() { echo "[teardown] $*"; }

log "Deleting cluster resources..."
"$CLI" "$PROPS" delete cluster 2>/dev/null || true

log "Teardown complete."
