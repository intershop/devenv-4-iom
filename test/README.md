# Tests

## Unit Tests

Unit tests verify that `template_engine.sh` renders each `.yml.template` file
correctly. They require no running cluster and can be executed on any machine
with bash.

**Run all unit tests:**

    test/run-unit-tests.sh

`run-unit-tests.sh` discovers all `test/unit/test_*.sh` scripts, runs each in
turn, and prints a combined pass/fail summary. It exits with a non-zero code if
any script fails.

### Structure

    test/unit/
      assert.sh                     # assert library (assert_contains, assert_not_contains, assert_exit_success)
      test.properties.default       # properties file used by all unit test scripts
      test_template_iom.sh          # tests for iom-single.yml.template
      test_template_mailsrv.sh      # tests for mailsrv.yml.template
      test_template_postgres.sh     # tests for postgres.yml.template

### How a Test Script Works

Each script calls `template_engine.sh --template=<file> --config=<props>`,
captures the rendered YAML, and uses `assert.sh` to check the output. Each
individual check is introduced with `test_case "description"` and followed by
one or more `assert_*` calls. The script ends with `test_summary`, which prints
the pass/fail count and exits non-zero on any failure.

`test_template_postgres.sh` additionally covers relative path resolution and the
unset-`POSTGRES_DATA_DIR` case (hostPath volume commented out).

---

## Integration Tests

Integration tests run `devenv-cli.sh` against a live Rancher Desktop cluster and
verify that pods reach the expected state.

**Prerequisites:** Rancher Desktop must be running with Kubernetes enabled and
`docker context use rancher-desktop` must have been run.

**Setup (run once before tests):**

    test/integration/setup.sh

**Run all integration tests:**

    test/run-integration-tests.sh

An optional filter argument runs only matching scripts:

    test/run-integration-tests.sh lifecycle   # runs only test_cluster_lifecycle.sh

**Teardown** (if tests fail partway):

    test/integration/teardown.sh

### Structure

    test/integration/
      assert.sh                                     # assert library, extended with wait_for_pod_running
      setup.sh                                      # verifies cluster and Docker connectivity
      teardown.sh                                   # deletes all cluster resources created by tests
      test.properties.rancher-desktop               # properties for lifecycle test (ID=iom-test)
      test-component.properties.rancher-desktop     # properties for component tests (ID=iom-unit, avoids namespace collision)
      test_postgres.sh                              # create/delete postgres, checks pod reaches Running
      test_mailserver.sh                            # create/delete mailserver, checks pod and external IP
      test_cluster_lifecycle.sh                     # full create cluster → verify → delete cluster cycle
