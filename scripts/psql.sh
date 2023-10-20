#!/bin/bash

# Parse parameters
for i in "$@"
do
  case $i in
    --bin-dir=*)
      BIN_DIR="${i#*=}"
      shift
      ;;

    --user=*)
      USER="${i#*=}"
      shift
      ;;

    --port=*)
      PORT="${i#*=}"
      shift
      ;;

    --database=*)
      DATABASE="${i#*=}"
      shift
      ;;

    *)
      # unknown option
      ;;
  esac
done

# Connect Client
${BIN_DIR}/psql -p ${PORT} -d ${DATABASE} -U ${USER}
