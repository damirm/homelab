#!/bin/bash

VM_ADDR=$(../scripts/homelab-vm-ip.sh)

if [[ "$1" == "--list" ]]; then
  cat << EOF
{
  "homelab": {
    "hosts": ["$VM_ADDR"]
  }
}
EOF
elif [[ "$1" == "--host" ]]; then
  cat << EOF
{
  "ansible_host": "$VM_ADDR"
}
EOF
else
  echo "{}"
fi
