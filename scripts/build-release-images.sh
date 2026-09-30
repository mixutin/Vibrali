#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/dist}"
SIZE="${VIBRALI_IMAGE_SIZE:-12G}"
RAW="$OUT/vibrali-amd64.raw"
USB="$OUT/vibrali-usb-amd64.img.zst"
VM="$OUT/vibrali-qemu-amd64.qcow2.zst"
QCOW="$OUT/vibrali-qemu-amd64.qcow2"

[[ $EUID -eq 0 ]] || {
  echo "Run this builder as root." >&2
  exit 1
}

mkdir -p "$OUT"
rm -f "$RAW" "$USB" "$VM" "$QCOW" "$OUT/SHA256SUMS"

for cmd in truncate losetup qemu-img zstd sha256sum; do
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
  losetup -d "${LOOP:-}" 2>/dev/null || true
}
trap cleanup EXIT

echo "Building Vibrali portable disk on $LOOP..."
VIBRALI_PASSWORD=vibrali "$ROOT/scripts/install-to-usb.sh" \
  --device "$LOOP" \
  --username vibrali \
  --hostname vibrali \
  --profiles all \
  --yes-really-erase \
  --non-interactive

sync
echo "Creating QEMU image..."
qemu-img convert -p -f raw -O qcow2 -c "$RAW" "$QCOW"
zstd -T0 -19 -f "$QCOW" -o "$VM"
rm -f "$QCOW"

ROOT_PART="${LOOP}p3"
LOCK_MOUNT=/mnt/vibrali-release-lock
mkdir -p "$LOCK_MOUNT"
mount "$ROOT_PART" "$LOCK_MOUNT"
chroot "$LOCK_MOUNT" usermod --lock vibrali
: > "$LOCK_MOUNT/etc/machine-id"
rm -f "$LOCK_MOUNT/var/lib/dbus/machine-id"
umount "$LOCK_MOUNT"

echo "Compressing locked USB image..."
zstd -T0 -19 -f "$RAW" -o "$USB"

sha256sum "$USB" "$VM" | sed "s#$OUT/##" > "$OUT/SHA256SUMS"
rm -f "$RAW"

echo "Release images:"
ls -lh "$OUT"
