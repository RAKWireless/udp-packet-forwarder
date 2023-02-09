#!/bin/bash

set -e
pushd $(dirname $0)

# --------------------------
# Configuration
# --------------------------
CORECELL_HAL_TAG=${CORECELL_HAL_TAG:-"V2.1.0"}

# --------------------------
# Methods
# --------------------------

source ../common.sh

# --------------------------
# Notify
# --------------------------

echo "-------------------------------------------------------"
echo "Building UDP Packet Forwarder for Corecell"
echo "-------------------------------------------------------"

# --------------------------
# Build packet_forwarder
# --------------------------

# Clone
git_clone_and_patch https://github.com/Lora-net/sx1302_hal.git sx1302_hal ${CORECELL_HAL_TAG} 
pushd sx1302_hal >> /dev/null

# Build
make

# Back
popd > /dev/null

# --------------------------
# Copy artifacts
# --------------------------

mkdir -p artifacts/corecell
cp sx1302_hal/packet_forwarder/lora_pkt_fwd artifacts/corecell/
cp sx1302_hal/util_chip_id/chip_id artifacts/corecell/

popd