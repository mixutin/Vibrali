#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${1:-$ROOT/dist/.ci/vibrali-qemu-ci.qcow2}"
BOOT_TIMEOUT="${VIBRALI_QEMU_BOOT_TIMEOUT:-360}"
OVMF_CODE="/usr/share/OVMF/OVMF_CODE_4M.secboot.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS_4M.ms.fd"
TMPDIR="$(mktemp -d)"
QCOW="$IMAGE"
VARS_COPY="$TMPDIR/OVMF_VARS_4M.ms.fd"
SERIAL_LOG="$TMPDIR/serial.log"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

fail() {
  echo "QEMU Secure Boot smoke test failed: $*" >&2
  exit 1
}

for cmd in qemu-system-x86_64 qemu-img zstd timeout grep cp; do
  command -v "$cmd" >/dev/null 2>&1 || fail "missing command: $cmd"
done

[[ -s "$IMAGE" ]] || fail "missing QEMU release image: $IMAGE"
[[ -f "$OVMF_CODE" ]] || fail "Secure Boot OVMF code was not found: $OVMF_CODE"
[[ -f "$OVMF_VARS" ]] || fail "Microsoft-enrolled OVMF variables were not found: $OVMF_VARS"

case "$IMAGE" in
  *.zst)
    QCOW="$TMPDIR/vibrali-qemu-secure.qcow2"
    zstd -d -f "$IMAGE" -o "$QCOW"
    ;;
  *.qcow2) ;;
  *) fail "unsupported image format: $IMAGE" ;;
esac

qemu-img check "$QCOW"
cp "$OVMF_VARS" "$VARS_COPY"

qemu_args=(
  -machine "q35,smm=on,accel=tcg"
  -global "driver=cfi.pflash01,property=secure,value=on"
  -smp 2
  -m 3072
  -drive "if=pflash,format=raw,unit=0,readonly=on,file=$OVMF_CODE"
  -drive "if=pflash,format=raw,unit=1,file=$VARS_COPY"
  -drive "file=$QCOW,if=virtio,format=qcow2"
  -nic "user,model=virtio-net-pci"
  -smbios "type=1,serial=VIBRALI-CI-SECURE"
  -boot "order=c"
  -serial "file:$SERIAL_LOG"
  -monitor none
  -display none
  -no-reboot
)

echo "UEFI Secure Boot smoke test..."
set +e
timeout "$BOOT_TIMEOUT" qemu-system-x86_64 "${qemu_args[@]}"
status=$?
set -e

if [[ $status -eq 124 ]]; then
  cat "$SERIAL_LOG" >&2 || true
  fail "Secure Boot timed out after ${BOOT_TIMEOUT}s"
fi
if [[ $status -ne 0 ]]; then
  cat "$SERIAL_LOG" >&2 || true
  fail "QEMU exited with status $status"
fi
if grep -q 'VIBRALI_CI_BOOT_FAIL' "$SERIAL_LOG"; then
  cat "$SERIAL_LOG" >&2
  fail "guest probe reported a failed check"
fi
grep -q 'VIBRALI_CI_PASS secure-boot-enabled' "$SERIAL_LOG" || {
  cat "$SERIAL_LOG" >&2
  fail "guest did not prove UEFI Secure Boot was enabled"
}
grep -Eq 'VIBRALI_CI_BOOT_OK count=[0-9]+ failures=0' "$SERIAL_LOG" || {
  cat "$SERIAL_LOG" >&2
  fail "guest success marker missing"
}

echo "QEMU UEFI Secure Boot smoke test: ok"
