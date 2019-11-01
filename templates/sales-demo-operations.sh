#!/bin/bash

usage() {
    ME=$(basename $0)
    cat <<EOF
$ME
    controls IOM installation with ID ${ID}.

SYNOPSIS
    $ME start|stop|free-storage
EOF
}

start_iom() {
    echo "create namespace"
    kubectl create namespace ${EnvId} || exit 1

    echo "start mail server"
    "${PROJECT_PATH}/scripts/template_engine.sh" "${PROJECT_PATH}/templates/mailhog.yml.template" "${ENV_DIR}/${CONFIG_FILE}" | kubectl apply --namespace ${EnvId} -f - || exit 1

    echo "create local Docker volume"
    docker volume create --name=${EnvId}-pgdata -d local || exit 1

    echo "link Docker volume to database storage"
    MOUNTPOINT="\"$(docker volume inspect --format='{{.Mountpoint}}' ${EnvId}-pgdata)\"" "${PROJECT_PATH}/scripts/template_engine.sh" "${PROJECT_PATH}/templates/postgres-storage.yml.template" "${ENV_DIR}/${CONFIG_FILE}" | kubectl apply --namespace ${EnvId} -f - || exit 1

    echo "start postgres database"
    "${PROJECT_PATH}/scripts/template_engine.sh" "${PROJECT_PATH}/templates/postgres.yml.template" "${ENV_DIR}/${CONFIG_FILE}" | kubectl apply --namespace ${EnvId} -f - || exit 1

    echo "start IOM"
    "${PROJECT_PATH}/scripts/template_engine.sh" "${PROJECT_PATH}/templates/iom.yml.template" "${ENV_DIR}/${CONFIG_FILE}" | kubectl apply --namespace ${EnvId} -f - || exit 1
}
    
case $1 in
    start)
        start_iom
        ;;
    stop)
        stop_iom
        ;;
    free-storage)
        free_storage
        ;;
    *)
        usage 1>&2
        exit 1
    ;;
esac

