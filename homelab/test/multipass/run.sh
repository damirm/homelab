#!/usr/bin/env bash
set -euo pipefail

NAME="${NAME:-homelab-test}"
PUBKEY_FILE="${PUBKEY_FILE:-$HOME/.ssh/homelab_id_ed25519.pub}"

if [[ ! -f "$PUBKEY_FILE" ]]; then
  echo "No pubkey: $PUBKEY_FILE" >&2
  exit 1
fi

pubkey="$(cat "$PUBKEY_FILE")"
tmp_ci="$(mktemp)"

cat > "$tmp_ci" << EOF
#cloud-config
users:
  - name: ansible
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${pubkey}
package_update: true
packages:
  - python3
  - python3-apt
  - curl
EOF

if multipass info "$NAME" > /dev/null 2>&1; then
  echo "[*] Multipass instance exists: $NAME"
else
  multipass launch 24.04 --name "$NAME" --cloud-init "$tmp_ci" --cpus 2 --memory 4G --disk 20G
fi

ip="$(multipass info "$NAME" | awk '/IPv4/{print $2; exit}')"
echo "[*] VM IP: $ip"

cd ansible
ansible-galaxy collection install -r requirements.yaml
ansible-playbook -i "${ip}," -u ansible playbooks/homelab.yaml
