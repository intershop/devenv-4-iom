#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_VARS="$DEVENV_DIR/bin/template-variables"
source "$SCRIPT_DIR/assert.sh"

echo "=== deprecated properties ==="

# Helper: source template-variables with given env vars pre-set and capture
# the resulting value of a named variable plus any warnings on stderr.
# Usage: eval_var VAR_NAME [KEY=VALUE ...]
eval_var() {
    local var="$1"; shift
    env -i "$@" bash -c "
        log_msg() { echo \"\$@\" >&2; }
        . '$TEMPLATE_VARS'
        echo \"\${$var}\"
    " 2>/tmp/test_deprecated_warnings
}

# ---------------------------------------------------------------------------
# DOCKER_DB_IMAGE
# ---------------------------------------------------------------------------

test_case "DOCKER_DB_IMAGE only: POSTGRES_IMAGE takes its value"
RESULT=$(eval_var POSTGRES_IMAGE DOCKER_DB_IMAGE=postgres:16)
assert_contains "POSTGRES_IMAGE set from DOCKER_DB_IMAGE" "$RESULT" "postgres:16"

test_case "DOCKER_DB_IMAGE only: deprecation warning emitted"
WARNINGS=$(cat /tmp/test_deprecated_warnings)
assert_contains "warning mentions DOCKER_DB_IMAGE" "$WARNINGS" "DOCKER_DB_IMAGE"
assert_contains "warning says POSTGRES_IMAGE will be set" "$WARNINGS" "POSTGRES_IMAGE has been set to the value of DOCKER_DB_IMAGE"

test_case "DOCKER_DB_IMAGE + POSTGRES_IMAGE: POSTGRES_IMAGE value is kept"
RESULT=$(eval_var POSTGRES_IMAGE DOCKER_DB_IMAGE=postgres:16 POSTGRES_IMAGE=postgres:17)
assert_contains "POSTGRES_IMAGE unchanged" "$RESULT" "postgres:17"
assert_not_contains "POSTGRES_IMAGE not overwritten by old" "$RESULT" "postgres:16"

test_case "DOCKER_DB_IMAGE + POSTGRES_IMAGE: warning says old property is ignored"
WARNINGS=$(cat /tmp/test_deprecated_warnings)
assert_contains "warning mentions DOCKER_DB_IMAGE" "$WARNINGS" "DOCKER_DB_IMAGE"
assert_contains "warning says ignored" "$WARNINGS" "ignored because POSTGRES_IMAGE is set"

# ---------------------------------------------------------------------------
# IMAGE_PULL_POLICY
# ---------------------------------------------------------------------------

test_case "IMAGE_PULL_POLICY only: IMAGE_PULL_POLICY_IOM takes its value"
RESULT=$(eval_var IMAGE_PULL_POLICY_IOM IMAGE_PULL_POLICY=Never)
assert_contains "IMAGE_PULL_POLICY_IOM set from IMAGE_PULL_POLICY" "$RESULT" "Never"

test_case "IMAGE_PULL_POLICY only: deprecation warning emitted"
WARNINGS=$(cat /tmp/test_deprecated_warnings)
assert_contains "warning mentions IMAGE_PULL_POLICY" "$WARNINGS" "IMAGE_PULL_POLICY"
assert_contains "warning says IMAGE_PULL_POLICY_IOM will be set" "$WARNINGS" "IMAGE_PULL_POLICY_IOM has been set to the value of IMAGE_PULL_POLICY"

test_case "IMAGE_PULL_POLICY + IMAGE_PULL_POLICY_IOM: IMAGE_PULL_POLICY_IOM value is kept"
RESULT=$(eval_var IMAGE_PULL_POLICY_IOM IMAGE_PULL_POLICY=Never IMAGE_PULL_POLICY_IOM=IfNotPresent)
assert_contains "IMAGE_PULL_POLICY_IOM unchanged" "$RESULT" "IfNotPresent"
assert_not_contains "IMAGE_PULL_POLICY_IOM not overwritten by old" "$RESULT" "Never"

test_case "IMAGE_PULL_POLICY + IMAGE_PULL_POLICY_IOM: warning says old property is ignored"
WARNINGS=$(cat /tmp/test_deprecated_warnings)
assert_contains "warning mentions IMAGE_PULL_POLICY" "$WARNINGS" "IMAGE_PULL_POLICY"
assert_contains "warning says ignored" "$WARNINGS" "ignored because IMAGE_PULL_POLICY_IOM is set"

rm -f /tmp/test_deprecated_warnings
test_summary
