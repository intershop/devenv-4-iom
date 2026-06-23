#!/bin/bash
# Verifies that the Kubernetes cluster is ready for integration tests.
# Must be run once before test scripts. Idempotent — safe to re-run.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() { echo "[setup] $*"; }
die() { echo "[setup] ERROR: $*" >&2; exit 1; }

CONTEXT=$(grep '^KUBERNETES_CONTEXT=' "$SCRIPT_DIR/devenv.project.properties" 2>/dev/null | tail -1 | cut -d= -f2-)
CONTEXT="${CONTEXT:-rancher-desktop}"

log "Checking cluster connectivity (context: $CONTEXT)..."
kubectl cluster-info --context="$CONTEXT" > /dev/null 2>&1 \
    || die "Cluster context '$CONTEXT' is not reachable. Is your cluster running with Kubernetes enabled?"

log "Checking Docker connectivity..."
docker info > /dev/null 2>&1 \
    || die "Docker is not reachable. On Rancher Desktop run: docker context use rancher-desktop"

log "Setup complete."
