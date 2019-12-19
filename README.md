# Introduction
The purpose of this document is to describe how to set up an IOM environment with prepared docker images for development purposes.

# Prerequisites
In order to start with docker on your host machine and to work with it without problems, the installation of some tools is required.

## Bash
### Windows
Install Git Bash (comes with https://gitforwindows.org/)
Use Git Bash in VS Code, see https://code.visualstudio.com/docs/editor/integrated-terminal#_configuration
Open settings in C:\Users\myuser\AppData\Roaming\Code\User\seetings.json and add the following line:
```json
// enable Git Bash in Visual Studio Code
"terminal.integrated.shell.windows": "C:\\Program Files\\Git\\bin\\bash.exe"
```
If you don't able to locate settings.json, see https://code.visualstudio.com/docs/getstarted/settings
### Mac OS X
Bash is part of Mac OS X, there is nothing to do.

## Docker-Desktop
### Windows
Install Docker Desktop (https://www.docker.com/products/docker-desktop)
```
**Caution: While installing you will be signed-out without further acknowledgements as well as probably be rebooted! So save everything before installing ...**
```

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
# Windows users should not use a home directory because the used drive (e.g. U:\)
# possibly is not available to be shared in the docker desktop settings.
# CONFIG_FILE=~/environments/2.15.0.0-SNAPSHOT/config.properties
CONFIG_FILE=/d/environments/2.15.0.0-SNAPSHOT/config.properties
 
ENV_DIR=$(dirname "$CONFIG_FILE")
   
cd "$DEVENV4IOM_DIR"
  
# make a copy of the sample configuration
mkdir -p "$ENV_DIR"
ENV_DIR="$ENV_DIR" scripts/template_engine.sh scripts/variables.sample > "$CONFIG_FILE" && \
    echo "adapt '$CONFIG_FILE' to your needs"
  
# adapt the configuration to your needs
vi "$CONFIG_FILE"
```

## Generate documentation, aliases and Kubernetes resource configurations

Once the configuration file is created and adapted, according Kubernetes resource configurations, aliases and documentation can be created. The devenv-4-iom project comes with some scripts/templates to generate these files. The example below shows an example, assuming your config file is named ~/2.15.0.0-SNAPSHOT/config.properties.

```sh
DEVENV4IOM_DIR=/d/git/oms/devenv-4-iom
# Windows users should not use a home directory because the used drive (e.g. U:\)
# possibly is not available to be shared in the docker desktop settings.
# CONFIG_FILE=~/environments/2.15.0.0-SNAPSHOT/config.properties
CONFIG_FILE=/d/environments/2.15.0.0-SNAPSHOT/config.properties
  
ENV_DIR=$(dirname "$CONFIG_FILE")
  
cd "$DEVENV4IOM_DIR"
  
# generate the environment specific html documentation
scripts/template_engine.sh templates/index.template "$CONFIG_FILE" > "$ENV_DIR/index.html" && \
    echo "Open '$ENV_DIR/index.html' in your browser"
```

## Finalize the setup
Now use your browser to open the recently created HTML-documentation (named "$CONF_DIR/index.html" in example above). You have to process the following steps:

* Continue executing steps listed in section "Initialize/Reconfigure the IOM environment" of generated HTML-docu.