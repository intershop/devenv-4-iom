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

start_iom() {
    kubectl create namespace ${EnvId}
}
    
