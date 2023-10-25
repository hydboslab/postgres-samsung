#!/bin/bash

# Parse parameters
for i in "$@"
do
  case $i in
    --sysbench-base-dir=*)
      SYSBENCH_BASE_DIR="${i#*=}"
      shift
      ;;

    *)
      # unknown option
      ;;
  esac
done

cd ${SYSBENCH_BASE_DIR}

sudo apt-get install -y autoconf libtool libpq-dev

make clean -j4 --silent

./autogen.sh
./configure --without-mysql --with-pgsql --silent
make -j4 --silent

