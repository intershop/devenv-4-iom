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

Integration tests run `devenv-cli.sh` against a live Kubernetes cluster and
verify that pods reach the expected state.

### Docker Images

The tests require four Docker images. Two are pulled from public registries and
need no preparation; two are project-specific and must be built or provided
before running the tests:

| Variable | Default value | Source |
|---|---|---|
| `DOCKER_DB_IMAGE` | `postgres:15` | public — pulled automatically |
| `MAILSRV_IMAGE` | `axllent/mailpit` | public — pulled automatically |
| `IOM_DBACCOUNT_IMAGE` | `iom-dbaccount:1.5.0` | project-specific — must be built or loaded |
| `IOM_IMAGE` | `ci-iom:5.1.0-1.0.0-SNAPSHOT` | project-specific — must be built or loaded |

The default image names in `test.properties.rancher-desktop` and
`test-component.properties.rancher-desktop` are placeholders. Before running
the tests, set the actual image names in an override file (see
[Configuring Image Names](#configuring-image-names)).

### Configuring Image Names

All image variables and the Kubernetes context can be overridden by supplying
a properties file on the command line. This avoids editing the versioned
properties files and works equally well in local development and CI pipelines.

Create a file — for example `test/integration/test.properties.local` — and set
whichever values you need to override:

```
KUBERNETES_CONTEXT=rancher-desktop
IOM_DBACCOUNT_IMAGE=iom-dbaccount:1.5.0
IOM_IMAGE=my-iom:4.8.0
```

Then pass it with `--config`:

    test/run-integration-tests.sh --config=test/integration/test.properties.local

The override file is layered on top of the base properties files — values in the
override take precedence, everything else comes from the base files. The override
file is intentionally not committed (add it to `.gitignore` locally, or generate
it in CI as a pipeline step).

### Running Tests Locally (Rancher Desktop)

**Prerequisites:**

- [Rancher Desktop](https://rancherdesktop.io/) running with Kubernetes enabled
- `docker context use rancher-desktop`
- Project-specific images built or loaded into the local Docker daemon

**Setup (run once):**

    test/integration/setup.sh

**Run all tests:**

    test/run-integration-tests.sh --config=<your-override-file>

**Filter to a single script:**

    test/run-integration-tests.sh --config=<your-override-file> lifecycle

**Teardown** (if tests fail partway):

    test/integration/teardown.sh --config=<your-override-file>

### Running Tests in an Azure CI Pipeline

The integration tests can run on a Linux agent with k3s installed. k3s uses the
same `rancher.io/local-path` storage provisioner as Rancher Desktop and exposes
host paths into the cluster without any additional configuration — no path prefix
is required.

#### Agent setup

Install k3s in single-node mode with the Kubernetes API on a fixed port:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -
```

`traefik` is disabled because _devenv-4-iom_ manages its own LoadBalancer
services via k3s's built-in ServiceLB (formerly klipper-lb). k3s writes a
kubeconfig to `/etc/rancher/k3s/k3s.yaml`; copy or symlink it so that `kubectl`
and _devenv-4-iom_ can reach it:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER" ~/.kube/config
```

The cluster context name in this file is `default`. Set that in your override
properties file (see below).

Install the remaining required tools:

```bash
# kubectl is bundled with k3s; install the standalone binary for convenience
# or use: sudo k3s kubectl ...
sudo apt-get install -y docker.io jq git    # Debian/Ubuntu
# or: sudo yum install -y docker jq git    # RHEL/CentOS
```

#### Pipeline step — generate override file

In the pipeline, generate a properties file from environment variables or
pipeline variables so that no credentials are stored in source files:

```bash
cat > test/integration/test.properties.ci <<EOF
KUBERNETES_CONTEXT=default
IOM_DBACCOUNT_IMAGE=$(IOM_DBACCOUNT_IMAGE)
IOM_IMAGE=$(IOM_IMAGE)
EOF
```

(Replace `$(IOM_DBACCOUNT_IMAGE)` with the correct Azure Pipelines variable
syntax for your pipeline, e.g. `$(Build.BuildId)` or a pipeline variable.)

#### Pipeline step — run tests

```bash
test/integration/setup.sh --config=test/integration/test.properties.ci
test/run-integration-tests.sh --config=test/integration/test.properties.ci
```

### Structure

    test/integration/
      assert.sh                                     # assert library, extended with wait_for_pod_running
      setup.sh                                      # verifies cluster and Docker connectivity
      teardown.sh                                   # deletes all cluster resources created by tests
      test.properties.rancher-desktop               # base properties for lifecycle test (ID=iom-test)
      test-component.properties.rancher-desktop     # base properties for component tests (ID=iom-unit)
      test_postgres.sh                              # create/delete postgres, checks pod reaches Running
      test_mailserver.sh                            # create/delete mailserver, checks pod and external IP
      test_cluster_lifecycle.sh                     # full create cluster → verify → delete cluster cycle
