#!/bin/bash

# Parse parameters
for i in "$@"
do
  case $i in
    --base-dir=*)
      BASE_DIR="${i#*=}"
      shift
      ;;

    --src-dir=*)
      SRC_DIR="${i#*=}"
      shift
      ;;

    --install-dir=*)
      INSTALL_DIR="${i#*=}"
      shift
      ;;

    --compile-option=*)
      COMPILE_OPTION="${i#*=}"
      shift
      ;;

    --configure)
      CONFIGURE=YES
      shift
      ;;

    --gdb)
      GDB=YES
      shift
      ;;

    *)
      # unknown option
      ;;
  esac
done
# GDB
if [ "${GDB}"=="YES" ]
then
  COMPILE_OPTION="${COMPILE_OPTION} -ggdb -Og -g3 -fno-omit-frame-pointer"
fi

# Postgres source directory
cd ${SRC_DIR}

# Cleanup
make clean -j2 -s

# Configure
if [ ${CONFIGURE}==YES ]
then
  ./configure --silent --prefix=${INSTALL_DIR} --enable-cassert --enable-debug CFLAGS="${COMPILE_OPTION}"
fi

# Build & Install
make -j2 -s
make install -j2 -s

