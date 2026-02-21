#!/usr/bin/env bash
set -euo pipefail

ENGINE="${ENGINE:-docker}"
IMAGE="${IMAGE:-homelab/iso-builder:24.04}"

UBUNTU_ISO_URL="${UBUNTU_ISO_URL:-https://mirror.yandex.ru/ubuntu-releases/24.04.3/ubuntu-24.04.3-live-server-amd64.iso}"
UBUNTU_ISO_CHECKSUM="${UBUNTU_ISO_CHECKSUM:-sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b}"

OUTPUT_ISO="${OUTPUT_ISO:-/work/dist/ubuntu-24.04-autoinstall-homelab.iso}"
SEED_DIR="${SEED_DIR:-/work/packer/ubuntu2404/http}"

DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

exec "${ENGINE}" run --rm \
  --platform="${DOCKER_PLATFORM}" \
  -e UBUNTU_ISO_URL="${UBUNTU_ISO_URL}" \
  -e UBUNTU_ISO_CHECKSUM="${UBUNTU_ISO_CHECKSUM}" \
  -e OUTPUT_ISO="${OUTPUT_ISO}" \
  -e SEED_DIR="${SEED_DIR}" \
  -v "${repo_root}:/work" \
  "${IMAGE}"
