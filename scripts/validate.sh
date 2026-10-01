#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

required=(
  README.md
  ROADMAP.md
  SECURITY.md
  docs/ARCHITECTURE.md
  docs/USB_INSTALL.md
  docs/WORKSTATION.md
  docs/DEVELOPMENT.md
  docs/ENCRYPTION.md
  docs/FAQ.md
  docs/HARDWARE.md
  docs/RECOVERY.md
  docs/RESCUE_ISO.md
  docs/RELEASE_CHECKLIST.md
  docs/RELEASE_NOTES_TEMPLATE.md
  docs/RELEASE_POLICY.md
  docs/SECURITY_BASELINE.md
  docs/SECURE_BOOT.md
  docs/THREAT_MODEL.md
  docs/TROUBLESHOOTING.md
  CONTRIBUTING.md
  external-tools/README.md
  external-tools/manifest.txt
  packages/base.txt
  packages/desktop.txt
  packages/network.txt
  scripts/install-to-usb.sh
  scripts/build-release-images.sh
  scripts/build-rescue-iso.sh
  scripts/verify-release-artifacts.sh
  scripts/test-qemu-release.sh
  scripts/test-qemu-secure-boot.sh
  scripts/test-release-installer.sh
  .github/workflows/release.yml
  .github/workflows/rescue-build.yml
  .github/workflows/rolling-build.yml
  scripts/ci/vibrali-ci-probe
  scripts/ci/vibrali-ci-probe.service
  scripts/fetch-external-tool.sh
  scripts/audit-external-tools.sh
  scripts/validate-external-tools.sh
  scripts/validate-tool-profiles.sh
  site/index.html
  site/style.css
  site/install.sh
  config/rootfs/etc/os-release
  config/rootfs/etc/default/zramswap
  config/rootfs/etc/nftables.conf
  config/rootfs/etc/sudoers.d/90-vibrali
  config/rootfs/etc/systemd/journald.conf.d/vibrali-portable.conf
  config/rootfs/usr/local/bin/vibrali-session-init
  config/rootfs/usr/local/bin/vibrali-welcome
  config/rootfs/usr/local/bin/vibrali-toolbox
  config/rootfs/usr/local/bin/vibrali-firewall
  config/rootfs/usr/local/bin/vibrali-display-scale
  config/rootfs/etc/xdg/menus/applications-merged/vibrali-security.menu
  config/rootfs/usr/lib/firefox-esr/distribution/policies.json
  config/rootfs/etc/xdg/autostart/vibrali-welcome.desktop
  config/rootfs/etc/xdg/autostart/vibrali-clipman.desktop
  config/rootfs/usr/share/applications/vibrali-welcome.desktop
  assets/brand/vibrali-logo.png
  assets/brand/vibrali-wallpaper-default.png
)

for path in "${required[@]}"; do
  test -s "$path" || { echo "missing or empty: $path" >&2; exit 1; }
done

for path in \
  config/rootfs/usr/local/sbin/vibrali-ci-probe \
  config/rootfs/etc/systemd/system/vibrali-ci-probe.service
do
  test ! -e "$path" || {
    echo "CI-only probe must not ship in product rootfs: $path" >&2
    exit 1
  }
done

while IFS= read -r file; do
  bash -n "$file"
done < <(find scripts -type f -name '*.sh' -print)

bash -n site/install.sh
bash -n scripts/ci/vibrali-ci-probe
bash -n config/rootfs/usr/local/bin/vibrali-session-init
bash -n config/rootfs/usr/local/bin/vibrali-welcome
bash -n config/rootfs/usr/local/bin/vibrali-toolbox
bash -n config/rootfs/usr/local/bin/vibrali-firewall
bash -n config/rootfs/usr/local/bin/vibrali-display-scale
bash -n config/rootfs/etc/skel/.bashrc
grep -Fxq 'source /usr/local/lib/vibrali/gef.py' config/rootfs/etc/skel/.gdbinit
bash -n config/rootfs/etc/skel/.zshrc

while IFS= read -r file; do
  sh -n "$file"
done < <(find config/hooks -type f -print)

