#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${VIBRALI_RESCUE_WORKDIR:-$ROOT/.rescue-build}"
OUT="${1:-$ROOT/dist}"
STAGE="$WORK/config/includes.chroot/usr/share/vibrali-source"

[[ $EUID -eq 0 ]] || {
  echo "Run this builder as root." >&2
  exit 1
}

for cmd in lb rsync; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing command: $cmd" >&2
    exit 1
  }
done

rm -rf "$WORK"
mkdir -p "$WORK" "$OUT"
cp -a "$ROOT/rescue/config" "$WORK/config"

mkdir -p "$STAGE"
rsync -a "$ROOT/scripts/" "$STAGE/scripts/"
rsync -a "$ROOT/config/" "$STAGE/config/"
rsync -a "$ROOT/packages/" "$STAGE/packages/"
rsync -a "$ROOT/external-tools/" "$STAGE/external-tools/"
rsync -a "$ROOT/assets/" "$STAGE/assets/"

chmod 0755 "$WORK/config/includes.chroot/usr/local/bin/vibrali-rescue-install"
chmod 0755 "$WORK/config/includes.chroot/etc/skel/Desktop/vibrali-install.desktop"

(
  cd "$WORK"
  lb config \
    --mode debian \
    --distribution trixie \
    --architectures amd64 \
    --linux-flavours amd64 \
    --binary-images iso-hybrid \
    --debian-installer none \
    --security false \
    --archive-areas "main contrib non-free-firmware" \
    --bootappend-live "boot=live components username=vibrali hostname=vibrali-rescue"
  lb build
)

ISO="$(find "$WORK" -maxdepth 1 -type f -name 'live-image-amd64.hybrid.iso' -print -quit)"
[[ -n "$ISO" && -s "$ISO" ]] || {
  echo "Rescue ISO build did not produce the expected hybrid ISO." >&2
  exit 1
}

install -m0644 "$ISO" "$OUT/vibrali-rescue-amd64.iso"
sha256sum "$OUT/vibrali-rescue-amd64.iso" > "$OUT/vibrali-rescue-amd64.iso.sha256"

echo "Rescue ISO:"
ls -lh "$OUT/vibrali-rescue-amd64.iso" "$OUT/vibrali-rescue-amd64.iso.sha256"
