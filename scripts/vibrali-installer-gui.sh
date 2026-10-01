#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT/scripts/install-to-usb.sh"
TERMINAL="${VIBRALI_GUI_TERMINAL:-xfce4-terminal}"

die() {
  zenity --error --title="Vibrali Installer" --text="$1" 2>/dev/null || true
  echo "$1" >&2
  exit 1
}

command -v zenity >/dev/null 2>&1 || {
  echo "Missing required command: zenity" >&2
  exit 1
}
command -v lsblk >/dev/null 2>&1 || die "Missing required command: lsblk"
[[ -x "$INSTALLER" ]] || die "Vibrali source installer not found at $INSTALLER"

mapfile -t DISK_ROWS < <(
  lsblk -dnpo NAME,SIZE,MODEL,TRAN,TYPE,RM |
    awk '$5 == "disk" {
      model=$3
      if ($4 != "") model=model " (" $4 ")"
      removable=($6 == "1" ? "removable" : "fixed")
      printf "%s|%s|%s|%s\n", $1, $2, model, removable
    }'
)

((${#DISK_ROWS[@]} > 0)) || die "No whole-disk install targets were detected."

zenity_args=(
  --list
  --title="Vibrali Installer — Target Disk"
  --text="Choose the whole disk to erase and install Vibrali onto."
  --width=760
  --height=420
  --column="Device"
  --column="Size"
  --column="Model / bus"
  --column="Type"
)

for row in "${DISK_ROWS[@]}"; do
  IFS='|' read -r path size model removable <<<"$row"
  zenity_args+=("$path" "$size" "$model" "$removable")
done

DEVICE="$(zenity "${zenity_args[@]}")" || exit 0
[[ -n "$DEVICE" ]] || exit 0

identity="$(zenity --forms   --title="Vibrali Installer — Identity"   --text="Choose the initial workstation identity."   --add-entry="Username"   --add-entry="Hostname"   --separator='|')" || exit 0
IFS='|' read -r USERNAME HOSTNAME <<<"$identity"
USERNAME="${USERNAME:-vibrali}"
HOSTNAME="${HOSTNAME:-vibrali}"

profile_mode="$(zenity --list   --title="Vibrali Installer — Tool Profiles"   --text="Base and desktop are always installed. Choose optional tooling."   --radiolist   --column="" --column="Selection" --column="Description"   TRUE all "All optional security, lab and development profiles"   FALSE none "Base desktop only"   FALSE custom "Choose a comma-separated subset")" || exit 0

PROFILE_SPEC="$profile_mode"
if [[ "$profile_mode" == "custom" ]]; then
  available="$(bash "$INSTALLER" --list-profiles | paste -sd, -)"
  PROFILE_SPEC="$(zenity --entry     --title="Vibrali Installer — Custom Profiles"     --text="Available profiles:\n$available\n\nEnter comma-separated profile names:"     --entry-text="$available")" || exit 0
  [[ -n "$PROFILE_SPEC" ]] || die "At least one profile name is required for a custom selection."
fi

ENCRYPT_ROOT=0
if zenity --question   --title="Vibrali Installer — Encryption"   --text="Encrypt the root filesystem with LUKS2?\n\nThis keeps the USB portable and asks for a disk passphrase at boot."; then
  ENCRYPT_ROOT=1
fi

summary="$(lsblk -dnpo NAME,SIZE,MODEL,SERIAL,TRAN "$DEVICE" 2>/dev/null || printf '%s' "$DEVICE")"
confirm_text="The selected disk will be completely erased.\n\n$summary\n\nProfiles: $PROFILE_SPEC\nUsername: $USERNAME\nHostname: $HOSTNAME"
if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  confirm_text+="\nEncryption: LUKS2 root"
else
  confirm_text+="\nEncryption: disabled"
fi
confirm_text+="\n\nContinue only if this is the correct removable target."

zenity --question   --title="Vibrali Installer — ERASE DISK"   --ok-label="Erase and Install"   --cancel-label="Cancel"   --width=620   --text="$confirm_text" || exit 0

cmd=(
  sudo
  "$INSTALLER"
  --device "$DEVICE"
  --username "$USERNAME"
  --hostname "$HOSTNAME"
  --profiles "$PROFILE_SPEC"
  --yes-really-erase
)
if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  cmd+=(--encrypt-root)
fi

printf -v quoted '%q ' "${cmd[@]}"

if [[ "${VIBRALI_GUI_PRINT_COMMAND:-0}" == "1" ]]; then
  printf '%s\n' "$quoted"
  exit 0
fi

command -v "$TERMINAL" >/dev/null 2>&1 || die "Terminal not found: $TERMINAL"
exec "$TERMINAL" --hold --command="$quoted"
