#!/bin/bash

TMP_ERR="$(mktemp)"
TMP_OUT="$(mktemp)"
trap "rm -f $TMP_ERR $TMP_OUT" EXIT SIGTERM

################################################################################
# display help messages
################################################################################

#-------------------------------------------------------------------------------
help() {
    ME=$(basename "$0")
    cat <<EOF
$ME
    command line interface for $ID.

SYNOPSIS
    $ME [CONFIG-FILE] COMMAND

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

COMMANDS
    info|i*            get information about kubernetes resources
    create|c*          create Kubernetes/Docker resources
    delete|de*         delete Kubernetes/Docker resources
    wait|w*            wait for Kubernetes resourses to get ready
    apply|a*           apply customization
    dump|du*           create or load dump
    update|u*          update devenv4iom specific artifacts
    log|l*             simple access to log-messages

Run '$ME [CONFIG-FILE] COMMAND --help|-h' for more information on a command.
EOF
}

#-------------------------------------------------------------------------------
help-info() {
    ME=$(basename "$0")
    cat <<EOF
display information about Kubernetes/Docker resources

SYNOPSIS
    $ME [CONFIG-FILE] info RESOURCE

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

RESOURCE
    iom|i*             view information about iom
    postgres|p*        view information about postgres
    mailserver|m*      view information about mailserver
    storage|s*         view information about storage

Run '$ME [CONFIG-FILE] info RESOURCE  --help|-h' for more information on a command.
EOF
}

#-------------------------------------------------------------------------------
help-info-iom() {
    ME=$(basename "$0")
    cat <<EOF
view information about IOM

SYNOPSIS
    $ME [CONFIG-FILE] info iom

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.
EOF
}

#-------------------------------------------------------------------------------
help-info-postgres() {
    ME=$(basename "$0")
    cat <<EOF
view information about postgres

SYNOPSIS
    $ME [CONFIG-FILE] info postgres

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.
EOF
}

#-------------------------------------------------------------------------------
help-info-mailserver() {
    ME=$(basename "$0")
    cat <<EOF
view information about mailserver

SYNOPSIS
    $ME [CONFIG-FILE] info mailserver

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.
EOF
}

#-------------------------------------------------------------------------------
help-info-storage() {
    ME=$(basename "$0")
    cat <<EOF
view information about storage

SYNOPSIS
    $ME [CONFIG-FILE] info storage

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.
EOF
}

#-------------------------------------------------------------------------------
help-info-cluster() {
    ME=$(basename "$0")
    cat <<EOF
view information about cluster

SYNOPSIS
    $ME [CONFIG-FILE] info cluster

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.
EOF
}

#-------------------------------------------------------------------------------
help-create() {
    ME=$(basename "$0")
    cat <<EOF
create Kubernetes/Docker resource

SYNOPSIS
    $ME [CONFIG-FILE] create RESOURCE

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

RESOURCE
    storage|s*         create persistant local Docker storage
    namespace|n*       create kubernetes namespace
    mailserver|m*      create mail server 
    postgres|p*        create postgres server
    iom|i*             create iom server
    cluster|c*         create all resources

Run '$ME [CONFIG-FILE] create RESOURCE --help|-h' for more information
EOF
}

#-------------------------------------------------------------------------------
help-create-storage() {
    ME=$(basename "$0")
    cat <<EOF
create a local Docker volume for persistent storage of DB data

SYNOPSIS
    $ME [CONFIG-FILE] create storage

OVERVIEW
    Creates a Docker volume, depending on configuration variable 
    KEEP_DATABASE_DATA. If you want to use persistent storage, the Docker volume
    has to be created before starting postgres.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    KEEP_DATABASE_DATA - only when set to true, the Docker volume will be 
      created. 
    ID - name of Docker volume will be derived from ID

SEE
    $ME [CONFIG-FILE] delete storage
    $ME [CONFIG-FILE] info   storage
    $ME [CONFIG-FILE] create postgres

BACKGROUND
    # executed only, if KEEP_DATABASE_DATA is true
    $KeepDatabaseSh docker volume create --name=$EnvId-pgdata -d local
EOF
}

#-------------------------------------------------------------------------------
help-create-namespace() {
    ME=$(basename "$0")
    cat <<EOF
creates a Kubernetes namespace, which will be used for all other resources

SYNOPSIS
    $ME [CONFIG-FILE] create namespace

OVERVIEW
    Kubernetes namespaces are isolating different devenv4iom instances from
    each other. 

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    ID - the name of namespace is derived from the ID of current configuration.

SEE
    $ME [CONFIG-FILE] delete namespace

BACKGROUND
    kubectl create namespace $EnvId
EOF
}

#-------------------------------------------------------------------------------
help-create-mailserver() {
    ME=$(basename "$0")
    cat <<EOF
creates a mail-server, that is used by IOM to send mails

SYNOPSIS
    $ME [CONFIG-FILE] create mailserver

OVERVIEW
    Creates a mail-server and according service.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    MAILHOG_IMAGE - defines the image of the mailserver to be used.
    IMAGE_PULL_POLICY - defines when to pull the image from origin.
    ID - the namespace to used is derived from ID

SEE
    $ME [CONFIG-FILE] delete mailserver
    $ME [CONFIG-FILE] info pods

BACKGROUND
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/mailhog.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl apply --namespace $EnvId -f -
EOF
}

#-------------------------------------------------------------------------------
help-create-postgres() {
    ME=$(basename "$0")
    cat <<EOF
creates postgres server for use by IOM

SYNOPSIS
    $ME [CONFIG-FILE] create postgres

OVERVIEW
    Creates postgres-server and according service. If KEEP_DATABASE_DATA is
    set to true, the Docker volume has to be created in advance. 

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    DOCKER_DB_IMAGE - docker image to be used
    PGHOST - if set, indicates the usage of an external postgres server. Command
      will not create a postgres server in this case.
    KEEP_DATABASE_DATA - if set to true, command links the local Docker volume
      to postgres store.
    IMAGE_PULL_POLICY - defines when to pull the image from origin
    ID - the namespace, where postgres-server and -service are created, is
      derived from ID of current configuration.

SEE
    $ME [CONFIG-FILE] delete postgres
    $ME [CONFIG-FILE] create storage
    $ME [CONFIG-FILE] info pods

BACKGROUND
    # Link Docker volume to database storage (only if KEEP_DATABASE_DATA == true)
    $KeepDatabaseSh MOUNTPOINT="\"\$(docker volume inspect --format='{{.Mountpoint}}' $EnvId-pgdata)\"" \\
    $KeepDatabaseSh   "$PROJECT_PATH/scripts/template_engine.sh" \\
    $KeepDatabaseSh   "$PROJECT_PATH/templates/postgres-storage.yml.template" \\
    $KeepDatabaseSh   "$CONFIG_FILE" | 
    $KeepDatabaseSh   kubectl apply --namespace $EnvId -f -

    # create postgres
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/postgres.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl apply --namespace $EnvId -f -
EOF
}

#-------------------------------------------------------------------------------
help-create-iom() {
    ME=$(basename "$0")
    cat <<EOF
creates IOM server

SYNOPSIS
    $ME [CONFIG-FILE] create iom

OVERVIEW
    Creates iom-server and according service.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    IOM_DBACCOUNT_IMAGE - defines the dbaccount image to be used
    IOM_CONFIG_IMAGE - defines the config image to be used
    IOM_APP_IMAGE - defines the iom application image to be used
    IMAGE_PULL_POLICY - defines when to pull images from origin

SEE
    $ME [CONFIG-FILE] delete iom
    $ME [CONFIG-FILE] info pods

BACKGROUND
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/iom.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl apply --namespace $EnvId -f -
EOF
}

#-------------------------------------------------------------------------------
help-create-cluster() {
    ME=$(basename "$0")
    cat <<EOF
creates all resources, required by IOM

SYNOPSIS
    $ME [CONFIG-FILE] create cluster

OVERVIEW
    Creates all resources to run IOM in devenv4iom (storage, namespace, 
    postgres, mailserver, iom). Finally, this is a shorcut for a couple of
    different commands only.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

SEE
    $ME [CONFIG-FILE] create storage
    $ME [CONFIG-FILE] create namespace
    $ME [CONFIG-FILE] create postgres
    $ME [CONFIG-FILE] create mailserver
    $ME [CONFIG-FILE] create iom
EOF
}

#-------------------------------------------------------------------------------
help-delete() {
    ME=$(basename "$0")
    cat <<EOF
delete Kubernetes/Docker resource

SYNOPSIS
    $ME [CONFIG-FILE] delete RESOURCE

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

RESOURCE
    storage|s*         delete persistant local Docker storage
    namespace|n*       delete kubernetes namespace including all resources 
                       belonging to this namespace
    mailserver|m*      delete mail server
    postgres|p*        delete postgres server
    iom|i*             delete iom server
    cluster|c*         delete all resources, except storage

Run '$ME [CONFIG-FILE] delete RESOURCE --help|-h' for more information
EOF
}

#-------------------------------------------------------------------------------
help-delete-storage() {
    ME=$(basename "$0")
    cat <<EOF
deletes local Docker volume, that is used for persistent storage of DB data

SYNOPSIS
    $ME [CONFIG-FILE] delete storage

OVERVIEW
    Deletes the Docker volume used for persistent storage of database data.
    Before deleting storage, you have to delete postgres.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    ID - name of Docker volume will be derived from ID.

SEE
    $ME [CONFIG-FILE] create storage
    $ME [CONFIG-FILE] info   storage
    $ME [CONFIG-FILE] delete postgres

BACKGROUND
    docker volume rm $EnvId-pgdata
EOF
}

#-------------------------------------------------------------------------------
help-delete-namespace() {
    ME=$(basename "$0")
    cat <<EOF
deletes the Kubernetes namespace, used be current IOM installation

SYNOPSIS
    $ME [CONFIG-FILE] delete namespace

OVERVIEW
    When deleting the namespace, all resources of this namespace are deleted
    too. These are iom, posgres and mailserver, but not the Docker volume
    used for persistent storage of database data.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    ID - the name of namespace is derived from the ID of current configuration.

SEE
    $ME [CONFIG-FILE] create namespace

BACKGROUND
    kubectl delete namespace ${EnvId}
EOF
}

#-------------------------------------------------------------------------------
help-delete-mailserver() {
    ME=$(basename "$0")
    cat <<EOF
deletes mail-server, that is used by IOM to send mails

SYNOPSIS
    $ME [CONFIG-FILE] delete mailserver

OVERVIEW
    Deletes the mail-server and the according service.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    ID - the namespace, where mail-server is deleted, is derived from ID

SEE
    $ME [CONFIG-FILE] create mailserver
    $ME [CONFIG-FILE] info   mailserver

BACKGROUND
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/mailhog.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl delete --namespace $EnvId -f -
EOF
}

#-------------------------------------------------------------------------------
help-delete-postgres() {
    ME=$(basename "$0")
    cat <<EOF
deletes postgres server used by IOM

SYNOPSIS
    $ME [CONFIG-FILE] delete postgres

OVERVIEW
    Deletes postgres-server and according service.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    ID - the namespace, where postgres is deleted from, is derived from ID

SEE
    $ME [CONFIG-FILE] create postgres
    $ME [CONFIG-FILE] info   postgres
    $ME [CONFIG-FILE] info   pods

BACKGROUND
    # Stop/Remove postgres database
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/postgres.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl delete --namespace $EnvId -f -

    # Unlink Docker volume from database storage
    MOUNTPOINT="\"\$(docker volume inspect --format='{{.Mountpoint}}' $EnvId-pgdata)\"" \\
      "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/postgres-storage.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl delete --namespace $EnvId -f -
EOF
}

#-------------------------------------------------------------------------------
help-delete-iom() {
    ME=$(basename "$0")
    cat <<EOF
deletes IOM

SYNOPSIS
    $ME [CONFIG-FILE] delete iom

OVERVIEW
    Deletes IOM and the according service.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    ID - the namespace, where iom is deleted from, is derived from ID

SEE
    $ME [CONFIG-FILE] create iom
    $ME [CONFIG-FILE] info   iom
    $ME [CONFIG-FILE] info   pods

BACKGROUND
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/iom.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl delete --namespace $EnvId -f -
EOF
}

#-------------------------------------------------------------------------------
help-delete-cluster() {
    ME=$(basename "$0")
    cat <<EOF
deletes all resources used by IOM, except storage

SYNOPSIS
    $ME [CONFIG-FILE] delete cluster

OVERVIEW
    Deletes all resources used by IOM, except storage. These are iom, postgres,
    mailserver, postgres, namespace. Finally, this is a shortcut for a couple of
    different commands only.
    Storage will not be deleted, as it is the basic idea of persistent storage,
    to survive the deletion of postgres.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

SEE
    $ME [CONFIG-FILE] delete iom
    $ME [CONFIG-FILE] delete postgres
    $ME [CONFIG-FILE] delete mailserver
    $ME [CONFIG-FILE] delete postgres
    $ME [CONFIG-FILE] delete namespace
    $ME [CONFIG-FILE] delete storage
EOF
}

#-------------------------------------------------------------------------------
help-wait() {
    ME=$(basename "$0")
    cat <<EOF
wait for Kubernetes resource to get ready

SYNOPSIS
    $ME [CONFIG-FILE] wait RESOURCE

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

RESOURCE
    mailserver|m*      wait for mail server
    postgres|p*        wait for postgres server
    iom|i*             wait for iom server

Run '$ME [CONFIG-FILE] wait RESOURCE --help|-h' for more information
EOF
}

#-------------------------------------------------------------------------------
help-wait-mailserver() {
    ME=$(basename "$1")
    cat <<EOF
wait for mailserver to get ready

SYNOPSIS
    $ME [CONFIG-FILE] wait mailserver [TIMEOUT]

ARGUMENTS
    TIMEOUT in seconds. Defaults to 60.

OVERVIEW
    Waits for the mailserver pod to get ready. The "wait mailserver" command
    is intended to be used in scripts, which are relying on the availability of
    the mail server.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.
EOF
}

#-------------------------------------------------------------------------------
help-wait-postgres() {
    ME=$(basename "$1")
    cat <<EOF
wait for postgres to get ready

SYNOPSIS
    $ME [CONFIG-FILE] wait postgres [TIMEOUT]

ARGUMENTS
    TIMEOUT in seconds. Defaults to 60.

OVERVIEW
    Waits for the postgres pod to get ready. The "wait postgres" command
    is intended to be used in scripts, which are relying on the availability of
    the postgres server.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.
EOF
}

#-------------------------------------------------------------------------------
help-wait-iom() {
    ME=$(basename "$1")
    cat <<EOF
wait for iom to get ready

SYNOPSIS
    $ME [CONFIG-FILE] wait iom [TIMEOUT]

ARGUMENTS
    TIMEOUT in seconds. Defaults to 60.

OVERVIEW
    Waits for the iom pod to get ready. The "wait iom" command is intended to be
    used in scripts, which are relying on the availability of the iom server.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.
EOF
}

