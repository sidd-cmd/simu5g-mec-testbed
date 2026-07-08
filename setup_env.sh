#!/bin/bash
# Source this file to set up the OMNeT++ / INET / Simu5G environment:
#   source setup_env.sh

export OMNETPP_ROOT=~/omnetpp-6.0.1
export INET_ROOT=~/omnetpp-6.0.1/samples/inet4.5
export PATH=$OMNETPP_ROOT/bin:$PATH
export LD_LIBRARY_PATH=$INET_ROOT/out/gcc-release/src:$LD_LIBRARY_PATH

echo "OMNETPP_ROOT=$OMNETPP_ROOT"
echo "INET_ROOT=$INET_ROOT"
echo "Environment ready."
