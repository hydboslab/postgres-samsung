#!/bin/bash

cd ../

git clone https://github.com/cmu-db/noisepage.git

cd noisepage
sudo ./script/installation/packages.sh

mkdir build
cd build

cmake -GNinja \
-DCMAKE_BUILD_TYPE=Release \
-DNOISEPAGE_USE_JEMALLOC=ON \
-DNOISEPAGE_UNITY_BUILD=ON \
-DNOISEPAGE_BUILD_BENCHMARKS=ON \
-DNOISEPAGE_BUILD_TESTS=ON \
-DNOISEPAGE_UNITTEST_OUTPUT_ON_FAILURE=ON ..

cd ../../postgres-samsung

# commands:
# ninja noisepage
# ./bin/noisepage