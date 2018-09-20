#!/bin/bash

ME=$(basename $0)

usage() {
    cat <<EOF
$ME
    Initializes the database with a given dump file.

SYNOPSIS
    $ME [-SP <PG superuser password>] [-SU <PG superuser>] [-UP <user password>] [-U <user>] [-h <host>] [-p <port>] [-d <database>] [-f <dump file>] [-L <logdirectory>] [-o <options>] [-v <verbose>] [-?]

    All options have default values.

DESCRIPTION
    This script can be used to initialize the database with a given dump file.

    Other options:

    -?
      Display this help and exit.

OPTIONS DEFAULT VALUES

    SP <PG superuser password>  \$PGPASSWORD (postgres default) | \$POSTGRES_PASSWORD (docker default) | postgres

    SU <PG superuser>           \$PG_SUPERUSER | \$POSTGRES_USER (docker default) | postgres

    UP <user password>          \$PG_USER_PASSWD | OmsDB

    U <user>                    \$PG_USER | oms_user

    h <host>                    \$PG_HOST | localhost

    p <port>                    \$PG_PORT | 5432

    d <database>                \$PG_DATABASE | oms_db

    f <dump file>               \$PG_DUMP_FILE | OmsDB.initial.<latest>.sql.gz

    L <logdirectory>            \$PG_LOGDIR | .

    o <options>                 \$PG_OPTIONS | ENCODING='UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8' CONNECTION LIMIT=-1

    v <verbose>

EXAMPLES

    ${ME} -SP mysecretpassword -SU postgres -U oms_user -h 10.0 10.01 -d oms_db

EOF
}

# default configurations

# to use this the initialization script with official postgres docker image,
# the default environment are uses as defaults

CONFIG_SUPERUSER="${PG_SUPERUSER:-$POSTGRES_USER}"
CONFIG_SUPERUSER="${CONFIG_SUPERUSER:-postgres}"
CONFIG_SUPERUSER_PASSWD="${PGPASSWORD:-$POSTGRES_PASSWORD}"
CONFIG_SUPERUSER_PASSWD="${CONFIG_SUPERUSER_PASSWD:-postgres}"
CONFIG_USER="${PG_USER:-oms_user}"
CONFIG_USER_PASSWD="${PG_USER_PASSWD:-OmsDB}"
CONFIG_HOST="${PG_HOST:-localhost}"
CONFIG_PORT="${PG_PORT:-5432}"
CONFIG_DATABASE="${PG_DATABASE:-oms_db}"
CONFIG_LOGDIR="${PG_LOGDIR:-.}"
CONFIG_DUMP_FILE="${PG_DUMP_FILE:-$( ls /tmp/src/postgres/dumps/OmsDB.initial.*.sql.gz 2> /dev/null | sort -r | head -n 1)}"
CONFIG_OPTIONS="${PG_OPTIONS:-ENCODING='UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8' CONNECTION LIMIT=-1}"
CONFIG_VERBOSE=

# check the command line

while [ -n "$1" ]; do
   case "$1" in
        '-?')
            usage
            exit 0
            ;;
        '?')
            usage
            exit 0
            ;;
        -SU)
            CONFIG_SUPERUSER=$2
            shift
            ;;
        -U)
            CONFIG_USER=$2
            shift
            ;;
        -h)
            CONFIG_HOST=$2
            shift
            ;;
        -p)
            CONFIG_PORT=$2
            shift
            ;;
        -d)
            CONFIG_DATABASE=$2
            shift
            ;;
        -f)
            CONFIG_DUMP_FILE=$2
            shift
            ;;
        -L)
            CONFIG_LOGDIR=$2
            shift
            ;;
        -o)
            CONFIG_OPTIONS=$2
            shift
            ;;
        -v)
            CONFIG_VERBOSE=1
            shift
            ;;
        -*)
            echo "$ME: invalid option: $1" >&2
            exit 1
            ;;
        *)
            {
              echo "$ME: unexpected argument: $1" >&2
              exit 1
            }
            ;;
   esac
   shift
done

# use redirections for the verbose mode

if [ "$CONFIG_VERBOSE" = 1 ]; then
    exec 4>&2 3>&1
else
    exec 4>/dev/null 3>/dev/null
fi


CONFIG_LOGFILE=$CONFIG_LOGDIR/$ME-$(date +%Y%m%d_%H%M).log

