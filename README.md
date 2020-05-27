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
    - Select _Turn off_ if it is running
    - Right click on it again and select _Move_
    - Follow the prompts and move (e.g. _D:\virtualization\Hyper-V_)
    - Go to Docker _Settings > Advanced_
    - Change _Disk image location_ (e.g. D:\virtualization\Hyper-V\Virtual Hard Disks)
    - _**Apply**_

**After resetting your password you can have some problems with your shared drives. In those cases use _Settings > Shared Drives > Reset credentials_.**

### Mac OS X
- Install _Docker Desktop_, see https://www.docker.com/products/docker-desktop
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
    echo "export PATH=\"\$PATH:/c/Program\ Files/jq\"" >> ~/.profile
    ```
    Depending on your shell it migth be necessary to edit the PATH before calling any other shell in ~/.profile. So you can either add this path element in your shell profile (might be ~/.bash_profile) or
- A better way would be to add a path element to the global windows environment as it's supposed to be - this also removes variances with the mount points of your windows drive paths


- Support alias in VS Code
  - Open settings in C:\Users\myuser\AppData\Roaming\Code\User\settings.json
    ```json
    // Support alias in Visual Studio Code
    "terminal.integrated.shellArgs.windows": ["-l"],
    ```

### Mac OS X
_jq_ is not part of standard distribution of Mac OS X. In order to install additional tools like _jq_, it's recommended to use one of the Open Source Package Management systems. I recommend the usage of [_Mac Ports_](https://www.macports.org/). Please follow the [installation instruction](https://www.macports.org/install.php) to setup _Mac Ports_. Once _Mac Ports_ is installed, the installation of _jq_ can be done by the following command:
```sh
sudo port install jq
```

# Setup of _devenv-4-iom_
## Checkout the devenv-4-iom project
_devenv-4-iom_ provides all the tools, that are needed to configure and run an _IOM_ instance in your local _Kubernetes_ cluster. You need to have this project locally on your computer.
```sh
# checkout the devenv-4-iom project
cd /d/git/oms/
git clone https://bitbucket.intershop.de/scm/iom/devenv-4-iom.git
```

### Windows
Add _devenv-cli.sh_ to the PATH variable if you want to be able to call from everywhere:
   - either in your shell call 
    ```sh
    echo "export PATH=\"\$PATH:/d/git/devenv-4-iom\"" >> ~/.profile
    ```
    (your profile file might vary if you're using bash)
   - or edit your whole windows system to search also in the directory your devenv-cli.sh is checked out to. This way also removes variances with the mount points of your windows drive paths

### Mac OS X
In order to become able to use _devenv-cli.sh_ without the need to call it with its absolute path, you have to extend your PATH variable. Please edit _.profile_ in your home-directory and add the according entry.

# Next steps
Now open _index.html_ from _devenv-4-iom_ directory in your browser and proceed the _First steps_ section to get familiar with _devenv-4-iom_.
