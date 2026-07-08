#!/bin/bash
export OMNETPP_ROOT=~/omnetpp-6.0.1
export INET_ROOT=~/omnetpp-6.0.1/samples/inet4.5
export PATH=$OMNETPP_ROOT/bin:$PATH
export LD_LIBRARY_PATH=$INET_ROOT/out/gcc-release/src:$LD_LIBRARY_PATH

cd ~/omnetpp-6.0.1/samples/Simu5G

./out/gcc-release/Simu5G \
  -u Qtenv \
  -n simulations:src:$INET_ROOT/src \
  -l $INET_ROOT/out/gcc-release/src/libINET.so \
  -c Standalone \
  simulations/NR/standalone/omnetpp.ini
