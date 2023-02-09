#!/bin/bash

set -e
pushd $(dirname $0)

# --------------------------
# Configuration
# --------------------------
INTERFACE=$1
V2_LIBMPSSE_TAG=${V2_LIBMPSSE_TAG:-"master"}
V2_HAL_TAG=${V2_HAL_TAG:-"v5.0.1"}
V2_PF_TAG=${V2_PF_TAG:-"v4.0.1"}

# --------------------------
# Methods
# --------------------------

source ../common.sh

# --------------------------
# Notify
# --------------------------

echo "-------------------------------------------------------"
echo "Building UDP Packet Forwarder for V2 in $INTERFACE mode"
echo "-------------------------------------------------------"

# --------------------------
# Build libmpsse
# --------------------------

if [[ ! -d libmpsse ]]; then

    # Clone
    git_clone_and_patch https://github.com/devttys0/libmpsse.git libmpsse ${V2_LIBMPSSE_TAG} 

    # Change directory to repo
    pushd libmpsse >> /dev/null

    # Build repo
    pushd src >> /dev/null
    ./configure --disable-python
    make
    make install
    ldconfig
    popd > /dev/null

    # Back
    popd > /dev/null

fi

# --------------------------
# Build lora_gateway
# --------------------------

git_clone_and_patch https://github.com/Lora-net/lora_gateway.git lora_gateway ${V2_HAL_TAG} 

# Change directory to repo
pushd lora_gateway >> /dev/null

# Set interface
echo "CFG_SPI= $INTERFACE" >> libloragw/library.cfg

# Build repo
make clean
make

# Back
popd > /dev/null

# --------------------------
# Build packet_forwarder
# --------------------------

git_clone_and_patch https://github.com/Lora-net/packet_forwarder.git packet_forwarder ${V2_PF_TAG} 

# Change directory to repo
pushd packet_forwarder >> /dev/null

# Build repo
make clean
make

# Back
popd > /dev/null

# --------------------------
# Copy artifacts
# --------------------------
mkdir -p artifacts/v2/$INTERFACE
cp packet_forwarder/lora_pkt_fwd/lora_pkt_fwd artifacts/v2/$INTERFACE/
if [[ "$INTERFACE" == "ftdi" ]]; then
    cp lora_gateway/libloragw/99-libftdi.rules artifacts/v2/$INTERFACE/
fi

popd