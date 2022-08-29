# Azure DevOps Integration

## Overview

The figure below shows the relations between *devenv-4-iom*, an IOM-project and the *Azure DevOps Environment*, which is part of the *Intershop Commerce Platform*. The *Azure DevOps Environment* is providing build-artifacts and the IOM Docker-images. Both are required to develop IOM-projects.

![DevOps Integration Overview](DevOps-Integration-Overview.png)

## Get Access to Maven Repository

When creating a new IOM-project, the project will be tied to a certain *Azure DevOps Environment* (see [Documentation of *IOM Project Archetype*](https://github.com/intershop/iom-project-archetype/blob/main/README.md)). 

The URL of the *Maven Repository*, that is providing the IOM build artifacts (//repositories/repository[id='iom-maven-artifacts']/url in *pom.xml*) is specific for each *Azure DevOps Environment*. In order to build the IOM-project locally, the local computer needs to have read-access to this Maven Repository.

To get access to this Maven Repository, a file *~/.m2/settings.xml* has to be created, which has to contain the credentials for the access to the repository. The *Azure DevOps Environment* provides all the necessary information, to setup *~/.m2/settings.xml*. Just follow these steps:

1. Log in to *Azure DevOps Environment*
2. Open *Artifacts* in menu on the left
3. Select feed *iom-maven-artifacts*
4. Click *Connect to Feed*
5. Select *Maven*
6. Follow the instruction to *Add or Edit settings.xml ...*. Remember creating a *Personal Access Token* and putting it into *~/.m2/settings.xml*, too.

## Get Access to *Intershop Docker Repository*

The *Intershop Docker Repository* provides the Standard IOM Docker images. These Standard IOM Docker images have two purposes:
* The IOM Docker image will be extended by the IOM-project with project specific customizations and configurations. Hence, when building the IOM project locally, read access to the *Intershop Docker Repository* is required.
* The IOM dbaccount image is required to run the IOM project locally within *devenv-4-iom*. This image serves as an initialization image, that is preparing the database account.

Hence, read access to *Intershop Docker Repository* is required for building the IOM project *and* for running it in *devenv-4-iom*. Both types of usage are requiring different methods to provide this access.

In both cases the *CLI secret* is required. To get the *CLI secret*, please follow these steps:

1. Open [docker.tools.intershop.com](https://docker.tools.intershop.com) in the browser.
2. Log in with *LOGIN VIA OIDC PROVIDER* and use your Intershop Azure account.
3. Select *User Profile* on top left of the page.
4. In the dialog you can copy the CLI secret.

In order to build the IOM project locally, you have to always log in to *docker.tools.intershop.com* using your Intershop Azure account and the CLI secret:

    docker login docker.tools.intershop.com

For running the IOM project in *devenv-4-iom*, an *image pull secret* (Kubernetes secret object) has to be created for *docker.tools.intershop.com*. The *image pull secret* has to be created within the default namespace of Kubernetes and the name of the secret has to be set within the configuration of *devenv-4-iom*.

The following command shows how to create the Kubernetes secret *intershop-pull-secret*:

    kubectl create secret docker-registry intershop-pull-secret \
      --context="docker-desktop" \
      --docker-server=docker.tools.intershop.com \
      --docker-username='<your Intershop Azure account>' \
      --docker-password='<CLI secret>'

Finally, the name of the newly created Kubernetes secret has to be passed to *devenv-4-iom*. To do so, set the key *IMAGE_PULL_SECRET* within the user-specific configuration file of *devenv-4-iom* (devenv.user.properties):

    # change into the root directory of IOM project
    echo IMAGE_PULL_SECRET=intershop-pull-secret

## Get Access to *Project Docker Repository*

When creating a new IOM-project, the project will be tied to a certain *Azure DevOps Environment* (see [Documentation of *IOM Project Archetype*](https://github.com/intershop/iom-project-archetype/blob/main/README.md)). The relation between IOM-project and the *Azure DevOps Environment* is defined by two values, which can be found in the projects *pom.xml*.

These are the URL of the *Maven Repository*, that is providing the IOM build artifacts (//repositories/repository[id='iom-maven-artifacts']/url in *pom.xml*) and the Name of the IOM Docker Repository (//properties/intershop.docker.repo in *pom.xml*).



---
[< Configuration](02_configuration.md) | [^ Index](../README.md) | [Development Process >](04_operations.md)
