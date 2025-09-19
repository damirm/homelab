#!/usr/bin/env bash

cd "$(dirname "$0")"

INVENTORY=$1

if [ ! -f "$INVENTORY" ]; then
  echo "$INVENTORY is not a file"
  exit 1
fi

ansible-galaxy collection install -r requirements.yaml

ansible-playbook \
  --inventory-file "$INVENTORY" \
  playbooks/playbook.yaml
