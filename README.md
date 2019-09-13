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
    * Setting > Advanced
        * CPUs: 3
        * Memory: 8192
    * Setting > Kubernetes > Enable Kubernetes
    * (Optional) Move your DockerDesktopVM to desired device
        * Stop Docker Desktop
        * Start 'Hyper-V Manager'
        * Select your PC in the left hand pane
        * Right click on the correct virtual machine (e.g. DockerDesktopVM)
        * Select 'Turn off' if it is running
        * Right click on it again and select 'Move'
        * Follow the prompts and move (e.g. D:\virtualization\Hyper-V)
        * Restart Docker Desktop
        * Setting > Advanced > Change 'Disk image location' (e.g. D:\virtualization\Hyper-V\Virtual Hard Disks)
* Install jq (https://stedolan.github.io/jq/download)
    * Download to C:\Program Files\jq
    * Open GIT BASH console
    * Set an alias
        ```sh
        echo "alias jq=\"/c/Program\ Files/jq/jq-win64.exe\"" >> ~/.profile
        ```
    * Support alias in VS Code
    * Open settings in C:\Users\myuser\AppData\Roaming\Code\User\setings.json
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

* Setup
    ```sh
    # Install
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
    
    # Determine token
    TOKEN=$(kubectl -n kube-system describe secret default | grep "token:" | sed -E 's/.*token: *//g')
    
    # Configure token for current context
    kubectl config set-credentials "$(kubectl config current-context)" --token="$TOKEN"
    ```
* Make dashboard accessable
    ```sh
    # Proxy to make dashboard accessable
    kubectl proxy
    ```
* Open http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/ in your browser
* Choose kubeconfig file (C:\Users\myuser\.kube\config resp. U:\.kube\config)

## Intershop Order Management

### (Optional) Access to Docker Build Repositories
```sh
docker login -u user -p password docker-build.rnd.intershop.de
```

### (Optional) Get images from Intershop Repositories 
```sh
docker pull docker-build.rnd.intershop.de/intershop/iom-dbaccount:1.0.0.0-SNAPSHOT
docker pull docker-build.rnd.intershop.de/intershop/iom-dbinit:2.15.0.0-SNAPSHOT
docker pull docker-build.rnd.intershop.de/intershop/iom-app:2.15.0.0-SNAPSHOT
```

### Provide configuration for your dockerized IOM instance

For every dockerized IOM installation you need to have a configuration file with some required entries. You can find a variables.sample file within the devenv-4-iom project. Create a copy of this file (e.g. at your home directory) and adapt configuration settings matching the directories you have choosen before and some other settings.

#### Provide configuration
```sh
ID=2.15.0.0-SNAPSHOT
DEVENV4IOM_DIR=/d/git/oms/devenv-4-iom
CONFIG_FILE="/u/${ID}/config.properties"

CONF_DIR=$(dirname "$CONFIG_FILE")
  
cd "$DEVENV4IOM_DIR"
 
# make a copy of the sample configuration
mkdir -p "$CONF_DIR"
cp scripts/variables.sample "$CONFIG_FILE" && \
    echo "adapt '$CONFIG_FILE' to your needs"
 
# adapt the configuration to your needs
vi "$CONFIG_FILE"
```

### Generate documentation, aliases and kubernetes resource configurations

Once the configuration file is created and adapted, according kubernetes resource configurations, aliases and documentation can be created. The devenv-4-iom project comes with some scripts/templates to generate these files. The example below shows an example, assuming your config file is named ~/2.15.0.0-SNAPSHOT.config.
```sh
ID=2.15.0.0-SNAPSHOT
DEVENV4IOM_DIR=/d/git/oms/devenv-4-iom
CONFIG_FILE="/u/${ID}/config.properties"
 
CONF_DIR=$(dirname "$CONFIG_FILE")
 
cd "$DEVENV4IOM_DIR"
 
# generate the environment specific html documentation
# scripts/template_engine.sh templates/index.template "$CONFIG_FILE" > "$CONF_DIR/$CONF_BASE-docu.html"
 
# generate the environment specific alias script
# scripts/template_engine.sh templates/alias.template "$CONFIG_FILE" > "$CONF_DIR/$CONF_BASE-alias.sh"
 
# generate the environment specific kubernetes resource configurations
scripts/template_engine.sh templates/iom.yml.template "$CONFIG_FILE" > "$CONF_DIR/iom.yml"
scripts/template_engine.sh templates/postgres.yml.template "$CONFIG_FILE" > "$CONF_DIR/postgres.yml"
```

# Create IOM cluster

```sh
ID=2.15.0.0-SNAPSHOT
DEVENV4IOM_DIR=/d/git/oms/devenv-4-iom
CONFIG_FILE="/u/${ID}/config.properties"
 
CONF_DIR=$(dirname "$CONFIG_FILE")

cd "$DEVENV4IOM_DIR"

scripts/template_engine.sh  templates/postgres.yml templates/template-variables | kubectl apply -f -
scripts/template_engine.sh  templates/iom.yml templates/template-variables | kubectl apply -f -

# DOCKER_DB_IMAGE=postgres:11 scripts/template_engine.sh templates/postgres.yml | kubectl apply -f -
```

* Open http://localhost:8080/omt in your browser

# Remove IOM cluster

```sh
./scripts/template_engine.sh  templates/iom.yml templates/template-variables | kubectl delete -f -
./scripts/template_engine.sh  templates/postgres.yml templates/template-variables | kubectl delete -f -
```