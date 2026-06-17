#!/bin/bash
# Verifies that the Kubernetes cluster is ready for integration tests.
# Must be run once before test scripts. Idempotent — safe to re-run.
#
# Usage:
#   test/integration/setup.sh [--config=<file>]
#
# --config=<file>   Override properties file. KUBERNETES_CONTEXT from this file
#                   is used when checking cluster connectivity.
#                   The environment variable INTEGRATION_TEST_CONFIG has the
#                   same effect and is set automatically when invoked via
#                   run-integration-tests.sh --config=<file>.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() { echo "[setup] $*"; }
die() { echo "[setup] ERROR: $*" >&2; exit 1; }

# Accept --config on the command line; fall back to the environment variable.
CONFIG_OVERRIDE="${INTEGRATION_TEST_CONFIG:-}"
for ARG in "$@"; do
    case "$ARG" in
        --config=*) CONFIG_OVERRIDE="${ARG#--config=}" ;;
    esac
done

if [ -n "$CONFIG_OVERRIDE" ] && [ ! -f "$CONFIG_OVERRIDE" ]; then
    die "config file not found: $CONFIG_OVERRIDE"
fi

# Determine Kubernetes context.
KUBERNETES_CONTEXT="rancher-desktop"
for PROPS_FILE in "$SCRIPT_DIR/test.properties.rancher-desktop" "$CONFIG_OVERRIDE"; do
    if [ -n "$PROPS_FILE" ] && [ -f "$PROPS_FILE" ]; then
        VAL=$(grep '^KUBERNETES_CONTEXT=' "$PROPS_FILE" 2>/dev/null | tail -1 | cut -d= -f2-)
        [ -n "$VAL" ] && KUBERNETES_CONTEXT="$VAL"
    fi
done

log "Checking cluster connectivity (context: $KUBERNETES_CONTEXT)..."
kubectl cluster-info --context="$KUBERNETES_CONTEXT" > /dev/null 2>&1 \
    || die "Cluster context '$KUBERNETES_CONTEXT' is not reachable. Is your cluster running with Kubernetes enabled?"

log "Checking Docker connectivity..."
docker info > /dev/null 2>&1 \
    || die "Docker is not reachable. On Rancher Desktop run: docker context use rancher-desktop"

log "Setup complete."
