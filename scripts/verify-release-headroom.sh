#!/usr/bin/env bash
set -euo pipefail

DIST="${1:-dist}"
BUILD_INFO="$DIST/BUILD_INFO.txt"

fail() {
  echo "release headroom verification failed: $*" >&2
  exit 1
}

[[ -s "$BUILD_INFO" ]] || fail "missing BUILD_INFO.txt"

read_value() {
  local key="$1"
  awk -F= -v key="$key" '$1 == key {print $2; exit}' "$BUILD_INFO"
}

root_size="$(read_value root_size_bytes)"
root_used="$(read_value root_used_bytes)"
root_free="$(read_value root_free_bytes)"
min_free_gib="$(read_value min_release_free_gib)"

for pair in   "root_size_bytes:$root_size"   "root_used_bytes:$root_used"   "root_free_bytes:$root_free"   "min_release_free_gib:$min_free_gib"
do
  key="${pair%%:*}"
  value="${pair#*:}"
  [[ "$value" =~ ^[0-9]+$ ]] || fail "$key is missing or invalid"
done

(( min_free_gib >= 1 )) || fail "min_release_free_gib must be positive"
required_free=$((min_free_gib * 1024 * 1024 * 1024))
(( root_size > 0 )) || fail "root filesystem size is zero"
(( root_used <= root_size )) || fail "root usage exceeds filesystem size"
(( root_free >= required_free )) ||
  fail "root filesystem free space is below the recorded minimum"

echo "release root headroom: ok ($root_free bytes free; minimum ${min_free_gib} GiB)"
