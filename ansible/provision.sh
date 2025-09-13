#!/usr/bin/env bash

cd "$(dirname "$0")"

INVENTORY=$1

if [ ! -f "$INVENTORY" ]; then
  echo "$INVENTORY is not a file"
  exit 1
fi

ansible-playbook \
  --inventory-file "$INVENTORY" \
  --private-key "$HOME/.ssh/id_ed25519" \
  playbooks/playbook.yaml
