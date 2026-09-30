#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${1:-$ROOT/dist/.ci/vibrali-qemu-ci.qcow2}"
BOOT_TIMEOUT="${VIBRALI_QEMU_BOOT_TIMEOUT:-360}"
TMPDIR="$(mktemp -d)"
QCOW="$TMPDIR/vibrali-qemu-amd64.qcow2"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

fail() {
  echo "QEMU release smoke test failed: $*" >&2
  exit 1
}

for cmd in qemu-system-x86_64 qemu-img zstd timeout grep cp; do
  command -v "$cmd" >/dev/null 2>&1 || fail "missing command: $cmd"
done

[[ -s "$IMAGE" ]] || fail "missing QEMU release image: $IMAGE"

OVMF_CODE=""
OVMF_VARS=""
OVMF_CANDIDATES=(
  "/usr/share/OVMF/OVMF_CODE_4M.fd|/usr/share/OVMF/OVMF_VARS_4M.fd"
  "/usr/share/OVMF/OVMF_CODE.fd|/usr/share/OVMF/OVMF_VARS.fd"
  "/usr/share/edk2/ovmf/OVMF_CODE.fd|/usr/share/edk2/ovmf/OVMF_VARS.fd"
)

for pair in "${OVMF_CANDIDATES[@]}"; do
  IFS='|' read -r code vars <<< "$pair"
  if [[ -f "$code" && -f "$vars" ]]; then
    OVMF_CODE="$code"
    OVMF_VARS="$vars"
    break
  fi
done

[[ -n "$OVMF_CODE" ]] || fail "OVMF firmware was not found"

case "$IMAGE" in
  *.zst)
    echo "Decompressing QEMU smoke image..."
    zstd -d -f "$IMAGE" -o "$QCOW"
    ;;
  *.qcow2)
    QCOW="$IMAGE"
    ;;
  *)
    fail "unsupported image format: $IMAGE"
    ;;
esac

qemu-img check "$QCOW"

boot_once() {
  local expected_count="$1"
  local vars_copy="$TMPDIR/OVMF_VARS_${expected_count}.fd"
  local serial_log="$TMPDIR/serial-${expected_count}.log"
  local status
  local -a qemu_args

  cp "$OVMF_VARS" "$vars_copy"

  qemu_args=(
    -machine "q35,accel=tcg"
    -smp 2
    -m 3072
    -drive "if=pflash,format=raw,unit=0,readonly=on,file=$OVMF_CODE"
    -drive "if=pflash,format=raw,unit=1,file=$vars_copy"
    -drive "file=$QCOW,if=virtio,format=qcow2"
    -nic "user,model=virtio-net-pci"
    -smbios "type=1,serial=VIBRALI-CI"
    -boot "order=c"
    -serial "file:$serial_log"
    -monitor none
    -display none
    -no-reboot
  )

  echo "UEFI boot smoke test #$expected_count..."
  set +e
  timeout "$BOOT_TIMEOUT" qemu-system-x86_64 "${qemu_args[@]}"
  status=$?
  set -e

  if [[ $status -eq 124 ]]; then
    cat "$serial_log" >&2 || true
    fail "boot #$expected_count timed out after ${BOOT_TIMEOUT}s"
  fi

  if [[ $status -ne 0 ]]; then
    cat "$serial_log" >&2 || true
    fail "QEMU exited with status $status on boot #$expected_count"
  fi

  if grep -q 'VIBRALI_CI_BOOT_FAIL' "$serial_log"; then
    cat "$serial_log" >&2
    fail "guest probe reported a failed check on boot #$expected_count"
  fi

  if ! grep -q "VIBRALI_CI_BOOT_OK count=$expected_count failures=0" "$serial_log"; then
    cat "$serial_log" >&2
    fail "guest success marker missing for boot #$expected_count"
  fi

  if [[ $expected_count -eq 2 ]]; then
    if ! grep -q 'VIBRALI_CI_PASS writable-state-persisted' "$serial_log"; then
      cat "$serial_log" >&2
      fail "writable-state persistence was not verified"
    fi
    if ! grep -q 'VIBRALI_CI_PASS package-install-persisted' "$serial_log"; then
      cat "$serial_log" >&2
      fail "package database persistence was not verified"
    fi
    if ! grep -q 'VIBRALI_CI_PASS package-file-persisted' "$serial_log"; then
      cat "$serial_log" >&2
      fail "installed package files did not persist"
    fi
  fi
}

boot_once 1
boot_once 2

echo "QEMU UEFI boot and persistence smoke tests: ok"
