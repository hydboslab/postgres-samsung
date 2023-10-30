#!/bin/bash

# Usage: source ./CH.sh

PGCONFIG=$(pwd)/pgsql/bin/pg_config

if [ ! -d ../pg_hint_plan ]; then
    cd ..

    git clone https://github.com/ossc-db/pg_hint_plan.git
    
    cd pg_hint_plan

    make PG_CONFIG=${PGCONFIG}
    make PG_CONFIG=${PGCONFIG} install

    cd ../postgres-samsung

    sed -i "/shared_preload_libraries/ c\shared_preload_libraries = 'pg_hint_plan'	# (change requires restart)" ./config/postgresql.conf
    sed -i "/shared_preload_libraries/ c\shared_preload_libraries = 'pg_hint_plan'	# (change requires restart)" ./data/postgresql.conf
fi