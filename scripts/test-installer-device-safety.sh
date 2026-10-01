#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT/scripts/install-to-usb.sh"
TMPDIR="$(mktemp -d)"
BIG_IMAGE="$TMPDIR/vibrali-big.img"
MID_IMAGE="$TMPDIR/vibrali-mid.img"
SMALL_IMAGE="$TMPDIR/vibrali-small.img"
BIG_LOOP=""
MID_LOOP=""
SMALL_LOOP=""

cleanup() {
  set +e
  [[ -z "$BIG_LOOP" ]] || losetup -d "$BIG_LOOP" 2>/dev/null || true
  [[ -z "$MID_LOOP" ]] || losetup -d "$MID_LOOP" 2>/dev/null || true
  [[ -z "$SMALL_LOOP" ]] || losetup -d "$SMALL_LOOP" 2>/dev/null || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

fail() {
  echo "installer device-safety test failed: $*" >&2
  exit 1
}

[[ $EUID -eq 0 ]] || fail "run this test as root"

for cmd in losetup truncate dd sha256sum; do
  command -v "$cmd" >/dev/null 2>&1 || fail "missing command: $cmd"
done

truncate -s 16G "$BIG_IMAGE"
printf 'VIBRALI-SAFETY-SENTINEL\n' | dd of="$BIG_IMAGE" conv=notrunc status=none
BIG_LOOP="$(losetup --find --show "$BIG_IMAGE")"

before_hash="$(dd if="$BIG_LOOP" bs=1M count=1 status=none | sha256sum | awk '{print $1}')"

dry_output="$("$INSTALLER" --device "$BIG_LOOP" --profiles none --dry-run 2>&1)"
grep -q 'DRY RUN' <<<"$dry_output" || fail "dry-run banner was not shown"
grep -q 'Dry run complete' <<<"$dry_output" || fail "dry-run did not complete"

after_hash="$(dd if="$BIG_LOOP" bs=1M count=1 status=none | sha256sum | awk '{print $1}')"
[[ "$before_hash" == "$after_hash" ]] || fail "dry-run changed the target device"

truncate -s 16G "$MID_IMAGE"
MID_LOOP="$(losetup --find --show "$MID_IMAGE")"

set +e
full_output="$("$INSTALLER" --device "$MID_LOOP" --profiles all --dry-run 2>&1)"
full_status=$?
set -e
[[ $full_status -ne 0 ]] || fail "undersized full-profile target unexpectedly passed preflight"
grep -q 'full Vibrali profile set requires at least 24 GiB' <<<"$full_output" ||
  fail "full-profile capacity error did not show the expected requirement"

truncate -s 8G "$SMALL_IMAGE"
SMALL_LOOP="$(losetup --find --show "$SMALL_IMAGE")"

set +e
small_output="$("$INSTALLER" --device "$SMALL_LOOP" --profiles none --dry-run 2>&1)"
small_status=$?
set -e
[[ $small_status -ne 0 ]] || fail "undersized target unexpectedly passed preflight"
grep -q 'Target is too small' <<<"$small_output" || fail "undersized target did not show the expected error"

set +e
confirm_output="$("$INSTALLER" --device "$BIG_LOOP" --profiles none --non-interactive 2>&1)"
confirm_status=$?
set -e
[[ $confirm_status -ne 0 ]] || fail "install without --yes-really-erase unexpectedly succeeded"
grep -q 'Refusing destructive install without --yes-really-erase' <<<"$confirm_output" ||
  fail "missing destructive-confirmation refusal"

confirm_hash="$(dd if="$BIG_LOOP" bs=1M count=1 status=none | sha256sum | awk '{print $1}')"
[[ "$before_hash" == "$confirm_hash" ]] || fail "confirmation refusal changed the target device"

echo "installer device-safety tests: ok"
