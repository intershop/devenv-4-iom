# Introduction
The purpose of this document is to describe how to set up _devenv-4-iom_. It provides you with all the tools and documentation, that is required to run _IOM_ in a _Kubernetes_ environment with special support for typical developer tasks.

# Prerequisites
In order to work with _devenv-4-iom_ on your host machine, the installation of some additional tools is required.

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
- Make Kubernetes Dashboard accessible. Hint, if you want to use another port, simply append _--port <number>_ to the command line. In this case, the port has to be adjusted in link of the dashboard too.
  ```sh
  # Start proxy to make dashboard accessible
  kubectl proxy
  ```
- TODO: confg-file!!!
- Now you can open the Dashboard at http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/ in your browser.
  You can _**Skip**_ the login, due to the patch, that was applied before.

# Configuration and setup of _devenv-4-iom_
## Checkout the devenv-4-iom project
_devenv-4-iom_ provides all the tools, that are needed to configure and run an _IOM_ instance in your local _Kubernetes_ cluster. You need to have this project locally on your computer to continue configuration process.
```sh
# checkout the devenv-4-iom project
cd /d/git/oms/
git clone https://bitbucket.intershop.de/scm/iom/devenv-4-iom.git
```

## Concept of managing different _IOM_ instances
_devenv-4-iom_ supports a simple directory based model to manage configurations. The configuration of each _IOM_ instance is located within an own sub-directory, which is named with _ID_ of the instance. Within the sub-directory, all other configuration artifacts, shared directories, scripts, etc. are located.
```
<directory containing configs>/
├── 2.16.0.0-SNAPSHOT/
│   ├── config.properties
│   ├── devenv-cli.sh
│   ├── index.html
│   ├── geb.properties
│   ├── ws.properties
│   ├── share/
│   ├── logs/
│   └── ...
├── <ID>/
│   ├── config.properties
│   ├── devenv-cli.sh
│   ├── index.html
│   ├── geb.properties
│   ├── ws.properties
│   ├── share/
│   ├── logs/
│   └── ...
└── .../
```
The configuration directory structure must not be located on a shared drive, as sharing of directories with _Docker Desktop_ may not work in this case. Your Windows home directory may be located on a shared drive (e.g. U:). In this case, the configuration directory structure has to be placed somewhere else. You have to make sure, that the [configuration directory is shared with _Docker Desktop_](https://blogs.msdn.microsoft.com/stevelasker/2016/06/14/configuring-docker-for-windows-volumes/) (check _Docker Desktop > Preferences > File Sharing_).

## Initialize a configuration directory for your IOM instance
This steps must only be processed, when initializing the _FIRST_ configuration directory. Any update of an existing directory has to be made using the command line interface, located inside the config-directory. The documentation (index.html) found at config directory will guide you. This documentation also shows you how to add an additional configuration directory.

For every _IOM_ instance in your local _Kubernetes_ cluster, you need to have a configuration directory with config-file, command line interface and other entries. The following box shows, how to create the config-directory, config-file, command line interface and further documentation.

Scripts found in following box have to be executed in base directory of configurations! _ID_ has to be set to the _ID_ you want to use and variable _DEVENV4IOM_DIR_ has to be set to the installation directory of _devenv-4-iom_ on your host, before executing the scripts.
```sh
# Adapt the following variable to the directory, where devenv-4-iom is installed:
DEVENV4IOM=/d/git/oms/devenv-4-iom
 
# Adapt the following variable to your needs:
ID=2.16.0.0-SNAPSHOT
 
# create the configuration file containing default settings
mkdir -p "$ID" &&
  ID=$ID ENV_DIR="$(pwd)/$ID" \
  "$DEVENV4IOM/scripts/template_engine.sh" \
  "$DEVENV4IOM/templates/config.properties.template" > \
  "$ID/config.properties" &&
  echo success
 
# create the command line interface
"$DEVENV4IOM/scripts/template_engine.sh" \
  "$DEVENV4IOM/templates/devenv-cli.sh.template" \
  "$ID/config.properties" > \
  "$ID/devenv-cli.sh" &&
  chmod +x "$ID/devenv-cli.sh" && echo success
 
# create remaining files
"./$ID/devenv-cli.sh" update all &&
  echo && echo "open $ID/index.html in your browser for further instructions" && echo
```
Now open the newly created documentation in your browser and proceed the _First steps_ to get started with _devenv-4-iom_.










### (Optional) Access to Docker Build Repositories
```sh
docker login -u user -p password docker-build.rnd.intershop.de
```

