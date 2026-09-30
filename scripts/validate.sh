#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

required=(
  README.md
  ROADMAP.md
  SECURITY.md
  config/package-lists/core.list.chroot
  config/package-lists/pentest.list.chroot
  scripts/build.sh
)

for path in "${required[@]}"; do
  test -s "$path" || { echo "missing or empty: $path" >&2; exit 1; }
done

while IFS= read -r file; do bash -n "$file"; done < <(find scripts -type f -name '*.sh' -print)
while IFS= read -r file; do sh -n "$file"; done < <(find config/hooks -type f -print)

python3 - <<'PY'
from pathlib import Path
for path in Path("config/package-lists").glob("*.list.chroot"):
    packages = [x.strip() for x in path.read_text().splitlines() if x.strip()]
    if packages != sorted(set(packages)):
        raise SystemExit(f"{path}: package list must be sorted and unique")
print("package manifests: ok")
PY

echo "Vibrali repository validation passed."
