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
case "$*" in
  "-dnpo NAME,SIZE,TYPE,RM") echo "/dev/fake 64G disk 1" ;;
  "-dn -o MODEL /dev/fake") echo "Test Disk Model" ;;
  "-dn -o TRAN /dev/fake") echo "usb" ;;
  "-dnpo NAME,SIZE,MODEL,SERIAL,TRAN /dev/fake") echo "/dev/fake 64G TestDisk SERIAL usb" ;;
  *) exit 1 ;;
esac
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
