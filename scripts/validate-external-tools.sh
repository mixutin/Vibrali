#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/external-tools/manifest.txt"

[[ -s "$MANIFEST" ]] || {
  echo "external tool manifest is missing or empty: $MANIFEST" >&2
  exit 1
}

declare -A seen=()
count=0
line_no=0

while IFS= read -r line || [[ -n "$line" ]]; do
  line_no=$((line_no + 1))
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue

  IFS='|' read -r name version url sha license kind update_source extra <<< "$line"

  [[ -z "${extra:-}" ]] || { echo "manifest line $line_no: too many fields" >&2; exit 1; }
  [[ "$name" =~ ^[a-z0-9][a-z0-9._-]*$ ]] || { echo "manifest line $line_no: invalid name" >&2; exit 1; }
  [[ "$version" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] || { echo "manifest line $line_no: invalid version" >&2; exit 1; }
  [[ "$url" == https://* && "$url" != *[[:space:]]* ]] || { echo "manifest line $line_no: URL must be HTTPS" >&2; exit 1; }
  [[ "$sha" =~ ^[0-9a-f]{64}$ ]] || { echo "manifest line $line_no: invalid SHA-256" >&2; exit 1; }
  [[ -n "$license" && "$license" != *[[:space:]]* ]] || { echo "manifest line $line_no: missing/invalid license" >&2; exit 1; }
  [[ "$kind" == "file" || "$kind" == "archive" ]] || { echo "manifest line $line_no: invalid kind" >&2; exit 1; }
  [[ "$update_source" == "none" || "$update_source" =~ ^github-(release|tag):[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || {
    echo "manifest line $line_no: invalid update source" >&2
    exit 1
  }
  [[ -z "${seen[$name]:-}" ]] || { echo "manifest line $line_no: duplicate tool $name" >&2; exit 1; }

  seen["$name"]=1
  count=$((count + 1))
done < "$MANIFEST"

(( count > 0 )) || { echo "external tool manifest has no tool entries" >&2; exit 1; }

echo "external tool manifest: ok ($count pinned tool(s))"
