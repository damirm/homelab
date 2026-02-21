packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">= 1.1.0"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.0"
    }
  }
}

variable "ubuntu_iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso"
}

variable "ubuntu_iso_checksum" {
  type    = string
  default = "sha256:REPLACE_WITH_UBUNTU_24_04_ISO_SHA256"
}

variable "accelerator" {
  type    = string
  default = "hvf"
}

variable "ssh_username" {
  type    = string
  default = "ansible"
}

variable "ssh_private_key_file" {
  type    = string
  default = "~/.ssh/homelab_id_ed25519"
}

variable "disk_size_mb" {
  type    = number
  default = 40960
}

source "qemu" "ubuntu2404_qcow" {
  iso_url      = var.ubuntu_iso_url
  iso_checksum = var.ubuntu_iso_checksum

  output_directory = "output/ubuntu2404-qcow"
  vm_name          = "ubuntu2404-homelab"
  format           = "qcow2"

  disk_size = var.disk_size_mb
  cpus      = 2
  memory    = 4096

  headless    = true
  accelerator = var.accelerator

  http_directory = "${path.root}/http"

  net_device     = "virtio-net"
  disk_interface = "virtio"

  ssh_username         = var.ssh_username
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "35m"

  shutdown_command = "sudo shutdown -P now"

  boot_wait = "5s"
  boot_command = [
    "c",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<enter>",
    "initrd /casper/initrd",
    "<enter>",
    "boot",
    "<enter>"
  ]
}

build {
  name    = "ubuntu2404-homelab-qcow"
  sources = ["source.qemu.ubuntu2404_qcow"]

  provisioner "ansible" {
    playbook_file = "${path.root}/../../ansible/playbooks/homelab.yaml"
    user          = var.ssh_username
    extra_arguments = [
      "--extra-vars", "build_mode=true"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }
}

