#/bin/bash

git submodule init
git submodule update
cd engine
make clean
make EXENAME=Grid
mv Grid ../Grid
cd ..
./start.sh
