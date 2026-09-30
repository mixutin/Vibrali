#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${1:-$(find "$ROOT/build" -maxdepth 1 -name '*.iso' -print -quit 2>/dev/null || true)}"

if [[ -z "$ISO" || ! -f "$ISO" ]]; then
  echo "No ISO found. Run ./scripts/build.sh first." >&2
  exit 1
fi

command -v qemu-system-x86_64 >/dev/null 2>&1 || {
  echo "qemu-system-x86_64 is required." >&2
  exit 1
}

exec qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cpu host -boot d -cdrom "$ISO" -nic user,model=virtio-net-pci
