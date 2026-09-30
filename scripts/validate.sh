#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

required=(
  README.md
  ROADMAP.md
  SECURITY.md
  docs/ARCHITECTURE.md
  docs/USB_INSTALL.md
  packages/base.txt
  packages/desktop.txt
  packages/network.txt
  scripts/install-to-usb.sh
  scripts/build-release-images.sh
  site/index.html
  site/style.css
  site/install.sh
  config/rootfs/etc/os-release
  assets/brand/vibrali-logo.png
  assets/brand/vibrali-wallpaper-default.png
)

for path in "${required[@]}"; do
  test -s "$path" || { echo "missing or empty: $path" >&2; exit 1; }
done

while IFS= read -r file; do
  bash -n "$file"
done < <(find scripts -type f -name '*.sh' -print)

bash -n site/install.sh

while IFS= read -r file; do
  sh -n "$file"
done < <(find config/hooks -type f -print)

python3 - <<'PY'
from pathlib import Path
paths = list(Path("packages").glob("*.txt"))
paths += list(Path("config/package-lists").glob("*.list.chroot"))
for path in paths:
    packages = [
        line.strip()
        for line in path.read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if packages != sorted(set(packages)):
        raise SystemExit(f"{path}: package list must be sorted and unique")
print("package manifests: ok")
PY

diff -u \
  <(
    for path in packages/*.txt; do
      name="${path##*/}"
      name="${name%.txt}"
      case "$name" in
        base|desktop) continue ;;
      esac
      printf '%s\n' "$name"
    done | LC_ALL=C sort
  ) \
  <(./scripts/install-to-usb.sh --list-profiles)

grep -q -- '--profiles LIST' <(./scripts/install-to-usb.sh --help)
grep -q -- '--dry-run' <(./scripts/install-to-usb.sh --help)
bash ./scripts/test-installer-cli.sh

echo "Vibrali repository validation passed."
