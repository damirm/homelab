SHELL := /bin/bash

CONTAINER_ENGINE ?= docker
ISO_BUILDER_IMAGE ?= homelab/iso-builder:24.04
DOCKER_PLATFORM ?= linux/amd64
PACKER_DIR := packer/ubuntu2404
ANSIBLE_DIR := ansible

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-26s %s\n", $$1, $$2}'

tools:
	@command -v packer >/dev/null
	@command -v ansible-playbook >/dev/null
	@command -v ansible-galaxy >/dev/null
	@command -v $(CONTAINER_ENGINE) >/dev/null

ansible-deps:
	cd $(ANSIBLE_DIR) && ansible-galaxy collection install -r requirements.yaml

apply: ansible-deps
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventories/prod/hosts.ini playbooks/homelab.yaml

ping:
	cd $(ANSIBLE_DIR) && ansible -i inventories/prod/hosts.ini all -m ping

packer-iso-init:
	cd $(PACKER_DIR) && packer init -upgrade .

packer-fmt:
	packer fmt -recursive $(PACKER_DIR)

packer-iso-validate: ## validate ISO packer template
	cd $(PACKER_DIR) && packer validate autoinstall-iso.pkr.hcl

iso-builder-image:
	$(CONTAINER_ENGINE) build --platform=$(DOCKER_PLATFORM) -t $(ISO_BUILDER_IMAGE) -f iso/Dockerfile .

iso-build: iso-builder-image packer-iso-init ## Build bare metal autoinstall ISO into dist/
	cd $(PACKER_DIR) && packer build autoinstall-iso.pkr.hcl

usb-write: ## Write ISO to USB (DANGEROUS). Example: make usb-write DEV=/dev/sdX
	@ISO=$${ISO:-dist/ubuntu-24.04-autoinstall-homelab.iso} DEV=$${DEV:-} ./scripts/write-usb.sh

test-multipass: ansible-deps ## Create multipass VM and run ansible
	@chmod +x test/multipass/run.sh
	@./test/multipass/run.sh

test-multipass-destroy: ## Destroy multipass VM (NAME=homelab-test)
	@NAME=$${NAME:-homelab-test}; multipass delete -p $$NAME || true

test-vagrant: ansible-deps ## vagrant up (runs ansible provision)
	cd test/vagrant && vagrant up

test-vagrant-destroy: ## vagrant destroy
	cd test/vagrant && vagrant destroy -f

