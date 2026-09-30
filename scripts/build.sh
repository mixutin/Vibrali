#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/.work/live"
OUT="$ROOT/build"

command -v lb >/dev/null 2>&1 || {
  echo "live-build is required. See docs/BUILDING.md" >&2
  exit 1
}

mkdir -p "$WORK" "$OUT"
rsync -a --delete --exclude .git --exclude .work --exclude build "$ROOT/" "$WORK/"

cd "$WORK"
rsync -a config/rootfs/ config/includes.chroot/
lb clean --purge || true
lb config   --architectures amd64   --distribution trixie   --archive-areas "main contrib non-free-firmware"   --binary-images iso-hybrid   --bootappend-live "boot=live components persistence quiet splash"   --debian-installer none   --iso-application "Vibrali"   --iso-publisher "Vibrali Project"   --iso-volume "VIBRALI"

lb build

find . -maxdepth 1 -type f -name '*.iso' -exec cp -v {} "$OUT/" \;
sha256sum "$OUT"/*.iso > "$OUT/SHA256SUMS"
echo "Build complete: $OUT"
