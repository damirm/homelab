#!/usr/bin/env bash

set -ex

ISO_PATH=$1

if [ ! -f "$ISO_PATH" ]; then
  echo "$ISO_PATH is not a file"
  exit 1
fi

VM_NAME=homelab
VM_RAM=8192
VM_CPUS=16
VM_DISK_GB=20

LIBVIRT_ISO_PATH="/var/lib/libvirt/images/$VM_NAME.iso"
LIBVIRT_QCOW_PATH="/var/lib/libvirt/images/$VM_NAME.qcow2"

if sudo virsh list --all | grep -q "$VM_NAME"; then
  # sudo virsh destroy --domain "$VM_NAME"
  sudo virsh undefine --domain "$VM_NAME" --storage vda
fi

if sudo virsh vol-list --pool images | grep -q "$VM_NAME.qcow2"; then
  # sudo virsh detach-disk --domain "$VM_NAME" --target "$LIBVIRT_QCOW_PATH"
  sudo virsh vol-delete --pool images --vol "$LIBVIRT_QCOW_PATH"
fi

if sudo virsh vol-list --pool images | grep -q "$VM_NAME.iso"; then
  sudo virsh vol-delete --pool images --vol "$LIBVIRT_ISO_PATH"
fi

trap "sudo rm $LIBVIRT_ISO_PATH" EXIT
sudo cp "$ISO_PATH" "$LIBVIRT_ISO_PATH"

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
