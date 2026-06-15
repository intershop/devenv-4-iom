# Docker Desktop — kind Engine

Docker Desktop supports two Kubernetes cluster engines, selectable under _Settings > Kubernetes > Kubernetes engine_:

- **kubeadm** — the classic engine, used prior to Docker Desktop 4.40.
- **kind** — the new default engine since Docker Desktop 4.40.

_devenv-4-iom_ supports both engines without any configuration change.

## How Storage Works on Each Engine

### kubeadm engine

The kubeadm engine exposes Docker volume paths directly to the Kubernetes node. _devenv-4-iom_ previously relied on this by inspecting the Docker volume mount path and injecting it into a Kubernetes `local` PersistentVolume backed by that path.

### kind engine

The kind engine runs the Kubernetes node as a Docker container. That container has no access to Docker volume paths from the host VM, so the old approach breaks: the PVC never binds and PostgreSQL never starts.

_devenv-4-iom_ now avoids this entirely by omitting the `storageClassName` field from the PersistentVolumeClaim. Kubernetes then uses the cluster's default StorageClass automatically:

- On the **kind engine**: `standard` (provisioner: `rancher.io/local-path`) — set as default by Docker Desktop.
- On the **kubeadm engine**: `hostpath` (provisioner: `docker.io/hostpath`) — set as default by Docker Desktop.

No configuration change is needed when switching between engines.

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

## Complete Example Configuration

The configuration is the same for both engines:

    ID=my-iom
    KUBERNETES_CONTEXT=docker-desktop
    IMAGE_PULL_POLICY=IfNotPresent
    IOM_DBACCOUNT_IMAGE=docker.tools.intershop.com/iom/intershophub/iom-dbaccount:1.5.0
    IOM_IMAGE=docker.tools.intershop.com/iom/intershophub/iom:5.1.0

## Switching Between Engines

When switching from kubeadm to kind (or back), first delete your existing cluster and storage:

    devenv-cli.sh delete cluster

Then change the Docker Desktop engine setting and restart Docker Desktop before creating a new cluster.

> **Note:** Persistent database data stored under the kubeadm engine is not transferable to the kind engine and vice versa. A fresh cluster always starts with an empty database.

---
[< Troubleshooting](08_troubleshooting.md) | [^ Index](../README.md)