#-------------------------------------------------------------------------------
help-apply() {
    ME=$(basename "$0")
    cat <<EOF
apply customization

SYNOPSIS
    $ME [CONFIG-FILE] apply RESOURCE

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

RESOURCE
    deployment|de*     apply custom deployment artifacts
    mail-templates|m*  apply custom mail-templates
    xsl-templates|x*   apply custom xsl-template
    sql-scripts|sql-s* apply custom sql-scripts
    sql-config|sql-c*  apply custom sql-config
    json-config|j*     apply custom json-config
    dbmigrate|db*      apply custom db-migration

Run '$ME [CONFIG-FILE] apply RESOURCE --help|-h' for more information on a command.
EOF
}

#-------------------------------------------------------------------------------
help-apply-deployment() {
    ME=$(basename "$0")
    cat <<EOF
deploys custom built artifacts

SYNOPSIS
    $ME [CONFIG-FILE] apply deployment [PATTERN]

ARGUMENTS
    PATTERN - optional. Pattern is simply a regex, which will be matched
      againts deployment artifacts. If pattern is set, only artifacts matching
      the pattern will be redeployed in forced mode.
      If pattern is not set, all artifacts will be undeployed and deployed
      again.

OVERVIEW
    The Developer VM has an extended search-path for deployments. The scripts 
    doing the deployment are looking first at directory /opt/oms/application-dev,
    instead of the standard directory /opt/oms/application, which contains all
    the standard deployment artifacts delivered by the Docker image. Hence, if 
    an artifact was found in /opt/oms/application-dev, the according standard 
    artifact will be ignored.
    All you have to do, is to mount a directory containing your custom built 
    artifacts at /opt/oms/application-dev. To do so, you have to:
    - set variable CUSTOM_APPS_DIR in your config file and make sure, that the
      directory is shared in Docker Desktop.
    - After changing CUSTOM_APPS_DIR, the IOM needs to be restarted.
    Once you have configured your developer VM this way, your custom built 
    artifacts are deployed right at the start of IOM.

    Alternatively you can use Wildfly Console for deployments too.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    CUSTOM_APPS_DIR - directory, where your custom built artifacts are located.
      Make sure, the directory is shared with Docker Desktop.
    ID - the namespace used, is derived from ID

SEE
    $ME [CONFIG-FILE] info iom

BACKGROUND
    # redeploy omt selectively 
    POD_NAME=\$(kubectl get pods --namespace $EnvId -l app=iom -o jsonpath="{.items[0].metadata.name}")
    kubectl exec \$POD_NAME --namespace $EnvId -- bash -ic redeploy omt

    # redeploy all
    POD_NAME=\$(kubectl get pods --namespace $EnvId -l app=iom -o jsonpath="{.items[0].metadata.name}")
    kubectl exec \$POD_NAME --namespace $EnvId -- bash -ic redeploy
EOF
}

#-------------------------------------------------------------------------------
help-apply-mail-templates() {
    ME=$(basename "$0")
    cat <<EOF
rolls out custom mail-templates

SYNOPSIS
  $ME [CONFIG-FILE] apply mail-templates

OVERVIEW
    The developer VM contains an additional directory /opt/oms/templates-dev,
    which will be used as mount point for custom mail templates. Part of the 
    developer VM is also the script apply-templates, which copies the templates
    from /opt/oms/templates-dev to the standard directory /opt/oms/var/templates.
    If you want to roll out custom mail templates in a running developer VM, you
    have to:
    - set variable CUSTOM_TEMPLATES_DIR in your config file and make sure, that
      the directory is shared in Docker Desktop.
    - After changing CUSTOM_TEMPLATES_DIR, the IOM needs to be restarted.
    If CUSTOM_TEMPLATES_DIR is configured, the templates are also copied when 
    starting IOM.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    CUSTOM_TEMPLATES_DIR - directory, where your custom mail templates are
      located. Make sure, the directory is shared with Docker Desktop.
    ID - the namespace used, is derived from ID

SEE
    $ME [CONFIG-FILE] delete iom
    $ME [CONFIG-FILE] create iom
    $ME [CONFIG-FILE] info   iom

BACKGROUND
    POD_NAME=\$(kubectl get pods --namespace $EnvId -l app=iom -o jsonpath="{.items[0].metadata.name}")
    kubectl exec \$POD_NAME --namespace $EnvId -- bash -ic apply-templates
EOF
}

#-------------------------------------------------------------------------------
help-apply-xsl-templates() {
    ME=$(basename "$0")
    cat <<EOF
rolls out custom xsl-templates

SYNOPSIS
  $ME [CONFIG-FILE] apply xsl-templates

OVERVIEW
    The developer VM contains a directory /opt/oms/xslt-dev, which will be used
    as mount point for custom xsl templates. Part of the developer VM is also
    the script apply-xslt, which copies the templates from /opt/oms/xslt-dev to
    the standard directory /opt/oms/var/xslt. If you want to roll out custom xsl
    templates in a running developer VM, you have to:
    - set variable CUSTOM_XSLT_DIR in your config file and make sure, that the
      directory is shared in Docker Desktop.
    - After changing CUSTOM_XSLT_DIR, IOM has to be restarted.
    If CUSTOM_XSLT_DIR is configured, the templates are also copied when 
    starting IOM.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    CUSTOM_XSLT_DIR - directory, where your custom xsl templates are located.
      Make sure, the directory is shared with Docker Desktop.
    ID - the namespace used, is derived from ID.

SEE
    $ME [CONFIG-FILE] delete iom
    $ME [CONFIG-FILE] create iom
    $ME [CONFIG-FILE] info   iom

BACKGROUND
    POD_NAME=\$(kubectl get pods --namespace $EnvId -l app=iom -o jsonpath="{.items[0].metadata.name}")
    kubectl exec \$POD_NAME --namespace $EnvId -- bash -ic apply-xslt
EOF
}

#-------------------------------------------------------------------------------
help-apply-sql-scripts() {
    ME=$(basename "$0")
    cat <<EOF
applies sql-files from passed directory or single sql-file

SYNOPSIS
    $ME [CONFIG-FILE] apply sql-scripts DIRECTORY|FILE [TIMEOUT]

ARGUMENTS
    DIRECTORY|FILE has to be shared in Docker Desktop!
    TIMEOUT in seconds. Defaults to 60.

OVERVIEW
    The docker-image defined by IOM_CONFIG_IMAGE contains all the necessary 
    tools to apply sql-scripts to the IOM database. Devenv4iom enables you to
    use these tools as easy as possible. Therefore it provides a Kubernetes job
    (apply-sql-job), that applies sql-file(s) to the IOM database.

    There are two different modes, that can be used.

    If a directory is passed to the job, all sql-files found in this directory 
    are processed in numerical order, starting with the smallest one. 
    Sub-directories are not scanned for sql-files.

    If a file is passed to the job, only this file will be executed.

    The logs are printed in json format. Verbosity can be controlled by 
    configuration variable OMS_LOGLEVEL_SCRIPTS.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    ID - the namespace used, is derived from ID
    OMS_LOGLEVEL_SCRIPTS - controls verbosity of script applying the sql-files.

SEE
    $ME [CONFIG-FILE] info iom

BACKGROUND
    # define directory with sql-file (has to be an absolute path)
    export SQL_SRC=<DIRECTORY>
    
    # start apply-sql-job
    "$PROJECT_PATH/scripts/template_engine.sh" \
      "$PROJECT_PATH/templates/apply-sql.yml.template" \
      "$CONFIG_FILE" | kubectl apply --namespace $EnvId -f -

    # get logs of job
    POD_NAME=\$(kubectl get pods --namespace $EnvId \
      -l job-name=apply-sql-job \
      -o jsonpath="{.items[0].metadata.name}")
    kubectl logs \$POD_NAME --namespace $EnvId

    # delete apply-sql-job
    "$PROJECT_PATH/scripts/template_engine.sh" \
      "$PROJECT_PATH/templates/apply-sql.yml.template" \
      "$CONFIG_FILE" | kubectl delete --namespace $EnvId -f -
EOF
}

#-------------------------------------------------------------------------------
help-apply-sql-config() {
    ME=$(basename "$0")
    cat <<EOF
applies custom sql configuration

SYNOPSIS
    $ME [CONFIG-FILE] apply sql-config

OVERVIEW
    Scripts for sql-configuration are simple sql-scripts, which can be easily
    developed and tested with the help of the developer task 
    "apply sql-scripts". But sql-configuration in CaaS project context is more
    complex. E.g. the scripts are executed depending on the currently activated
    environment. In order to enable you to test sql configuration scripts
    exactly in the same context as in real IOM installations, the developer task
    "apply sql-config" is provided.
    To be able to roll out complete sql configurations, you have to:
    - set variable CUSTOM_SQLCONF_DIR in your config file and make sure, that
      the directory is shared in Docker Desktop.
    - set variable CAAS_ENV_NAME in your config file to the environment you want
      to test.
    You should have an eye on the logs created by the configuration process.
    These logs are printed in json format. Verbosity can be controlled by
    configuration variable OMS_LOGLEVEL_SCRIPTS.
    If CUSTOM_SQLCONFIG_DIR is configured, the custom sql configuration is also
    applied when starting IOM.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    CUSTOM_SQLCONF_DIR - directory, where your custom sql-configuration is
      located.
    CAAS_ENV_NAME - the name of environment controls, which parts of sql-
      configuration will be applied and which not.
    OMS_LOGLEVEL_SCRIPTS - controls verbosity of script applying sql-
      configuration.

SEE
    $ME [CONFIG-FILE] info iom

BACKGROUND
    # start sqlconfig-job
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/sqlconfig.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl apply --namespace $EnvId -f -

    # get logs of job
    POD_NAME=\$(kubectl get pods --namespace $EnvId -l job-name=sqlconfig-job -o jsonpath="{.items[0].metadata.name}")
    kubectl logs \$POD_NAME --namespace $EnvId

    # delete sqlconfig-job
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/sqlconfig.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl delete --namespace $EnvId -f -
EOF
}

#-------------------------------------------------------------------------------
help-apply-json-config() {
    ME=$(basename "$0")
    cat <<EOF
applies custom json configuration

SYNOPSIS
    $ME [CONFIG-FILE] apply json-config

OVERVIEW
    Json configuration of IOM is not publicly available. There exists no task to
    support development of single json configuration scripts. Additionally the
    current implementation of json configuration does not use the concept of
    environments (configuration variable CAAS_ENV_NAME). The current developer
    task "apply json-config" is able to apply complete json configurations
    exactly in the same context as in a real IOM installation.
    To be able to roll out json configurations, you have to:
    - set variable CUSTOM_JSONCONF_DIR in your config file and make sure, that
      the directory is shared in Docker Desktop.
    You should have an eye on the logs created by the configuration process.
    These logs are printed in json format. Verbosity can be controlled by
    configuration variable OMS_LOGLEVEL_SCRIPTS.
    If CUSTOM_JSONCONFIG_DIR is configured, the custom json configuration is
    also applied when starting IOM.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    CUSTOM_JSONCONF_DIR - directory, where your custom json-confguration is
      located.
    IOM_CONFIG_IMAGE - defines the image to be used when executing the job.
    IMAGE_PULL_POLICY - defines when to pull the image from origin.
    OMS_LOGLEVEL_SCRIPTS - controls verbosity of script applying json-
      configuration.
    ID - the namespace used, is derived from ID.

SEE
    $ME [CONFIG-FILE] info iom

BACKGROUND
    # start jsonconfig-job
    "${PROJECT_DIR}/scripts/template_engine.sh" \\
      "${PROJECT_DIR}/templates/jsonconfig.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl apply --namespace $EnvId -f -

    # get logs of job
    POD_NAME=\$(kubectl get pods --namespace $EnvId -l job-name=jsonconfig-job -o jsonpath="{.items[0].metadata.name}")
    kubectl logs \$POD_NAME --namespace $EnvId

    # delete jsonconfig-job
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/jsonconfig.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl delete --namespace $EnvId -f -
EOF
}

#-------------------------------------------------------------------------------
help-apply-dbmigrate() {
    ME=$(basename "$0")
    cat <<EOF
applies custom dbmigrate scripts

SYNOPSIS
    $ME [CONFIG-FILE] apply dbmigrate

OVERVIEW
    To develop and test a single or a couple of sql-scripts (which can be 
    migration scripts too), the developer task "apply sql-scripts" is the first
    choice. But at some point of development, the dbmigrate process as a whole
    has to be tested too. The dbmigrate process is somewhat more complex than
    simply applying sql-scripts from a directory. It first loads stored
    procedures from directory stored_procedures and then it applies the
    migrations scripts found in directory migrations. The order of execution is
    controlled by the names of sub-directories within migrations and the naming
    of the migration scripts itself (numerically sorted, smallest first).

    The IOM_CONFIG_IMAGE contains a shell script, that is applying the migration
    scripts, which are delivered along with the docker image. The developer task
    "apply dbmigrate" enables you to use this dbmigrate script along with the
    migration scripts located at CUSTOM_DBMIGRATE_DIR. Hence, if you want to
    roll out custom dbmigrate scripts, you have to:
    - set variable CUSTOM_DBMIGRATE_DIR in your config file and make sure, that
      the directory is shared in Docker Desktop.
    You can and should have an eye on the logs created by the migration process.
    These logs are printed in json format. Verbosity can be controlled by
    configuration variable OMS_LOGLEVEL_SCRIPTS.
    If CUSTOM_DBMIGRATE_DIR is configured, the custom dbmigrate scripts are also
    applied when starting IOM.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    CUSTOM_DBMIGRATE_DIR - directory, where your custom dbmigrate scripts are
      located. This directory needs two sub-directories: stored_procedures,
      migrations.
    IOM_CONFIG_IMAGE - defines the image to be used when executing the job.
    IMAGE_PULL_POLICY - defines, when to pull the image from origin.
    OMS_LOGLEVEL_SCRIPTS - controls verbosity of script doing the db-migration.
    ID - the namespace used, is derived from ID.

SEE
    $ME [CONFIG-FILE] info iom

BACKGROUND
    # start dbmigrate-job
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/dbmigrate.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl apply --namespace $EnvId -f -

    # get logs of job
    POD_NAME=\$(kubectl get pods --namespace $EnvId -l job-name=dbmigrate-job -o jsonpath="{.items[0].metadata.name}")
    kubectl logs \$POD_NAME --namespace $EnvId

    # delete dbmigrate-job
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/dbmigrate.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl delete --namespace $EnvId -f -
EOF
}

#-------------------------------------------------------------------------------
help-dump() {
    ME=$(basename "$0")
    cat <<EOF
handle dump

SYNOPSIS
    $ME [CONFIG-FILE] dump OPERATION

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

OPERATION
    create|c*          create dump
    load|l*            load dump

Run '$ME [CONFIG-FILE] dump OPERATION --help|-h' for more information on a command.
EOF
}

