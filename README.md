# Introduction
The purpose of this document is to describe how to set up an IOM environment with prepared docker images for development purposes.

# Prerequisites
In order to start with docker on your host machine and to work with it without problems, the installation of some tools is required.

## Bash
### Windows
- Install Git Bash (comes with https://gitforwindows.org/)
- Use Git Bash in VS Code, see https://code.visualstudio.com/docs/editor/integrated-terminal#_configuration
- Open settings in C:\Users\myuser\AppData\Roaming\Code\User\seetings.json and add the following line:
  ```json
  // enable Git Bash in Visual Studio Code
  "terminal.integrated.shell.windows": "C:\\Program Files\\Git\\bin\\bash.exe"
  ```
If you don't able to locate settings.json, see https://code.visualstudio.com/docs/getstarted/settings
### Mac OS X
Bash is part of Mac OS X, there is nothing to do.

## Docker-Desktop
### Windows
Install Docker Desktop, see https://www.docker.com/products/docker-desktop

**Caution: While installing you will be signed-out without further acknowledgements as well as probably be rebooted! So save everything before installing ...**

- Start _Docker Desktop_ by clicking the Docker Desktop shortcut
- In the context bar (bottom right on Windows Desktop), click right mouse button on Docker icon
- Select _Settings_ and you will get the modal for settings of _Docker Desktop_.
  - Go to _Settings > Advanced_
    - CPUs: 3
    - Memory: 8192
    - _**Apply**_
  - Go to _Settings > Kubernetes_
    - _Enable Kubernetes_
    - _**Apply**_
  - Go to _Settings > Shared Drives_
    - Share drives that should be available for Kubernetes. You should share the drive, that is holding the IOM sources, as well the drive with the configurations of _devenv-4-iom_.
    - _**Apply**_
  - Optional: move your _Docker Desktop VM_ to desired device
    - Stop Docker Desktop
    - Start _Hyper-V Manager_
    - Select your PC in the left hand pane
    - Right click on the correct virtual machine (e.g.DockerDesktopVM)
    - Select _Torn off_ if it is running
    - Right click on it again and select _Move_
    - Follow the prompts and move (e.g. _D:\virtualization\Hyper-V_)
    - Go to Docker _Settings > Advanced_
    - Change _Disk image location_ (e.g. D:\virtualization\Hyper-V\Virtual Hard Disks)
    - _**Apply**_

**After resetting your password you can have some problems with your shared drives. In those cases use _Settings > Shared Drives > Reset credentials_.**

### Mac OS X
- Install_ Docker Desktop_, see https://www.docker.com/products/docker-desktop
- Enable _Docker Desktop version of Kubernetes_:
  - Enable _Docker Icon > Kubernetes > docker-desktop_
- Check file-sharing. Your home directory should be shared (if you are using it to hold configurations of _deven-4-iom_, IOM sources, etc).
  - Check _Docker Icon > Preferences > File Sharing_
- Set CPU and memory usage. When running a single IOM instance in Docker-Desktop you need to assign 2 CPUs and 10 GB memory.
  - Setup at _Docker Icon > Preferences > Advanced_

## jq - command-line JSON processor
_jq_ is a command line tool to work with json messages. Since all messages, created by _devenv-4-iom_ and _IOM_, are json messages, it is a very useful tool. jq is not included in _devenv-4-iom_. _devenv-4-iom_ does not depend on it (except the _'log *'_ command), but it's strongly recommended that you install _jq_ too.

### Windows
Install jq, see https://stedolan.github.io/jq/download
- Download to C:\Program Files\jq
- Open Git Bash console
  - Set an alias. The alias is required when using _jq_ interactively in the console window, e.g. to comprehend the examples, that can be found in documentation of _devenv-4-iom_h.
    ```sh
    echo "alias jq=\"/c/Program\ Files/jq/jq-win64.exe\"" >> ~/.profile
    ```
  - Add _jq_ to the PATH variable. This is required for the _'log *'_ commands of _devenv-cli.sh_ to work. These commands are executing _jq_ internally and have to find it in _PATH_.
    ```sh
    echo "export PATH=\"$PATH:/c/Program\ Files/jq\"" >> ~/.profile
    ```
- Support alias in VS Code
  - Open settings in C:\Users\myuser\AppData\Roaming\Code\User\setings.json
    ```json
    // Support alias in Visual Studio Code
    "terminal.integrated.shellArgs.windows": ["-l"],
    ```

### Mac OS X
_jq_ is not part of standard distribution of Mac OS X. In order to install additional tools like _jq_, it's recommended to use one of the Open Source Package Management systems. I recommend the usage of [_Mac Ports_](https://www.macports.org/). Please follow the [installation instruction](https://www.macports.org/install.php) to setup _Mac Ports_. Once _Mac Ports_ is installed, the installation of _jq_ can be done by the following command:
```sh
sudo port install jq
```

## Kubernetes Dashboard
Install Kubernetes Dashboard, see https://github.com/kubernetes/dashboard
- Execute the following code in a bash:
  ```sh
  # Install
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
     
  # Determine token
  TOKEN=$(kubectl -n kube-system describe secret default | grep "token:" | sed -E 's/.*token: *//g')
     
  # Configure token for current context
  kubectl config set-credentials "$(kubectl config current-context)" --token="$TOKEN"
 
  # Patch kubernetes-dashboard deployment to bypassing authentication
  PATCH=$(cat << 'EOF'
  spec:
    template:
      spec:
        containers:
        - name: kubernetes-dashboard
          args:
            - --enable-skip-login
            - --disable-settings-authorizer       
            - --auto-generate-certificates
  EOF
  )
  kubectl patch deployment kubernetes-dashboard --namespace kube-system --patch "$PATCH"
  ```
  - Make Kubernetes Dashboard accessible
  ```sh
  # Start proxy to make dashboard accessible
  kubectl proxy
  ```
  - Now you can open the [Dashboard](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/) in your browser.
    You can _**Skip**_ the login, due to the patch, that was applied before.

# Configuration and setup of _devenv-4-iom_

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