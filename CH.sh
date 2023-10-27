#!/bin/bash

# Usage: source ./CH.sh

USER=$(whoami)
PSQL=$(pwd)/pgsql/bin/psql

if [ ! -d ../citus-benchmark ]; then
    cd ..

    sudo apt-get -y install wget
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
    sudo apt-get -y update

    git clone https://github.com/citusdata/citus-benchmark.git

    cd citus-benchmark

    # build.sh
    # Add the path to the psql executable to the psql command
    sed -i "s_psql_${PSQL}_g" ./build.sh

    # parse-arguments.sh
    # Modify default values for environment variables
    sed -i "131s/.*/export PGPORT=\${PGPORT:-5678}/g" ./parse-arguments.sh
    sed -i "132s/.*/export PGUSER=\${PGUSER:-${USER}}/g" ./parse-arguments.sh
    sed -i "133s/.*/export PGDATABASE=\${PGDATABASE:-chbenchmark}/g" ./parse-arguments.sh
    sed -i "134,137s/^/# /" ./parse-arguments.sh
    sed -i "138s/.*/export PGPASSWORD=\${PGPASSWORD:-${USER}}/g" ./parse-arguments.sh

    # run.sh
    # Add the path to the psql executable to the psql command
    sed -i "s_psql_${PSQL}_g" ./run.sh

    # ch_benchmark.py
    # Add the path to the psql executable to the psql command
    sed -i "s_psql_${PSQL}_g" ./ch_benchmark.py

    cd ../postgres-samsung
fi

cp ./scripts/._.sh ../citus-benchmark/set_options.sh