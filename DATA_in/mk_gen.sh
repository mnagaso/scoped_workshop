#!/bin/bash

##################################################################

# binaries: 1 == forward, 2 == adjoint/kernel
forward=$1

##################################################################

if [ "$forward" == "" ]; then echo "usage: ./mk_frontera.sh forward(==1/==2 for kernel binaries)"; exit 1; fi

#source /etc/profile
#module list

## compilation for xcreate_header_file
## to run on login node
echo
echo "compiling xcreate_header_file..."
echo

#check for perfool, leads to unusable xcreate_header_file executable
#perf=`module list -t > tmp.txt 2>&1; fgrep perflite tmp.txt; rm -f tmp.txt`
#if [ "$perf" == "" ]; then
# echo "perflite not loaded"
#else
# echo "loaded $perf"
# echo "unloading $perf for xcreate_header_file..."
# module unload $perf
#fi

make clean
rm -rf bin/*

make -j1 xcreate_header_file
# checks exit code
if [[ $? -ne 0 ]]; then exit 1; fi
if [ ! -e bin/xcreate_header_file ]; then exit 1; fi

rm -rf bin.header_file
cp -rp bin bin.header_file


if [ "$forward" == "1" ]; then

# forward simulations
#
# only needed to produce synthetics for flexwin/measurements
#
echo
echo "compiling forward simulations..."
echo
#make clean
rm -f bin/xmeshfem3D bin/xspecfem3D
rm -rf OUTPUT_FILES/*
rm -rf bin.forward

mkdir -p bin
cp bin.header_file/xcreate_header_file bin/

make -j1  all
# checks exit code
if [[ $? -ne 0 ]]; then exit 1; fi

make aux
make tomo
make postprocess
# checks exit code
if [[ $? -ne 0 ]]; then exit 1; fi
if [ ! -e bin/xspecfem3D ]; then exit 1; fi

cp -rp bin bin.forward

# backup setup file
mv OUTPUT_FILES/* bin.forward/
cp setup/constants.h bin.forward/

if [ ! -e bin.forward/xspecfem3D ]; then exit 1; fi

fi


if [ "$forward" == "2" ]; then

# kernel simulations
#
# needed for forward/backward simulations to create adjoint kernels
#
echo
echo "compiling kernel simulations..."
echo
#make clean
rm -f bin/xmeshfem3D bin/xspecfem3D
rm -rf OUTPUT_FILES/*
rm -rf bin.kernel

./change_simulation_type.pl -F

mkdir -p bin
cp bin.header_file/xcreate_header_file bin/

make -j1 all
# checks exit code
if [[ $? -ne 0 ]]; then exit 1; fi

make aux
make tomo
make postprocess
# checks exit code
if [[ $? -ne 0 ]]; then exit 1; fi

cp -rf bin bin.kernel

# backup setup file
mv OUTPUT_FILES/* bin.kernel/
cp setup/constants.h bin.kernel/

if [ ! -e bin.kernel/xspecfem3D ]; then exit 1; fi

fi

echo
echo

## checks
if [[ $? -ne 0 ]]; then echo "compilation failed"; exit 1; fi


echo
echo "done successfully"
echo

