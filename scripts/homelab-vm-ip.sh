#!/bin/bash

sudo virsh net-dhcp-leases default | grep homelab | awk '{print $5}' | cut -d'/' -f1
