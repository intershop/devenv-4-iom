#!/bin/bash
# Tests: create mailserver / delete mailserver.
# Uses the component properties file (ID=iom-unit) to avoid collision
# with the lifecycle test (ID=iom-test).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

CLI="$DEVENV_DIR/bin/devenv-cli.sh"
PROPS="$SCRIPT_DIR/test-component.properties.rancher-desktop"
NAMESPACE="iomunit"
POD_TIMEOUT=60

# devenv-cli.sh auto-discovers devenv.project.properties next to PROPS.
# Read KUBERNETES_CONTEXT from there for kubectl calls.
CONTEXT=$(grep '^KUBERNETES_CONTEXT=' "$SCRIPT_DIR/devenv.project.properties" 2>/dev/null | tail -1 | cut -d= -f2-)
CONTEXT="${CONTEXT:-rancher-desktop}"

echo "=== mailserver ==="

# Ensure clean state
"$CLI" "$PROPS" delete mailserver > /dev/null 2>&1 || true
kubectl delete namespace "$NAMESPACE" --context="$CONTEXT" --wait > /dev/null 2>&1 || true
kubectl create namespace "$NAMESPACE" --context="$CONTEXT" > /dev/null 2>&1

test_case "create mailserver succeeds"
"$CLI" "$PROPS" create mailserver > /dev/null 2>&1
assert_exit_success "exit code 0" $?

test_case "mailsrv pod reaches Running"
TESTS_RUN=$((TESTS_RUN + 1))
if wait_for_pod_running mailsrv "$NAMESPACE" "$CONTEXT" "$POD_TIMEOUT"; then
    echo "  PASS: mailsrv pod is Running"
else
    echo "  FAIL: mailsrv pod did not reach Running within ${POD_TIMEOUT}s"
    kubectl describe pod mailsrv -n "$NAMESPACE" --context="$CONTEXT" 2>/dev/null | tail -20
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_case "mailsrv-service has external IP"
TESTS_RUN=$((TESTS_RUN + 1))
IP=$(wait_for_external_ip mailsrv-service "$NAMESPACE" "$CONTEXT" 60)
if [ -n "$IP" ]; then
    echo "  PASS: mailsrv-service external IP is '$IP'"
else
    echo "  FAIL: mailsrv-service has no external IP (LoadBalancer pending)"
    kubectl describe service mailsrv-service -n "$NAMESPACE" --context="$CONTEXT" 2>/dev/null | tail -10
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_case "delete mailserver succeeds"
"$CLI" "$PROPS" delete mailserver > /dev/null 2>&1
assert_exit_success "exit code 0" $?

test_case "mailsrv pod is gone after delete"
TESTS_RUN=$((TESTS_RUN + 1))
sleep 5
POD=$(kubectl get pod mailsrv -n "$NAMESPACE" --context="$CONTEXT" 2>/dev/null | grep mailsrv)
if [ -z "$POD" ]; then
    echo "  PASS: mailsrv pod is gone"
else
    echo "  FAIL: mailsrv pod still exists after delete"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Cleanup
kubectl delete namespace "$NAMESPACE" --context="$CONTEXT" --wait > /dev/null 2>&1 || true

test_summary
