# Docker Desktop — kind Engine

Docker Desktop supports two Kubernetes cluster engines, selectable under _Settings > Kubernetes > Kubernetes engine_:

- **kubeadm** — the classic engine, used prior to Docker Desktop 4.40.
- **kind** — the new default engine since Docker Desktop 4.40.

_devenv-4-iom_ supports both engines. The only required change when switching to the kind engine is setting the `STORAGE_CLASS` configuration variable.

## Why a Configuration Change is Required

The kubeadm engine exposes a Docker-managed filesystem path directly to the Kubernetes node, which _devenv-4-iom_ uses to back the PostgreSQL PersistentVolume with a local Docker volume. With the kind engine, the Kubernetes node runs as a Docker container and does not have access to Docker volume paths from the host. Persistent storage must therefore be provided through a Kubernetes StorageClass that supports dynamic provisioning.

The kind engine ships with the `standard` StorageClass (using `rancher.io/local-path` as provisioner), which handles this automatically.

## Required Configuration

Add the following line to your `devenv.project.properties` or `devenv.user.properties`:

    STORAGE_CLASS=standard

With this setting, _devenv-4-iom_ skips the Docker volume creation step entirely and lets the `standard` StorageClass provision storage for PostgreSQL automatically.

## Node Count

When using the kind engine, the node count must be set to **1** (_Settings > Kubernetes > Node count_). _devenv-4-iom_ mounts local development directories (custom apps, templates, XSL files, etc.) as `hostPath` volumes into the IOM container. These paths are only accessible on the node where the pod is scheduled. A multi-node cluster would cause IOM pods to be scheduled on nodes where the directories are not available.

## Checking Your Current Engine

To verify which engine your Docker Desktop cluster is using, check the available StorageClasses:

    kubectl get storageclass

The output for the **kind engine** contains `rancher.io/local-path` as provisioner:

    NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION
    hostpath             rancher.io/local-path   Delete          WaitForFirstConsumer   false
    standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false

The output for the **kubeadm engine** contains `docker.io/hostpath` as provisioner:

    NAME                 PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION
    hostpath (default)   docker.io/hostpath   Delete          Immediate           false

## Complete Example Configuration for kind Engine

    ID=my-iom
    KUBERNETES_CONTEXT=docker-desktop
    IMAGE_PULL_POLICY=IfNotPresent
    IOM_DBACCOUNT_IMAGE=docker.tools.intershop.com/iom/intershophub/iom-dbaccount:1.5.0
    IOM_IMAGE=docker.tools.intershop.com/iom/intershophub/iom:5.1.0
    STORAGE_CLASS=standard

## Switching Between Engines

When switching from kubeadm to kind (or back), first delete your existing cluster and storage:

    devenv-cli.sh delete cluster
    devenv-cli.sh delete storage

Then change the Docker Desktop engine setting, restart Docker Desktop, and update `STORAGE_CLASS` in your configuration file before creating a new cluster.

> **Note:** Persistent database data stored under the kubeadm engine is not transferable to the kind engine and vice versa. A fresh cluster always starts with an empty database.

---
[< Troubleshooting](08_troubleshooting.md) | [^ Index](../README.md)