#-------------------------------------------------------------------------------
help-dump-create() {
    ME=$(basename "$0")
    cat <<EOF
creates a dump of current database

SYNOPSIS
    $ME [CONFIG-FILE] dump create

OVERVIEW
    Devenv4iom provides a job to create a dump of the IOM database. This job
    uses variable CUSTOM_DUMPS_DIR. It writes the dumps to this directory. The
    created dumps will use the following naming pattern:
    OmsDump.year-month-day.hour.minute.second-hostname.sql.gz. To create dumps,
    you have to:
    - set variable CUSTOM_DUMPS_DIR in your config file and make sure, that the
      directory is shared in Docker Desktop.
    You should check the output of the dump-job. The logs of the job a printed
    in json format. Verbosity can be controlled by the configuration variable 
    OMS_LOGLEVEL_SCRIPTS.
    
    If CUSTOM_DUMPS_DIR is configured, the newest custom dump will be loaded,
    when starting IOM with an empty database (according to the load-rules that
    can be found in overview of '$ME dump load'.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    CUSTOM_DUMPS_DIR - directory, where custom dumps will be stored. If this
      variable is empty, no dumps will be created.
    IOM_CONFIG_IMAGE - defines the image to be used, when executing the job.
    IMAGE_PULL_POLICY - defines, when to pull the image from origin.
    OMS_LOGLEVEL_SCRIPTS - controls verbosity of script creating the dump.
    ID - the namespace used, is derived from ID.

SEE
    $ME [CONFIG-FILE] dump load

BACKGROUND
    # start dump-job
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/dump.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl apply --namespace $EnvId -f -

    # get logs of job
    POD_NAME=\$(kubectl get pods --namespace $EnvId -l job-name=dump-job -o jsonpath="{.items[0].metadata.name}")
    kubectl logs \$POD_NAME --namespace $EnvId

    # delete dump-job
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/dump.yml.template" \\
      "$CONFIG_FILE" | 
      kubectl delete --namespace $EnvId -f -
EOF
}

#-------------------------------------------------------------------------------
help-dump-load() {
    ME=$(basename "$0")
    cat <<EOF
loads a custom dump into database

SYNOPSIS
    $ME [CONFIG-FILE] dump load

OVERVIEW
    When starting IOM and the conneted database is empty, the config container
    is loading the initial dump. Devenv4iom gives you the possibility to load a
    custom dump during this process. This custom dump will be treated exactly as
    any other dump, which is part of the docker image. If you want to load a
    custom dump, you have to:
    - set variable CUSTOM_DUMPS_DIR in your config file and make sure, that the
      directory is shared in Docker Desktop. The dump you want to load, has to
      be located within this directory. To be recognized as a dump, it has to
      have the extension .sql.gz. If the directory contains more than one
      dump-file, the script of the config container selects the one, which's
      name is numerically largest. You can check this with following command:
      ls *.sql.gz | sort -nr | head -n 1

    The custom dump can be loaded only, if the database is empty. The current
    command executes all the necessary steps to restart IOM with an empty
    database:
    - delete iom
    - delete postgres
    - delete storage
    - create storage
    - create postgres
    - create iom
    You should inspect the logs created when running the config container. Was
    really the dump loaded, you think it was? The logs of config process are
    printed in json format. Verbosity can be controlled by configuration
    variable OMS_LOGLEVEL_SCRIPTS.

    This command works only, if an internal PostgreSQL-server is used.
    Devenv4iom is not able to control an external PostgreSQL server!

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    CUSTOM_DUMPS_DIR - the directory, where custom dumps has to be located.

    As 'dump load' is a shortcut for a couple of others commands only, you 
    should find out more about CONFIG, by requesting help of these commands.

SEE
    $ME [CONFIG-FILE] delete iom
    $ME [CONFIG-FILE] delete postgres
    $ME [CONFIG-FILE] delete storage
    $ME [CONFIG-FILE] create storage
    $ME [CONFIG-FILE] create postgres
    $ME [CONFIG-FILE] create iom
EOF
}

#-------------------------------------------------------------------------------
help-update() {
    ME=$(basename "$0")
    cat <<EOF
update devenv4iom specific resource

SYNOPSIS
    $ME [CONFIG-FILE] update RESOURCE

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

RESOURCE
    config|co*         update configuration file
    doc|d*             update HTML documentation
    ws-props|w*        update ws.properties
    geb-props|g*       update geb.properties
    all|a*             update all

Run '$ME [CONFIG-FILE] update RESOURCE --help|-h' for more information on a command.
EOF
}

#-------------------------------------------------------------------------------
help-update-config() {
    ME=$(basename "$0")
    cat <<EOF
updates config file

SYNOPSIS
    $ME [CONFIG-FILE] update config

OVERVIEW
    Devenv4iom provides templates of config files. With every new version new
    config variables might be introduced or the description of existing config
    variables might be improved.
    The 'update config' reads the old configuration and creates a new config
    file containing the original configuration values. The old config file
    will persist as a backup copy.
    Hence, you should run 'update config' after every update of devenv4iom.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

SEE
    "$CONFIG_FILE"

BACKGROUND
    BAK="bak_\$(date '+%Y-%m-%d.%H.%M.%S')"
    cp "$CONFIG_FILE" \\
       "$CONFIG_FILE.\$BAK"
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/config.properties.template" \\
      "$CONFIG_FILE.\$BAK" > \\
      "$CONFIG_FILE"
EOF
}

#-------------------------------------------------------------------------------
help-update-doc() {
    ME=$(basename "$0")
    cat <<EOF
updates htlm docu

SYNOPSIS
    $ME [CONFIG-FILE] update docu

OVERVIEW
    Devenv4io provides a template for html documention. Depending on config
    variables, the html docu provides you a matching documentation.
    html docu has to updated, after updating devenv4iom.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

SEE
    $ENV_DIR/index.html

BACKGROUND
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/index.template" \\
      "$CONFIG_FILE" > \\
      "$ENV_DIR/index.html"
EOF
}

#-------------------------------------------------------------------------------
help-update-ws-props() {
    ME=$(basename "$0")
    cat <<EOF
updates ws.properties

SYNOPSIS
    $ME [CONFIG-FILE] update ws-props

OVERVIEW
    Updates the ws.properties file, which is required to run ws-tests on the
    managed IOM installation.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

SEE
    "$ENV_DIR/ws.properties"

BACKGROUND
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/ws.properties.template" \\
      "$CONFIG_FILE" > "$ENV_DIR/ws.properties"
EOF
}

#-------------------------------------------------------------------------------
help-update-geb-props() {
    ME=$(basename "$0")
    cat <<EOF
updates geb.properties

SYNOPSIS
    $ME [CONFIG-FILE] update geb-props

OVERVIEW
    Updates the geb.properties file, which is required to run geb-tests on the
    managed IOM installation.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

SEE
    "$ENV_DIR/geb.properties"

BACKGROUND
    "$PROJECT_PATH/scripts/template_engine.sh" \\
      "$PROJECT_PATH/templates/geb.properties.template" \\
      "$CONFIG_FILE" > "$ENV_DIR/geb.properties"
EOF
}

#-------------------------------------------------------------------------------
help-update-all() {
    ME=$(basename "$0")
    cat <<EOF
updates all configuration artifacts

SYNOPSIS
    $ME [CONFIG-FILE] update all

OVERVIEW
    Updates all configuration artifacts of current configuration. Shortcut for
    all other update-tasks.

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

SEE
    $ME [CONFIG-FILE] update config
    $ME [CONFIG-FILE] update doc
    $ME [CONFIG-FILE] update ws-props
    $ME [CONFIG-FILE] update geb-props
EOF
}

#-------------------------------------------------------------------------------
help-log() {
    ME=$(basename "$0")
    cat <<EOF
very basic access to log-messages

SYNOPSIS
    $ME [CONFIG-FILE] log WHAT

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

WHAT
    dbaccount|d*       get message logs of dbaccount init-container
    config|c*          get message logs of iom-config init-container
    app|ap*            get message logs of iom-app container
    access|ac*         get access logs of iom-app container

Run '$ME [CONFIG-FILE] log WHAT --help|-h' for more information on command
EOF
}

#-------------------------------------------------------------------------------
help-log-dbaccount() {
    ME=$(basename "$0")
    cat <<EOF
get messages of dbaccount init-container

SYNOPSIS
    $ME [CONFIG-FILE] log dbaccount [LEVEL] [-f]

ARGUMENTS
    LEVEL - optional. If set, has to be one of
      FATAL|ERROR|WARN|INFO|DEBUG|TRACE. If not set, WARN will be used.
      The passed level defines which messages are printed. Only messages of
      passed level and higher levels will be shown.
    -f - optional. If set, $ME follows new messages only. If not set, ALL 
      messages created until now are printed and the process ends after it.

OVERVIEW
    Requires 'jq' to be installed!
    Writes messages of dbaccount init-container and filters them according
    the passed log-level. 
    Behaves differntly when used inside and outside a pipe.
    If output is written to a terminal, $ME formats the messages.
    If output written to a pipe, no formatting is applied. This makes it easier
    to use the output for further processing. 

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG  
    OMS_LOGLEVEL_SCRIPTS - controls what type of messages are written. Messages,
      that are not written in container, can never be seen.

SEE
    $ME [CONFIG-FILE] info iom
EOF
}

#-------------------------------------------------------------------------------
help-log-config() {
    ME=$(basename "$0")
    cat <<EOF
get messages of config init-container

SYNOPSYS
    $ME [CONFIG-FILE] log config [LEVEL] [-f]

ARGUMENTS
    LEVEL - optional. If set, has to be one of
      FATAL|ERROR|WARN|INFO|DEBUG|TRACE. If not set, WARN will be used.
      The passed level defines which messages are printed. Only messages of
      passed level and higher levels will be shown.
    -f - optional. If set, $ME follows new messages only. If not set, ALL
      messages created until now are printed and the process ends after it.

OVERVIEW
    Requires 'jq' to be installed!
    Writes messages of config init-container and filters them according the
    passed log-level. 
    Behaves differently when used inside and outside of a pipe. 
    If output is written to a terminal, $ME formats the messages.
    If output written to a pipe, no formatting is applied. This makes it easier
    to use the output for further processing. 

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    OMS_LOGLEVEL_SCRIPTS - controls what type of messages are written. Messages,
      that are not written in container, can never be seen.

SEE
    $ME [CONFIG-FILE] info iom
EOF
}

#-------------------------------------------------------------------------------
help-log-app() {
    ME=$(basename "$0")
    cat <<EOF
get messages of iom application-container

SYNOPSIS
    $ME [CONFIG-FILE] log app [LEVEL] [-f]

ARGUMENTS
    LEVEL - optional. If set, has to be one of
      FATAL|ERROR|WARN|INFO|DEBUG|TRACE. If not set, WARN will be used.
      The passed level defines which messages are printed. Only messages of
      passed level and higher levels will be shown.
    -f - optional. If set, $ME follows new messages only. If not set, ALL
      messages created until now are printed and the process ends after it.

OVERVIEW
    Requires 'jq' to be installed!
    Writes messages of iom application-container and filters them according
    the passed log-level. 
    The Wildfly application server still writes some messages, that are not in
    json format. Those messages can only be seen, when accessing the output of
    the container directly.
    Behaves differently when used inside and outside of a pipe. 
    If output is written to a terminal, $ME formats the messages.
    If output written to a pipe, no formatting is applied. This makes it easier
    to use the output for further processing. 

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

CONFIG
    OMS_LOGLEVEL_SCRIPTS - controls what type of messages are written by 
      scripts. Messages, that are not written in container, can never be seen.
    OMS_LOGLEVEL_CONSOLE
    OMS_LOGLEVEL_IOM
    OMS_LOGLEVEL_HIBERNATE
    OMS_LOGLEVEL_QUARTZ
    OMS_LOGLEVEL_ACTIVEMQ
    OMS_LOGLEVEL_CUSTOMIZATION - all these variables control what type of 
      messages are written by Wildfly application server and the IOM 
      applications. Messages, that are not written in container, can never be
      seen.

SEE
    $ME [CONFIG-FILE] info iom
EOF
}

#-------------------------------------------------------------------------------
help-log-access() {
    ME=$(basename "$0")
    cat <<EOF
get access logs of iom application-container

SYNOPSIS
    $ME [CONFIG-FILE] log access [LEVEL] [-f]

ARGUMENTS
    LEVEL - optional. If set, has to be one of ERROR|ALL. If not set, ERROR will
      be used. The passed level defines which messages are printed. If set to 
      ERROR, only access-log entries are printed, where http status-code is 
      equal or greater than 400.
    -f - optional. If set, $ME follows new log-entries only. If not set, ALL
      log-entries created until now are printed and the process ends after it.

OVERVIEW
    Requires 'jq' to be installed!
    Writes access logs of iom application-container and filters them
    according the passed log-level.
    Behaves differently when used inside and outside of a pipe. 
    If output is written to a terminal, $ME formats the messages.
    If output written to a pipe, no formatting is applied. This makes it easier
    to use the output for further processing. 

CONFIG-FILE
    Name of config-file to be used. If not set, the environment variable
    DEVENV4IOM_CONFIG will be checked. If no config-file can be found, $ME
    ends with an error.

SEE
    $ME [CONFIG-FILE] info iom
EOF
}

################################################################################
# helper functions
################################################################################

#-------------------------------------------------------------------------------
# print error message
# $1: level 0
# $2: level 1
#-------------------------------------------------------------------------------
syntax_error() (
    ME="$(basename "$0")"
    log_json ERROR "Syntax error. Please call '$ME $CONFIG_FILE $1 $2 --help' to get more information." < /dev/null
)

#-------------------------------------------------------------------------------
# logs message in json format to stdout
# $1:    log-level (ERROR|WARN|INFO|DEBUG)
# $2:    log-message
# stdin: additional info (error output of programs, etc.)
#-------------------------------------------------------------------------------
# does not use jq, in order to reduce installation efforts and dependencies
log_json() (
    LEVEL=$1
    MSG=$2
    ADD_INFO_IN="$(mktemp)"
    ADD_INFO="$(mktemp)"
    trap "rm -f $ADD_INFO_IN $ADD_INFO" EXIT SIGTERM
    
    # get REQUESTED_LEVEL
    case $LEVEL in
        ERROR)
            REQUESTED_LEVEL=0
            ;;
        WARN)
            REQUESTED_LEVEL=1
            ;;
        INFO)
            REQUESTED_LEVEL=2
            ;;
        DEBUG)
            REQUESTED_LEVEL=3
            ;;
        *)
            echo "log_json: unknown LEVEL '$LEVEL'" 1>&2
            rm -f "$ADD_INFO_IN" "$ADD_INFO"
            exit 1
            ;;
    esac
    # get ALLOWED_LEVEL (from configuration)
    case $OMS_LOGLEVEL_DEVENV in
        ERROR)
            ALLOWED_LEVEL=0
            ;;
        WARN)
            ALLOWED_LEVEL=1
            ;;
        INFO)
            ALLOWED_LEVEL=2
            ;;
        DEBUG)
            ALLOWED_LEVEL=3
            ;;
        *)
            echo "log_json: config variable OMS_LOGLEVEL_DEVENV contains invalid value '$OMS_LOGLEVEL_DEVENV'" 1>&2
            rm -f "$ADD_INFO_IN" "$ADD_INFO"
            exit 1
            ;;
    esac
    
    # quote MSG
    MSG="$(echo $MSG | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | tr -d '\000-\037')"

    # quote additional info
    cat > "$ADD_INFO_IN"
    if [ -s "$ADD_INFO_IN" ]; then
        { echo -n '"'; cat "$ADD_INFO_IN" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | tr -d '\000-\037'; echo -n '"'; } > "$ADD_INFO"
    fi

    # write json message if REQUESTED_LEVEL <= ALLOWED_LEVEL
    if [ $REQUESTED_LEVEL -le $ALLOWED_LEVEL ]; then
        if [ -s "$ADD_INFO_IN" ]; then
            echo "{ \
\"tenant\":\"Intershop\", \
\"environment\":\"devenv4iom\", \
\"logHost\":\"$(hostname)\", \
\"logVersion\":\"1.0\", \
\"appName\":\"devenv4iom\", \
\"appVersion\":\"$DEVENV4IOM_VERSION\", \
\"logType\":\"script\", \
\"timestamp\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\", \
\"level\":\"$LEVEL\", \
\"message\":\"$MSG\", \
\"processName\":\"$(basename $0)\", \
\"additionalInfo\":$(cat $ADD_INFO), \
\"configName\":\"$CAAS_ENV_NAME\" \
}"
        else
            echo "{ \
\"tenant\":\"Intershop\", \
\"environment\":\"devenv4iom\", \
\"logHost\":\"$(hostname)\", \
\"logVersion\":\"1.0\", \
\"appName\":\"devenv4iom\", \
\"appVersion\":\"$DEVENV4IOM_VERSION\", \
\"logType\":\"script\", \
\"timestamp\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\", \
\"level\":\"$LEVEL\", \
\"message\":\"$MSG\", \
\"processName\":\"$(basename $0)\", \
\"configName\":\"$CAAS_ENV_NAME\" \
}"
        fi
    fi
    rm -f "$ADD_INFO_IN" "$ADD_INFO"
)

