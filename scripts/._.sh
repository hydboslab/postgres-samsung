#!/bin/bash

# Usage: ./set_options.sh

# ------------------------------------------------------------------------------
# build & run
WAREHOUSE=2

# Workers
OLTP_WORKER=4
OLAP_WORKER=2

# Runtime & rampup time (minutes)
DURATION=1
RAMPUP=0
# ------------------------------------------------------------------------------






















































CPUCORE=$(grep -c processor /proc/cpuinfo)

# TPC-C: OLTP workload
# TPC-H: OLAP workload

# build.tcl
#
# diset tpcc pg_num_vu #:
# - Set the number of virtual users building the data set to #
#
# diset tpcc pg_count_ware #:
# - Set the number of warehouse to #
#
sed -i "/pg_num_vu/ c\diset tpcc pg_num_vu $(($WAREHOUSE<=$CPUCORE?$WAREHOUSE:$CPUCORE))" ./build.tcl
sed -i "/pg_count_ware/ c\diset tpcc pg_count_ware ${WAREHOUSE}" ./build.tcl

# run.sh (OLAP)
#
# CH_THREAD_COUNT=${CH_THREAD_COUNT:-#}:
# - Set the number of virtual users running TPC-H to #
#
# RAMPUP_TIME=${RAMPUP_TIME:-#}:
# - Set the rampup time of TPC-H to # minutes
#
# DEFAULT_CH_RUNTIME_IN_SECS=${DEFAULT_CH_RUNTIME_IN_SECS:-#}:
# - Set the run time of TPC-H to # seconds
#
sed -i "/CH_THREAD_COUNT=/ c\CH_THREAD_COUNT=\${CH_THREAD_COUNT:-${OLAP_WORKER}}" ./run.sh
sed -i "/RAMPUP_TIME=/ c\RAMPUP_TIME=\${RAMPUP_TIME:-${RAMPUP}}" ./run.sh
sed -i "/DEFAULT_CH_RUNTIME_IN_SECS=/ c\DEFAULT_CH_RUNTIME_IN_SECS=\${DEFAULT_CH_RUNTIME_IN_SECS:-$(($DURATION * 60))}" ./run.sh

# run.tcl (OLTP)
#
# diset tpcc pg_count_ware #:
# - Set the number of warehouse
#
# diset tpcc pg_rampup #:
# - Set the rampup time of TPC-C to # minutes
#
# diset tpcc pg_duration #:
# - Set the run time of TPC-C to # minutes
#
# vuset vu #:
# - Set the number of virtual users running TPC-C to #
#
sed -i "/pg_count_ware/ c\diset tpcc pg_count_ware ${WAREHOUSE}" ./run.tcl
sed -i "/pg_rampup/ c\diset tpcc pg_rampup ${RAMPUP}" ./run.tcl
sed -i "/pg_duration/ c\diset tpcc pg_duration ${DURATION}" ./run.tcl
sed -i "/vuset vu/ c\vuset vu ${OLTP_WORKER}" ./run.tcl