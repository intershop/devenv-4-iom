# Changes on branch chore/117544-infrastructure-update

## Problem being solved

Docker Desktop 4.40 introduced the **kind engine** as the new default for its built-in Kubernetes cluster, replacing the classic **kubeadm engine**. devenv-4-iom broke with the kind engine because of a fundamental storage incompatibility: the existing code creates a Docker volume on the host, inspects its filesystem path via `docker volume inspect --format='{{.Mountpoint}}'`, and injects that path into a Kubernetes `local` PersistentVolume. With kind, the Kubernetes node is a Docker container — it has no access to Docker volume paths from the host VM, so the PVC never binds and postgres never starts.

Deeper investigation revealed that Docker Desktop's kind engine also breaks `hostPath` volumes for live host-directory sharing: the kind node sees a stale snapshot of the host filesystem, not a live mount. Because `CUSTOM_*_DIR` features depend on live `hostPath` sharing, this means Docker Desktop kind cannot fully support devenv-4-iom.

The solution is to migrate to **Rancher Desktop** as the primary supported platform. Rancher Desktop uses k3s in a proper virtual machine (Lima on macOS/Linux, WSL2 on Windows), where `hostPath` volumes work correctly on all platforms.

---

## Changes explained file by file

### `templates/postgres.yml.template` — hostPath volume for persistent storage

The old approach (Docker volume + `postgres-storage.yml.template`) is replaced by a `hostPath` volume, following the same pattern already used by `CUSTOM_*_DIR` variables in `iom-single.yml.template`. When `POSTGRES_DATA_DIR` is set, the volume definition becomes:

```yaml
- name: db-data
  hostPath:
    path: "${MOUNT_PREFIX}${POSTGRES_DATA_DIR}"
```

Docker Desktop maps host home directories into both the kubeadm VM and the kind node container, so this path is accessible in both engines. Data lives on the host filesystem outside the Kubernetes namespace and therefore survives `delete cluster`. When `POSTGRES_DATA_DIR` is empty, the `${KeepDatabaseYml}` prefix comments out the volume block and postgres runs without persistent storage.

The old PVC section (previously added for default StorageClass provisioning) is removed entirely — no PVC, no StorageClass dependency.

---

### `templates/postgres-storage.yml.template` — removed

This template created a `local` PersistentVolume backed by a Docker volume path. It was specific to the kubeadm engine and is now fully superseded by the hostPath approach. Removed.

---

### `bin/template-variables` — KEEP_DATABASE_DATA replaced by POSTGRES_DATA_DIR

`KEEP_DATABASE_DATA` (boolean, default `true`) is replaced by:

```bash
POSTGRES_DATA_DIR="${POSTGRES_DATA_DIR}"
if [ -n "$POSTGRES_DATA_DIR" ]; then
    KeepDatabaseYml=''
else
    KeepDatabaseYml='#'
fi
```

Setting `POSTGRES_DATA_DIR` to a host path enables persistent storage; leaving it empty disables it. This is the same mental model as `CUSTOM_APPS_DIR` and friends — users already know it. `KeepDatabaseSh` is removed since it was only used in now-deleted storage command help text.

`DOCKER_DB_IMAGE` default also updated from `postgres:12` (end-of-life) to `postgres:15`.

---

### `bin/devenv-cli.sh` — storage commands removed, cluster commands simplified

**Removed entirely**: `create storage`, `delete storage`, `info storage` commands — functions, help functions, dispatch table entries, and all mentions in other help texts. The directory lifecycle is the user's responsibility, exactly as with `CUSTOM_*_DIR`.

**`docker_volume_exists()`**: helper function removed (no longer needed).

**`create-cluster`**: no longer calls `create-storage` — reduced to `create-namespace && create-postgres && create-mailserver && create-iom`.

**`dump-load`**: removed the `delete-storage` / `create-storage` calls and the `KEEP_DATABASE_DATA` guard. The hostPath directory is simply reused across postgres restarts, so no storage renewal is needed when loading a dump.

**`info-postgres`**: `KEEP_DATABASE_DATA` label replaced with `POSTGRES_DATA_DIR`.

**`help-create-postgres`** / **`help-delete-postgres`** / **`help-delete-cluster`** / **`help-delete-namespace`**: updated to describe `POSTGRES_DATA_DIR` and clarify that host data is not affected by cluster deletion.

---

### `templates/config.properties.template` — POSTGRES_DATA_DIR documented

`KEEP_DATABASE_DATA` entry replaced with `POSTGRES_DATA_DIR`, with a comment explaining the pattern (matching the style of `CUSTOM_APPS_DIR` documentation).

---

### `doc/00_installation.md` — kind engine section updated

