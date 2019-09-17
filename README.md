# Introduction
The purpose of this document is to describe how to set up an IOM environment with prepared docker images for development purposes.

# Prerequisites
In order to start with docker on your host machine and to work with it without problems, the installation of some tools is required.

* Install Git Bash (comes with https://gitforwindows.org/)
    * Use Git Bash in VS Code
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
    * Open Git Bash console
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
* Install Kubernetes Dashboard (https://github.com/kubernetes/dashboard)
    ```sh
    # Install
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
    
    # Determine token
    TOKEN=$(kubectl -n kube-system describe secret default | grep "token:" | sed -E 's/.*token: *//g')
    
    # Configure token for current context
    kubectl config set-credentials "$(kubectl config current-context)" --token="$TOKEN"
    ```

    * Make Kubernetes Dashboard accessible
        ```sh
        # Proxy to make dashboard accessible
        kubectl proxy
        ```
    * Open http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/ in your browser
    * Choose kubeconfig file (C:\Users\myuser\.kube\config resp. U:\.kube\config)

# Configuration and setup

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

## Provide configuration for your dockerized IOM instance

For every IOM instance in your local Kubernetes cluster, you need to have a configuration file with some required entries. You can find a variables.sample file within the devenv-4-iom project. Create a copy of this file (e.g. at your home directory) and adapt configuration settings matching the directories you have chosen before and some other settings.

```sh
DEVENV4IOM_DIR=/d/git/oms/devenv-4-iom
CONFIG_FILE=~/2.15.0.0-SNAPSHOT/config.properties

CONF_DIR=$(dirname "$CONFIG_FILE")
  
cd "$DEVENV4IOM_DIR"
 
# make a copy of the sample configuration
mkdir -p "$CONF_DIR"
cp scripts/variables.sample "$CONFIG_FILE" && \
    echo "adapt '$CONFIG_FILE' to your needs"
 
# adapt the configuration to your needs
vi "$CONFIG_FILE"
```

## Generate documentation, aliases and Kubernetes resource configurations

Once the configuration file is created and adapted, according Kubernetes resource configurations, aliases and documentation can be created. The devenv-4-iom project comes with some scripts/templates to generate these files. The example below shows an example, assuming your config file is named ~/2.15.0.0-SNAPSHOT/config.properties.

```sh
DEVENV4IOM_DIR=/d/git/oms/devenv-4-iom
CONFIG_FILE=~/2.15.0.0-SNAPSHOT/config.properties
 
CONF_DIR=$(dirname "$CONFIG_FILE")
 
cd "$DEVENV4IOM_DIR"
 
# generate the environment specific html documentation
scripts/template_engine.sh templates/index.template "$CONFIG_FILE" > "$CONF_DIR/index.html"
 
# generate the environment specific alias script
# scripts/template_engine.sh templates/alias.template "$CONFIG_FILE" > "$CONF_DIR/$CONF_BASE-alias.sh"

# generate the environment specific kubernetes resource configurations
scripts/template_engine.sh templates/iom.yml.template "$CONFIG_FILE" > "$CONF_DIR/iom.yml"
scripts/template_engine.sh templates/postgres.yml.template "$CONFIG_FILE" > "$CONF_DIR/postgres.yml"
```

## Finalize the setup
Now use your browser to open the recently created HTML-documentation (named "$CONF_DIR/index.html" in example above). You have to process the following steps:

* Continue executing steps listed in section "Initialize/Reconfigure the IOM environment" of generated HTML-docu.