#!/usr/bin/env bash
set -euo pipefail

ISO="${ISO:-dist/ubuntu-24.04-autoinstall-homelab.iso}"
DEV="${DEV:-}"

if [[ -z "${DEV}" ]]; then
  echo "Usage: DEV=/dev/sdX ISO=dist/xxx.iso $0"
  echo "On macOS DEV looks like /dev/diskN (we will use /dev/rdiskN for speed)"
  exit 1
fi

if [[ ! -f "$ISO" ]]; then
  echo "ISO not found: $ISO" >&2
  exit 1
fi

echo "[!] This will ERASE ALL DATA on $DEV"
read -r -p "Type 'YES' to continue: " confirm
[[ "$confirm" == "YES" ]]

uname_s="$(uname -s)"

if [[ "$uname_s" == "Darwin" ]]; then
  echo "[*] macOS: unmount disk"
  diskutil unmountDisk "$DEV" || true
  rawdev="$DEV"
  rawdev="${rawdev/\/dev\/disk/\/dev\/rdisk}"
  echo "[*] Writing $ISO to $rawdev"
  sudo dd if="$ISO" of="$rawdev" bs=4m conv=sync status=progress
  sync
  echo "[*] Eject"
  diskutil eject "$DEV" || true
else
  echo "[*] Linux: unmount partitions"
  sudo umount "${DEV}"* 2> /dev/null || true
  echo "[*] Writing $ISO to $DEV"
  sudo dd if="$ISO" of="$DEV" bs=4M conv=fsync status=progress
  sync
fi

echo "[*] Done"