Both engines are now described as equally supported without any additional configuration requirement. Links to `doc/09_docker_desktop.md` for details.

---

### `doc/01_first_steps.md`, `doc/04_operations.md`, `doc/05_development_process.md` — storage commands removed

All references to `create storage`, `delete storage`, `info storage`, and `KEEP_DATABASE_DATA` replaced with `POSTGRES_DATA_DIR` and the hostPath approach. The first-steps walkthrough no longer includes a separate storage creation step.

---

### `doc/09_docker_desktop.md` — new chapter

A complete reference for the kind engine covering:
- Why the old approach broke on kind (Docker container node cannot access host VM Docker volumes)
- How hostPath volumes work on both engines (Docker Desktop maps host directories into both)
- How to detect which engine is active (`kubectl get storageclass` output for each)
- Node count requirement and why (hostPath volumes are node-local)
- A complete example properties file (identical for both engines)
- How to switch between engines

---

### `doc/08_troubleshooting.md` — navigation link + updated example output

Adds a forward navigation link to the new chapter 09. Example `info postgres` output updated to show `POSTGRES_DATA_DIR` instead of `KEEP_DATABASE_DATA`.

---

### `doc/10_rancher_desktop.md` — new chapter

A complete setup guide for Rancher Desktop covering:
- Why Rancher Desktop is the recommended platform (`hostPath` volumes work correctly on all platforms)
- macOS installation (Kubernetes enabled by default, virtiofs for fast file sharing)
- Linux installation
- Windows installation and the Git Bash path format issue: `MOUNT_PREFIX=/mnt` bridges `/c/Users/...` (Git Bash) to `/mnt/c/Users/...` (WSL2 node)
- Configuration: `KUBERNETES_CONTEXT=rancher-desktop`, example properties file
- Verifying the setup with `kubectl` commands

---

### `doc/00_installation.md` — Rancher Desktop as primary platform

Rancher Desktop now replaces Docker Desktop as the recommended Kubernetes platform. Docker Desktop remains listed as an alternative with a link to `doc/09_docker_desktop.md`.

---

### `doc/05_development_process.md` — MOUNT_PREFIX for Rancher Desktop Windows

Updated the MOUNT_PREFIX description to cover both Rancher Desktop (`/mnt`) and Docker Desktop (`/run/desktop/mnt/host`) on Windows, with a link to `doc/10_rancher_desktop.md`.

---

### `templates/config.properties.template` — MOUNT_PREFIX comment updated

Replaced the WSL2-only comment with a clear table covering both Rancher Desktop and Docker Desktop Windows use cases.

---

### `bin/template-variables` — KUBERNETES_CONTEXT default changed

Default changed from `docker-desktop` to `rancher-desktop`, reflecting the new recommended platform.

---

### `README.md` — index entry + release notes

- Adds `doc/09_docker_desktop.md` and `doc/10_rancher_desktop.md` to the documentation index
- Updates release notes for 2.8.0: Rancher Desktop support, `POSTGRES_DATA_DIR`, postgres:15 default

---

### `CLAUDE.md` — project guidance for Claude Code

Documents the project structure, CLI usage, configuration system and architecture for future Claude Code sessions working in this repository.

---

### `test/` — new test suite

**Unit tests** (`test/unit/`, `test/run-unit-tests.sh`): no cluster required, run anywhere with bash. Render each template with both `test.properties.kubeadm` and `test.properties.kind` and assert the YAML output is structurally correct — right images, right fields present/absent, no unsubstituted `${VAR}` references. Both engine property files now set `POSTGRES_DATA_DIR=/tmp/test-pgdata`.

**Integration tests** (`test/integration/`, `test/run-integration-tests.sh`): require a running Docker Desktop cluster with the kind engine. Three test scripts:

| Script | What it tests |
|---|---|
| `test_postgres.sh` | hostPath volume present in pod spec, pod reaches Running |
| `test_mailserver.sh` | mailsrv pod reaches Running, LoadBalancer gets external IP |
| `test_cluster_lifecycle.sh` | Full `create cluster` → all 3 pods Running → all services have external IPs → `delete cluster` |

`setup.sh` handles loading all images into the kind node (`docker save | docker exec -i ... ctr import`) since kind node containers have their own isolated image cache. `teardown.sh` cleans up if tests fail partway through.

Two separate properties files are used to avoid namespace collisions when running all tests in sequence: `test-component.properties.kind` (`ID=iom-unit`, `POSTGRES_DATA_DIR=/tmp/iom-unit-pgdata`) for the component tests and `test.properties.kind` (`ID=iom-test`, `POSTGRES_DATA_DIR=/tmp/iom-test-pgdata`) for the lifecycle test.
