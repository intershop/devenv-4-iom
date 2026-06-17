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
      test.properties.kubeadm       # properties file for kubeadm engine scenarios
      test.properties.kind          # properties file for kind engine scenarios
      test_template_iom.sh          # tests for iom-single.yml.template
      test_template_mailsrv.sh      # tests for mailsrv.yml.template
      test_template_postgres.sh     # tests for postgres.yml.template

### How a Test Script Works

Each script calls `template_engine.sh --template=<file> --config=<props>`,
captures the rendered YAML, and uses `assert.sh` to check the output. Each
individual check is introduced with `test_case "description"` and followed by
one or more `assert_*` calls. The script ends with `test_summary`, which prints
the pass/fail count and exits non-zero on any failure.

Most templates are rendered twice — once with `test.properties.kubeadm` and
once with `test.properties.kind` — to catch engine-specific regressions.
`test_template_postgres.sh` additionally covers relative path resolution and the
unset-`POSTGRES_DATA_DIR` case.

---

## Integration Tests

Integration tests run `devenv-cli.sh` against a live Kubernetes cluster and
verify that pods reach the expected state.

> **Note:** The integration tests are currently **out of date**. They were
> written for the Docker Desktop kind engine and reference concepts that have
> since been removed (PVCs, `StorageClass: standard`, `test_storage.sh`). They
> need to be updated to target Rancher Desktop and the current `hostPath`-based
> storage approach before they can be used.

### Structure

    test/integration/
      assert.sh                         # same assert library as unit tests, extended with wait_for_pod_running
      setup.sh                          # loads images into the kind node (outdated — targets kind engine)
      teardown.sh                       # deletes all cluster resources created by tests
      test.properties.kind              # properties for lifecycle test (ID=iom-test)
      test-component.properties.kind    # properties for component tests (ID=iom-unit, avoids namespace collision)
      test_postgres.sh                  # create/delete postgres, checks pod reaches Running
      test_mailserver.sh                # create/delete mailserver, checks pod and external IP
      test_cluster_lifecycle.sh         # full create cluster → verify → delete cluster cycle

**Run all integration tests:**

    test/run-integration-tests.sh

An optional filter argument runs only matching scripts:

    test/run-integration-tests.sh lifecycle   # runs only test_cluster_lifecycle.sh

**Teardown** (if tests fail partway):

    test/integration/teardown.sh
