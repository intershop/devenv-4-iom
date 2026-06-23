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
      test_template_iom.sh          # tests for iom.yml.template
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

Integration tests run `devenv-cli.sh` against a live Kubernetes cluster and
verify that pods reach the expected state.

### Configuration

The integration tests use _devenv-4-iom_'s standard two-file configuration
mechanism (see [doc/02_configuration.md](../doc/02_configuration.md)):

- `test/integration/devenv.project.properties` — project-level settings shared
  by all test scripts: image names, `KUBERNETES_CONTEXT`, and `IMAGE_PULL_POLICY_IOM`.
  **Edit this file to configure image names before running the tests.**
- `test/integration/test.properties.rancher-desktop` and
  `test-component.properties.rancher-desktop` — per-test user files containing
  only `ID` and `POSTGRES_DATA_DIR`. These are passed as the first argument to
  `devenv-cli.sh`; devenv then auto-discovers `devenv.project.properties` from
  the same directory.

### Docker Images

Four Docker images are required. Two are pulled from public registries
automatically; two are project-specific and must be built or loaded into the
local Docker daemon before running the tests.

| Variable | Default value | Source |
|---|---|---|
| `POSTGRES_IMAGE` | `postgres:17` | public — pulled automatically |
| `MAILSRV_IMAGE` | `axllent/mailpit` | public — pulled automatically |
| `IOM_DBACCOUNT_IMAGE` | `iom-dbaccount:1.5.0` | project-specific — must be built or loaded |
| `IOM_IMAGE` | `ci-iom:5.1.0-1.0.0-SNAPSHOT` | project-specific — must be built or loaded |

Set the correct image names in `test/integration/devenv.project.properties`
before running the tests.

### Running Tests Locally (Rancher Desktop)

**Prerequisites:**

- [Rancher Desktop](https://rancherdesktop.io/) running with Kubernetes enabled
- `docker context use rancher-desktop`
- Image names set in `test/integration/devenv.project.properties`
- Project-specific images built or loaded into the local Docker daemon

**Setup (run once):**

    test/integration/setup.sh

**Run all tests:**

    test/run-integration-tests.sh

**Filter to a single script:**

    test/run-integration-tests.sh lifecycle

**Teardown** (if tests fail partway):

    test/integration/teardown.sh

### Running Tests in an Azure CI Pipeline

The integration tests can run on a Linux agent with k3s installed. k3s uses the
same `rancher.io/local-path` storage provisioner as Rancher Desktop and exposes
host paths into the cluster without any additional configuration.

#### Agent setup

Install k3s in single-node mode:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -
```

`traefik` is disabled because _devenv-4-iom_ manages its own LoadBalancer
services via k3s's built-in ServiceLB. Copy the kubeconfig so that `kubectl`
and _devenv-4-iom_ can reach the cluster:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER" ~/.kube/config
```

The kubeconfig written by k3s uses the context name `default`. Update
`KUBERNETES_CONTEXT` accordingly:

```bash
sed -i 's/^KUBERNETES_CONTEXT=.*/KUBERNETES_CONTEXT=default/' \
    test/integration/devenv.project.properties
```

Install the remaining required tools:

```bash
sudo apt-get install -y docker.io jq git    # Debian/Ubuntu
# or: sudo yum install -y docker jq git    # RHEL/CentOS
```

#### Pipeline step — set image names

Set `IOM_DBACCOUNT_IMAGE` and `IOM_IMAGE` in `devenv.project.properties` to
the images built earlier in the pipeline:

```bash
sed -i "s|^IOM_DBACCOUNT_IMAGE=.*|IOM_DBACCOUNT_IMAGE=$(IOM_DBACCOUNT_IMAGE)|" \
    test/integration/devenv.project.properties
sed -i "s|^IOM_IMAGE=.*|IOM_IMAGE=$(IOM_IMAGE)|" \
    test/integration/devenv.project.properties
```

Replace `$(IOM_DBACCOUNT_IMAGE)` and `$(IOM_IMAGE)` with the actual Azure
Pipelines variable references for your pipeline.

#### Pipeline step — run tests

```bash
test/integration/setup.sh
test/run-integration-tests.sh
```

### Structure

    test/integration/
      assert.sh                                     # assert library, extended with wait_for_pod_running
      devenv.project.properties                     # shared project config: image names, KUBERNETES_CONTEXT
      setup.sh                                      # verifies cluster and Docker connectivity
      teardown.sh                                   # deletes all cluster resources created by tests
      test.properties.rancher-desktop               # user config for lifecycle test (ID=iom-test)
      test-component.properties.rancher-desktop     # user config for component tests (ID=iom-unit)
      test_postgres.sh                              # create/delete postgres, checks pod reaches Running
      test_mailserver.sh                            # create/delete mailserver, checks pod and external IP
      test_cluster_lifecycle.sh                     # full create cluster → verify → delete cluster cycle
