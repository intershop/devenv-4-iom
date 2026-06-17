#!/bin/bash
# Tests: full create cluster → verify all pods running → delete cluster.
# This is the end-to-end test covering the complete IOM stack.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

CLI="$DEVENV_DIR/bin/devenv-cli.sh"
PROPS="$SCRIPT_DIR/test.properties.rancher-desktop"
NAMESPACE="iomtest"
IOM_TIMEOUT=300   # IOM startup including dbaccount init takes several minutes

# devenv-cli.sh auto-discovers devenv.project.properties next to PROPS.
# Read KUBERNETES_CONTEXT from there for kubectl calls.
CONTEXT=$(grep '^KUBERNETES_CONTEXT=' "$SCRIPT_DIR/devenv.project.properties" 2>/dev/null | tail -1 | cut -d= -f2-)
CONTEXT="${CONTEXT:-rancher-desktop}"

echo "=== cluster lifecycle ==="

# Ensure clean state from any previous run
"$CLI" "$PROPS" delete cluster > /dev/null 2>&1 || true
kubectl delete namespace "$NAMESPACE" --context="$CONTEXT" --wait > /dev/null 2>&1 || true

# ---- create cluster ----

test_case "create cluster succeeds"
OUTPUT=$("$CLI" "$PROPS" create cluster 2>&1)
assert_exit_success "exit code 0" $?

test_case "namespace created"
TESTS_RUN=$((TESTS_RUN + 1))
if kubectl get namespace "$NAMESPACE" --context="$CONTEXT" > /dev/null 2>&1; then
    echo "  PASS: namespace $NAMESPACE exists"
else
    echo "  FAIL: namespace $NAMESPACE not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ---- wait for all pods ----

test_case "postgres pod reaches Running"
TESTS_RUN=$((TESTS_RUN + 1))
if wait_for_pod_running postgres "$NAMESPACE" "$CONTEXT" 120; then
    echo "  PASS: postgres pod is Running"
else
    echo "  FAIL: postgres pod did not reach Running within 120s"
    kubectl describe pod -l app=postgres -n "$NAMESPACE" --context="$CONTEXT" 2>/dev/null | tail -20
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_case "mailsrv pod reaches Running"
TESTS_RUN=$((TESTS_RUN + 1))
if wait_for_pod_running mailsrv "$NAMESPACE" "$CONTEXT" 60; then
    echo "  PASS: mailsrv pod is Running"
else
    echo "  FAIL: mailsrv pod did not reach Running within 60s"
    kubectl describe pod mailsrv -n "$NAMESPACE" --context="$CONTEXT" 2>/dev/null | tail -20
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_case "iom pod reaches Running"
TESTS_RUN=$((TESTS_RUN + 1))
if wait_for_pod_running iom "$NAMESPACE" "$CONTEXT" "$IOM_TIMEOUT"; then
    echo "  PASS: iom pod is Running (within ${IOM_TIMEOUT}s)"
else
    echo "  FAIL: iom pod did not reach Running within ${IOM_TIMEOUT}s"
    kubectl describe pod -l app=iom -n "$NAMESPACE" --context="$CONTEXT" 2>/dev/null | tail -30
    kubectl logs -l app=iom -n "$NAMESPACE" --context="$CONTEXT" --tail=50 2>/dev/null
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ---- verify services ----

test_case "all three services have external IP"
for SVC in iom-service postgres-service mailsrv-service; do
    TESTS_RUN=$((TESTS_RUN + 1))
    IP=$(kubectl get service "$SVC" -n "$NAMESPACE" --context="$CONTEXT" \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -n "$IP" ]; then
        echo "  PASS: $SVC external IP is '$IP'"
    else
        echo "  FAIL: $SVC has no external IP (LoadBalancer pending)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
done

# ---- delete cluster ----

test_case "delete cluster succeeds"
OUTPUT=$("$CLI" "$PROPS" delete cluster 2>&1)
assert_exit_success "exit code 0" $?

test_case "namespace is removed after delete cluster"
TESTS_RUN=$((TESTS_RUN + 1))
sleep 5
if kubectl get namespace "$NAMESPACE" --context="$CONTEXT" > /dev/null 2>&1; then
    echo "  FAIL: namespace $NAMESPACE still exists after delete cluster"
    TESTS_FAILED=$((TESTS_FAILED + 1))
else
    echo "  PASS: namespace $NAMESPACE is gone"
fi

test_summary
