#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${1:-$ROOT/dist}"
CHECKSUMS="$DIST/SHA256SUMS"
USB="$DIST/vibrali-usb-amd64.img.zst"
VM="$DIST/vibrali-qemu-amd64.qcow2.zst"
BUILD_INFO="$DIST/BUILD_INFO.txt"
PACKAGE_VERSIONS="$DIST/PACKAGE_VERSIONS.txt"
EXPECT_QEMU="${VIBRALI_EXPECT_QEMU:-1}"
TMPDIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

fail() {
  echo "release artifact verification failed: $*" >&2
  exit 1
}

for cmd in sha256sum zstd python3 dd stat sort awk sed grep head wc; do
  command -v "$cmd" >/dev/null 2>&1 || fail "missing command: $cmd"
done

[[ "$EXPECT_QEMU" == "0" || "$EXPECT_QEMU" == "1" ]] ||
  fail "VIBRALI_EXPECT_QEMU must be 0 or 1"

required_paths=("$CHECKSUMS" "$USB" "$BUILD_INFO" "$PACKAGE_VERSIONS")
expected_artifacts=(BUILD_INFO.txt PACKAGE_VERSIONS.txt vibrali-usb-amd64.img.zst)
if [[ "$EXPECT_QEMU" == "1" ]]; then
  required_paths+=("$VM")
  expected_artifacts+=(vibrali-qemu-amd64.qcow2.zst)
fi
for path in "${required_paths[@]}"; do
  [[ -s "$path" ]] || fail "missing or empty artifact: $path"
done

expected_names="$(printf '%s\n' "${expected_artifacts[@]}" | sort)"
actual_names="$(
  awk '{print $2}' "$CHECKSUMS" |
    sed 's/^\*//' |
    sort
)"
[[ "$actual_names" == "$expected_names" ]] ||
  fail "SHA256SUMS does not contain exactly the expected release images"

(
  cd "$DIST"
  sha256sum -c SHA256SUMS
)

zstd -t "$USB"
if [[ "$EXPECT_QEMU" == "1" ]]; then
  zstd -t "$VM"
fi

grep -Eq '^source_commit=([0-9a-f]{40}|unknown)$' "$BUILD_INFO" ||
  fail "BUILD_INFO.txt is missing a valid source commit"
grep -Eq '^debian_suite=[A-Za-z0-9._-]+$' "$BUILD_INFO" ||
  fail "BUILD_INFO.txt is missing the Debian suite"
grep -Fq 'packages/base.txt' "$BUILD_INFO" ||
  fail "BUILD_INFO.txt is missing package manifest hashes"
grep -Fq 'external-tools/manifest.txt' "$BUILD_INFO" ||
  fail "BUILD_INFO.txt is missing external-tool manifest provenance"
head -n 1 "$PACKAGE_VERSIONS" | awk -F '\t' '$1 == "Package" && $2 == "Version" {ok=1} END {exit !ok}' ||
  fail "PACKAGE_VERSIONS.txt is missing its header"
[[ "$(wc -l < "$PACKAGE_VERSIONS")" -gt 10 ]] ||
  fail "PACKAGE_VERSIONS.txt is unexpectedly small"

extract_prefix() {
  local input="$1"
  local output="$2"
  local mib="$3"
  local expected_bytes=$((mib * 1024 * 1024))

  set +o pipefail
  zstd -dc -- "$input" 2>/dev/null |
    dd of="$output" bs=1M count="$mib" iflag=fullblock status=none
  set -o pipefail

  local actual_bytes
  actual_bytes="$(stat -c %s "$output")"
  [[ "$actual_bytes" -eq "$expected_bytes" ]] ||
    fail "could not extract $mib MiB prefix from $input"
}

USB_PREFIX="$TMPDIR/usb-prefix.img"
VM_PREFIX="$TMPDIR/qcow-prefix.bin"

# The current layout places the ext4 root just after the 512 MiB EFI partition.
# 520 MiB is enough to include the GPT, EFI FAT32 boot sector and root ext4
# superblock without decompressing the whole USB image.
extract_prefix "$USB" "$USB_PREFIX" 520
python_args=("$USB_PREFIX")
if [[ "$EXPECT_QEMU" == "1" ]]; then
  extract_prefix "$VM" "$VM_PREFIX" 1
  python_args+=("$VM_PREFIX")
fi

python3 - "${python_args[@]}" <<'PY'
from pathlib import Path
import struct
import sys

usb = Path(sys.argv[1]).read_bytes()
qcow = Path(sys.argv[2]).read_bytes() if len(sys.argv) > 2 else None
sector = 512

def fail(message: str) -> None:
    raise SystemExit(f"release artifact verification failed: {message}")

if usb[510:512] != b"\x55\xaa":
    fail("USB image is missing the protective MBR signature")

if usb[sector:sector + 8] != b"EFI PART":
    fail("USB image is missing the primary GPT header")

header = sector
entry_lba = struct.unpack_from("<Q", usb, header + 72)[0]
entry_count = struct.unpack_from("<I", usb, header + 80)[0]
entry_size = struct.unpack_from("<I", usb, header + 84)[0]

if entry_size < 128 or entry_count < 3:
    fail("USB image GPT partition table is malformed")

partitions: dict[str, tuple[int, int]] = {}
for index in range(min(entry_count, 16)):
    offset = entry_lba * sector + index * entry_size
    if usb[offset:offset + 16] == b"\x00" * 16:
        continue

    first_lba, last_lba = struct.unpack_from("<QQ", usb, offset + 32)
    raw_name = usb[offset + 56:offset + entry_size]
    name = raw_name.decode("utf-16le", errors="ignore").split("\x00", 1)[0]
    partitions[name] = (first_lba, last_lba)

for name in ("BIOS_BOOT", "VIBRALI_EFI", "VIBRALI_ROOT"):
    if name not in partitions:
        fail(f"USB image is missing GPT partition {name}")

ordered = [partitions[name] for name in ("BIOS_BOOT", "VIBRALI_EFI", "VIBRALI_ROOT")]
for (first, last), (next_first, _) in zip(ordered, ordered[1:]):
    if first > last or last >= next_first:
        fail("USB image partitions overlap or have invalid bounds")

efi_offset = partitions["VIBRALI_EFI"][0] * sector
if usb[efi_offset + 82:efi_offset + 90] != b"FAT32   ":
    fail("EFI partition does not contain a FAT32 filesystem signature")

root_offset = partitions["VIBRALI_ROOT"][0] * sector
superblock = root_offset + 1024
if superblock + 0x88 > len(usb):
    fail("USB prefix is too short to inspect the ext4 superblock")

ext4_magic = struct.unpack_from("<H", usb, superblock + 0x38)[0]
if ext4_magic != 0xEF53:
    fail("root partition does not contain an ext4 superblock")

label = usb[superblock + 0x78:superblock + 0x88].split(b"\x00", 1)[0].decode(
    "ascii", errors="ignore"
)
if label != "VIBRALI_ROOT":
    fail(f"unexpected root filesystem label: {label!r}")

if qcow is not None:
    if qcow[:4] != b"QFI\xfb":
        fail("QEMU artifact is not a QCOW2 image")

    version = struct.unpack_from(">I", qcow, 4)[0]
    if version not in (2, 3):
        fail(f"unsupported QCOW2 version: {version}")

print("release image structure: ok")
PY

echo "release artifacts: ok"
