#!/usr/bin/env bash

set -ex

ISO_PATH=$1

if [ ! -f "$ISO_PATH" ]; then
  echo "$ISO_PATH is not a file"
  exit 1
fi

LIBVIRT_ISO_PATH="/var/lib/libvirt/images/homelab.iso"
LIBVIRT_QCOW_PATH="/var/lib/libvirt/images/homelab.qcow2"

trap "sudo rm $LIBVIRT_ISO_PATH" EXIT

sudo cp "$ISO_PATH" "$LIBVIRT_ISO_PATH"

VM_NAME=homelab
VM_RAM=2048
VM_CPUS=8
VM_DISK_GB=20

if virsh list --all | grep -q "$VM_NAME"; then
  sudo virsh detach-disk --domain "$VM_NAME" --target "$LIBVIRT_QCOW_PATH"
  sudo virsh destroy --domain "$VM_NAME"
  sudo virsh undefine --domain "$VM_NAME"
  sudo rm "$LIBVIRT_QCOW_PATH"
fi

# TODO: Should I specify path to disk?
sudo virt-install \
  --name "$VM_NAME" \
  --ram "$VM_RAM" \
  --vcpus "$VM_CPUS" \
  --disk "path=$LIBVIRT_QCOW_PATH,size=$VM_DISK_GB,format=qcow2" \
  --cdrom "$LIBVIRT_ISO_PATH" \
  --network bridge=virbr0,model=virtio \
  --boot cdrom,hd,menu=on \
  --input keyboard,bus=usb \
  --virt-type qemu \
  --autoconsole graphical \
  --osinfo ubuntu24.04 \
  --destroy-on-exit
