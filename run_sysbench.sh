#!/bin/bash
if [[ "$1" == "-h" ]]; then
  echo "Usage: `basename $0` [options]"
  echo "Options:"
  echo "  --install   install sysbench from source"
  echo "  --cleanup   cleanup sysbench"
  echo "  --prepare   prepare sysbench"
  echo "  --run       run sysbench"
  exit 0
fi

# Directories
BASE_DIR=$(pwd)

SCRIPT_DIR="${BASE_DIR}/scripts"

SYSBENCH_DIR="${BASE_DIR}/sysbench"

# Scripts
INSTALL_SCRIPT="${SCRIPT_DIR}/install_sysbench.sh"
SYSBENCH_SCRIPT="${SCRIPT_DIR}/sysbench.sh"

# DB Config
USER=$(whoami)
DATABASE=${USER}
PORT=5678 # If you change the port, you must change the postgresql.conf file in config directory

TABLE_SIZE=100000
TABLES=12
TIME=3600
THREADS=12
REPORT_INTERVAL=1
SECONDARY=off
CREATE_SECONDARY=false
WARMUP_TIME=0
RAND_TYPE=zipfian
RAND_ZIPFIAN_EXP=0.0
LUA="${SYSBENCH_DIR}/src/lua/oltp_update_non_index.lua"

# Parse parameters
for i in "$@"
do
  case $i in
    --install)
      INSTALL=YES
      shift
      ;;

    --cleanup)
      CLEANUP=YES
      shift
      ;;

    --prepare)
      PREPARE=YES
      shift
      ;;

    --run)
      RUN=YES
      shift
      ;;

    *)
      # unknown option
      ;;
  esac
done

echo "INSTALL = ${INSTALL}"
echo "CLEANUP = ${CLEANUP}"
echo "PREPARE = ${PREPARE}"
echo "RUN     = ${RUN}"

# Install Sysbench
if [[ "${INSTALL}" == "YES" ]]
then
    ${INSTALL_SCRIPT} \
      --sysbench-base-dir=${SYSBENCH_DIR}
fi

# Cleanup Sysbench
if [[ "${CLEANUP}" == "YES" ]]
then
    ${SYSBENCH_SCRIPT} \
      --sysbench-dir=${SYSBENCH_DIR} \
      --pgsql-user=${USER} \
      --pgsql-host=localhost \
      --pgsql-port=${PORT} \
      --pgsql-db=${DATABASE} \
      --table-size=${TABLE_SIZE} \
      --tables=${TABLES} \
      --time=${TIME} \
      --threads=${THREADS} \
      --report-interval=${REPORT_INTERVAL} \
      --secondary=${SECONDARY} \
      --create-secondary=${CREATE_SECONDARY} \
      --warmup-time=${WARMUP_TIME} \
      --rand-type=${RAND_TYPE} \
      --rand-zipfian-exp=${RAND_ZIPFIAN_EXP} \
      --lua=${LUA} \
      --mode=cleanup
fi

# Prepare Sysbench
if [[ "${PREPARE}" == "YES" ]]
then
    ${SYSBENCH_SCRIPT} \
      --sysbench-dir=${SYSBENCH_DIR} \
      --pgsql-user=${USER} \
      --pgsql-host=localhost \
      --pgsql-port=${PORT} \
      --pgsql-db=${DATABASE} \
      --table-size=${TABLE_SIZE} \
      --tables=${TABLES} \
      --time=${TIME} \
      --threads=${THREADS} \
      --report-interval=${REPORT_INTERVAL} \
      --secondary=${SECONDARY} \
      --create-secondary=${CREATE_SECONDARY} \
      --warmup-time=${WARMUP_TIME} \
      --rand-type=${RAND_TYPE} \
      --rand-zipfian-exp=${RAND_ZIPFIAN_EXP} \
      --lua=${LUA} \
      --mode=prepare
fi

# Run Sysbench
if [[ "${RUN}" == "YES" ]]
then
    ${SYSBENCH_SCRIPT} \
      --sysbench-dir=${SYSBENCH_DIR} \
      --pgsql-user=${USER} \
      --pgsql-host=localhost \
      --pgsql-port=${PORT} \
      --pgsql-db=${DATABASE} \
      --table-size=${TABLE_SIZE} \
      --tables=${TABLES} \
      --time=${TIME} \
      --threads=${THREADS} \
      --report-interval=${REPORT_INTERVAL} \
      --secondary=${SECONDARY} \
      --create-secondary=${CREATE_SECONDARY} \
      --warmup-time=${WARMUP_TIME} \
      --rand-type=${RAND_TYPE} \
      --rand-zipfian-exp=${RAND_ZIPFIAN_EXP} \
      --lua=${LUA} \
      --mode=run
fi
