#!/bin/bash
if [[ "$1" == "-h" ]]; then
  echo "Usage: `basename $0` [options]"
  echo "Options:"
  echo "  --help      print help"
  echo "  --install   install sysbench from source"
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

# Test config
THREADS=1
TIME=60
REPORT_INTERVAL=1
RAND_TYPE=uniform
RAND_ZIPFIAN_EXP=0.8 # only for RAND_TYPE=zipfian

# Test type
LUA="oltp_read_write.lua"
# ------------------------------------------------------------------------------
























































# Parse parameters
for i in "$@"
do
  case $i in
    --help)
      HELP=YES
      shift
      ;;

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

echo "HELP    = ${HELP}"
echo "INSTALL = ${INSTALL}"
echo "CLEANUP = ${CLEANUP}"
echo "PREPARE = ${PREPARE}"
echo "RUN     = ${RUN}"

CURR_DIR=$(pwd)

cd ./sysbench

# Print help
if [[ "${HELP}" == "YES" ]]
then
    ./src/sysbench --help
fi

# Install Sysbench
if [[ "${INSTALL}" == "YES" ]]
then
    make clean -j --silent
    ./autogen.sh
    ./configure --without-mysql --with-pgsql --silent
    make -j --silent
fi

# Cleanup Sysbench
if [[ "${CLEANUP}" == "YES" ]]
then
    ./src/sysbench \
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
      --rand-zipfian-exp=${RAND_ZIPFIAN_EXP} \
      "./src/lua/${LUA}" \
      cleanup
fi

# Prepare Sysbench
if [[ "${PREPARE}" == "YES" ]]
then
    ./src/sysbench \
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
      --rand-zipfian-exp=${RAND_ZIPFIAN_EXP} \
      "./src/lua/${LUA}" \
      prepare
fi

# Run Sysbench
if [[ "${RUN}" == "YES" ]]
then
    ./src/sysbench \
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
      --rand-zipfian-exp=${RAND_ZIPFIAN_EXP} \
      "./src/lua/${LUA}" \
      run
fi