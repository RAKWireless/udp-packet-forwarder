#!/bin/bash

set -e
cd $(dirname $0)

REMOTE_TAG=${REMOTE_TAG:-f8c9335} # This is latest commit on master branch at 20220120

# Clone 
if [[ ! -d repo ]]; then
    git clone https://github.com/RAKWireless/rak_common_for_gateway repo
fi

# Check out tag
pushd repo
git checkout ${REMOTE_TAG}

# Apply patches
if [ -f ../${REMOTE_TAG}.patch ]; then
    echo "Applying ${REMOTE_TAG}.patch ..."
    git apply ../${REMOTE_TAG}.patch
fi

# Build
pushd lora
FOLDERS=(rak7243 rak2246 rak2247_usb rak2247_spi rak2287 rak5146)
for FOLDER in ${FOLDERS[@]}; do
    pushd $FOLDER
    ./install.sh
    popd
done
popd

# Get out of repo folder
popd
