#!/usr/bin/env bash
set -Eeuo pipefail

REPO="mixutin/Vibrali"
BASE="https://github.com/$REPO/releases/latest/download"
IMAGE_NAME="vibrali-usb-amd64.img.zst"
TTY=/dev/tty
TMP=""
DOWNLOADED_IMAGE=""

cleanup() {
  [[ -z "${TMP:-}" ]] || rm -rf "$TMP"
}

c0='\033[0m'
cyan='\033[1;36m'
violet='\033[1;35m'
green='\033[1;32m'
yellow='\033[1;33m'
red='\033[1;31m'

say() { printf "%b%s%b\n" "$cyan" "$*" "$c0"; }
ok() { printf "%b✓%b %s\n" "$green" "$c0" "$*"; }
warn() { printf "%b!%b %s\n" "$yellow" "$c0" "$*"; }
die() { printf "%b✗%b %s\n" "$red" "$c0" "$*" >&2; exit 1; }

banner() {
  printf "%b" "$violet"
  cat <<'EOF'
     ╲        ╱
      ╲  ◈   ╱      V I B R A L I
       ╲    ╱       portable security linux
        ╲  ╱
         \/
EOF
  printf "%b\n" "$c0"
}

download_release() {
  local base="$1"
  local tmp="$2"
  local image_name="$3"
  local image="$tmp/$image_name"
  local expected actual found part n

  mkdir -p "$tmp"

  say "[1/5] Downloading release manifest"
  curl -fsSL --retry 3 "$base/SHA256SUMS" -o "$tmp/SHA256SUMS" ||
    die "No downloadable Vibrali release is available yet."

  say "[2/5] Downloading the latest Vibrali USB image"

  if curl -fsIL "$base/$image_name" >/dev/null 2>&1; then
    curl -fL --retry 3 --progress-bar "$base/$image_name" -o "$image"
  else
    warn "Release is split into multiple GitHub assets; assembling locally."
    : > "$image"
    found=0
    for n in $(seq -w 0 49); do
      part="$image_name.part-$n"
      if curl -fsIL "$base/$part" >/dev/null 2>&1; then
        curl -fL --retry 3 --progress-bar "$base/$part" -o "$tmp/$part"
        cat "$tmp/$part" >> "$image"
        rm -f "$tmp/$part"
        found=1
      elif [[ $found -eq 1 ]]; then
        break
      fi
    done
    [[ $found -eq 1 ]] || die "Could not find the USB image in the latest release."
  fi

  expected="$(awk -v f="$image_name" '$2 == f {print $1}' "$tmp/SHA256SUMS")"
  [[ -n "$expected" ]] || die "Release checksum for $image_name is missing."
  actual="$(sha256sum "$image" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || die "Checksum verification failed."
  ok "Release checksum verified"

  DOWNLOADED_IMAGE="$image"
}

