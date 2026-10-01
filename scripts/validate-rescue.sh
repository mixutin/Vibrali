#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

required=(
  docs/RESCUE_ISO.md
  scripts/build-rescue-iso.sh
  scripts/vibrali-installer-gui.sh
  .github/workflows/rescue-build.yml
  rescue/config/package-lists/vibrali-rescue.list.chroot
  rescue/config/archives/vibrali-security.list.chroot
  rescue/config/includes.chroot/usr/local/bin/vibrali-rescue-install
  rescue/config/includes.chroot/usr/share/applications/vibrali-install.desktop
  rescue/config/includes.chroot/etc/skel/Desktop/vibrali-install.desktop
)

for path in "${required[@]}"; do
  [[ -e "$path" ]] || {
    echo "missing rescue artifact: $path" >&2
    exit 1
  }
done

for package in   btrfs-progs ca-certificates cryptsetup debootstrap dnsutils gdisk gparted   grub-efi-amd64-signed mdadm mtr-tiny network-manager nvme-cli parted   sbsigntool shim-signed smartmontools sudo testdisk util-linux xfsprogs zenity
do
  grep -Fxq "$package" rescue/config/package-lists/vibrali-rescue.list.chroot || {
    echo "rescue package missing: $package" >&2
    exit 1
  }
done

grep -Fq 'SOURCE=/usr/share/vibrali-source' rescue/config/includes.chroot/usr/local/bin/vibrali-rescue-install
grep -Fq 'scripts/install-to-usb.sh' rescue/config/includes.chroot/usr/local/bin/vibrali-rescue-install
grep -Fq 'Name=Install Vibrali' rescue/config/includes.chroot/usr/share/applications/vibrali-install.desktop
grep -Fq 'Name=Install Vibrali' rescue/config/includes.chroot/etc/skel/Desktop/vibrali-install.desktop
grep -Fq 'vibrali-installer-gui.sh' rescue/config/includes.chroot/usr/share/applications/vibrali-install.desktop
grep -Fq 'trixie-security' rescue/config/archives/vibrali-security.list.chroot
grep -Fq -- '--security false' scripts/build-rescue-iso.sh
grep -Fq -- '--linux-flavours amd64' scripts/build-rescue-iso.sh

bash -n scripts/build-rescue-iso.sh
bash -n rescue/config/includes.chroot/usr/local/bin/vibrali-rescue-install

echo "Vibrali rescue configuration validation passed."
