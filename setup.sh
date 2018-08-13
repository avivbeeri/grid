#/bin/bash

git submodule init
git submodule update
cd engine
make
cd ..
./start.sh
