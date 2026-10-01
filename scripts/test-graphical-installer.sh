#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin" "$TMP/repo/scripts"
cp "$ROOT/scripts/vibrali-installer-gui.sh" "$TMP/repo/scripts/vibrali-installer-gui.sh"
cp "$ROOT/scripts/install-to-usb.sh" "$TMP/repo/scripts/install-to-usb.sh"
cp -a "$ROOT/packages" "$TMP/repo/packages"
chmod +x "$TMP/repo/scripts/"*.sh

cat > "$TMP/bin/lsblk" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == "-dnpo NAME,SIZE,MODEL,TRAN,TYPE,RM" ]]; then
  echo "/dev/fake 64G TestDisk usb disk 1"
elif [[ "$*" == "-dnpo NAME,SIZE,MODEL,SERIAL,TRAN /dev/fake" ]]; then
  echo "/dev/fake 64G TestDisk SERIAL usb"
else
  exit 1
fi
EOF

cat > "$TMP/bin/zenity" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"Target Disk"*) echo "/dev/fake" ;;
  *"Identity"*) echo "tester|vibrali-gui" ;;
  *"Tool Profiles"*) echo "all" ;;
  *"Encryption"*) exit 0 ;;
  *"ERASE DISK"*) exit 0 ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$TMP/bin/lsblk" "$TMP/bin/zenity"

output="$(
  PATH="$TMP/bin:$PATH"   VIBRALI_GUI_PRINT_COMMAND=1   bash "$TMP/repo/scripts/vibrali-installer-gui.sh"
)"

for token in   "/dev/fake"   "--username tester"   "--hostname vibrali-gui"   "--profiles all"   "--yes-really-erase"   "--encrypt-root"
do
  grep -Fq -- "$token" <<<"$output" || {
    echo "graphical installer smoke test missing token: $token" >&2
    echo "$output" >&2
    exit 1
  }
done

echo "graphical installer smoke test: ok"
