#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/dist}"
SIZE="${VIBRALI_IMAGE_SIZE:-24G}"
RAW="$OUT/vibrali-amd64.raw"
USB="$OUT/vibrali-usb-amd64.img.zst"
VM="$OUT/vibrali-qemu-amd64.qcow2.zst"
QCOW="$OUT/vibrali-qemu-amd64.qcow2"
CI_DIR="$OUT/.ci"
CI_QCOW="$CI_DIR/vibrali-qemu-ci.qcow2"
CI_MOUNT="$CI_DIR/root"
BUILD_INFO="$OUT/BUILD_INFO.txt"
PACKAGE_VERSIONS="$OUT/PACKAGE_VERSIONS.txt"
ZSTD_LEVEL="${VIBRALI_ZSTD_LEVEL:-10}"
PROBE_SOURCE="$ROOT/scripts/ci/vibrali-ci-probe"
PROBE_UNIT_SOURCE="$ROOT/scripts/ci/vibrali-ci-probe.service"

[[ $EUID -eq 0 ]] || {
  echo "Run this builder as root." >&2
  exit 1
}

if [[ ! "$ZSTD_LEVEL" =~ ^[0-9]+$ ]] || (( ZSTD_LEVEL < 1 || ZSTD_LEVEL > 19 )); then
  echo "VIBRALI_ZSTD_LEVEL must be an integer from 1 through 19." >&2
  exit 2
fi

mkdir -p "$OUT"
rm -f "$RAW" "$USB" "$VM" "$QCOW" "$OUT/SHA256SUMS" "$BUILD_INFO" "$PACKAGE_VERSIONS"
mkdir -p "$CI_MOUNT"
rm -f "$CI_QCOW"

for cmd in truncate losetup qemu-img zstd sha256sum mount umount mountpoint install mkdir ln rm chroot; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing command: $cmd" >&2
    exit 1
  }
done

truncate -s "$SIZE" "$RAW"
LOOP="$(losetup --find --show "$RAW")"

cleanup() {
  set +e
  sync
  mountpoint -q "$CI_MOUNT" && umount "$CI_MOUNT"
  losetup -d "${LOOP:-}" 2>/dev/null || true
}
trap cleanup EXIT

[[ -s "$PROBE_SOURCE" ]] || { echo "Missing CI guest probe: $PROBE_SOURCE" >&2; exit 1; }
[[ -s "$PROBE_UNIT_SOURCE" ]] || { echo "Missing CI guest probe unit: $PROBE_UNIT_SOURCE" >&2; exit 1; }

echo "Building Vibrali portable disk on $LOOP..."
VIBRALI_PASSWORD=vibrali "$ROOT/scripts/install-to-usb.sh" \
  --device "$LOOP" \
  --username vibrali \
  --hostname vibrali \
  --profiles all \
  --yes-really-erase \
  --non-interactive

ROOT_PART="${LOOP}p3"

sync
echo "Injecting CI-only boot probe..."
mount "$ROOT_PART" "$CI_MOUNT"

echo "Recording release build provenance..."
SOURCE_COMMIT="${VIBRALI_SOURCE_COMMIT:-}"
if [[ -z "$SOURCE_COMMIT" ]] && command -v git >/dev/null 2>&1; then
  SOURCE_COMMIT="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || true)"
fi
[[ -n "$SOURCE_COMMIT" ]] || SOURCE_COMMIT=unknown
DEBIAN_SUITE="$(awk -F= '$1 == "VERSION_CODENAME" {gsub(/"/, "", $2); print $2}' "$CI_MOUNT/etc/os-release")"
PROFILES="$(tr '\n' ',' < "$CI_MOUNT/etc/vibrali/profiles" | sed 's/,$//')"

{
  printf 'Package\tVersion\n'
  chroot "$CI_MOUNT" dpkg-query -W -f='${binary:Package}\t${Version}\n' | LC_ALL=C sort
} > "$PACKAGE_VERSIONS"

