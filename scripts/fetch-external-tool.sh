#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/external-tools/manifest.txt"

usage() {
  cat <<'EOF'
Usage:
  fetch-external-tool.sh TOOL [DESTINATION_DIRECTORY]

Downloads one pinned external Vibrali tool over HTTPS, verifies its exact SHA-256, and
prints the verified local file path.
EOF
}

[[ $# -ge 1 && $# -le 2 ]] || { usage >&2; exit 2; }
TOOL="$1"
DEST_DIR="${2:-${VIBRALI_EXTERNAL_CACHE:-/var/cache/vibrali/external}}"

[[ "$TOOL" =~ ^[a-z0-9][a-z0-9._-]*$ ]] || {
  echo "Invalid external tool name: $TOOL" >&2
  exit 2
}

line="$(awk -F'|' -v tool="$TOOL" '
  $0 !~ /^[[:space:]]*#/ && NF && $1 == tool { print; exit }
' "$MANIFEST")"

[[ -n "$line" ]] || {
  echo "Unknown external tool: $TOOL" >&2
  exit 2
}

IFS='|' read -r name version url expected_sha _license kind <<< "$line"

[[ "$kind" == "file" || "$kind" == "archive" ]] || {
  echo "Unsupported external tool kind for $name: $kind" >&2
  exit 1
}

mkdir -p "$DEST_DIR"
dest="$DEST_DIR/$name-$version"

verify_file() {
  local path="$1"
  printf '%s  %s\n' "$expected_sha" "$path" | sha256sum -c - >/dev/null 2>&1
}

if [[ -f "$dest" ]] && verify_file "$dest"; then
  printf '%s\n' "$dest"
  exit 0
fi

tmp="$(mktemp "$DEST_DIR/.${name}-${version}.XXXXXX")"
cleanup() {
  rm -f "$tmp"
}
trap cleanup EXIT

curl \
  --fail \
  --location \
  --silent \
  --show-error \
  --proto '=https' \
  --tlsv1.2 \
  "$url" \
  -o "$tmp"

if ! verify_file "$tmp"; then
  echo "SHA-256 verification failed for $name $version." >&2
  exit 1
fi

chmod 0644 "$tmp"
mv -f "$tmp" "$dest"
trap - EXIT

printf '%s\n' "$dest"