python3 - <<'PY'
from pathlib import Path
paths = list(Path("packages").glob("*.txt"))
paths += list(Path("config/package-lists").glob("*.list.chroot"))
for path in paths:
    packages = [
        line.strip()
        for line in path.read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if packages != sorted(set(packages)):
        raise SystemExit(f"{path}: package list must be sorted and unique")
print("package manifests: ok")
PY

python3 - <<'PY'
import json
import xml.etree.ElementTree as ET
from pathlib import Path

firefox_policy = json.loads(Path("config/rootfs/usr/lib/firefox-esr/distribution/policies.json").read_text())
preferences = firefox_policy["policies"].get("Preferences", {})
expected_preferences = {
    "browser.cache.disk.enable": False,
    "browser.cache.memory.enable": True,
    "browser.sessionstore.interval": 60000,
}
for preference, expected in expected_preferences.items():
    entry = preferences.get(preference)
    if not isinstance(entry, dict) or entry.get("Value") != expected or entry.get("Status") != "default":
        raise SystemExit(f"Firefox portable-storage preference missing/invalid: {preference}")
if preferences["browser.sessionstore.interval"].get("Type") != "number":
    raise SystemExit("Firefox sessionstore interval must be explicitly typed as a number")
ET.parse("config/rootfs/etc/xdg/menus/applications-merged/vibrali-security.menu")

categories = {
    "network": "VibraliNetwork",
    "web": "VibraliWeb",
    "auth": "VibraliAuth",
    "pwn": "VibraliPwn",
    "reverse": "VibraliReverse",
    "crypto": "VibraliCrypto",
    "forensics": "VibraliForensics",
    "wireless": "VibraliWireless",
    "directory": "VibraliDirectory",
    "defensive": "VibraliDefensive",
}
for name, category in categories.items():
    launcher = Path(f"config/rootfs/usr/share/applications/vibrali-toolbox-{name}.desktop")
    text = launcher.read_text()
    if f"Categories={category};" not in text:
        raise SystemExit(f"{launcher}: missing expected category {category}")
print("desktop security menu/browser policy: ok")
PY

python3 - <<'PY'
from pathlib import Path

nft = Path("config/rootfs/etc/nftables.conf").read_text()
required = [
    "table inet vibrali",
    "policy drop",
    "policy accept",
    'iifname "lo" accept',
    "ct state established,related accept",
]
for token in required:
    if token not in nft:
        raise SystemExit(f"nftables baseline missing: {token}")

sudoers = Path("config/rootfs/etc/sudoers.d/90-vibrali").read_text()
for token in ["Defaults use_pty", "Defaults timestamp_timeout=5", "Defaults passwd_timeout=1"]:
    if token not in sudoers:
        raise SystemExit(f"sudo baseline missing: {token}")

print("firewall/sudo security baseline: ok")
PY

diff -u \
  <(
    for path in packages/*.txt; do
      name="${path##*/}"
      name="${name%.txt}"
      case "$name" in
        base|desktop) continue ;;
      esac
      printf '%s\n' "$name"
    done | LC_ALL=C sort
  ) \
  <(./scripts/install-to-usb.sh --list-profiles)

grep -q -- '--profiles LIST' <(./scripts/install-to-usb.sh --help)
grep -q -- '--dry-run' <(./scripts/install-to-usb.sh --help)
grep -q -- '--encrypt-root' <(./scripts/install-to-usb.sh --help)
grep -q 'cryptsetup-initramfs' scripts/install-to-usb.sh
grep -q 'VIBRALI_CRYPT' scripts/install-to-usb.sh
grep -q '/etc/crypttab' scripts/install-to-usb.sh
grep -Fxq 'grub-efi-amd64-signed' packages/base.txt
grep -Fxq 'shim-signed' packages/base.txt
grep -Fxq 'sbsigntool' packages/base.txt
for package in btrfs-progs ca-certificates cryptsetup debootstrap dnsutils gdisk gparted grub-efi-amd64-signed mdadm mtr-tiny network-manager nvme-cli parted sbsigntool shim-signed smartmontools sudo testdisk util-linux xfsprogs; do
  grep -Fxq "$package" rescue/config/package-lists/vibrali-rescue.list.chroot || {
    echo "rescue package missing: $package" >&2
    exit 1
  }
