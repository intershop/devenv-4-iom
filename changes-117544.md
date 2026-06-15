# Changes on branch chore/117544-infrastructure-update

## Problem being solved

Docker Desktop 4.40 introduced the **kind engine** as the new default for its built-in Kubernetes cluster, replacing the classic **kubeadm engine**. devenv-4-iom broke with the kind engine because of a fundamental storage incompatibility: the existing code creates a Docker volume on the host, inspects its filesystem path via `docker volume inspect --format='{{.Mountpoint}}'`, and injects that path into a Kubernetes `local` PersistentVolume. With kind, the Kubernetes node is a Docker container — it has no access to Docker volume paths from the host VM, so the PVC never binds and postgres never starts.

---

## Changes explained file by file

### `templates/postgres.yml.template` — inline PVC using cluster default StorageClass

The PersistentVolumeClaim definition is now part of `postgres.yml.template` itself, gated by `${KeepDatabaseYml}` (which comments it out when `KEEP_DATABASE_DATA` is not `true`). The `storageClassName` field is deliberately omitted — Kubernetes then assigns the cluster's default StorageClass automatically:

- On the **kind engine**: `standard` (provisioner: `rancher.io/local-path`)
- On the **kubeadm engine**: `hostpath` (provisioner: `docker.io/hostpath`)

This follows the same pattern used by Helm charts like bitnami/postgresql, which omit `storageClassName` for the same reason.

---

### `templates/postgres-storage.yml.template` — removed

This template created a `local` PersistentVolume backed by a Docker volume path. It was specific to the kubeadm engine and is now superseded by the inline PVC in `postgres.yml.template`. Removing it simplifies the codebase and makes storage provisioning engine-agnostic.

---

### `bin/devenv-cli.sh` — storage logic simplified

**`create-postgres`**: the block that ran `docker volume inspect` and applied `postgres-storage.yml.template` has been removed. The PVC is now always part of `postgres.yml` and is provisioned by the cluster automatically.

**`delete-postgres`**: the block that deleted `postgres-storage.yml` resources has been removed. PVCs are deleted along with their namespace, so no separate cleanup step is needed.

**`info-storage`**: updated to show the PersistentVolumeClaim status (from `postgres-pvc` in the namespace) instead of the now-irrelevant docker volume and PV information.

**`help-create-storage` / `help-delete-storage`**: help text updated to note that the kind engine has no action to take for storage.

---

### `bin/template-variables` — postgres default image updated

`DOCKER_DB_IMAGE` default changed from `postgres:12` (end-of-life October 2023) to `postgres:15`.

---

### `templates/config.properties.template` — STORAGE_CLASS removed

The `STORAGE_CLASS` variable entry has been removed since it is no longer needed.

---

### `doc/00_installation.md` — kind engine section updated

The Kubernetes engine selection section now describes both engines as equally supported without any additional configuration requirement, and links to `doc/09_docker_desktop_kind.md` for details.

---

### `doc/09_docker_desktop_kind.md` — new chapter

A complete reference for the kind engine covering:
- Why the old approach broke on kind (Docker container node cannot access host VM Docker volumes)
- How the default StorageClass mechanism resolves this without configuration
- How to detect which engine is active (`kubectl get storageclass` output for each)
- Node count requirement and why (hostPath volumes are node-local)
- A complete example properties file (identical for both engines)
- How to switch between engines

---

### `doc/08_troubleshooting.md` — navigation link

Adds a forward navigation link to the new chapter 09.

---

### `README.md` — index entry + release notes

- Adds `doc/09_docker_desktop_kind.md` to the documentation index
- Adds release notes for 2.8.0: kind engine support and postgres:15 default

---

### `CLAUDE.md` — project guidance for Claude Code

Documents the project structure, CLI usage, configuration system and architecture for future Claude Code sessions working in this repository.

---

### `test/` — new test suite

**Unit tests** (`test/unit/`, `test/run-unit-tests.sh`): no cluster required, run anywhere with bash. Render each template with both `test.properties.kubeadm` and `test.properties.kind` and assert the YAML output is structurally correct — right images, right fields present/absent, no unsubstituted `${VAR}` references.

**Integration tests** (`test/integration/`, `test/run-integration-tests.sh`): require a running Docker Desktop cluster with the kind engine. Four test scripts:

| Script | What it tests |
|---|---|
| `test_storage.sh` | `create/delete storage` — no docker volume created on kind |
| `test_postgres.sh` | PVC provisioned by default StorageClass, binds, pod reaches Running |
| `test_mailserver.sh` | mailsrv pod reaches Running, LoadBalancer gets external IP |
| `test_cluster_lifecycle.sh` | Full `create cluster` → all 3 pods Running → all services have external IPs → `delete cluster` |

`setup.sh` handles loading all images into the kind node (`docker save | docker exec -i ... ctr import`) since kind node containers have their own isolated image cache. `teardown.sh` cleans up if tests fail partway through.

Two separate properties files are used to avoid namespace collisions when running all tests in sequence: `test-component.properties.kind` (`ID=iom-unit`) for the component tests and `test.properties.kind` (`ID=iom-test`) for the lifecycle test.
