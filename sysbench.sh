#!/bin/bash
if [[ "$1" == "-h" ]]; then
  echo "Usage: `basename $0` [options]"
  echo "Options:"
  echo "  --cleanup   cleanup sysbench"
  echo "  --prepare   prepare sysbench"
  echo "  --run       run sysbench"
  exit 0
fi






# ------------------------------------------------------------------------------
# User, DB
USER=sbtest
PASSWORD=sbtest
DATABASE=sbtest

# Connection
HOST=localhost
PORT=5678

# Size of data
TABLE_SIZE=10000
TABLES=1

# Secondary index
CREATE_SECONDARY=false

# Running config
THREADS=1
TIME=60
REPORT_INTERVAL=1
RAND_TYPE=uniform

# Running type
LUA="oltp_read_write.lua"
# ------------------------------------------------------------------------------
























































# Parse parameters
for i in "$@"
do
  case $i in
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

echo "CLEANUP = ${CLEANUP}"
echo "PREPARE = ${PREPARE}"
echo "RUN     = ${RUN}"

# Cleanup Sysbench
if [[ "${CLEANUP}" == "YES" ]]
then
    sysbench \
      --db-driver=pgsql \
      --pgsql-user=${USER} \
      --pgsql-host=${HOST} \
      --pgsql-port=${PORT} \
      --pgsql-db=${DATABASE} \
      --table-size=${TABLE_SIZE} \
      --tables=${TABLES} \
      --time=${TIME} \
      --threads=${THREADS} \
      --report-interval=${REPORT_INTERVAL} \
      --create-secondary=${CREATE_SECONDARY} \
      --rand-type=${RAND_TYPE} \
      "/usr/share/sysbench/${LUA}" \
      cleanup
fi

# Prepare Sysbench
if [[ "${PREPARE}" == "YES" ]]
then
    sysbench \
      --db-driver=pgsql \
      --pgsql-user=${USER} \
      --pgsql-host=${HOST} \
      --pgsql-port=${PORT} \
      --pgsql-db=${DATABASE} \
      --table-size=${TABLE_SIZE} \
      --tables=${TABLES} \
      --time=${TIME} \
      --threads=${THREADS} \
      --report-interval=${REPORT_INTERVAL} \
      --create-secondary=${CREATE_SECONDARY} \
      --rand-type=${RAND_TYPE} \
      "/usr/share/sysbench/${LUA}" \
      prepare
fi

# Run Sysbench
if [[ "${RUN}" == "YES" ]]
then
    sysbench \
      --db-driver=pgsql \
      --pgsql-user=${USER} \
      --pgsql-host=${HOST} \
      --pgsql-port=${PORT} \
      --pgsql-db=${DATABASE} \
      --table-size=${TABLE_SIZE} \
      --tables=${TABLES} \
      --time=${TIME} \
      --threads=${THREADS} \
      --report-interval=${REPORT_INTERVAL} \
      --create-secondary=${CREATE_SECONDARY} \
      --rand-type=${RAND_TYPE} \
      "/usr/share/sysbench/${LUA}" \
      run
fi
