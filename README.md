# SETUP

## General

* Install GIT BASH (comes with https://gitforwindows.org/)
    * Use GIT BASH in VS Code
        * https://code.visualstudio.com/docs/editor/integrated-terminal#_configuration
        * Open settings in C:\Users\myuser\AppData\Roaming\Code\User\seetings.json
            ```json
            ...
            // Git Bash
            "terminal.integrated.shell.windows": "C:\\Program Files\\Git\\bin\\bash.exe"
            ...
            ```
* Install Docker Desktop (https://www.docker.com/products/docker-desktop)
    * Setting > Kubernetes > Enable Kubernetes
* Install jq (https://stedolan.github.io/jq/download)
    * Download to C:\Program Files\jq
    * Open GIT BASH console
    * Set an alias
        ```sh
        echo "alias jq=\"/c/Program\ Files/jq/jq-win64.exe\"" >> ~/.profile
        ```
    * Support alias in VS Code
    * Open settings in C:\Users\myuser\AppData\Roaming\Code\User\seetings.json
        ```json
        ...
        // Git Bash
        "terminal.integrated.shellArgs.windows": ["-l"],
        ...
        ```

## Tools

### Kubernetes Dashboard
Dashboard is a web-based Kubernetes user interface. You can use Dashboard to deploy containerized applications to a Kubernetes cluster, troubleshoot your containerized application, and manage the cluster resources. You can use Dashboard to get an overview of applications running on your cluster, as well as for creating or modifying individual Kubernetes resources (such as Deployments, Jobs, DaemonSets, etc). For example, you can scale a Deployment, initiate a rolling update, restart a pod or deploy new applications using a deploy wizard.

Dashboard also provides information on the state of Kubernetes resources in your cluster and on any errors that may have occurred.
```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
```

## Intershop

### Access to Docker Build Repositories
```sh
docker login -u omsdeploy -p AKCp2WXCQMJb6cGKso9FJfWerMe1V248PVx8DM19BNsTKrRFQ3f3LTRfsAEHZPmX6ZAnd8a4X docker-build.rnd.intershop.de
```


# get images from intershop repos

docker pull docker-build.rnd.intershop.de/intershop/iom-dbaccount:1.0.0.0-SNAPSHOT
docker pull docker-build.rnd.intershop.de/intershop/iom-dbinit:2.15.0.0-SNAPSHOT
docker pull docker-build.rnd.intershop.de/intershop/iom-app:2.15.0.0-SNAPSHOT

kubectl apply -f postgres.yml