echo 1>&3
echo "CONFIG" 1>&3
echo 1>&3
echo "CONFIG_SUPERUSER_PASSWD: $CONFIG_SUPERUSER_PASSWD" 1>&3
echo "CONFIG_USER:             $CONFIG_USER" 1>&3
echo "CONFIG_USER_PASSWD:      $CONFIG_USER_PASSWD" 1>&3
echo "CONFIG_HOST:             $CONFIG_HOST" 1>&3
echo "CONFIG_PORT:             $CONFIG_PORT" 1>&3
echo "CONFIG_DATABASE:         $CONFIG_DATABASE" 1>&3
echo "CONFIG_LOGDIR:           $CONFIG_LOGDIR" 1>&3
echo "CONFIG_LOGFILE:          $CONFIG_LOGFILE" 1>&3
echo "CONFIG_DUMP_FILE:        $CONFIG_DUMP_FILE" 1>&3
echo "CONFIG_OPTIONS:          $CONFIG_OPTIONS" 1>&3
echo 1>&3

# try to create the log dir
mkdir -p $CONFIG_LOGDIR || {
   echo "Cannot create log directory $CONFIG_LOGDIR (you can choose another location with the -L option)" 1>&2
   exit 1
}

# try to create the log file
echo '' > $CONFIG_LOGFILE || {
   echo "Cannot create log file $CONFIG_LOGFILE (you can choose another location with the -L option)" 1>&2
   exit 1
}

# check that a postgres connection could be established

SUPERUSER_PSQL="psql -X -v ON_ERROR_STOP=1 -h $CONFIG_HOST -p $CONFIG_PORT -U $CONFIG_SUPERUSER -d postgres"
USER_PSQL="psql -X -v ON_ERROR_STOP=1 -h $CONFIG_HOST -p $CONFIG_PORT -U $CONFIG_USER -d $CONFIG_DATABASE"

CHECK_CONNECTION=`PGPASSWORD=$CONFIG_SUPERUSER_PASSWD $SUPERUSER_PSQL -P format=u -tqX -c "SELECT 'ok';"` || {
  echo "Cannot establish a connection to $CONFIG_HOST:$CONFIG_PORT $CONFIG_DATABASE as user $CONFIG_SUPERUSER" 1>&2
  exit 1;
}

# check that the datbase does not already exist

CHECK_USER_EXISTS=`PGPASSWORD=$CONFIG_SUPERUSER_PASSWD $SUPERUSER_PSQL -P format=u -tqX -c "SELECT COUNT(*) FROM pg_database WHERE datname = '$CONFIG_DATABASE';"`

if  [ _$CHECK_USER_EXISTS = _1 ]; then
  echo "Database '$CONFIG_DATABASE' already exists." 1>&2
  exit 1;
fi

# check that the user does not already exist

CHECK_USER_EXISTS=`PGPASSWORD=$CONFIG_SUPERUSER_PASSWD $SUPERUSER_PSQL -P format=u -tqX -c "SELECT COUNT(*) FROM pg_roles WHERE rolname = '$CONFIG_USER';"`

if  [ _$CHECK_USER_EXISTS = _1 ]; then
  echo "User '$CONFIG_USER' already exists." 1>&2
  exit 1;
fi

# check that the given dump file exists

if [ ! -z "$CONFIG_DUMP_FILE" -a ! -f "$CONFIG_DUMP_FILE" ]; then
    echo "Configured dump file '$CONFIG_DUMP_FILE' does not exist." 1>&2
    exit 1
fi

# creates the user and the database

echo 1>&3
echo "Create user and database" 1>&3
echo 1>&3

PGPASSWORD=$CONFIG_SUPERUSER_PASSWD $SUPERUSER_PSQL -L $CONFIG_LOGFILE 1>&3 <<-EOSQL
    -- create user
    CREATE ROLE "$CONFIG_USER" LOGIN PASSWORD '$CONFIG_USER_PASSWD' SUPERUSER INHERIT CREATEDB CREATEROLE NOREPLICATION;

    -- create database
    CREATE DATABASE "$CONFIG_DATABASE" WITH OWNER = "$CONFIG_USER" $CONFIG_OPTIONS;

    -- set the search path
    ALTER DATABASE "$CONFIG_DATABASE" SET search_path = oms, customer, omt, product, system, testcases, bizconf, public, "\$user"
EOSQL

# import the given database dump

if [ ! -z "$CONFIG_DUMP_FILE" ]; then
    echo 1>&3
    echo "import database dump" 1>&3
    echo 1>&3
    gunzip -c $CONFIG_DUMP_FILE | PGPASSWORD=$CONFIG_USER_PASSWD $USER_PSQL -L $CONFIG_LOGFILE 1>&3
fi