done
grep -q '^SOURCE=/usr/share/vibrali-sourcegrep -q -- '--uefi-secure-boot' scripts/install-to-usb.sh
grep -q 'sbverify --list /boot/efi/EFI/BOOT/BOOTX64.EFI' scripts/install-to-usb.sh
grep -q 'sbverify --list /boot/efi/EFI/BOOT/grubx64.efi' scripts/install-to-usb.sh
grep -q 'VIBRALI-CI-SECURE' scripts/ci/vibrali-ci-probe
grep -q 'secure-boot-enabled' scripts/ci/vibrali-ci-probe
grep -q 'OVMF_CODE_4M.secboot.fd' scripts/test-qemu-secure-boot.sh
grep -q 'OVMF_VARS_4M.ms.fd' scripts/test-qemu-secure-boot.sh
grep -Fxq 'power-profiles-daemon' packages/desktop.txt
grep -Fxq 'x11-xserver-utils' packages/desktop.txt
grep -q '/Gdk/WindowScalingFactor' config/rootfs/usr/local/bin/vibrali-display-scale
bash ./scripts/test-installer-cli.sh
grep -q 'COSIGN_IDENTITY_REGEXP' site/install.sh
grep -q 'verify_manifest_signature' site/install.sh
bash ./scripts/test-release-installer.sh
bash ./scripts/validate-external-tools.sh
grep -q 'github-release:' external-tools/manifest.txt
bash ./scripts/validate-tool-profiles.sh

grep -Fq 'SIZE="${VIBRALI_IMAGE_SIZE:-32G}"' scripts/build-release-images.sh || {
  echo "release image size default must stay in scripts/build-release-images.sh" >&2
  exit 1
}
for workflow in .github/workflows/release.yml .github/workflows/rolling-build.yml; do
  if grep -q 'VIBRALI_IMAGE_SIZE' "$workflow"; then
    echo "$workflow must not override VIBRALI_IMAGE_SIZE; the builder is the single source of truth" >&2
    exit 1
  fi
done

echo "Vibrali repository validation passed."
 rescue/config/includes.chroot/usr/local/bin/vibrali-rescue-install
grep -q 'scripts/install-to-usb.sh' rescue/config/includes.chroot/usr/local/bin/vibrali-rescue-install
grep -q 'Name=Install Vibrali' rescue/config/includes.chroot/usr/share/applications/vibrali-install.desktop
grep -q -- '--uefi-secure-boot' scripts/install-to-usb.sh
grep -q 'sbverify --list /boot/efi/EFI/BOOT/BOOTX64.EFI' scripts/install-to-usb.sh
grep -q 'sbverify --list /boot/efi/EFI/BOOT/grubx64.efi' scripts/install-to-usb.sh
grep -q 'VIBRALI-CI-SECURE' scripts/ci/vibrali-ci-probe
grep -q 'secure-boot-enabled' scripts/ci/vibrali-ci-probe
grep -q 'OVMF_CODE_4M.secboot.fd' scripts/test-qemu-secure-boot.sh
grep -q 'OVMF_VARS_4M.ms.fd' scripts/test-qemu-secure-boot.sh
grep -Fxq 'power-profiles-daemon' packages/desktop.txt
grep -Fxq 'x11-xserver-utils' packages/desktop.txt
grep -q '/Gdk/WindowScalingFactor' config/rootfs/usr/local/bin/vibrali-display-scale
bash ./scripts/test-installer-cli.sh
grep -q 'COSIGN_IDENTITY_REGEXP' site/install.sh
grep -q 'verify_manifest_signature' site/install.sh
bash ./scripts/test-release-installer.sh
bash ./scripts/validate-external-tools.sh
grep -q 'github-release:' external-tools/manifest.txt
bash ./scripts/validate-tool-profiles.sh

grep -Fq 'SIZE="${VIBRALI_IMAGE_SIZE:-32G}"' scripts/build-release-images.sh || {
  echo "release image size default must stay in scripts/build-release-images.sh" >&2
  exit 1
}
for workflow in .github/workflows/release.yml .github/workflows/rolling-build.yml; do
  if grep -q 'VIBRALI_IMAGE_SIZE' "$workflow"; then
    echo "$workflow must not override VIBRALI_IMAGE_SIZE; the builder is the single source of truth" >&2
    exit 1
  fi
done

echo "Vibrali repository validation passed."
