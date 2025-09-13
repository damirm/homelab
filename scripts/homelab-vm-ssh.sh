#!/bin/bash

SCRIPT_DIR=$(dirname -- "${BASH_SOURCE[0]}")
VM_ADDR=$($SCRIPT_DIR/homelab-vm-ip.sh)

ssh "yw@$VM_ADDR" -i ~/.ssh/id_ed25519