#-------------------------------------------------------------------------------
# get name of operating system
# TODO: this is a copy of the funktion from template_engine.sh to become able
# to read template-variables. A better solution might be to move this function
# to template-varaibles!
#-------------------------------------------------------------------------------
OS() {
    if ! uname -o > /dev/null 2>&1; then
        uname -s
    else
        uname -o
    fi
}

#-------------------------------------------------------------------------------
# wait for job to complete
# $1: job name
# $2: timeout [s]
# ->: true - if job was successfully completed before timeout
#     false - else
#-------------------------------------------------------------------------------
kube_job_wait() (
    JOB_NAME=$1
    TIMEOUT=$2
    PHASE=$(kubectl get pods --namespace $EnvId -l job-name=$JOB_NAME -o jsonpath='{.items[0].status.phase}' 2> /dev/null)
    START_TIME=$(date '+%s')
    while [ \( "$PHASE" != 'Succeeded' \) -a \( $PHASE"" != 'Failed' \) -a \( $(date '+%s') -lt $(expr "$START_TIME" + "$TIMEOUT") \) ]; do
        sleep 5
        PHASE=$(kubectl get pods --namespace $EnvId -l job-name=$JOB_NAME -o jsonpath='{.items[0].status.phase}' 2> /dev/null)
    done
    [ \( "$PHASE" = 'Succeeded' \) ]
)

#-------------------------------------------------------------------------------
# wait for pod to be in phase running
# $1: app name (iom|postgres|mailhog)
# $2: timeout [s]
# ->: true - if pod is running before timeout
#     false - if timeout is reached before pod is running
#-------------------------------------------------------------------------------
# TODO: don't test first pod only
kube_pod_wait() (
    APP_NAME=$1
    TIMEOUT=$2
    PHASE=$(kubectl get pods --namespace $EnvId -l app=$APP_NAME -o jsonpath='{.items[0].status.phase}' 2> /dev/null)    
    START_TIME=$(date '+%s')
    while [ \( "$PHASE" != 'Succeeded' \) -a \
               \( "$PHASE" != 'Failed' \) -a \
               \( "$PHASE" != 'Running' \) -a \
               \( $(date '+%s') -lt $(expr "$START_TIME" + "$TIMEOUT") \) ]; do
        sleep 5
        PHASE=$(kubectl get pods --namespace $EnvId -l app=$APP_NAME -o jsonpath='{.items[0].status.phase}' 2> /dev/null)
    done
    [ "$PHASE" = 'Running' ]
)

#-------------------------------------------------------------------------------
# wait for initContainer to be terminated
# $1: app name (iom)
# $2: name of init-container (e.g. dbaccount, config)
# $3: timeout [s]
# ->  true - if init-container is terminated before timeout
#     false - else
#-------------------------------------------------------------------------------
kube_init_wait() (
    APP_NAME=$1
    INIT_NAME=$2
    TIMEOUT=$3
    TERMINATED=$(kubectl get pods --namespace $EnvId -l app=$APP_NAME -o jsonpath='{.items[*].status.initContainerStatuses[?(@.name=="'$INIT_NAME'")].state.terminated}' 2> /dev/null)
    START_TIME=$(date '+%s')
    while [ -z "$TERMINATED" -a \( $(date '+%s') -lt $(expr "$START_TIME" + "$TIMEOUT") \) ]; do
        sleep 5
        TERMINATED=$(kubectl get pods --namespace $EnvId -l app=$APP_NAME -o jsonpath='{.items[*].status.initContainerStatuses[?(@.name=="'$INIT_NAME'")].state.terminated}' 2> /dev/null)
    done
    [ ! -z "$TERMINATED" ]
)

#-------------------------------------------------------------------------------
# kubernetes namespace exists
# ->: true|false
#-------------------------------------------------------------------------------
kube_namespace_exists() (
    NAME=$1
    # list all namespaces and check if the requested namespace exists
    NAMESPACE_EXISTS=false
    for NAMESPACE in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2> /dev/null); do
        if [ "$NAMESPACE" = "$EnvId" ]; then
            NAMESPACE_EXISTS=true
            break
        fi
    done
    [ "$NAMESPACE_EXISTS" = 'true' ]
)

#-------------------------------------------------------------------------------
# Docker volume exists
# $1: name
# ->: true|false
#-------------------------------------------------------------------------------
docker_volume_exists() (
    NAME=$1
    # list all volumes and check if requested volume already exists
    VOLUME_EXISTS=false
    for VOLUME in $(docker volume ls -q 2> /dev/null); do
        if [ "$VOLUME" = "$EnvId-$NAME" ]; then
            VOLUME_EXISTS=true
            break
        fi
    done
    [ "$VOLUME_EXISTS" = 'true' ]
)

#-------------------------------------------------------------------------------
# kubernetes resource exists?
# $1: type (pod|service)
# $2: name
# ->: true|false
#-------------------------------------------------------------------------------
kube_resource_exists() (
    TYPE=$1
    NAME=$2
    # list all resources and check if NAME exists
    RESOURCE_EXISTS=false
    for RESOURCE in $(kubectl get $TYPE -o jsonpath='{.items[*].metadata.name}' --namespace=$EnvId 2> /dev/null); do
        if [ "$RESOURCE" = "$NAME" ]; then
            RESOURCE_EXISTS=true
            break
        fi
    done
    [ "$RESOURCE_EXISTS" = 'true' ]
)

#-------------------------------------------------------------------------------
# $1: timestamp
# ->  seconds
#-------------------------------------------------------------------------------
time2seconds() {
    if [ "$(OS)" = 'Darwin' ]; then
        date -j -f '%Y-%m-%dT%H:%M:%SZ' "$1" '+%s'
    else
        date -d "$1" '+%s'
    fi
}

