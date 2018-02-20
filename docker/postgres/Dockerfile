ARG DOCKER_DB_IMAGE=postgres:latest

FROM $DOCKER_DB_IMAGE

# the dbmigrate.sh script uses OMS_HOME in "dir <path>" default option
# OMS_HOME should point to the docker volume mount point of the docker-compose.template
ENV OMS_HOME=/tmp/src

ADD dbinit.sh /usr/local/bin/
