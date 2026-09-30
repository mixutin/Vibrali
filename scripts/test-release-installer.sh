#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=site/install.sh
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


test_resumed_download() {
  local fixture="$TEST_TMP/resume"
  local work="$TEST_TMP/resume-work"
  local payload="$fixture/$IMAGE_NAME"

  mkdir -p "$fixture" "$work"
  printf 'vibrali-resumable-download-fixture-with-enough-bytes-to-split\n' > "$payload"
  write_manifest "$fixture"

  head -c 17 "$payload" > "$work/$IMAGE_NAME.partial"

  DOWNLOADED_IMAGE=""
  download_release "file://$fixture" "$work" "$IMAGE_NAME"

  cmp -s "$payload" "$DOWNLOADED_IMAGE" ||
    fail "interrupted direct download did not resume to the original payload"
  [[ ! -e "$work/$IMAGE_NAME.partial" ]] ||
    fail "partial download marker remained after successful resume"
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

for cmd in curl sha256sum awk split cmp; do
  command -v "$cmd" >/dev/null 2>&1 || fail "missing command: $cmd"
done

if [[ $# -gt 0 ]]; then
  command -v zstd >/dev/null 2>&1 || fail "missing command: zstd"
fi

test_release_tag_parser() {
  local tag

  tag="$(cat <<'JSON' | latest_release_tag_from_json
[
  {
    "tag_name": "v0.1.0-dev.1",
    "prerelease": true
  }
]
JSON
  )"

  [[ "$tag" == "v0.1.0-dev.1" ]] ||
    fail "latest release tag parser did not return the preview tag"
}

test_existing_install_still_requires_confirmation() {
  local fake_tty="$TEST_TMP/existing-install-confirmation"
  local output status

  printf 'NOT-VIBRALI\n' > "$fake_tty"

  lsblk() {
    if [[ "$*" == "-nr -o LABEL /dev/fake-vibrali" ]]; then
      printf 'VIBRALI_ROOT\n'
      return 0
    fi
    if [[ "$*" == "-d -o NAME,SIZE,MODEL,SERIAL,TRAN /dev/fake-vibrali" ]]; then
      printf 'NAME SIZE MODEL SERIAL TRAN\n'
      printf 'fake 64G TEST EXISTING usb\n'
      return 0
    fi
    return 1
  }

  set +e
  output="$(TTY="$fake_tty" confirm_target_erase /dev/fake-vibrali 2>&1)"
  status=$?
  set -e
  unset -f lsblk

  [[ $status -ne 0 ]] || fail "existing Vibrali target bypassed destructive confirmation"
  grep -q 'existing Vibrali installation was detected' <<<"$output" ||
    fail "existing Vibrali target did not show the replacement warning"
  grep -q 'Cancelled' <<<"$output" ||
    fail "existing Vibrali target did not cancel on incorrect confirmation"
}

test_piped_entrypoint() {
  local output

  output="$(
    sed 's/^  main "\$@"$/  printf "%s\\n" "piped-entrypoint-ok"/' "$ROOT/site/install.sh" |
      bash
  )"

  [[ "$output" == "piped-entrypoint-ok" ]] ||
    fail "piped installer entrypoint did not execute safely under set -u"
}

test_release_tag_parser
test_existing_install_still_requires_confirmation
test_piped_entrypoint
test_direct_download
test_split_download
test_resumed_download
test_bad_checksum

if [[ $# -gt 0 ]]; then
  test_release_contract "$1"
fi

echo "release installer smoke tests: ok"