main() {
  local IMAGE TARGET root_source root_parent confirm ROOT_PART POST HOSTNAME PASS1 PASS2

  [[ -r "$TTY" ]] || die "Run this installer from an interactive terminal."
  trap cleanup EXIT
  TMP="$(mktemp -d)"

  banner
  say "Portable full-system USB installer"
  printf "This will download the latest signed-by-checksum Vibrali image and write it to a disk.\n\n"

  for cmd in curl lsblk findmnt sha256sum zstd dd mount chroot awk sed blockdev readlink; do
    command -v "$cmd" >/dev/null 2>&1 || die "Missing required command: $cmd"
  done

  command -v sudo >/dev/null 2>&1 || die "sudo is required."
  sudo -v
  ok "Host prerequisites ready"

  download_release "$BASE" "$TMP" "$IMAGE_NAME"
  IMAGE="$DOWNLOADED_IMAGE"

  say "[3/5] Select the destination disk"
  printf "\n"
  lsblk -dpno NAME,SIZE,MODEL,TRAN,RM,TYPE | awk '$6 == "disk" {print}'
  printf "\n"
  read -r -p "Target whole disk (example /dev/sdb): " TARGET < "$TTY"
  TARGET="$(readlink -f "$TARGET")"

  [[ -b "$TARGET" ]] || die "Not a block device: $TARGET"
  [[ "$(lsblk -dn -o TYPE "$TARGET")" == "disk" ]] ||
    die "Choose a whole disk, not a partition."

  root_source="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
  root_parent="$(lsblk -sno NAME "$root_source" 2>/dev/null | tail -1 | tr -d ' ' || true)"
  if [[ -n "$root_parent" && "$TARGET" == "/dev/$root_parent" ]]; then
    die "Refusing to overwrite the disk containing the running operating system."
  fi

  printf "\n%bSelected target:%b\n" "$yellow" "$c0"
  lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN "$TARGET"
  printf "\n%bALL DATA ON %s WILL BE ERASED.%b\n" "$red" "$TARGET" "$c0"
  read -r -p "Type VIBRALI to continue: " confirm < "$TTY"
  [[ "$confirm" == "VIBRALI" ]] || die "Cancelled."

  say "[4/5] Writing Vibrali to $TARGET"

  while read -r node mountpoint_path; do
    [[ -n "${mountpoint_path:-}" ]] || continue
    sudo umount "$node" 2>/dev/null || true
  done < <(lsblk -nrpo NAME,MOUNTPOINTS "$TARGET")

  zstd -dc "$IMAGE" | sudo dd of="$TARGET" bs=8M status=progress conv=fsync
  sync
  if command -v partprobe >/dev/null 2>&1; then
    sudo partprobe "$TARGET" 2>/dev/null || true
  else
    sudo blockdev --rereadpt "$TARGET" 2>/dev/null || true
  fi
  sudo udevadm settle 2>/dev/null || true
  ok "Portable system written"

  part() {
    if [[ "$TARGET" =~ [0-9]$ ]]; then
      printf '%sp%s' "$TARGET" "$1"
    else
      printf '%s%s' "$TARGET" "$1"
    fi
  }

  ROOT_PART="$(part 3)"
  for _ in $(seq 1 20); do
    [[ -b "$ROOT_PART" ]] && break
    sudo udevadm settle 2>/dev/null || true
    sleep 0.5
  done
  [[ -b "$ROOT_PART" ]] || die "The Vibrali root partition did not appear."

  say "[5/5] Personalize the installation"
  read -r -p "Hostname [vibrali]: " HOSTNAME < "$TTY"
  HOSTNAME="${HOSTNAME:-vibrali}"
  [[ "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]] ||
    die "Invalid hostname."

  read -r -s -p "Password for user vibrali: " PASS1 < "$TTY"
  printf "\n"
  read -r -s -p "Repeat password: " PASS2 < "$TTY"
  printf "\n"
  [[ -n "$PASS1" && "$PASS1" == "$PASS2" ]] || die "Passwords did not match."

  POST="$TMP/root"
  mkdir -p "$POST"
  sudo mount "$ROOT_PART" "$POST"
  printf 'vibrali:%s\n' "$PASS1" | sudo chroot "$POST" chpasswd
  sudo chroot "$POST" usermod --unlock vibrali
  printf '%s\n' "$HOSTNAME" | sudo tee "$POST/etc/hostname" >/dev/null
  sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $HOSTNAME/" "$POST/etc/hosts"
  sudo sh -c ": > '$POST/etc/machine-id'"
  sudo rm -f "$POST/var/lib/dbus/machine-id"
  sudo umount "$POST"
  PASS1=""
  PASS2=""

  printf "\n"
  ok "Vibrali is installed and personalized."
  say "Next: reboot, open your firmware boot menu, and choose the USB drive."
  printf "User: %bvibrali%b  Hostname: %b%s%b\n" "$violet" "$c0" "$violet" "$HOSTNAME" "$c0"
  printf "Docs: https://mixutin.github.io/Vibrali/\n\n"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
