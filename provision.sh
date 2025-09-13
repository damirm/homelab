#!/usr/bin/env bash

ansible-playbook \
  --inventory-file ansible/vm-inventory.sh \
  --private-key "$HOME/.ssh/id_ed25519" \
  ansible/playbook.yaml
