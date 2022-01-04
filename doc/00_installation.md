# Installation
## Prerequisites
In order to use _devenv-4-iom_ on your host machine, the installation of some additional tools is required.

### Bash
**Windows**

1. Install Git Bash (comes with [Git for Windows](https://gitforwindows.org/)).
1. Use Git Bash in VS Code, see [Integrated Terminal](https://code.visualstudio.com/docs/editor/integrated-terminal#_configuration) in the Visual Studio Code documentation.
1. Open settings in C:\Users\myuser\AppData\Roaming\Code\User\seetings.json and add the following line:
   ```json
   // enable Git Bash in Visual Studio Code
   "terminal.integrated.shell.windows": "C:\\Program Files\\Git\\bin\\bash.exe"
   ```
If you are not able to locate _settings.json_, see [User and Workspace Settings](https://code.visualstudio.com/docs/getstarted/settings) in the Visual Studio Code documentation.

**Mac OS X**

Bash is part of Mac OS X, there is nothing to do.

### Docker-Desktop
Docker-Desktop is recommended, since it not only provides a Docker environment, but also Kubernetes functionality, which is required to use _devenv-4-iom_. Other Docker/Kubernetes implementations can be used along with _devenv-4-iom_, but they are all have restrictions, that makes their usage much more complicated.

**Windows**

To install [Docker Desktop](https://www.docker.com/products/docker-desktop), perform the following steps:  
> **Optional:** Define an alternate installation location to save place on drive _C_. 
> - Example, run as Admin: `mklink /J "C:\Program Files\Docker" "D:\myssdalternateprogramlocation\Docker"`
> - (see https://forums.docker.com/t/docker-installation-directory/32773/7)  
> - troubelshooting, deinstallation: https://github.com/docker/for-win/issues/1544 
     
> **Caution:** While installing you will be signed-out without further acknowledgements and your PC will probably be restarted. So save everything before installing.

1. Start _Docker Desktop_ by clicking the _Docker Desktop_ shortcut.
1. In the context bar (bottom right on Windows Desktop), right-click on the Docker icon.
1. Select _Settings_. 
   - The modal for settings of _Docker Desktop_ is displayed.   
1. Adjust the following settings:
    - _Settings > Resources > Advanced_
       - These values are minimum values. You might use larger numbers, if your computers resources are large enough.
       - CPUs: 2
       - Memory: 8192
       - _**Apply**_
    - _Settings > Kubernetes_
       - _Enable Kubernetes_
       - _**Apply**_
    - _Settings > Resources > File Sharing_
       - Share drives that should be available for Kubernetes. You should share the drive, that is holding the IOM-project sources.
       - _**Apply**_
5. **Optional** - Move your _Docker Desktop VM_ to the desired device:
     1. Stop _Docker Desktop_.
     1. Start _Hyper-V Manager_.
     1. Select your PC in the left hand pane.
     1. Right-click on the correct virtual machine (e.g. DockerDesktopVM).
     1. Select _Turn off_ if it is running.
     1. Right-click on it again and select _Move_.
     1. Follow the prompts and move (e.g. `D:\virtualization\Hyper-V`).
     1. In Docker, go to _Settings > Advanced_.
     1. Change _Disk image location_ (e.g. to D:\virtualization\Hyper-V\Virtual Hard Disks).
     1. Click _**Apply**_.

**Mac OS X**

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop).
2. Enable _Kubernetes in Docker Desktop_.
    - To do so click _Docker Icon > Preferences > Kubernetes > Enable Kubernetes_.
3. Make sure, the directory holding IOM-project sources is shared.
    - To do so click _Docker Icon > Preferences > Resources > File Sharing_.
4. Set CPU and memory usage. When running a single IOM instance in Docker-Desktop you need to assign at least 2 CPUs and 8 GB memory.
    - To do so click _Docker Icon > Preferences > Resources > Advanced_.

### jq - Command-Line JSON Processor
_jq_ is a command-line tool that allows to work with JSON messages. Since all messages created by _devenv-4-iom_ and _IOM_ are JSON messages, it is a very useful tool.

jq is not included in _devenv-4-iom_ and _devenv-4-iom_ does not depend on it (except the `log *` commands), but it is strongly recommended that you install _jq_ as well.

**Windows**

Install jq, see [Download jq](https://stedolan.github.io/jq/download).
1. Download to _C:\Program Files\jq_
1. Open the Git Bash console.
    1. Set an alias. The alias is required when using _jq_ interactively in the console window, e.g. to comprehend the examples which are [part of the documentation](05_log_messages.md#jq).
        ```sh
         echo "alias jq=\"/c/Program\ Files/jq/jq-win64.exe\"" >> ~/.profile
         ```
    1. Add _jq_ to the PATH variable. This is required for the `log *` commands of `devenv-cli.sh` to work. These commands execute _jq_ internally and have to find it in _PATH_.
        ```sh
         echo "export PATH=\"\$PATH:/c/Program\ Files/jq\"" >> ~/.profile
        ```
    Depending on your shell, it migth be necessary to edit the PATH before calling any other shell in ~/.profile. You can add this path element in your shell profile (might be ~/.bash_profile). Alternatively refer to the following step.
1. Support alias in VS Code. Therefore open `settings.json` which can be found in `C:\Users\myuser\AppData\Roaming\Code\User\settings.json`.
    ```json
    // Support alias in Visual Studio Code
    "terminal.integrated.shellArgs.windows": ["-l"],
    ```

**Mac OS X**

_jq_ is not part of a standard distribution of Mac OS X. In order to install additional tools like _jq_, it is recommended to use one of the open source package management systems. Intershop recommends using [Mac Ports](https://www.macports.org/). Please follow the [installation instruction](https://www.macports.org/install.php) to set up _Mac Ports_. Once _Mac Ports_ is installed, the installation of _jq_ can be done by using the following command:
```sh
sudo port install jq
```

## Setup of _devenv-4-iom_
In order to use _devenv-4-iom_, you need a local copy on your computer. This copy can simply created, by cloning the sources. The _main_ branch always contains the latest release version.

    # get devenv-4-iom
    git clone git@github.com:intershop/iom-devenv.git
    cd iom-devenv
    git checkout main

In order to become able to use _devenv-cli.sh_ without the need to call it with its absolute path, you have to extend your PATH variable. Please edit `.profile` in your home-directory and add the according entry.

---
[^ up](../README.md) | [> next chapter](01_first_steps.md)