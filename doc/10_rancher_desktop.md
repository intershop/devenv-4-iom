# Rancher Desktop

[Rancher Desktop](https://rancherdesktop.io/) is the recommended platform for running _devenv-4-iom_. It is open-source, free for commercial use, and provides a stable Kubernetes environment that fully supports all _devenv-4-iom_ features including `hostPath` volumes for local file sharing.

## Why Rancher Desktop?

_devenv-4-iom_ relies on `hostPath` volumes to mount local development directories (custom apps, templates, XSL files, database data) into the Kubernetes cluster. Rancher Desktop exposes host paths correctly into the Kubernetes node on all supported platforms, which means all `CUSTOM_*_DIR` and `POSTGRES_DATA_DIR` settings work as expected.

## Installation

### macOS

1. Download and install [Rancher Desktop](https://rancherdesktop.io/).
2. During first launch, select **dockerd (moby)** as the container runtime (required for `docker` CLI compatibility) or **containerd** if you prefer. Either works.
3. Kubernetes is enabled by default.
4. macOS 13 (Ventura) and later: Rancher Desktop uses [virtiofs](https://virtio-fs.gitlab.io/) for file sharing between the host and the Lima VM. This provides fast, reliable access to any directory under `/Users`. No additional configuration is needed.

### Linux

1. Download and install [Rancher Desktop](https://rancherdesktop.io/) using the package for your distribution (AppImage, .deb, .rpm, etc.).
2. Kubernetes is enabled by default.
3. All directories on the host are directly accessible inside the Kubernetes node — `hostPath` volumes work without any prefix configuration.

### Windows

1. Install [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install) first.
2. Download and install [Rancher Desktop](https://rancherdesktop.io/).
3. Kubernetes is enabled by default.

#### Path Format for Windows (Git Bash)

On Windows, _devenv-4-iom_ is run from Git Bash. Git Bash represents Windows paths using the POSIX convention:

- Git Bash: `/c/Users/myuser/myproject`
- Windows native: `C:\Users\myuser\myproject`

Inside the Rancher Desktop WSL2 virtual machine, Windows drives are accessible at `/mnt/c/`, `/mnt/d/`, etc. The Kubernetes node sees paths in the form `/mnt/c/Users/myuser/myproject`.

This means the path format that _devenv-4-iom_ passes via `CUSTOM_*_DIR` or `POSTGRES_DATA_DIR` (in Git Bash format, e.g. `/c/Users/...`) does not match what the Kubernetes node expects (`/mnt/c/Users/...`).

To bridge this gap, set `MOUNT_PREFIX=/mnt` in your `devenv.user.properties` or `devenv.project.properties`:

```
MOUNT_PREFIX=/mnt
```

_devenv-4-iom_ prepends this value to every `hostPath` it constructs, turning `/c/Users/...` into `/mnt/c/Users/...` — which is exactly what the Rancher Desktop Kubernetes node expects.

> **Important:** Use the Git Bash path format `/c/Users/...` for all `CUSTOM_*_DIR` and `POSTGRES_DATA_DIR` settings. Do **not** write `/mnt/c/Users/...` in those variables; the `MOUNT_PREFIX` takes care of the translation.

## Configuration

After installing Rancher Desktop, set `KUBERNETES_CONTEXT` to `rancher-desktop` in your configuration file. This is also the default value, so if no context is configured explicitly, _devenv-4-iom_ will use Rancher Desktop automatically.

**`devenv.user.properties` (or `devenv.project.properties`):**

```
ID=my-iom
KUBERNETES_CONTEXT=rancher-desktop
IMAGE_PULL_POLICY=IfNotPresent
IOM_DBACCOUNT_IMAGE=docker.tools.intershop.com/iom/intershophub/iom-dbaccount:1.5.0
IOM_IMAGE=docker.tools.intershop.com/iom/intershophub/iom:5.1.0
```

For **Windows only**, add:

```
MOUNT_PREFIX=/mnt
```

## Verifying the Setup

After installation, verify that the Rancher Desktop context is available and the cluster is running:

```sh
kubectl config get-contexts
kubectl --context rancher-desktop get nodes
```

The cluster has a single node named `lima-rancher-desktop` (macOS/Linux) or `rancher-desktop` (Windows):

```
NAME                   STATUS   ROLES           AGE   VERSION
lima-rancher-desktop   Ready    control-plane   5m    v1.35.5+k3s1
```

Check the default StorageClass:

```sh
kubectl --context rancher-desktop get storageclass
```

Expected output:

```
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  21h
```

The `local-path` StorageClass is used automatically by any PersistentVolumeClaim that does not request a specific StorageClass.

---
[< Docker Desktop](09_docker_desktop.md) | [^ Index](../README.md)
