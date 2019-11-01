#/bin/bash

git submodule init
git submodule update
cd engine
make clean-all
make MODE=release EXENAME=Grid
mv Grid ../Grid
cd ..
./start.sh
