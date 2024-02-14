#!/bin/bash

# Uses docker buildx and https://github.com/estesp/manifest-tool

FIRST=$1
ARGS=$@
MANIFEST_TOOL=manifest-tool

export TAG=$(git rev-parse --short HEAD)
export VERSION=$(git describe --abbrev=0 --tags)
export MAJOR=$(git describe --abbrev=0 --tags | cut -d '.' -f1)
export BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
export REGISTRY=${REGISTRY:-"rakwireless/udp-packet-forwarder"}

# Check we have buildx extension for docker
docker buildx version &> /dev/null
if [[ $? -ne 0 ]]; then
  echo "ERROR: docker or docker buildx extension are not installed"
  exit 1
fi

if [ "$FIRST" == "--push" ]; then

  # Check we have the manifest modifier tool
  hash $MANIFEST_TOOL &> /dev/null
  if [[ $? -ne 0 ]]; then
    echo "ERROR: $MANIFEST_TOOL could not be found!"
    exit 1
  fi

  # Ask confirmation if pushing to a registry
  echo "Pushing image into $REGISTRY"
  echo "Tags: $MAJOR, $VERSION, $TAG, latest"
  read -r -p "Are you sure? [y/N] " response
  if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Cancelled"
    exit 1
  fi

fi

# Building
time docker buildx bake $ARGS

# Merge individual archs into the same tags
if [ "$FIRST" == "--push" ]; then

    MANIFEST=manifest.yaml
    cat > $MANIFEST << EOL
image: $REGISTRY:$TAG
tags: ['$VERSION', '$MAJOR', 'latest']
manifests:
  - image: $REGISTRY:aarch64-latest
    platform:
      architecture: arm64
      os: linux  
  - image: $REGISTRY:armv7hf-latest
    platform:
      architecture: arm
      os: linux  
  - image: $REGISTRY:armv6l-latest
    platform:
      architecture: arm
      os: linux  
  - image: $REGISTRY:amd64-latest
    platform:
      architecture: amd64
      os: linux  
EOL

    $MANIFEST_TOOL push from-spec $MANIFEST
    rm $MANIFEST

fi
