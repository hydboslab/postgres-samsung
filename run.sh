#!/bin/bash
if [[ "$1" == "-h" ]]; then
  echo "Usage: `basename $0` [options]"
  echo "Options:"
  echo "  --install           compile and install postgres source"
  echo "  --initdb            initialize database using initdb command"
  echo "  --start             start the main server process"
  echo "  --createdb          create a new user $(whoami), and create a database $(whoami) owned by user $(whoami)"
  echo "  --stop              terminate the main server process"
  echo "  --install-sysbench  install sysbench from source"
  exit 0
fi

# Directories
BASE_DIR=$(pwd)

SCRIPT_DIR="${BASE_DIR}/scripts"

SRC_DIR="${BASE_DIR}/postgres"

INSTALL_DIR="${BASE_DIR}/pgsql"
BIN_DIR="${INSTALL_DIR}/bin"
LIB_DIR="${INSTALL_DIR}/lib"

DATA_DIR="${BASE_DIR}/data"

CONFIG_DIR="${BASE_DIR}/config"

SYSBENCH_DIR="${BASE_DIR}/sysbench"

# Scripts
INSTALL_SCRIPT="${SCRIPT_DIR}/install.sh"
INIT_SERVER_SCRIPT="${SCRIPT_DIR}/init_server.sh"
START_SERVER_SCRIPT="${SCRIPT_DIR}/start_server.sh"
CREATE_DB_SCRIPT="${SCRIPT_DIR}/create_db.sh"
STOP_SERVER_SCRIPT="${SCRIPT_DIR}/stop_server.sh"
INSTALL_SYSBENCH_SCRIPT="${SCRIPT_DIR}/install_sysbench.sh"
PSQL_SCRIPT="${SCRIPT_DIR}/psql.sh"

LOGFILE="${BASE_DIR}/logfile"
CONFIGFILE="${CONFIG_DIR}/postgresql.conf"
CREATE_DB_SQL="${SCRIPT_DIR}/sql/create_db.sql"

# DB Config
USER=$(whoami)
DATABASE=${USER}
PORT=5678 # If you change the port, you must change the postgresql.conf file in config directory

# Parse parameters
for i in "$@"
do
  case $i in
    --install)
      INSTALL=YES
      shift
      ;;

    --initdb)
      INITDB=YES
      shift
      ;;

    --start)
      START=YES
      shift
      ;;

    --createdb)
      CREATEDB=YES
      shift
      ;;

    --stop)
      STOP=YES
      shift
      ;;

    --install-sysbench)
      INSTALL_SYSBENCH=YES
      shift
      ;;

    --psql)
      PSQL=YES
      shift
      ;;

    *)
      # unknown option
      ;;
  esac
done

echo "INSTALL           = ${INSTALL}"
echo "INITDB            = ${INITDB}"
echo "START             = ${START}"
echo "CREATEDB          = ${CREATEDB}"
echo "STOP              = ${STOP}"
echo "INSTALL_SYSBENCH  = ${INSTALL_SYSBENCH}"

# Install Postgres
if [[ "${INSTALL}" == "YES" ]]
then
    ${INSTALL_SCRIPT} \
      --base-dir=${BASE_DIR} \
      --src-dir=${SRC_DIR} \
      --install-dir=${INSTALL_DIR} \
      --compile-option="" \
      --configure
fi

# Init Server
if [[ "${INITDB}" == "YES" ]]
then
    ${INIT_SERVER_SCRIPT} \
      --bin-dir=${BIN_DIR} \
      --lib-dir=${LIB_DIR} \
      --data-dir=${DATA_DIR} \
      --configfile=${CONFIGFILE}
fi

# Start Server
if [[ "${START}" == "YES" ]]
then
    ${START_SERVER_SCRIPT} \
      --bin-dir=${BIN_DIR} \
      --data-dir=${DATA_DIR} \
      --logfile=${LOGFILE}
fi

# Create User & Database
if [[ "${CREATEDB}" == "YES" ]]
then
    ${CREATE_DB_SCRIPT} \
      --bin-dir=${BIN_DIR} \
      --user=${USER} \
      --port=${PORT} \
      --file=${CREATE_DB_SQL} \
      --database=${DATABASE}
fi

# Stop Server
if [[ "${STOP}" == "YES" ]]
then
    ${STOP_SERVER_SCRIPT} \
      --bin-dir=${BIN_DIR} \
      --data-dir=${DATA_DIR}
fi

# Install Sysbench
if [[ "${INSTALL_SYSBENCH}" == "YES" ]]
then
    ${INSTALL_SYSBENCH_SCRIPT} \
      --sysbench-base-dir=${SYSBENCH_DIR}
fi

# Run Client
if [[ "${PSQL}" == "YES" ]]
then
    ${PSQL_SCRIPT} \
      --bin-dir=${BIN_DIR} \
      --port=${PORT} \
      --user=${USER} \
      --database=${DATABASE}
fi
