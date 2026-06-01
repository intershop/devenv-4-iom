#!/bin/bash
# Prepares the kind-based Docker Desktop cluster for integration tests.
# Must be run once before test scripts. Idempotent — safe to re-run.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROPS="$SCRIPT_DIR/test.properties.kind"
CONTEXT="docker-desktop"

log() { echo "[setup] $*"; }
die() { echo "[setup] ERROR: $*" >&2; exit 1; }

# Verify cluster is reachable
log "Checking cluster connectivity..."
kubectl cluster-info --context="$CONTEXT" > /dev/null 2>&1 \
    || die "Cluster context '$CONTEXT' is not reachable. Is Docker Desktop running with Kubernetes enabled?"

# Verify StorageClass standard exists (kind engine)
log "Checking StorageClass 'standard'..."
kubectl get storageclass standard --context="$CONTEXT" > /dev/null 2>&1 \
    || die "StorageClass 'standard' not found. Is Docker Desktop configured to use the kind engine?"

# Pull public images if not already present locally, then load all images
# into the kind node via docker save | ctr import.
log "Loading images into kind node..."
for IMAGE in iom-dbaccount:1.5.0 ci-iom:5.1.0-1.0.0-SNAPSHOT postgres:15 axllent/mailpit; do
    if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
        log "  Pulling $IMAGE..."
        docker pull "$IMAGE" || die "Failed to pull image '$IMAGE'."
    fi
    log "  Loading $IMAGE..."
    docker save "$IMAGE" \
        | docker exec -i desktop-control-plane ctr -n k8s.io images import - \
        || die "Failed to load image '$IMAGE' into kind node."
done

log "Setup complete."
