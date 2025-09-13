#!/usr/bin/env bash

ISO_PATH=$1
DEVICE=$2

if [ ! -f "$ISO_PATH" ]; then
  echo "$ISO_PATH is not a file"
  exit 1
fi

if [ ! -f "$DEVICE" ]; then
  echo "Wrong device $DEVICE"
  exit 1
fi

sudo umount "$DEVICE"

sudo dd bs=4M if=$ISO_PATH of="$DEVICE" status=progress oflag=sync
