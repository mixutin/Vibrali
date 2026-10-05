#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${1:-$ROOT/dist-dev/vibrali-dev.qcow2}"
SIZE="${VIBRALI_DEV_VM_SIZE:-16G}"
PROFILES="${VIBRALI_DEV_VM_PROFILES:-none}"
PASSWORD="${VIBRALI_DEV_VM_PASSWORD:-vibrali}"
HOSTNAME="${VIBRALI_DEV_VM_HOSTNAME:-vibrali-dev}"
OUT_DIR="$(dirname "$OUTPUT")"
RAW="$OUT_DIR/.vibrali-dev.raw"
LOOP=""

[[ $EUID -eq 0 ]] || {
  echo "Run this builder as root." >&2
  exit 1
}

for cmd in truncate losetup qemu-img sync stat; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing command: $cmd" >&2
    exit 1
  }
done

owner="$(stat -c '%u:%g' "$ROOT")"
mkdir -p "$OUT_DIR"
rm -f "$RAW" "$OUTPUT"
truncate -s "$SIZE" "$RAW"
LOOP="$(losetup --find --show "$RAW")"

cleanup() {
  set +e
  sync
  if [[ -n "${LOOP:-}" ]]; then
    losetup -d "$LOOP" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "Building Vibrali development VM ($SIZE, profiles=$PROFILES)..."
VIBRALI_PASSWORD="$PASSWORD" "$ROOT/scripts/install-to-usb.sh" \
  --device "$LOOP" \
  --username vibrali \
  --hostname "$HOSTNAME" \
  --profiles "$PROFILES" \
  --yes-really-erase \
  --non-interactive

sync
losetup -d "$LOOP"
LOOP=""

echo "Converting raw disk to compressed QCOW2..."
qemu-img convert -p -f raw -O qcow2 -c "$RAW" "$OUTPUT"
rm -f "$RAW"
qemu-img check "$OUTPUT"
chown "$owner" "$OUTPUT"

echo
echo "Development VM ready: $OUTPUT"
qemu-img info "$OUTPUT"
echo "Initial login: vibrali / vibrali"
