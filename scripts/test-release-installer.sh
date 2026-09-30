#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../site/install.sh
source "$ROOT/site/install.sh"

TEST_TMP="$(mktemp -d)"
trap 'rm -rf "$TEST_TMP"' EXIT

fail() {
  echo "release installer smoke test failed: $*" >&2
  exit 1
}

write_manifest() {
  local dir="$1"
  (
    cd "$dir"
    sha256sum "$IMAGE_NAME" > SHA256SUMS
  )
}

test_direct_download() {
  local fixture="$TEST_TMP/direct"
  local work="$TEST_TMP/direct-work"

  mkdir -p "$fixture" "$work"
  printf 'vibrali-direct-release-fixture\n' > "$fixture/$IMAGE_NAME"
  write_manifest "$fixture"

  DOWNLOADED_IMAGE=""
  download_release "file://$fixture" "$work" "$IMAGE_NAME"

  [[ "$DOWNLOADED_IMAGE" == "$work/$IMAGE_NAME" ]] ||
    fail "direct download returned an unexpected path"
  cmp -s "$fixture/$IMAGE_NAME" "$DOWNLOADED_IMAGE" ||
    fail "direct download changed the payload"
}

test_split_download() {
  local source_dir="$TEST_TMP/split-source"
  local fixture="$TEST_TMP/split"
  local work="$TEST_TMP/split-work"
  local payload="$source_dir/$IMAGE_NAME"
  local digest

  mkdir -p "$source_dir" "$fixture" "$work"
  printf 'vibrali-split-release-fixture-with-several-parts\n' > "$payload"
  digest="$(sha256sum "$payload" | awk '{print $1}')"
  printf '%s  %s\n' "$digest" "$IMAGE_NAME" > "$fixture/SHA256SUMS"
  split -b 9 -d -a 2 "$payload" "$fixture/$IMAGE_NAME.part-"

  DOWNLOADED_IMAGE=""
  download_release "file://$fixture" "$work" "$IMAGE_NAME"

  cmp -s "$payload" "$DOWNLOADED_IMAGE" ||
    fail "split release was not reconstructed byte-for-byte"
}

test_bad_checksum() {
  local fixture="$TEST_TMP/bad-checksum"
  local work="$TEST_TMP/bad-checksum-work"

  mkdir -p "$fixture" "$work"
  printf 'vibrali-corrupt-release-fixture\n' > "$fixture/$IMAGE_NAME"
  printf '%064d  %s\n' 0 "$IMAGE_NAME" > "$fixture/SHA256SUMS"

  if (
    DOWNLOADED_IMAGE=""
    download_release "file://$fixture" "$work" "$IMAGE_NAME"
  ); then
    fail "checksum mismatch unexpectedly succeeded"
  fi
}

test_release_contract() {
  local release_dir="$1"
  local checksums="$release_dir/SHA256SUMS"
  local image="$release_dir/$IMAGE_NAME"
  local expected actual

  [[ -s "$checksums" ]] || fail "release SHA256SUMS is missing"
  [[ -s "$image" ]] || fail "release USB image is missing"

  expected="$(awk -v f="$IMAGE_NAME" '$2 == f {print $1}' "$checksums")"
  [[ -n "$expected" ]] || fail "release manifest does not name $IMAGE_NAME"

  actual="$(sha256sum "$image" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || fail "release USB image does not match SHA256SUMS"

  zstd -t "$image" >/dev/null
  echo "release installer artifact contract: ok"
}

for cmd in curl sha256sum awk split cmp zstd; do
  command -v "$cmd" >/dev/null 2>&1 || fail "missing command: $cmd"
done

test_direct_download
test_split_download
test_bad_checksum

if [[ $# -gt 0 ]]; then
  test_release_contract "$1"
fi

echo "release installer smoke tests: ok"
