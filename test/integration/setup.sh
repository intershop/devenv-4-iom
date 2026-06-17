#!/bin/bash
# Verifies that the Rancher Desktop cluster is ready for integration tests.
# Must be run once before test scripts. Idempotent — safe to re-run.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTEXT="rancher-desktop"

log() { echo "[setup] $*"; }
die() { echo "[setup] ERROR: $*" >&2; exit 1; }

log "Checking cluster connectivity..."
kubectl cluster-info --context="$CONTEXT" > /dev/null 2>&1 \
    || die "Cluster context '$CONTEXT' is not reachable. Is Rancher Desktop running with Kubernetes enabled?"

log "Checking Docker connectivity..."
docker info > /dev/null 2>&1 \
    || die "Docker is not reachable. Run: docker context use rancher-desktop"

log "Setup complete — Rancher Desktop cluster is ready."
