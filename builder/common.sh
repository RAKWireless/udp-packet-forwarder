#!/bin/bash

set -e

git_clone_and_patch() {

    URL=$1
    FOLDER=$2
    TAG=$3

    # Clone
    if [[ ! -d $FOLDER ]]; then
        git clone -b ${TAG} $URL $FOLDER
        pushd $FOLDER >> /dev/null
    else
        pushd $FOLDER >> /dev/null
        git checkout -- .
        git clean -d -x -f
        git checkout ${TAG}
    fi

    # Apply patches
    if [ -f ../$FOLDER.$TAG.patch ]; then
        echo "Applying $FOLDER.$TAG.patch ..."
        git apply ../$FOLDER.$TAG.patch
    fi

    popd >> /dev/null

}