{
  printf 'source_commit=%s\n' "$SOURCE_COMMIT"
  printf 'debian_suite=%s\n' "$DEBIAN_SUITE"
  printf 'architecture=amd64\n'
  printf 'image_size=%s\n' "$SIZE"
  printf 'zstd_level=%s\n' "$ZSTD_LEVEL"
  printf 'profiles=%s\n' "$PROFILES"
  printf 'github_ref=%s\n' "${GITHUB_REF:-local}"
  printf 'github_run_id=%s\n' "${GITHUB_RUN_ID:-local}"
  printf '\n[build-input-sha256]\n'
  (
    cd "$ROOT"
    sha256sum packages/*.txt external-tools/manifest.txt \
      scripts/install-to-usb.sh scripts/build-release-images.sh
  )
  printf '\n[apt-sources]\n'
  cat "$CI_MOUNT/etc/apt/sources.list"
} > "$BUILD_INFO"

install -Dm0755 "$PROBE_SOURCE" "$CI_MOUNT/usr/local/sbin/vibrali-ci-probe"
install -Dm0644 "$PROBE_UNIT_SOURCE" "$CI_MOUNT/etc/systemd/system/vibrali-ci-probe.service"
mkdir -p "$CI_MOUNT/etc/systemd/system/graphical.target.wants"
ln -sfn /etc/systemd/system/vibrali-ci-probe.service \
  "$CI_MOUNT/etc/systemd/system/graphical.target.wants/vibrali-ci-probe.service"

echo "Regenerating initramfs and GRUB configuration before CI boot..."
chroot "$CI_MOUNT" update-initramfs -u -k all
chroot "$CI_MOUNT" update-grub

sync
umount "$CI_MOUNT"

echo "Creating CI-instrumented QEMU smoke image..."
qemu-img convert -p -f raw -O qcow2 -c "$RAW" "$CI_QCOW"

echo "Removing CI-only instrumentation..."
mount "$ROOT_PART" "$CI_MOUNT"
rm -f "$CI_MOUNT/etc/systemd/system/graphical.target.wants/vibrali-ci-probe.service"
rm -f "$CI_MOUNT/etc/systemd/system/vibrali-ci-probe.service"
rm -f "$CI_MOUNT/usr/local/sbin/vibrali-ci-probe"

if [[ -e "$CI_MOUNT/etc/systemd/system/graphical.target.wants/vibrali-ci-probe.service" ||
      -e "$CI_MOUNT/etc/systemd/system/vibrali-ci-probe.service" ||
      -e "$CI_MOUNT/usr/local/sbin/vibrali-ci-probe" ]]; then
  echo "Refusing to build public images with CI boot instrumentation present." >&2
  exit 1
fi

sync
umount "$CI_MOUNT"

echo "Creating clean QEMU release image..."
qemu-img convert -p -f raw -O qcow2 -c "$RAW" "$QCOW"
zstd -T0 "-$ZSTD_LEVEL" -f "$QCOW" -o "$VM"
rm -f "$QCOW"

LOCK_MOUNT="$CI_MOUNT"
mount "$ROOT_PART" "$LOCK_MOUNT"
chroot "$LOCK_MOUNT" usermod --lock vibrali
password_state="$(chroot "$LOCK_MOUNT" passwd -S vibrali | awk '{print $2}')"
case "$password_state" in
  L|LK) ;;
  *)
    echo "Refusing to publish USB image: vibrali account is not locked (state: $password_state)." >&2
    exit 1
    ;;
esac
: > "$LOCK_MOUNT/etc/machine-id"
rm -f "$LOCK_MOUNT/var/lib/dbus/machine-id"
sync
umount "$LOCK_MOUNT"

echo "Compressing locked USB image..."
zstd -T0 "-$ZSTD_LEVEL" -f "$RAW" -o "$USB"

sha256sum "$USB" "$VM" "$BUILD_INFO" "$PACKAGE_VERSIONS" | sed "s#$OUT/##" > "$OUT/SHA256SUMS"
rm -f "$RAW"

echo "Release images:"
ls -lh "$OUT"
echo "CI smoke image:"
ls -lh "$CI_QCOW"
