#!/bin/bash
# Tests: create postgres / delete postgres on kind engine.
# Uses test-component.properties.kind (ID=iom-unit) to avoid collision
# with the lifecycle test (ID=iom-test).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

CLI="$DEVENV_DIR/bin/devenv-cli.sh"
PROPS="$SCRIPT_DIR/test-component.properties.kind"
CONTEXT="docker-desktop"
NAMESPACE="iomunit"
POD_TIMEOUT=120

echo "=== postgres (kind) ==="

# Ensure clean state
"$CLI" "$PROPS" delete postgres > /dev/null 2>&1 || true
kubectl delete namespace "$NAMESPACE" --context="$CONTEXT" --wait > /dev/null 2>&1 || true
kubectl create namespace "$NAMESPACE" --context="$CONTEXT" > /dev/null 2>&1

test_case "create postgres succeeds"
"$CLI" "$PROPS" create postgres > /dev/null 2>&1
assert_exit_success "exit code 0" $?

test_case "PVC is created"
TESTS_RUN=$((TESTS_RUN + 1))
if kubectl get pvc postgres-pvc -n "$NAMESPACE" --context="$CONTEXT" > /dev/null 2>&1; then
    echo "  PASS: PVC postgres-pvc exists"
else
    echo "  FAIL: PVC postgres-pvc not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_case "PVC uses standard StorageClass"
SC=$(kubectl get pvc postgres-pvc -n "$NAMESPACE" --context="$CONTEXT" \
    -o jsonpath='{.spec.storageClassName}' 2>/dev/null)
assert_contains "storageClassName is standard" "$SC" "standard"

test_case "PVC reaches Bound"
TESTS_RUN=$((TESTS_RUN + 1))
ELAPSED=0
while [ $ELAPSED -lt 60 ]; do
    PHASE=$(kubectl get pvc postgres-pvc -n "$NAMESPACE" --context="$CONTEXT" \
        -o jsonpath='{.status.phase}' 2>/dev/null)
    [ "$PHASE" = "Bound" ] && break
    sleep 5; ELAPSED=$((ELAPSED + 5))
done
if [ "$PHASE" = "Bound" ]; then
    echo "  PASS: PVC is Bound"
else
    echo "  FAIL: PVC phase is '$PHASE', expected Bound (waited 60s)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_case "postgres pod reaches Running"
TESTS_RUN=$((TESTS_RUN + 1))
if wait_for_pod_running postgres "$NAMESPACE" "$CONTEXT" "$POD_TIMEOUT"; then
    echo "  PASS: postgres pod is Running"
else
    echo "  FAIL: postgres pod did not reach Running within ${POD_TIMEOUT}s"
    kubectl describe pod -l app=postgres -n "$NAMESPACE" --context="$CONTEXT" 2>/dev/null | tail -20
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_case "postgres-service exists and has external IP"
TESTS_RUN=$((TESTS_RUN + 1))
IP=$(kubectl get service postgres-service -n "$NAMESPACE" --context="$CONTEXT" \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -n "$IP" ]; then
    echo "  PASS: postgres-service external IP is '$IP'"
else
    echo "  FAIL: postgres-service has no external IP"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_case "delete postgres succeeds"
"$CLI" "$PROPS" delete postgres > /dev/null 2>&1
assert_exit_success "exit code 0" $?

test_case "postgres pod is gone after delete"
TESTS_RUN=$((TESTS_RUN + 1))
sleep 5
PHASE=$(kubectl get pods -l app=postgres -n "$NAMESPACE" --context="$CONTEXT" \
    -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ -z "$PHASE" ]; then
    echo "  PASS: postgres pod is gone"
else
    echo "  FAIL: postgres pod still exists (phase: $PHASE)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Cleanup
kubectl delete namespace "$NAMESPACE" --context="$CONTEXT" --wait > /dev/null 2>&1 || true

test_summary
