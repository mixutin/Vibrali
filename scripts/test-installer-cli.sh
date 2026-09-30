#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT/scripts/install-to-usb.sh"

fail() {
  echo "installer CLI test failed: $*" >&2
  exit 1
}

help_output="$("$INSTALLER" --help)"
grep -q -- '--profiles LIST' <<<"$help_output" || fail "missing --profiles help"
grep -q -- '--list-profiles' <<<"$help_output" || fail "missing --list-profiles help"
grep -q -- '--dry-run' <<<"$help_output" || fail "missing --dry-run help"
grep -q -- '--encrypt-root' <<<"$help_output" || fail "missing --encrypt-root help"

expected_profiles="$(
  for path in "$ROOT"/packages/*.txt; do
    name="${path##*/}"
    name="${name%.txt}"
    case "$name" in
      base|desktop) continue ;;
    esac
    printf '%s\n' "$name"
  done | LC_ALL=C sort
)"
actual_profiles="$("$INSTALLER" --list-profiles)"
[[ "$actual_profiles" == "$expected_profiles" ]] || fail "profile discovery mismatch"

set +e
missing_profile_output="$("$INSTALLER" --profiles 2>&1)"
missing_profile_status=$?
set -e
[[ $missing_profile_status -eq 2 ]] || fail "--profiles without a value should exit 2"
grep -q -- '--profiles requires a value' <<<"$missing_profile_output" || fail "missing value error not shown"

set +e
core_profile_output="$("$INSTALLER" --profiles base --device /dev/null --dry-run 2>&1)"
core_profile_status=$?
set -e
[[ $core_profile_status -eq 2 ]] || fail "mandatory core profile should exit 2"
grep -q 'mandatory core' <<<"$core_profile_output" || fail "mandatory core error not shown"

set +e
unknown_profile_output="$("$INSTALLER" --profiles definitely-not-a-profile --device /dev/null --dry-run 2>&1)"
unknown_profile_status=$?
set -e
[[ $unknown_profile_status -eq 2 ]] || fail "unknown profile should exit 2"
grep -q 'Unknown optional profile' <<<"$unknown_profile_output" || fail "unknown profile error not shown"

set +e
unknown_option_output="$("$INSTALLER" --definitely-not-an-option 2>&1)"
unknown_option_status=$?
set -e
[[ $unknown_option_status -eq 2 ]] || fail "unknown option should exit 2"
grep -q 'Unknown option' <<<"$unknown_option_output" || fail "unknown option error not shown"

echo "installer CLI tests: ok"
