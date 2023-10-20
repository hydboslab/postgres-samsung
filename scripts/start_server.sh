#!/bin/bash

# Parse parameters
for i in "$@"
do
  case $i in
    --bin-dir=*)
      BIN_DIR="${i#*=}"
      shift
      ;;

    --data-dir=*)
      DATA_DIR="${i#*=}"
      shift
      ;;

    --logfile=*)
      LOGFILE="${i#*=}"
      shift
      ;;

    *)
      # unknown option
      ;;
  esac
done

rm $LOGFILE

# Server start
${BIN_DIR}/pg_ctl -D ${DATA_DIR} -l ${LOGFILE} start

