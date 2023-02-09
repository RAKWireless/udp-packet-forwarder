#!/bin/bash

set -e

# Build v2 SPI
v2/build.sh native

# Build v2 FTDI
v2/build.sh ftdi

# Build corecell
corecell/build.sh

# Copy artifacts
mkdir -p artifacts 
mv */artifacts/* artifacts/

