#!/bin/bash
# Removes all resources created by integration tests.
# Safe to run even if tests failed partway through.
#
# Usage:
#   test/integration/teardown.sh [--config=<file>]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLI="$DEVENV_DIR/bin/devenv-cli.sh"
BASE_PROPS="$SCRIPT_DIR/test.properties.rancher-desktop"

log() { echo "[teardown] $*"; }

CONFIG_OVERRIDE="${INTEGRATION_TEST_CONFIG:-}"
for ARG in "$@"; do
    case "$ARG" in
        --config=*) CONFIG_OVERRIDE="${ARG#--config=}" ;;
    esac
done

PROPS=$(mktemp)
trap "rm -f '$PROPS'" EXIT
cat "$BASE_PROPS" > "$PROPS"
if [ -n "$CONFIG_OVERRIDE" ] && [ -f "$CONFIG_OVERRIDE" ]; then
    printf '\n' >> "$PROPS"
    cat "$CONFIG_OVERRIDE" >> "$PROPS"
fi

log "Deleting cluster resources..."
"$CLI" "$PROPS" delete cluster 2>/dev/null || true

log "Teardown complete."
