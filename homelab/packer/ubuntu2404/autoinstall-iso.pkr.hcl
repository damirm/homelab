variable "output_iso" {
  type    = string
  default = "dist/ubuntu-24.04-autoinstall-homelab.iso"
}

source "null" "autoinstall_iso" {
  communicator = "none"
}

build {
  sources = ["source.null.autoinstall_iso"]

  provisioner "shell-local" {
    environment_vars = [
      "OUTPUT_ISO=/work/${var.output_iso}"
    ]
    inline = [
      "../../scripts/iso-build-container.sh"
    ]
  }
}

