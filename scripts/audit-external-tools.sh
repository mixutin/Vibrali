#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/external-tools/manifest.txt"

command -v curl >/dev/null 2>&1 || { echo "Missing required command: curl" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Missing required command: python3" >&2; exit 1; }

normalize_version() {
  local value="$1"
  value="${value#v}"
  value="${value#V}"
  printf '%s\n' "$value"
}

github_get() {
  local url="$1"
  local -a args=(
    --fail
    --silent
    --show-error
    --location
    -H "Accept: application/vnd.github+json"
    -H "User-Agent: Vibrali-external-tool-audit"
    -H "X-GitHub-Api-Version: 2022-11-28"
  )

  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi

  curl "${args[@]}" "$url"
}

latest_from_source() {
  local source="$1"
  local provider repo json

  provider="${source%%:*}"
  repo="${source#*:}"

  case "$provider" in
    github-release)
      json="$(github_get "https://api.github.com/repos/$repo/releases/latest")"
      python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])' <<<"$json"
      ;;
    github-tag)
      json="$(github_get "https://api.github.com/repos/$repo/tags?per_page=1")"
      python3 -c 'import json,sys; data=json.load(sys.stdin); print(data[0]["name"] if data else "")' <<<"$json"
      ;;
    *)
      echo "Unsupported update source: $source" >&2
      return 2
      ;;
  esac
}

outdated=0
errors=0
checked=0

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue

  IFS='|' read -r name version _url _sha _license _kind update_source extra <<< "$line"

  if [[ -n "${extra:-}" ]]; then
    echo "$name: malformed manifest row" >&2
    errors=$((errors + 1))
    continue
  fi

  if [[ "$update_source" == "none" ]]; then
    echo "$name: update audit disabled"
    continue
  fi

  checked=$((checked + 1))
  if ! latest="$(latest_from_source "$update_source")"; then
    echo "$name: could not resolve latest upstream version from $update_source" >&2
    errors=$((errors + 1))
    continue
  fi

  if [[ -z "$latest" ]]; then
    echo "$name: upstream returned no version for $update_source" >&2
    errors=$((errors + 1))
    continue
  fi

  pinned_normalized="$(normalize_version "$version")"
  latest_normalized="$(normalize_version "$latest")"

  if [[ "$pinned_normalized" == "$latest_normalized" ]]; then
    echo "$name: current ($version)"
  else
    echo "$name: UPDATE AVAILABLE (pinned $version, upstream $latest)"
    outdated=$((outdated + 1))
  fi
done < "$MANIFEST"

if (( errors > 0 )); then
  echo "external tool audit failed: $errors source error(s)" >&2
  exit 1
fi

if (( outdated > 0 )); then
  echo "external tool audit found $outdated outdated pin(s)" >&2
  exit 3
fi

echo "external tool audit: ok ($checked upstream source(s) checked)"
