#!/usr/bin/env bash

set -ex

ISO_PATH=$1
ISO_RESULT="$(basename $ISO_PATH .iso)-homelab.iso"

if [ ! -f "$ISO_PATH" ]; then
    echo "$ISO_PATH is not a file"
    exit 1
fi

podman run --rm \
    --volume "$(pwd):/data:z" \
    deserializeme/pxeless \
    --user-data "/data/autoinstall.yaml" \
    --source "/data/$ISO_PATH" \
    --destination "/data/$ISO_RESULT" \
    --timeout 5 \
    --all-in-one \
    --verbose