#-------------------------------------------------------------------------------
# get id of pod matching requested app-name
# if there is more than one pod matching (e.g. one is terminating, one is
# starting), the "running" pod is returned. If no such exists, the newer one
# will be selected.
# $1: app-name
# -> pod-name or empty, if no matching pod exists
#-------------------------------------------------------------------------------
kube_get_pod() (
    # get name, status, creation timestamp of pods and store them in an array
    # the array is flat and contains all names, statuses and creation timestamps in this order
    POD_INFO=( $(kubectl get pods --namespace $EnvId -l app=$1 -o jsonpath='{.items[*].metadata.name} {.items[*].status.phase} {.items[*].metadata.creationTimestamp}' 2> /dev/null) )
    POD_COUNT=$(expr ${#POD_INFO[@]} / 3)
    POD_NAME=''

    # search for a pod in state running and store its name
    # terminating pods still have the state running. Terminating pods can be
    # identified by checking deletionTimestamp. If this field exists, it is
    # terminating.
    I=0
    while [ \( -z "$POD_NAME" \) -a \( "$I" -lt "$POD_COUNT" \) ]; do
        NAME_INDEX=$(expr 0 \* $POD_COUNT + $I)
        STATUS_INDEX=$(expr 1 \* $POD_COUNT + $I)
        if [ "${POD_INFO[$STATUS_INDEX]}" = 'Running' ]; then
            # check deletionTimestamp
            if [ -z "$(kubectl get pod "${POD_INFO[$NAME_INDEX]}" --namespace $EnvId -o jsonpath='{.metadata.deletionTimestamp}' 2> /dev/null)" ]; then
                POD_NAME="${POD_INFO[$NAME_INDEX]}"
            fi
        fi
        I=$(expr $I + 1)
    done

    # search for the newest pod and store its name
    # if no running pod was found before
    if [ -z "$POD_NAME" ]; then
        I=0
        POD_SECONDS=
        while [  "$I" -lt "$POD_COUNT" ]; do
            NAME_INDEX=$(expr 0 \* $POD_COUNT + $I)
            TIMESTAMP_INDEX=$(expr 2 \* $POD_COUNT + $I)
            if [ -z "$POD_SECONDS" ]; then
                POD_SECONDS="$(time2seconds "${POD_INFO[$TIMESTAMP_INDEX]}")"
                POD_NAME="${POD_INFO[$NAME_INDEX]}"
            elif [ "$(time2seconds "${POD_INFO[$TIMESTAMP_INDEX]}")" -gt "$POD_SECONDS" ]; then
                POD_SECONDS="$(time2seconds "${POD_INFO[$TIMESTAMP_INDEX]}")"
                POD_NAME="${POD_INFO[$NAME_INDEX]}"
            fi
            I=$(expr $I + 1)
        done
    fi
    
    echo "$POD_NAME"
)

################################################################################
# functions, implementing the info handlers
################################################################################

#-------------------------------------------------------------------------------
# info iom
#-------------------------------------------------------------------------------
info-iom() {
    cat <<EOF
--------------------------------------------------------------------------------
$ID
--------------------------------------------------------------------------------
Links:
======
OMT:                        http://$HOST_IOM:$PORT_IOM_SERVICE/omt
DBDoc:                      http://$HOST_IOM:$PORT_IOM_SERVICE/dbdoc/
Wildfly (admin:admin):      http://$HOST_IOM:$PORT_WILDFLY_SERVICE/console
--------------------------------------------------------------------------------
Development:
============
Debug-Port:                 $PORT_DEBUG_SERVICE
CAAS_ENV_NAME:              $CAAS_ENV_NAME
CUSTOM_APPS_DIR:            $CUSTOM_APPS_DIR
CUSTOM_TEMPLATES_DIR:       $CUSTOM_TEMPLATES_DIR
CUSTOM_XSLT_DIR:            $CUSTOM_XSLT_DIR
CUSTOM_DBMIGRATE_DIR:       $CUSTOM_DBMIGRATE_DIR
CUSTOM_DUMPS_DIR:           $CUSTOM_DUMPS_DIR
CUSTOM_SQLCONF_DIR:         $CUSTOM_SQLCONF_DIR
CUSTOM_JSONCONF_DIR:        $CUSTOM_JSONCONF_DIR
--------------------------------------------------------------------------------
Direct access:
==============
CUSTOM_SHARE_DIR:           $CUSTOM_SHARE_DIR
--------------------------------------------------------------------------------
Logging:
========
OMS_LOGLEVEL_CONSOLE:       $OMS_LOGLEVEL_CONSOLE
OMS_LOGLEVEL_IOM:           $OMS_LOGLEVEL_IOM
OMS_LOGLEVEL_HIBERNATE:     $OMS_LOGLEVEL_HIBERNATE
OMS_LOGLEVEL_QUARTZ:        $OMS_LOGLEVEL_QUARTZ
OMS_LOGLEVEL_ACTIVEMQ:      $OMS_LOGLEVEL_ACTIVEMQ
OMS_LOGLEVEL_CUSTOMIZATION: $OMS_LOGLEVEL_CUSTOMIZATION
OMS_LOGLEVEL_SCRIPTS:       $OMS_LOGLEVEL_SCRIPTS
--------------------------------------------------------------------------------
Docker:
=======
IOM_DBACCOUNT_IMAGE:        $IOM_DBACCOUNT_IMAGE
IOM_CONFIG_IMAGE:           $IOM_CONFIG_IMAGE
IOM_APP_IMAGE:              $IOM_APP_IMAGE
IMAGE_PULL_POLICY:          $IMAGE_PULL_POLICY
--------------------------------------------------------------------------------
EOF
    POD="$(kube_get_pod iom)"
    if [ ! -z "$POD" ]; then
        cat <<EOF
Kubernetes:
===========
namespace:                  $EnvId
$(kubectl get pods --namespace=$EnvId -l app=iom)
--------------------------------------------------------------------------------
Usefull commands:
=================

Login into Pod:             kubectl exec --namespace $EnvId $POD -it bash

Currently used yaml:        kubectl get pod -l app=iom -o yaml --namespace=$EnvId
Describe iom pod:           kubectl describe --namespace $EnvId pod $POD
Describe iom deployment     kubectl describe --namespace $EnvId deployment iom
Describe iom service        kubectl describe --namespace $EnvId service iom-service

Get dbaccount logs:         kubectl logs $POD --namespace $EnvId -c dbaccount
Follow dbaccount logs:      kubectl logs --tail=1 -f $POD --namespace $EnvId -c dbaccount
Get config logs:            kubectl logs $POD --namespace $EnvId -c config
Follow config logs:         kubectl logs --tail=1 -f $POD --namespace $EnvId -c config
Get iom logs:               kubectl logs $POD --namespace $EnvId -c iom
Follow iom logs:            kubectl logs --tail=1 -f $POD --namespace $EnvId -c iom
--------------------------------------------------------------------------------
EOF
    fi
}

#-------------------------------------------------------------------------------
# info postgres
#-------------------------------------------------------------------------------
info-postgres() {
    cat <<EOF
--------------------------------------------------------------------------------
$ID
--------------------------------------------------------------------------------
Access to database:
===================
Host:                       $PgHostExtern
Port:                       $PgPortExtern
OMS_DB_USER:                $OMS_DB_USER
OMS_DB_PASS:                $OMS_DB_PASS
OMS_DB_NAME:                $OMS_DB_NAME
--------------------------------------------------------------------------------
Account Settings:
=================
OMS_DB_OPTIONS:             $OMS_DB_OPTIONS
OMS_DB_SEARCHPATH:          $OMS_DB_SEARCHPATH
--------------------------------------------------------------------------------
EOF
    if [ -z "$PGHOST" ]; then
        cat <<EOF
Server Settings:
================
POSTGRES_ARGS:              ${POSTGRES_ARGS[*]}
--------------------------------------------------------------------------------
Docker:
=======
DOCKER_DB_IMAGE:            $DOCKER_DB_IMAGE
IMAGE_PULL_POLICY:          $IMAGE_PULL_POLICY
--------------------------------------------------------------------------------
EOF
    fi
    POD="$(kube_get_pod postgres)"
    if [ ! -z "$POD" ]; then
        cat <<EOF
Kubernetes:
===========
namespace:                  $EnvId
KEEP_DATABASE_DATA:         $KEEP_DATABASE_DATA
$(kubectl get pods --namespace=$EnvId -l app=postgres)
--------------------------------------------------------------------------------
Usefull commands:
=================
Login into Pod:             kubectl exec --namespace $EnvId $POD -it bash
psql into root-db:          kubectl exec --namespace $EnvId $POD -it -- bash -c "PGUSER=$PGUSER PGDATABASE=$PGDATABASE psql"
psql into IOM-db:           kubectl exec --namespace $EnvId $POD -it -- bash -c "PGUSER=$OMS_DB_USER PGDATABASE=$OMS_DB_NAME psql"

Currently used yaml:        kubectl get pod -l app=postgres -o yaml --namespace=$EnvId
--------------------------------------------------------------------------------
EOF
    fi
}

#-------------------------------------------------------------------------------
# info mailserver
#-------------------------------------------------------------------------------
info-mailserver() {
    cat <<EOF
--------------------------------------------------------------------------------
$ID
--------------------------------------------------------------------------------
Links:
======
Web-UI:                     http://$HOST_IOM:$PORT_MAILHOG_UI_SERVICE
REST:                       http://$HOST_IOM:$PORT_MAILHOG_UI_SERVICE/api/v2/messages
--------------------------------------------------------------------------------
Docker:
=======
MAILHOG_IMAGE:              $MAILHOG_IMAGE
IMAGE_PULL_POLICY           $IMAGE_PULL_POLICY
--------------------------------------------------------------------------------
EOF
    POD="$(kube_get_pod mailhog)"
    if [ ! -z "$POD" ]; then
        cat <<EOF
Kubernetes:
===========
namespace:                  $EnvId
$(kubectl get pods --namespace=$EnvId -l app=mailhog)
--------------------------------------------------------------------------------
Usefull commands:
=================
Login into Pod:             kubectl exec --namespace $EnvId $POD -it sh
Currently used yaml:        kubectl get pod -l app=mailhog -o yaml --namespace=$EnvId
--------------------------------------------------------------------------------
EOF
    fi
}

#-------------------------------------------------------------------------------
# info storage
#-------------------------------------------------------------------------------
info-storage() {
    cat <<EOF
--------------------------------------------------------------------------------
$ID
--------------------------------------------------------------------------------
Config:
=======
KEEP_DATABASE_DATA:         $KEEP_DATABASE_DATA
--------------------------------------------------------------------------------
EOF
    if docker_volume_exists pgdata; then
        cat <<EOF
Docker:
=======
$(docker volume inspect $EnvId-pgdata)
--------------------------------------------------------------------------------
EOF
    else
        cat <<EOF
Docker:
=======
no docker volume with name $EnvId-pgdata exists.
--------------------------------------------------------------------------------
EOF
    fi
    if kube_resource_exists persistentvolumes $EnvId-postgres-pv; then
        cat <<EOF
Kubernetes:
===========
$(kubectl get persistentvolumes --namespace=$EnvId)
--------------------------------------------------------------------------------
Usefull commands:
=================
Currently used yaml:        kubectl get persistentvolumes -o yaml --namespace=$EnvId
--------------------------------------------------------------------------------
EOF
    else
        cat <<EOF
Kubernetes:
===========
no persistent volume with name $EnvId-postgres-pv exists.
--------------------------------------------------------------------------------
EOF
    fi
}

#-------------------------------------------------------------------------------
# info cluster
#-------------------------------------------------------------------------------
info-cluster() {
    cat <<EOF
--------------------------------------------------------------------------------
$ID
--------------------------------------------------------------------------------
Kubernetes Pods:
================
$(kubectl get pods --namespace=$EnvId)
--------------------------------------------------------------------------------
Kubernetes Services:
====================
$(kubectl get services --namespace=$EnvId)
--------------------------------------------------------------------------------
EOF
}

################################################################################
# functions, implementing the create handlers
################################################################################

#-------------------------------------------------------------------------------
# create storage
# -> true|false indicating success
#-------------------------------------------------------------------------------
create-storage() {
    SUCCESS=true
    if [ "$KEEP_DATABASE_DATA" = 'true' ] && ! docker_volume_exists pgdata; then
        docker volume create --name=$EnvId-pgdata -d local 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "create-storage: error creating docker volume $EnvId-pgdata" < "$TMP_ERR"
            SUCCESS=false
        else
            log_json INFO "create-storage: docker volume $EnvId-pgdata was successfully created" < "$TMP_OUT"
        fi
    else
        log_json INFO "create-storage: nothing to do" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# create namespace
# -> true|false indicating success
#-------------------------------------------------------------------------------
create-namespace() {
    SUCCESS=true
    if ! kube_namespace_exists; then
        kubectl create namespace $EnvId 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "create-namespace: error creating namespace '$EnvId'" < "$TMP_ERR"
            SUCCESS=true
        else
            log_json INFO "create-namespace: namespace '$EnvId' was successfully created" < "$TMP_OUT"
        fi
    else
        log_json INFO "create-namespace: nothing to do" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# create mailserver
# -> true|false indicating success
#-------------------------------------------------------------------------------
create-mailserver() {
    SUCCESS=true
    "$PROJECT_PATH/scripts/template_engine.sh" \
        "$PROJECT_PATH/templates/mailhog.yml.template" \
        "$CONFIG_FILE" | kubectl apply --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
    if [ $? -ne 0 ]; then
        log_json ERROR "create-mailserver: error creating mailserver" < "$TMP_ERR"
        SUCCESS=false
    else
        log_json INFO "create-mailserver: mailserver successfully created" < "$TMP_OUT"
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# create postgres
# -> true|false indicating success
#-------------------------------------------------------------------------------
create-postgres() {
    SUCCESS=true

    if [ -z "$PGHOST" ]; then
        # link Docker volume to database storage
        if [ "$KEEP_DATABASE_DATA" = 'true' ]; then
            MOUNTPOINT="\"$(docker volume inspect --format='{{.Mountpoint}}' $EnvId-pgdata)\"" \
                      "$PROJECT_PATH/scripts/template_engine.sh" \
                      "$PROJECT_PATH/templates/postgres-storage.yml.template" \
                      "$CONFIG_FILE" | kubectl apply --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
            if [ $? -ne 0 ]; then
                log_json ERROR "create-postgres: error linking docker volume to database storage" < "$TMP_ERR"
                SUCCESS=false
            else
                log_json INFO "create-postgres: successfully linked docker volume to database storage" < "$TMP_OUT"
            fi
        else
            log_json INFO "create-postges: no need to link docker volume to dabase storage" < /dev/null
        fi
        if [ "$SUCCESS" = 'true' ]; then
            if ! kube_resource_exists pods postgres || ! kube_resource_exists services postgres-service; then
                # start postgres pod/service
                "$PROJECT_PATH/scripts/template_engine.sh" \
                    "$PROJECT_PATH/templates/postgres.yml.template" \
                    "$CONFIG_FILE" | kubectl apply --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
                if [ $? -ne 0 ]; then
                    log_json ERROR "create-postgres: error creating postgres" < "$TMP_ERR"
                    SUCCESS=false
                else
                    log_json INFO "create-postgres: successfully created postgres" < "$TMP_OUT"
                fi
            else
                log_json INFO "create-postgres: pod and service already exist" < /dev/null
            fi
        fi
    else
        log_json INFO "create-postgres: nothing to do, external database configured (config variable PGHOST is set)" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# create iom
# -> true|false indicating success
#-------------------------------------------------------------------------------
create-iom() {
    SUCCESS=true
    "$PROJECT_PATH/scripts/template_engine.sh" \
        "$PROJECT_PATH/templates/iom.yml.template" \
        "$CONFIG_FILE" | kubectl apply --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
    if [ $? -ne 0 ]; then
        log_json ERROR "create-iom: error creating iom" < "$TMP_ERR"
        SUCCESS=false
    else
        log_json INFO "create-iom: successfully created iom" < "$TMP_OUT"
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# create cluster
# -> true|false indicating success
#-------------------------------------------------------------------------------
create-cluster() {
    create-storage &&
        create-namespace &&
        create-postgres &&
        kube_pod_wait postgres 300 &&
        create-mailserver &&
        create-iom
}

################################################################################
# functions, implementing the delete handlers
################################################################################

#---------------------------------------------------------------------------
# delete storage
# -> true|false indicating success
#---------------------------------------------------------------------------
delete-storage() {
    SUCCESS=true
    if docker_volume_exists pgdata; then
        docker volume rm $EnvId-pgdata 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "delete-storage: error deleting volume $EnvId-pgdata" < "$TMP_ERR"
            SUCCESS=false
        else
            log_json INFO "delete-storage: successfully deleted volume $EnvId-pgdata" < "$TMP_OUT"
        fi
    else
        log_json INFO "delete-storage: nothing to do" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# delete namespace
# -> true|false indicating success
#-------------------------------------------------------------------------------
delete-namespace() {
    SUCCESS=true
    if kube_namespace_exists; then
        kubectl delete namespace $EnvId 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "delete-namespace: error deleting namespace '$EnvId'" < "$TMP_ERR"
            SUCCESS=false
        else
            log_json INFO "delete-namespace: successfully deleted namespace '$EnvId'" < "$TMP_OUT"
        fi
    else
        log_json INFO "delete-namespace: nothing to do" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# delete mailserver
# -> true|false indicating success
#-------------------------------------------------------------------------------
delete-mailserver() {
    SUCCESS=true
    if kube_resource_exists pods mailhog || kube_resource_exists services mailhog-service; then
        "$PROJECT_PATH/scripts/template_engine.sh" \
            "$PROJECT_PATH/templates/mailhog.yml.template" \
            "$CONFIG_FILE" | kubectl delete --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "delete-mailserver: error deleting mail-server" < "$TMP_ERR"
            SUCCESS=false
        else
            log_json INFO "delete-mailserver: successfully deleted mail-server" < "$TMP_OUT"
        fi
    else
        log_json INFO "delete-mailserver: nothing to do" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# delete postgres
#-------------------------------------------------------------------------------
delete-postgres() {
    SUCCESS_PG=true
    SUCCESS_VL=true
    if kube_resource_exists pods postgres || kube_resource_exists services postgres-service; then
        "$PROJECT_PATH/scripts/template_engine.sh" \
            "$PROJECT_PATH/templates/postgres.yml.template" \
            "$CONFIG_FILE" | kubectl delete --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "delete-postgres: error deleting postgres" < "$TMP_ERR"
            SUCCESS_PG=false
        else
            log_json INFO "delete-postgres: successfully deleted postgres" < "$TMP_OUT"
        fi
    else
        log_json INFO "delete-postgres: nothing to do, to delete postgres" < /dev/null
    fi
    # unlink Docker volume from database storage
    if kube_resource_exists persistentvolumes $EnvId-postgres-pv; then
        MOUNTPOINT="\"$(docker volume inspect --format='{{.Mountpoint}}' $EnvId-pgdata)\"" \
                  "$PROJECT_PATH/scripts/template_engine.sh" \
                  "$PROJECT_PATH/templates/postgres-storage.yml.template" \
                  "$CONFIG_FILE" | kubectl delete --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "delete-postgres: error unlinking Docker volume from database storage" < "$TMP_ERR"
            SUCCESS_VL=false
        else
            log_json INFO "delete-postgres: successfully unlinked Docker volume from database storage" < "$TMP_OUT"
        fi
    else
        log_json INFO "delete-postgres: nothing to do, to unlink Docker volume from database storage" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ \( "$SUCCESS_PG" = 'true' \) -a \( "$SUCCESS_VL" = 'true' \) ]
}

#-------------------------------------------------------------------------------
# delete iom
#-------------------------------------------------------------------------------
delete-iom() {
    SUCCESS=true
    if kube_resource_exists pods iom || kube_resource_exists services iom-service; then
        "$PROJECT_PATH/scripts/template_engine.sh" \
            "$PROJECT_PATH/templates/iom.yml.template" \
            "$CONFIG_FILE" | kubectl delete --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "delete-iom: error deleting iom" < "$TMP_ERR"
            SUCCESS=false
        else
            log_json INFO "delete-iom: successfully deleted iom" < "$TMP_OUT"
        fi
    else
        log_json INFO "delete-iom: nothing to do" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# delete cluster
#-------------------------------------------------------------------------------
delete-cluster() {
    delete-iom &&
    delete-postgres &&
    delete-mailserver &&
    delete-namespace
}

################################################################################
# functions, implementing the wait handler
################################################################################

#-------------------------------------------------------------------------------
# wait for mailserver
# $1: timeout [s] (optional)
# ->  true|false indicating success
#-------------------------------------------------------------------------------
wait-mailserver() {
    # check and set timeout
    TIMEOUT=60
    if [ ! -z "$1" ] && ! ( echo "$1" | grep -q '^[0-9]*$'); then
        log_json WARN "wait-mailserver: invalid value passed for timeout ($1). Default value will be used" < /dev/null
    elif [ ! -z "$1" ]; then
        TIMEOUT=$1
    fi
    kube_pod_wait mailhog $TIMEOUT
    if [ $? -ne 0 ]; then
        log_json ERROR "wait-mailserver: timeout of $TIMEOUT s reached." < /dev/null
        false
    else
        true
    fi
}

#-------------------------------------------------------------------------------
# wait for postgres
# $1: timeout [s] (optional)
# ->  true|false indicating success
#-------------------------------------------------------------------------------
wait-postgres() {
    # check and set timeout
    TIMEOUT=60
    if [ ! -z "$1" ] && ! ( echo "$1" | grep -q '^[0-9]*$'); then
        log_json WARN "wait-postgres: invalid value passed for timeout ($1). Default value will be used" < /dev/null
    elif [ ! -z "$1" ]; then
        TIMEOUT=$1
    fi
    kube_pod_wait postgres $TIMEOUT
    if [ $? -ne 0 ]; then
        log_json ERROR "wait-postgres: timeout of $TIMEOUT s reached." < /dev/null
        false
    else
        true
    fi
}

#-------------------------------------------------------------------------------
# wait for iom
# $1: timeout [s] (optional)
# ->  true|false indicating success
#-------------------------------------------------------------------------------
wait-iom() {
    # check and set timeout
    TIMEOUT=60
    if [ ! -z "$1" ] && ! ( echo "$1" | grep -q '^[0-9]*$'); then
        log_json WARN "wait-iom: invalid value passed for timeout ($1). Default value will be used" < /dev/null
    elif [ ! -z "$1" ]; then
        TIMEOUT=$1
    fi
    kube_pod_wait iom $TIMEOUT
    if [ $? -ne 0 ]; then
        log_json ERROR "wait-iom: timeout of $TIMEOUT s reached." < /dev/null
        false
    else
        true
    fi
}

################################################################################
# functions, implementing the apply handler
################################################################################

#-------------------------------------------------------------------------------
# apply deployment
# $1: pattern
# ->: true|false indicating success
#-------------------------------------------------------------------------------
apply-deployment() {
    PATTERN=$1
    SUCCESS=true
    if [ ! -z "$CUSTOM_APPS_DIR" ]; then
        POD=$(kube_get_pod iom 2> "$TMP_ERR")
        if [ -z "$POD" ]; then
            log_json ERROR "apply-deployment: error getting pod name" < "$TMP_ERR"
            SUCCESS=false
        else
            if [ -z "$PATTERN" ]; then
                kubectl exec $POD --namespace $EnvId -- bash -ic redeploy 2> "$TMP_ERR" > "$TMP_OUT"
            else
                # TODO no messages visible, if script ended with error!
                kubectl exec $POD --namespace $EnvId -- bash -ic "/opt/oms/bin/forced-redeploy.sh --pattern=$PATTERN || true" 2> "$TMP_ERR" > "$TMP_OUT"
            fi   
            if [ $? -ne 0 ]; then
                log_json ERROR "apply-deployment: error applying deployments" < "$TMP_ERR"
                SUCCESS=false
            else
                # output is already in json format
                cat "$TMP_OUT"
                log_json INFO "apply-deployment: successfully applied deployments" < /dev/null
            fi
        fi
    else
        log_json INFO "apply-deployment: config variable CUSTOM_APPS_DIR not set, deployment skipped" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# apply mail templates
# -> true|false indicating success
#-------------------------------------------------------------------------------
apply-mail-templates() {
    SUCCESS=true
    if [ ! -z "$CUSTOM_TEMPLATES_DIR" ]; then
        POD=$(kube_get_pod iom 2> "$TMP_ERR")
        if [ -z "$POD" ]; then
            log_json ERROR "apply-mail-templates: error getting pod name" < "$TMP_ERR"
            SUCCESS=false
        else
            kubectl exec $POD --namespace $EnvId -- bash -ic apply-templates 2> "$TMP_ERR" > "$TMP_OUT"
            if [ $? -ne 0 ]; then
                log_json ERROR "apply-mail-templates: error applying mail templates" < "$TMP_ERR"
                SUCCESS=false
            else
                log_json INFO "apply-mail-templates: successfully applied mail templates" < "$TMP_OUT"
            fi
        fi
    else
        log_json INFO "apply-mail-templates: config variable CUSTOM_TEMPLATES_DIR not set, skipped applying mail templates" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# apply xsl templates
# -> true|false indicating success
#-------------------------------------------------------------------------------
apply-xsl-templates() {
    SUCCESS=true
    if [ ! -z "$CUSTOM_XSLT_DIR" ]; then
        POD=$(kube_get_pod iom 2> "$TMP_ERR")
        if [ -z "$POD" ]; then
            log_json ERROR "apply-xsl-templates: error getting pod name" < "$TMP_ERR"
            SUCCESS=false
        else
            kubectl exec $POD --namespace $EnvId -- bash -ic apply-xslt 2> "$TMP_ERR" > "$TMP_OUT"
            if [ $? -ne 0 ]; then
                log_json ERROR "apply-xsl-templates: error applying xsl templates" < "$TMP_ERR"
                SUCCESS=false
            else
                log_json INFO "apply-xsl-templates: successfully applied xsl templates" < "$TMP_OUT"
            fi
        fi
    else
        log_json INFO "apply-xsl-templates: config variable CUSTOM_XSLT_DIR not set, skipped applying xsl templates" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# apply sql scripts
# $1: sql-directory
# $2: timeout
# -> true|false indicating success
#-------------------------------------------------------------------------------
apply-sql-scripts() {
    SUCCESS=true

    # check and convert to absolute path
    if [ ! -d "$1" -a ! -f "$1" ]; then
        log_json ERROR "apply-sql-scripts: '$1' is nor a file or directory" < /dev/null
        SUCCESS=false
    else
        case "$1" in
            /*)
                SQL_SRC="$1"
                ;;
            *)
                SQL_SRC="$(pwd)/$1"
        esac
    fi

    # check and set timeout
    TIMEOUT=60
    if [ ! -z "$2" ] && ! ( echo "$2" | grep -q '^[0-9]*$'); then
        log_json WARN "apply-sql-scripts: invalid value passed for timeout ($2). Default value will be used" < /dev/null
    elif [ ! -z "$2" ]; then
        TIMEOUT=$2
    fi

    if [ "$SUCCESS" = 'true' ]; then
        # start apply-sql job
        SQL_SRC="$SQL_SRC" \
               "$PROJECT_PATH/scripts/template_engine.sh" \
               "$PROJECT_PATH/templates/apply-sql.yml.template" \
               "$CONFIG_FILE" | kubectl apply --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "apply-sql-scripts: error starting job" < "$TMP_ERR"
            SUCCESS=false
        else
            log_json INFO "apply-sql-scripts: job successfully started" < "$TMP_OUT"
            
            # wait for job to finish
            if ! kube_job_wait apply-sql-job $TIMEOUT; then
                log_json ERROR "apply-sql-scripts: timeout of $TIMEOUT seconds reached" < /dev/null
                SUCCESS=false
            fi
            # get logs of job
            POD=$(kubectl get pods --namespace $EnvId -l job-name=apply-sql-job -o jsonpath='{.items[0].metadata.name}' 2> "$TMP_ERR" )
            if [ -z "$POD" ]; then
                log_json ERROR "apply-sql-scripts: error getting pod name" < "$TMP_ERR"
                SUCCESS=false
            else
                kubectl logs $POD --namespace $EnvId 2> "$TMP_ERR" > "$TMP_OUT"
                if [ $? -ne 0 ]; then
                    log_json ERROR "apply-sql-scripts: error getting logs of job" < "$TMP_ERR"
                    SUCCESS=false
                else
                    # logs of job are already in json format
                    cat "$TMP_OUT"
                fi
            fi
            # delete apply-sql-job
            "$PROJECT_PATH/scripts/template_engine.sh" \
                "$PROJECT_PATH/templates/apply-sql.yml.template" \
                "$CONFIG_FILE" | kubectl delete --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
            if [ $? -ne 0 ]; then
                log_json ERROR "apply-sql-scripts: error deleting job" < "$TMP_ERR"
                SUCCESS=false
            else
                log_json INFO "apply-sql-scripts: successfully deleted job" < "$TMP_OUT"
            fi

            # it's easier for the user to detect an error, if the last message
            # is giving this information
            if [ "$SUCCESS" != 'true' ]; then
                log_json ERROR "apply-sql-scripts: job ended with ERROR" < /dev/null
            fi
        fi
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# apply sql config
# $1: timeout [s]
# -> true|false indicating success
#-------------------------------------------------------------------------------
apply-sql-config() {
    SUCCESS=true

    # check and set timeout
    TIMEOUT=60
    if [ ! -z "$1" ] && ! ( echo "$1" | grep -q '^[0-9]*$'); then
        log_json WARN "apply-sql-config: invalid value passed for timeout ($1). Default value will be used" < /dev/null
    elif [ ! -z "$1" ]; then
        TIMEOUT=$1
    fi

    if [ ! -z "$CUSTOM_SQLCONF_DIR" ]; then
        # start sqlconfig-job
        "$PROJECT_PATH/scripts/template_engine.sh" \
            "$PROJECT_PATH/templates/sqlconfig.yml.template" \
            "$CONFIG_FILE" | kubectl apply --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "apply-sql-config: error starting job" < "$TMP_ERR"
            SUCCESS=false
        else
            log_json INFO "apply-sql-config: job successfully started" < "$TMP_OUT"
            
            # wait for job to finish
            if ! kube_job_wait sqlconfig-job $TIMEOUT; then
                log_json ERROR "apply-sql-config: timeout of $TIMEOUT seconds reached" < /dev/null
                SUCCESS=false
            fi
            # get logs of job
            POD=$(kubectl get pods --namespace $EnvId -l job-name=sqlconfig-job -o jsonpath='{.items[0].metadata.name}' 2> "$TMP_ERR" )
            if [ -z "$POD" ]; then
                log_json ERROR "apply-sql-config: error getting pod name" < "$TMP_ERR"
                SUCCESS=false
            else
                kubectl logs $POD --namespace $EnvId 2> "$TMP_ERR" > "$TMP_OUT"
                if [ $? -ne 0 ]; then
                    log_json ERROR "apply-sql-config: error getting logs of job" < "$TMP_ERR"
                    SUCCESS=false
                else
                    # logs of job are already in json format
                    cat "$TMP_OUT"
                fi
            fi
            # delete sqlconfig-job
            "$PROJECT_PATH/scripts/template_engine.sh" \
                "$PROJECT_PATH/templates/sqlconfig.yml.template" \
                "$CONFIG_FILE" | kubectl delete --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
            if [ $? -ne 0 ]; then
                log_json ERROR "apply-sql-config: error deleting job" < "$TMP_ERR"
                SUCCESS=false
            else
                log_json INFO "apply-sql-config: successfully deleted job" < "$TMP_OUT"
            fi

            # it's easier for the user to detect an error, if the last message
            # is giving this information
            if [ "$SUCCESS" != 'true' ]; then
                log_json ERROR "apply-sql-config: job ended with ERROR" < /dev/null
            fi
        fi
    else
        log_json INFO "apply-sql-config: config variable CUSTOM_SQLCONF_DIR not set, no sql-config applied" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# apply json config
# $1: timeout [s]
# -> true|false indicating success
#-------------------------------------------------------------------------------
apply-json-config() {
    SUCCESS=true

    # check and set timeout
    TIMEOUT=60
    if [ ! -z "$1" ] && ! ( echo "$1" | grep -q '^[0-9]*$'); then
        log_json WARN "apply-json-config: invalid value passed for timeout ($1). Default value will be used" < /dev/null
    elif [ ! -z "$1" ]; then
        TIMEOUT=$1
    fi

    if [ ! -z "$CUSTOM_JSONCONF_DIR" ]; then
        # start jsonconfig-job
        "$PROJECT_PATH/scripts/template_engine.sh" \
            "$PROJECT_PATH/templates/jsonconfig.yml.template" \
            "$CONFIG_FILE" | kubectl apply --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "apply-json-config: error starting job" < "$TMP_ERR"
            SUCCESS=false
        else
            log_json INFO "apply-json-config: job successfully started" < "$TMP_OUT"

            # wait for job to finish
            if ! kube_job_wait jsonconfig-job $TIMEOUT; then
                log_json ERROR "apply-json-config: timeout of $TIMEOUT seconds reached" < /dev/null
                SUCCESS=false
            fi
            # get logs of job
            POD=$(kubectl get pods --namespace $EnvId -l job-name=jsonconfig-job -o jsonpath='{.items[0].metadata.name}' 2> "$TMP_ERR" )
            if [ -z "$POD" ]; then
                log_json ERROR "apply-json-config: error getting pod name" < "$TMP_ERR"
                SUCCESS=false
            else
                kubectl logs $POD --namespace $EnvId 2> "$TMP_ERR" > "$TMP_OUT"
                if [ $? -ne 0 ]; then
                    log_json ERROR "apply-json-config: error getting logs of job" < "$TMP_ERR"
                    SUCCESS=false
                else
                    # logs of job are already in json format
                    cat "$TMP_OUT"
                fi
            fi
            
            # delete jsonconfig-job
            "$PROJECT_PATH/scripts/template_engine.sh" \
                "$PROJECT_PATH/templates/jsonconfig.yml.template" \
                "$CONFIG_FILE" | kubectl delete --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
            if [ $? -ne 0 ]; then
                log_json ERROR "apply-json-config: error deleting job" < "$TMP_ERR"
                SUCCESS=false
            else
                log_json INFO "apply-json-config: successfully deleted job" < "$TMP_OUT"
            fi

            # it's easier for the user to detect an error, if the last message
            # is giving this information
            if [ "$SUCCESS" != 'true' ]; then
                log_json ERROR "apply-json-config: job ended with ERROR" < /dev/null
            fi
        fi
    else
        log_json INFO "apply-json-config: config variable CUSTOM_JSONCONF_DIR not set, no json-config applied" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# apply db-migrate scripts
# $1: timeout [s]
# -> true|false indicating success
#-------------------------------------------------------------------------------
apply-dbmigrate() {
    SUCCESS=true

    # check and set timeout
    TIMEOUT=60
    if [ ! -z "$1" ] && ! ( echo "$1" | grep -q '^[0-9]*$'); then
        log_json WARN "apply-dbmigrate: invalid value passed for timeout ($1). Default value will be used" < /dev/null
    elif [ ! -z "$1" ]; then
        TIMEOUT=$1
    fi

    if [ ! -z "$CUSTOM_DBMIGRATE_DIR" ]; then
        # start dbmigrate-job
        "$PROJECT_PATH/scripts/template_engine.sh" \
            "$PROJECT_PATH/templates/dbmigrate.yml.template" \
            "$CONFIG_FILE" | kubectl apply --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "apply-dbmigrate: error starting job" < "$TMP_ERR"
            SUCCESS=false
        else
            log_json INFO "apply-dbmigrate: job successfully started" < "$TMP_OUT"

            # wait for job to finish
            if ! kube_job_wait dbmigrate_job $TIMEOUT; then
                log_json ERRO "apply-dbmigrate: timeout of $TIMEOUT seconds reached" < /dev/null
                SUCCESS=false
            fi
            # get logs of job
            POD=$(kubectl get pods --namespace $EnvId -l job-name=dbmigrate-job -o jsonpath='{.items[0].metadata.name}' 2> "$TMP_ERR" )
            if [ -z "$POD" ]; then
                log_json ERROR "apply-dbmigrate: error getting pod name" < "$TMP_ERR"
                SUCCESS=false
            else
                kubectl logs $POD --namespace $EnvId 2> "$TMP_ERR" > "$TMP_OUT"
                if [ $? -ne 0 ]; then
                    log_json ERROR "apply-dbmigrate: error getting logs of job" < "$TMP_ERR"
                    SUCCESS=false
                else
                    # logs are already in json format
                    cat "$TMP_OUT"
                fi
            fi
            # delete dbmigrate-job
            "$PROJECT_PATH/scripts/template_engine.sh" \
                "$PROJECT_PATH/templates/dbmigrate.yml.template" \
                "$CONFIG_FILE" | kubectl delete --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
            if [ $? -ne 0 ]; then
                log_json ERROR "apply-dbmigrate: error deleting job" < "$TMP_ERR"
                SUCCESS=false
            else
                log_json INFO "apply-dbmigrate: successfully deleted job" < "$TMP_OUT"
            fi

            # it's easier for the user to detect an error, if the last message
            # is giving this information
            if [ "$SUCCESS" != 'true' ]; then
                log_json ERROR "apply-dbmigrate: job ended with ERROR" < /dev/null
            fi
        fi
    else
        log_json INFO "apply-dbmigrate: config variable CUSTOM_DBMIGRATE_DIR not set, db-migrate not applied" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

################################################################################
# functions, implementing the dump handler
################################################################################

#-------------------------------------------------------------------------------
# load dump
# -> true|false indicating success
#-------------------------------------------------------------------------------
dump-load() {
    SUCCESS=true
    
    if [ ! -z "$CUSTOM_DUMPS_DIR" ]; then
        if [ -z "$PGHOST" ]; then
            # delete iom & postgres
            if ! delete-iom; then
                SUCCESS=false
            fi
            if [ "$SUCCESS" = 'true' ] && ! delete-postgres; then
                SUCCESS=false
            fi
            # renew Docker local store
            if [ "$SUCCESS" = 'true' ] && ! delete-storage; then
                SUCCESS=false
            fi
            if [ "$KEEP_DATABASE_DATA" = 'true' ]; then
                if [ "$SUCCESS" = 'true' ] && ! create-storage; then
                    SUCCESS=false
                fi
            fi
            # create postgres and iom
            if [ "$SUCCESS" = 'true' ] && ! create-postgres; then
                SUCCESS=false
            fi
            if [ "$SUCCESS" = 'true' ] && ! kube_pod_wait postgres 300; then
                log_json ERROR "dump-load: error waiting for postgres to get running" < /dev/null
                SUCCESS=false
            fi
            if [ "$SUCCESS" = 'true' ]; then
                if ! create-iom; then
                    SUCCESS=false
                fi
            fi
        else
            log_json INFO "dump-load: external database configured, cannot load dump" < /dev/null
        fi
    else
        log_json INFO "dump-load: config variable CUSTOM_DUMPS_DIR not set, skipped loading dump" < /dev/null
    fi
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# create dump
# $1: timeout [s]
# -> true|false indicating success
#-------------------------------------------------------------------------------
dump-create() {
    SUCCESS=true

    # check and set timeout
    TIMEOUT=60
    if [ ! -z "$1" ] && ! ( echo "$1" | grep -q '^[0-9]*$'); then
        log_json WARN "dump-create: invalid value passed for timeout ($1). Default value will be used" < /dev/null
    elif [ ! -z "$1" ]; then
        TIMEOUT=$1
    fi
    
    if [ ! -z "$CUSTOM_DUMPS_DIR" ]; then
        # start dump-job
        "$PROJECT_PATH/scripts/template_engine.sh" \
            "$PROJECT_PATH/templates/dump.yml.template" \
            "$CONFIG_FILE" | kubectl apply --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
        if [ $? -ne 0 ]; then
            log_json ERROR "dump-create: error starting job" < "$TMP_ERR"
            SUCCESS=false
        else
            log_json INFO "dump-create: job successfully started" < "$TMP_OUT"

            # wait for job to finish
            if ! kube_job_wait dump-job $TIMEOUT; then
                log_json ERROR "dump-create: timeout of $TIMEOUT seconds reached" < /dev/null
                SUCCESS=false
            fi

            # get logs of job
            POD=$(kubectl get pods --namespace $EnvId -l job-name=dump-job -o jsonpath='{.items[0].metadata.name}' 2> "$TMP_ERR" )
            if [ -z "$POD" ]; then
                log_json ERROR "dump-create: error getting pod name" < "$TMP_ERR"
                SUCCESS=false
            else
                kubectl logs $POD --namespace $EnvId 2> "$TMP_ERR" > "$TMP_OUT"
                if [ $? -ne 0 ]; then
                    log_json ERROR "dump-create: error getting logs of job" < "$TMP_ERR"
                    SUCCESS=false
                else
                    # logs are already in json format
                    cat "$TMP_OUT"
                fi
            fi
            # delete dump-job
            "$PROJECT_PATH/scripts/template_engine.sh" \
                "$PROJECT_PATH/templates/dump.yml.template" \
                "$CONFIG_FILE" | kubectl delete --namespace $EnvId -f - 2> "$TMP_ERR" > "$TMP_OUT"
            if [ $? -ne 0 ]; then
                log_json ERROR "dump-create: error deleting job" < "$TMP_ERR"
                SUCCESS=false
            else
                log_json INFO "dump-create: successfully deleted job" < "$TMP_OUT"
            fi

            # it's easier for the user to detect an error, if the last message
            # is giving this information
            if [ "$SUCCESS" != 'true' ]; then
                log_json ERROR "dump-create: job ended with ERROR" < /dev/null
            fi
        fi
    else
        log_json INFO "dump-create: config variable CUSTOM_DUMPS_DIR not set, skipped creation of dump" < /dev/null
    fi
    rm -f "$TMP_ERR" "$TMP_OUT"
    [ "$SUCCESS" = 'true' ]
}

################################################################################
# functions, implementing the config handler
################################################################################

#-------------------------------------------------------------------------------
# update config file
# ->  true|false indicating success
#-------------------------------------------------------------------------------
update-config() {
    SUCCESS=true
    BAK="bak_$(date '+%Y-%m-%d.%H.%M.%S')"

    if ! cp "$CONFIG_FILE" "$CONFIG_FILE.$BAK" 2> "$TMP_ERR"; then
        log_json ERROR "update-config: error creating backup copy" < "$TMP_ERR"
        SUCCESS=false
    else
        "$PROJECT_PATH/scripts/template_engine.sh" \
            "$PROJECT_PATH/templates/config.properties.template" \
            "$CONFIG_FILE.$BAK" > "$CONFIG_FILE" 2> "$TMP_ERR"
        if [ $? -ne 0 ]; then
            log_json ERROR "update-config: error updating config file. Please analyze the problem, restore the config file from $CONFIG_FILE.$BAK and retry." < "$TMP_ERR"
            SUCCESS=false
        else
            log_json INFO "update-config: successfully updated config file" < /dev/null
        fi
    fi
    rm -f "$TMP_ERR"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# update html documentation
# ->  true|false indicating success
#-------------------------------------------------------------------------------
update-doc() {
    SUCCESS=true

    "$PROJECT_PATH/scripts/template_engine.sh" \
        "$PROJECT_PATH/templates/index.template" \
        "$CONFIG_FILE" > "$ENV_DIR/index.html" 2> "$TMP_ERR"
    if [ $? -ne 0 ]; then
        log_json ERROR "update-doc: error updating HTML docu." < "$TMP_ERR"
        SUCCESS=false
    else
        log_json INFO "update-doc: successfully updated HTML docu" < /dev/null
    fi
    rm -f "$TMP_ERR"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# update ws.properties
#-------------------------------------------------------------------------------
update-ws-props() {
    SUCCESS=true

    "$PROJECT_PATH/scripts/template_engine.sh" \
        "$PROJECT_PATH/templates/ws.properties.template" \
        "$CONFIG_FILE" > "$ENV_DIR/ws.properties" 2> "$TMP_ERR"
    if [ $? -ne 0 ]; then
        log_json ERROR "update-ws-props: error updating ws.properties." < "$TMP_ERR"
        SUCCESS=false
    else
        log_json INFO "update-ws-props: successfully updated ws.properties" < /dev/null
    fi
    rm -f "$TMP_ERR"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# update geb.properties
#-------------------------------------------------------------------------------
update-geb-props() {
    SUCCESS=true

    "$PROJECT_PATH/scripts/template_engine.sh" \
        "$PROJECT_PATH/templates/geb.properties.template" \
        "$CONFIG_FILE" > "$ENV_DIR/geb.properties" 2> "$TMP_ERR"
    if [ $? -ne 0 ]; then
        log_json ERROR "update-geb-props: error updating geb.properties." < "$TMP_ERR"
        SUCCESS=false
    else
        log_json INFO "update-geb-props: successfully updated geb.properties" < /dev/null
    fi
    rm -f "$TMP_ERR"
    [ "$SUCCESS" = 'true' ]
}

#-------------------------------------------------------------------------------
# update all
#-------------------------------------------------------------------------------
# TODO remove update of cli!
update-all() {
    update-config &&
        update-doc &&
        update-ws-props &&
        update-geb-props
}

################################################################################
# functions, implementing the log handler
################################################################################

#-------------------------------------------------------------------------------
# helper to find value in array
# $1: value
# $2: array
# -> true if found, else false
#-------------------------------------------------------------------------------
is_in_array() {
    VALUE="$1"
    shift
    ARRAY=( $@ )
    IS_IN_ARRAY=false
    for ENTRY in "${ARRAY[@]}"; do
        if [ "$ENTRY" = "$VALUE" ]; then
            IS_IN_ARRAY=true
            break
        fi
    done
    [ "$IS_IN_ARRAY" = 'true' ]
}

#-------------------------------------------------------------------------------
# helper to build jq filter for levels. The filter has to match all higher
# levels in array and the requested level itself.
# $1: Level
# $2: Array of levels
#-------------------------------------------------------------------------------
level_filter() {
    LEVEL="$1"
    shift
    LEVELS=( $@ )
    COUNT=0
    for ENTRY in "${LEVELS[@]}"; do
        if [ "$COUNT" -gt 0 ]; then
            echo -n ' or '
        fi
        echo -n "( .level == \"$ENTRY\")"
        if [ "$ENTRY" = "$LEVEL" ]; then
            break
        fi
        COUNT=$(expr $COUNT + 1)
    done
}

#-------------------------------------------------------------------------------
# get name of jq (since it differs on different platforms)
# -> name of jq
#-------------------------------------------------------------------------------
jq_get() {
    if [ ! -z "$(which jq 2> /dev/null)" ]; then
        echo 'jq'
    elif [ ! -z "$(which jq-win64) 2> /dev/null" ]; then
        echo 'jq-win64'
    fi
}

#-------------------------------------------------------------------------------
# get logs of dbaccount init container
# $1|2: [FATAL|ERROR|WARN|INFO|DEBUG|TRACE], defaults to WARN
# $1|2: [-f] if set, messages are printed in follow mode
# ->  true|false indicating success
#-------------------------------------------------------------------------------
log-dbaccount() (
    SUCCESS=false
    FOLLOW=false
    LEVEL=WARN
    LEVELS=(FATAL ERROR WARN INFO DEBUG TRACE)

    # decide how to interpret arguments
    if [ "$1" = '-f' -a ! -z "$2" ]; then
        FOLLOW=true
        LEVEL="$2"
    elif [ "$1" = '-f' ]; then
        FOLLOW=true
    elif [ "$2" = '-f' ]; then
        FOLLOW=true
        LEVEL="$1"
    elif [ ! -z "$1" ]; then
        LEVEL="$1"
    fi

    # check value of LEVEL
    if is_in_array "$(echo "$LEVEL" | tr '[a-z]' '[A-Z]')" ${LEVELS[@]}; then
        LEVEL=$(echo "$LEVEL" | tr '[a-z]' '[A-Z]')
        JQ="$(jq_get)"
        if [ -z "$JQ" ]; then
            log_json ERROR "log-dbaccount: jq not found" < /dev/null
        else
            if [ "$FOLLOW" = 'true' ]; then
                FOLLOW_FLAG="--tail=1 -f"
            else
                FOLLOW_FLAG=''
            fi
            
            # avoid formatting if output is written to pipe. This makes it much easier,
            # to process the results
            if [ -t 1 ]; then
                COMPACT_FLAG=''
            else
                COMPACT_FLAG='--compact-output'
            fi
            
            POD="$(kube_get_pod iom)"
            if [ ! -z "$POD" ]; then
                # make sure to get info about failed kubectl call
                set -o pipefail
                kubectl logs $FOLLOW_FLAG $POD --namespace $EnvId -c dbaccount 2> "$TMP_ERR" |
                    $JQ -R 'fromjson? | select(type == "object")' |
                    $JQ $COMPACT_FLAG "select((.logType != \"access\") and ( $(level_filter $LEVEL ${LEVELS[@]}) ))"
                RESULT=$?
                set +o pipefail
                if [ $RESULT -ne 0 ]; then
                    log_json ERROR "log_dbaccount: error getting logs" < "$TMP_ERR"
                else
                    SUCCESS=true
                fi
            else
                log_json ERROR "log_dbaccount: no pod available" < /dev/null
            fi
        fi
    else
        log_json ERROR "log-dbaccount: '$LEVEL' is not a valid log-level" < /dev/null
    fi
    rm -f "$TMP_ERR"
    [ "$SUCCESS" = 'true' ]
)

#-------------------------------------------------------------------------------
# get logs of config init container
# $1|2: [FATAL|ERROR|WARN|INFO|DEBUG|TRACE], defaults to WARN
# $1|2: [-f] if set, messages are printed in follow mode
# -> true|false indicating success
#-------------------------------------------------------------------------------
log-config() (
    SUCCESS=false
    FOLLOW=false
    LEVEL=WARN
    LEVELS=(FATAL ERROR WARN INFO DEBUG TRACE)

    # decide how to interpret arguments
    if [ "$1" = '-f' -a ! -z "$2" ]; then
        FOLLOW=true
        LEVEL="$2"
    elif [ "$1" = '-f' ]; then
        FOLLOW=true
    elif [ "$1" = '-f' ]; then
        FOLLOW=true
        LEVEL="$1"
    elif [ ! -z "$1" ]; then
        LEVEL="$1"
    fi   
    
    # check value of LEVEL
    if is_in_array "$(echo "$LEVEL" | tr '[a-z]' '[A-Z]')" ${LEVELS[@]}; then
        LEVEL=$(echo "$LEVEL" | tr '[a-z]' '[A-Z]')
        JQ="$(jq_get)"
        if [ -z "$JQ" ]; then
            log_json ERROR "log-config: jq not found" < /dev/null
        else
            if [ "$FOLLOW" = 'true' ]; then
                FOLLOW_FLAG='--tail=1 -f'
            else
                FOLLOW_FLAG=''
            fi
            
            # avoid formatting if output is written to pipe. This makes it much easier,
            # to process the results
            if [ -t 1 ]; then
                COMPACT_FLAG=''
            else
                COMPACT_FLAG='--compact-output'
            fi

            POD="$(kube_get_pod iom)"
            if [ ! -z "$POD" ]; then
                # make sure to get info about failed kubectl call
                set -o pipefail
                kubectl logs $FOLLOW_FLAG $POD --namespace $EnvId -c config 2> "$TMP_ERR" |
                    $JQ -R 'fromjson? | select(type == "object")' |
                    $JQ $COMPACT_FLAG "select((.logType != \"access\") and ( $(level_filter $LEVEL ${LEVELS[@]}) ))"
                RESULT=$?
                set +o pipefail
                if [ $RESULT -ne 0 ]; then
                    log_json ERROR "log-config: error getting logs" < "$TMP_ERR"
                else
                    SUCCESS=true
                fi
            else
                log_json ERROR "log-config: no pod available" < /dev/null
            fi
        fi
    else
        log_json ERROR "log-config: '$LEVEL' is not a valid log-level." < /dev/null
    fi
    rm -f "$TMP_ERR"
    [ "$SUCCESS" = 'true' ]
)

#-------------------------------------------------------------------------------
# get logs of IOM application container
# $1|2: [FATAL|ERROR|WARN|INFO|DEBUG|TRACE], defaults to WARN
# $1|2: [-f] if set, messages are printed in follow mode
# -> true|false indicating success
#-------------------------------------------------------------------------------
log-app() (
    SUCCESS=false
    FOLLOW=false
    LEVEL=WARN
    LEVELS=(FATAL ERROR WARN INFO DEBUG TRACE)

    # decide how to interpret arguments
    if [ "$1" = '-f' -a ! -z "$2" ]; then
        FOLLOW=true
        LEVEL="$2"
    elif [ "$1" = '-f' ]; then
        FOLLOW=true
    elif [ "$2" = '-f' ]; then
        FOLLOW=true
        LEVEL="$1"
    elif [ ! -z "$1" ]; then
        LEVEL="$1"
    fi
    
    # check value of LEVEL
    if is_in_array "$(echo "$LEVEL" | tr '[a-z]' '[A-Z]')" ${LEVELS[@]}; then
        LEVEL=$(echo "$LEVEL" | tr '[a-z]' '[A-Z]')
        JQ="$(jq_get)"
        if [ -z "$JQ" ]; then
            log_json ERROR "log-app: jq not found" < /dev/null
        else
            if [ "$FOLLOW" = 'true' ]; then
                FOLLOW_FLAG='--tail=1 -f'
            else
                FOLLOW_FLAG=''
            fi
            
            # avoid formatting if output is written to pipe. This makes it much easier,
            # to process the results
            if [ -t 1 ]; then
                COMPACT_FLAG=''
            else
                COMPACT_FLAG='--compact-output'
            fi
            
            POD="$(kube_get_pod iom)"
            if [ ! -z "$POD" ]; then
                # make sure to get info about failed kubectl call
                set -o pipefail
                kubectl logs $FOLLOW_FLAG $POD --namespace $EnvId -c iom 2> "$TMP_ERR" |
                    $JQ -R 'fromjson? | select(type == "object")' |
                    $JQ $COMPACT_FLAG "select((.logType != \"access\") and ( $(level_filter $LEVEL ${LEVELS[@]}) ))"
                RESULT=$?
                set +o pipefail
                if [ $RESULT -ne 0 ]; then
                    log_json ERROR "log-app: error getting logs" < "$TMP_ERR"
                else
                    SUCCESS=true
                fi
            else
                log_json ERROR "log-app: no pod available" < /dev/null
            fi
        fi
    else
        log_json ERROR "log-app: '$LEVEL' is not a valid log-level." < /dev/null
    fi
    rm -r "$TMP_ERR"
    [ "$SUCCESS" = 'true' ]
)

#-------------------------------------------------------------------------------
# get access logs of IOM application container
# $1|2: [ERROR|ALL], defaults to ERROR
# $1|2: [-f] if set, messages are printed in follow mode
# -> true|false indicating success
#-------------------------------------------------------------------------------
log-access() (
    SUCCESS=false
    FOLLOW=false
    LEVEL=ERROR
    LEVELS=(ERROR ALL)

    # decide how to interpret arguments
    if [ "$1" = '-f' -a ! -z "$2" ]; then
        FOLLOW=true
        LEVEL="$2"
    elif [ "$1" = '-f' ]; then
        FOLLOW=true
    elif [ "$2" = '-f' ]; then
        FOLLOW=true
        LEVEL="$1"
    elif [ ! -z "$1" ]; then
        LEVEL="$1"
    fi
    
    # check value of level
    if is_in_array "$(echo "$LEVEL" | tr '[a-z]' '[A-Z]')" ${LEVELS[@]}; then
        LEVEL=$(echo "$LEVEL" | tr '[a-z]' '[A-Z]')
        JQ="$(jq_get)"
        if [ -z "$JQ" ]; then
            log_json ERROR "log-app: jq not found" < /dev/null
        else
            if [ "$FOLLOW" = 'true' ]; then
                FOLLOW_FLAG='--tail=1 -f'
            else
                FOLLOW_FLAG=''
            fi
            
            if [ "$LEVEL" = 'ERROR' ]; then
                FILTER='and (.responseCode >= 400)'
            else
                FILTER=''
            fi
        
            # avoid formatting if output is written to pipe. This makes it much easier,
            # to process the results
            if [ -t 1 ]; then
                COMPACT_FLAG=''
            else
                COMPACT_FLAG='--compact-output'
            fi

            POD="$(kube_get_pod iom)"
            if [ ! -z "$POD" ]; then
                # make sure to get info about failed kubectl call
                set -o pipefail
                kubectl logs $FOLLOW_FLAG $POD --namespace $EnvId -c iom 2> "$TMP_ERR" |
                    $JQ -R 'fromjson? | select(type == "object")' |
                    $JQ $COMPACT_FLAG "select((.logType == \"access\") $FILTER)"
                RESULT=$?
                set +o pipefail
                if [ $RESULT -ne 0 ]; then
                    log_json ERROR "log_access: error getting logs" < "$TMP_ERR"
                else
                    SUCCESS=true
                fi
            else
                log_json ERROR "log-access: no pod available" < /dev/null
            fi
        fi
    else
        log_json ERROR "log-access: '$LEVEL' is not a valid log-level." < /dev/null
    fi
    rm -f "$TMP_ERR"
    [ "$SUCCESS" = 'true' ]
)

################################################################################
# read configuration
################################################################################

# TODO
# determine PROJECT_PATH
# determine CONFIG_FILE
# determine ENV_DIR to replace the template var. Later the according variable ENV_DIR should not be needed any longer and has to be eliminated!
# determine EnvId

# will be overwritten by CONFIG_FILE later
OMS_LOGLEVEL_DEVENV=ERROR

# if $1 is a file, it's assumed to be the config-file
if [ ! -z "$1" -a -f "$1" ]; then
    CONFIG_FILE="$1"
    shift
elif [ ! -z "$DEVENV4IOM_CONFIG" -a -f "$DEVENV4IOM_CONFIG" ]; then
    CONFIG_FILE="$DEVENV4IOM_CONFIG"
else
    log_json ERROR "No configuration file set." < /dev/null
    exit 1
fi

log_json INFO "Reading configuration from $CONFIG_FILE" < /dev/null

# read current config
if ! ( set -e; . "$CONFIG_FILE" ); then
    log_json ERROR "error reading '$CONFIG_FILE'" < /dev/null
    exit 1
fi
. "$CONFIG_FILE"


# TODO ENV_DIR has to be eliminated completely!
ENV_DIR=$(dirname "$CONFIG_FILE")

# TODO .. should not appear in PROJECT_PATH
# determine PROJECT_PATH
PROJECT_PATH="$(dirname $BASH_SOURCE)/.."

# get template variables
. $PROJECT_PATH/scripts/template-variables

################################################################################
# read command line arguments
################################################################################

# handle 1. level of command line arguments
LEVEL0=
case $1 in
    i*)
        LEVEL0=info
        ;;
    c*)
        LEVEL0=create
        ;;
    de*)
        LEVEL0=delete
        ;;
    w*)
        LEVEL0=wait
        ;;
    a*)
        LEVEL0=apply
        ;;
    du*)
        LEVEL0=dump
        ;;
    u*)
        LEVEL0=update
        ;;
    l*)
        LEVEL0=log
        ;;
    --help)
        help
        exit 0
        ;;
    -h)
        help
        exit 0
        ;;
    *)
        syntax_error
        exit 1
        ;;
esac

# handle next command line argument
shift

# handle 2. level of command line arguments
LEVEL1=
if [ "$LEVEL0" = "info" ]; then
    case $1 in
        i*)
            LEVEL1=iom
            ;;
        p*)
            LEVEL1=postgres
            ;;
        m*)
            LEVEL1=mailserver
            ;;
        s*)
            LEVEL1=storage
            ;;
        c*)
            LEVEL1=cluster
            ;;
        --help)
            help-info
            exit 1
            ;;
        -h)
            help-info
            exit 1
            ;;
        *)
            syntax_error info
            exit 1
            ;;
    esac
elif [ "$LEVEL0" = "create" ]; then
    case $1 in
        s*)
            LEVEL1=storage
            ;;
        n*)
            LEVEL1=namespace
            ;;
        m*)
            LEVEL1=mailserver
            ;;
        p*)
            LEVEL1=postgres
            ;;
        i*)
            LEVEL1=iom
            ;;
        c*)
            LEVEL1=cluster
            ;;
        --help)
            help-create
            exit 0
            ;;
        -h)
            help-create
            exit 0
            ;;
        *)
            syntax_error create
            exit 1
            ;;
    esac
elif [ "$LEVEL0" = "delete" ]; then
    case $1 in
        s*)
            LEVEL1=storage
            ;;
        n*)
            LEVEL1=namespace
            ;;
        m*)
            LEVEL1=mailserver
            ;;
        p*)
            LEVEL1=postgres
            ;;
        i*)
            LEVEL1=iom
            ;;
        c*)
            LEVEL1=cluster
            ;;
        --help)
            help-delete
            exit 1
            ;;
        -h)
            help-delete
            exit 1
            ;;
        *)
            syntax_error delete
            exit 1
            ;;
    esac
elif [ "$LEVEL0" = "wait" ]; then
    case $1 in
        m*)
            LEVEL1=mailserver
            ;;
        p*)
            LEVEL1=postgres
            ;;
        i*)
            LEVEL1=iom
            ;;
        --help)
            help-wait
            exit 0
            ;;
        -h)
            help-wait
            exit 0
            ;;
        *)
            syntax_error wait
            exit 1
            ;;
    esac
elif [ "$LEVEL0" = "apply" ]; then
    case $1 in
        de*)
            LEVEL1=deployment
            ;;
        m*)
            LEVEL1=mail-templates
            ;;
        x*)
            LEVEL1=xsl-templates
            ;;
        sql-s*)
            LEVEL1=sql-scripts
            ;;
        sql-c*)
            LEVEL1=sql-config
            ;;
        j*)
            LEVEL1=json-config
            ;;
        db*)
            LEVEL1=dbmigrate
            ;;
        --help)
            help-apply
            exit 0
            ;;
        -h)
            help-apply
            exit 0
            ;;
        *)
            syntax_error apply
            exit 1
            ;;
    esac
elif [ "$LEVEL0" = "dump" ]; then
    case $1 in
        c*)
            LEVEL1=create
            ;;
        l*)
            LEVEL1=load
            ;;
        --help)
            help-dump
            exit 0
            ;;
        -h)
            help-dump
            exit 0
            ;;
        *)
            syntax_error dump
            exit 1
            ;;
    esac
elif [ "$LEVEL0" = 'update' ]; then
    case $1 in
        co*)
            LEVEL1=config
            ;;
        d*)
            LEVEL1=doc
            ;;
        g*)
            LEVEL1=geb-props
            ;;
        w*)
            LEVEL1=ws-props
            ;;
        a*)
            LEVEL1=all
            ;;
        --help)
            help-update
            exit 0
            ;;
        -h)
            help-update
            exit 0
            ;;
        *)
            syntax_error update
            exit 1
            ;;
    esac
elif [ "$LEVEL0" = 'log' ]; then
    case $1 in
        d*)
            LEVEL1=dbaccount
            ;;
        c*)
            LEVEL1=config
            ;;
        ap*)
            LEVEL1=app
            ;;
        ac*)
            LEVEL1=access
            ;;
        --help)
            help-log
            exit 0
            ;;
        -h)
            help-log
            exit 0
            ;;
        *)
            syntax_error log
            exit 1
            ;;
    esac
fi

# handle next command line argument
shift

# handle --help|-h on detail level
# it's fully sufficient to find a -h or --help within remaining arguments
for ARG in "$@"; do
    case $ARG in
        --help*)
            eval help-$LEVEL0-$LEVEL1
            exit 0
            ;;
        -h*)
            eval help-$LEVEL0-$LEVEL1
            exit 0
            ;;
    esac
done

# get remaining arguments
ARG1=$1
ARG2=$2

################################################################################
# execute commands
################################################################################

# there is no command, accepting more than two arguments
if [ ! -z "$3" ]; then
    syntax_error $LEVEL0 $LEVEL1
    exit 1
fi

# handle command, requiring one argument
if [ "$LEVEL0" = 'apply' -a "$LEVEL1" = 'sql-scripts' ]; then
    if [ -z "$ARG1" ]; then
        syntax_error $LEVEL0 $LEVEL1
        exit 1
    fi
    eval $LEVEL0-$LEVEL1 "$ARG1" "$ARG2" || exit 1

# handle commands, accepting one argument
elif [    \( "$LEVEL0" = 'apply' -a "$LEVEL1" = 'sql-config'  \) -o \
          \( "$LEVEL0" = 'apply' -a "$LEVEL1" = 'json-config' \) -o \
          \( "$LEVEL0" = 'apply' -a "$LEVEL1" = 'dbmigrate'   \) -o \
          \( "$LEVEL0" = 'apply' -a "$LEVEL1" = 'deployment'  \) -o \
          \( "$LEVEL0" = 'wait'                               \) -o \
          \( "$LEVEL0" = 'dump'  -a "$LEVEL1" = 'create'      \) ]; then
    if [ ! -z "$ARG2" ]; then
        syntax_error $LEVEL0 $LEVEL1
        exit 1
    fi
    eval $LEVEL0-$LEVEL1 "$ARG1" || exit 1


# handle commands, accepting two arguments
elif [ "$LEVEL0" = 'log' ]; then
    eval $LEVEL0-$LEVEL1 "$ARG1" "$ARG2" || exit 1
    
# handle commands, not accepting any argument
else
    if [ ! -z "$ARG1" ]; then
        syntax_error $LEVEL0 $LEVEL1
        exit 1
    fi
    eval $LEVEL0-$LEVEL1 || exit 1
fi
