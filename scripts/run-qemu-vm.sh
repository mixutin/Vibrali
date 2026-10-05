#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${1:-$ROOT/dist/vibrali-qemu-amd64.qcow2}"
WIDTH="${VIBRALI_VM_WIDTH:-1920}"
HEIGHT="${VIBRALI_VM_HEIGHT:-1080}"
RAM_MB="${VIBRALI_VM_RAM_MB:-8192}"
CPUS="${VIBRALI_VM_CPUS:-4}"
SSH_PORT="${VIBRALI_VM_SSH_PORT:-2222}"
SPICE_MODE="${VIBRALI_VM_SPICE:-auto}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/vibrali-vm"

for value in "$WIDTH" "$HEIGHT" "$RAM_MB" "$CPUS" "$SSH_PORT"; do
  [[ "$value" =~ ^[0-9]+$ ]] || {
    echo "VM display/resource values must be positive integers." >&2
    exit 2
  }
done

[[ -s "$IMAGE" ]] || {
  echo "Missing QEMU image: $IMAGE" >&2
  exit 1
}

for cmd in qemu-system-x86_64 cp mkdir; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing command: $cmd" >&2
    exit 1
  }
done

OVMF_CODE=""
OVMF_VARS_TEMPLATE=""
for pair in   "/usr/share/OVMF/OVMF_CODE_4M.fd|/usr/share/OVMF/OVMF_VARS_4M.fd"   "/usr/share/OVMF/OVMF_CODE.fd|/usr/share/OVMF/OVMF_VARS.fd"   "/usr/share/edk2/ovmf/OVMF_CODE.fd|/usr/share/edk2/ovmf/OVMF_VARS.fd"
do
  IFS='|' read -r code vars <<< "$pair"
  if [[ -s "$code" && -s "$vars" ]]; then
    OVMF_CODE="$code"
    OVMF_VARS_TEMPLATE="$vars"
    break
  fi
done

[[ -n "$OVMF_CODE" ]] || {
  echo "OVMF firmware was not found." >&2
  exit 1
}

mkdir -p "$STATE_DIR"
OVMF_VARS="$STATE_DIR/OVMF_VARS.fd"
[[ -s "$OVMF_VARS" ]] || cp "$OVMF_VARS_TEMPLATE" "$OVMF_VARS"

if [[ -r /dev/kvm && -w /dev/kvm ]]; then
  machine="q35,accel=kvm"
  cpu="host"
else
  machine="q35,accel=tcg"
  cpu="max"
  echo "Warning: /dev/kvm is unavailable; falling back to slower TCG emulation." >&2
fi

qemu_args=(
  -name "Vibrali VM"
  -machine "$machine"
  -cpu "$cpu"
  -smp "$CPUS"
  -m "$RAM_MB"
  -drive "if=pflash,format=raw,unit=0,readonly=on,file=$OVMF_CODE"
  -drive "if=pflash,format=raw,unit=1,file=$OVMF_VARS"
  -drive "file=$IMAGE,if=virtio,format=qcow2,cache=writeback,discard=unmap"
  -device "virtio-vga,xres=$WIDTH,yres=$HEIGHT"
  -device "qemu-xhci,id=xhci"
  -device "usb-tablet,bus=xhci.0"
  -nic "user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22"
  -boot "order=c,menu=on"
)

use_spice=0
case "$SPICE_MODE" in
  1|on|yes) use_spice=1 ;;
  0|off|no) use_spice=0 ;;
  auto)
    command -v remote-viewer >/dev/null 2>&1 && use_spice=1
    ;;
  *)
    echo "VIBRALI_VM_SPICE must be auto, on/1, or off/0." >&2
    exit 2
    ;;
esac

if [[ "$use_spice" -eq 1 ]]; then
  command -v remote-viewer >/dev/null 2>&1 || {
    echo "remote-viewer is required for SPICE mode." >&2
    exit 1
  }

  SPICE_SOCKET="$STATE_DIR/spice.sock"
  rm -f "$SPICE_SOCKET"
  qemu-system-x86_64 "${qemu_args[@]}"     -display none     -spice "unix=on,addr=$SPICE_SOCKET,disable-ticketing=on"     -device virtio-serial-pci     -chardev spicevmc,id=vdagent,name=vdagent     -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 &
  qemu_pid=$!

  cleanup() {
    set +e
    kill "$qemu_pid" 2>/dev/null || true
    wait "$qemu_pid" 2>/dev/null || true
    rm -f "$SPICE_SOCKET"
  }
  trap cleanup EXIT INT TERM

  for _ in $(seq 1 50); do
    [[ -S "$SPICE_SOCKET" ]] && break
    kill -0 "$qemu_pid" 2>/dev/null || {
      wait "$qemu_pid"
      exit $?
    }
    sleep 0.1
  done

  [[ -S "$SPICE_SOCKET" ]] || {
    echo "SPICE socket did not appear." >&2
    exit 1
  }

  remote-viewer "spice+unix://$SPICE_SOCKET"
  wait "$qemu_pid"
else
  exec qemu-system-x86_64 "${qemu_args[@]}" -display "gtk,zoom-to-fit=on"
fi
