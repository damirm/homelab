#!/usr/bin/env bash

# NOTE: Actually we can use something like https://github.com/cloudymax/pxeless

set -euo pipefail

: "${UBUNTU_ISO_URL:?}"      # https://...  OR file:///work/... OR /work/...
: "${UBUNTU_ISO_CHECKSUM:?}" # format: sha256:<hex>
: "${OUTPUT_ISO:?}"          # e.g. /work/dist/ubuntu-24.04-autoinstall-homelab.iso
: "${SEED_DIR:?}"            # e.g. /work/packer/ubuntu2404/http

workdir="$(mktemp -d)"
iso_in="${workdir}/ubuntu.iso"
extract="${workdir}/extract"

cleanup() { rm -rf "$workdir"; }
trap cleanup EXIT

mkdir -p "$(dirname "$OUTPUT_ISO")"
mkdir -p "$extract"

fetch_iso() {
  local src="$1"
  if [[ "$src" == file://* ]]; then
    local path="${src#file://}"
    if [[ ! -f "$path" ]]; then
      echo "Local ISO not found: $path" >&2
      exit 1
    fi
    cp -f "$path" "$iso_in"
  elif [[ "$src" == /* ]]; then
    if [[ ! -f "$src" ]]; then
      echo "Local ISO not found: $src" >&2
      exit 1
    fi
    cp -f "$src" "$iso_in"
  else
    curl -L "$src" -o "$iso_in"
  fi
}

verify_checksum() {
  local spec="$1" # sha256:....
  local algo="${spec%%:*}"
  local expected="${spec#*:}"

  case "$algo" in
  sha256) ;;
  *)
    echo "Unsupported checksum algo: $algo (expected sha256:...)" >&2
    exit 1
    ;;
  esac

  local actual
  actual="$(sha256sum "$iso_in" | awk '{print $1}')"
  if [[ "$actual" != "$expected" ]]; then
    echo "Checksum mismatch:" >&2
    echo "  expected=$expected" >&2
    echo "  actual  =$actual" >&2
    exit 1
  fi
}

echo "[*] Fetch ISO from: $UBUNTU_ISO_URL"
fetch_iso "$UBUNTU_ISO_URL"

echo "[*] Verify checksum"
verify_checksum "$UBUNTU_ISO_CHECKSUM"

echo "[*] Extract ISO contents (no mount)"
xorriso -osirrox on -indev "$iso_in" -extract / "$extract" > /dev/null 2>&1

echo "[*] Add nocloud seed"
[[ -f "$SEED_DIR/user-data" ]] || {
  echo "Missing $SEED_DIR/user-data" >&2
  exit 1
}
[[ -f "$SEED_DIR/meta-data" ]] || {
  echo "Missing $SEED_DIR/meta-data" >&2
  exit 1
}

mkdir -p "$extract/nocloud"
cp -f "$SEED_DIR/user-data" "$extract/nocloud/user-data"
cp -f "$SEED_DIR/meta-data" "$extract/nocloud/meta-data"

echo "[*] Patch boot configs for autoinstall"
# UEFI grub
if [[ -f "$extract/boot/grub/grub.cfg" ]]; then
  sed -i 's|---| autoinstall ds=nocloud\;s=/cdrom/nocloud/ ---|g' "$extract/boot/grub/grub.cfg"
fi
if [[ -f "$extract/boot/grub/loopback.cfg" ]]; then
  sed -i 's|---| autoinstall ds=nocloud\;s=/cdrom/nocloud/ ---|g' "$extract/boot/grub/loopback.cfg"
fi
# BIOS isolinux
if [[ -f "$extract/isolinux/txt.cfg" ]]; then
  sed -i 's|---| autoinstall ds=nocloud\;s=/cdrom/nocloud/ ---|g' "$extract/isolinux/txt.cfg"
fi

echo "[*] Locate isohdpfx.bin (optional, improves dd-to-usb BIOS boot)"
MBR_BIN=""
for p in \
  /usr/lib/ISOLINUX/isohdpfx.bin \
  /usr/lib/syslinux/isohdpfx.bin \
  /usr/share/syslinux/isohdpfx.bin; do
  if [[ -f "$p" ]]; then
    MBR_BIN="$p"
    break
  fi
done

ISOHYBRID_ARGS=()
if [[ -n "$MBR_BIN" ]]; then
  ISOHYBRID_ARGS+=(-isohybrid-mbr "$MBR_BIN" -partition_offset 16)
else
  echo "[!] WARNING: isohdpfx.bin not found; ISO may still boot via UEFI but BIOS dd-to-usb may be less reliable"
fi

echo "[*] Determine BIOS boot image"
BIOS_BOOT_ARGS=()

if [[ -f "$extract/isolinux/isolinux.bin" ]]; then
  # Старый вариант (isolinux)
  BIOS_BOOT_ARGS=(
    -b isolinux/isolinux.bin
    -c isolinux/boot.cat
    -no-emul-boot -boot-load-size 4 -boot-info-table
  )
elif [[ -f "$extract/boot/grub/i386-pc/eltorito.img" ]]; then
  # Новый вариант (GRUB BIOS El Torito)
  BIOS_BOOT_ARGS=(
    -b boot/grub/i386-pc/eltorito.img
    -c boot.catalog
    -no-emul-boot -boot-load-size 4 -boot-info-table
  )
else
  echo "ERROR: Cannot find BIOS boot image (no isolinux/isolinux.bin and no boot/grub/i386-pc/eltorito.img)" >&2
  exit 1
fi

echo "[*] Determine UEFI boot image"
UEFI_BOOT_ARGS=()
if [[ -f "$extract/boot/grub/efi.img" ]]; then
  UEFI_BOOT_ARGS=(
    -eltorito-alt-boot
    -e boot/grub/efi.img
    -no-emul-boot
  )
else
  echo "[!] WARNING: boot/grub/efi.img not found; UEFI boot may not work"
fi

echo "[*] Repack ISO"
xorriso -as mkisofs \
  -r -V "UBUNTU24_AUTOINSTALL" \
  -o "$OUTPUT_ISO" \
  -J -l \
  "${ISOHYBRID_ARGS[@]}" \
  -A "Ubuntu Server 24.04 Autoinstall" \
  "${BIOS_BOOT_ARGS[@]}" \
  "${UEFI_BOOT_ARGS[@]}" \
  "$extract"

echo "[*] Done: $OUTPUT_ISO"
