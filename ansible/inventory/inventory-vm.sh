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
  "ansible_host": "$VM_ADDR",
  "ansible_user": "yw", 
  "ansible_ssh_private_key_file": "~/.ssh/id_ed25519"
}
EOF
else
  echo "{}"
fi
