#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE=""
USERNAME="vibrali"
HOSTNAME="vibrali"
SUITE="trixie"
MIRROR="https://deb.debian.org/debian"
TARGET="/mnt/vibrali-target"
CONFIRMED=0
NONINTERACTIVE=0
PROFILE_SPEC="all"
LIST_PROFILES=0

list_optional_profiles() {
  local manifest name

  for manifest in "$ROOT_DIR"/packages/*.txt; do
    [[ -e "$manifest" ]] || continue
    name="${manifest##*/}"
    name="${name%.txt}"
    case "$name" in
      base|desktop) continue ;;
    esac
    printf '%s\n' "$name"
  done | LC_ALL=C sort
}

usage() {
  cat <<'EOF'
Usage:
  sudo ./scripts/install-to-usb.sh --device /dev/sdX [options]

Options:
  --device PATH       Whole USB disk to erase and install to
  --username NAME     Initial user (default: vibrali)
  --hostname NAME     Hostname (default: vibrali)
  --suite NAME        Upstream package suite (default: trixie)
  --mirror URL        Upstream package mirror
  --profiles LIST     Optional package profiles: all, none, or comma-separated names
                      (default: all; base and desktop are always installed)
  --list-profiles     List available optional profile names and exit
  --yes-really-erase  Required destructive-operation acknowledgement
  --non-interactive   CI image build mode; accepted only for loop devices
  -h, --help          Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE="${2:-}"; shift 2 ;;
    --username) USERNAME="${2:-}"; shift 2 ;;
    --hostname) HOSTNAME="${2:-}"; shift 2 ;;
    --suite) SUITE="${2:-}"; shift 2 ;;
    --mirror) MIRROR="${2:-}"; shift 2 ;;
    --profiles)
      PROFILE_SPEC="${2:-}"
      [[ -n "$PROFILE_SPEC" ]] || { echo "--profiles requires a value." >&2; exit 2; }
      shift 2
      ;;
    --list-profiles) LIST_PROFILES=1; shift ;;
    --yes-really-erase) CONFIRMED=1; shift ;;
    --non-interactive) NONINTERACTIVE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ $LIST_PROFILES -eq 1 ]]; then
  list_optional_profiles
  exit 0
fi

SELECTED_MANIFESTS=(
  "$ROOT_DIR/packages/base.txt"
  "$ROOT_DIR/packages/desktop.txt"
)
SELECTED_PROFILES=()

case "$PROFILE_SPEC" in
  all)
    mapfile -t SELECTED_PROFILES < <(list_optional_profiles)
    ;;
  none)
    ;;
  *)
    IFS=',' read -r -a requested_profiles <<< "$PROFILE_SPEC"
    for profile in "${requested_profiles[@]}"; do
      [[ "$profile" =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
        echo "Invalid profile name: $profile" >&2
        exit 2
      }
      case "$profile" in
        base|desktop)
          echo "Profile '$profile' is part of the mandatory core and should not be listed in --profiles." >&2
          exit 2
          ;;
      esac
      [[ -f "$ROOT_DIR/packages/$profile.txt" ]] || {
        echo "Unknown optional profile: $profile" >&2
        echo "Use --list-profiles to see valid names." >&2
        exit 2
      }

      duplicate=0
      for existing in "${SELECTED_PROFILES[@]}"; do
        if [[ "$existing" == "$profile" ]]; then
          duplicate=1
          break
        fi
      done
      [[ $duplicate -eq 1 ]] || SELECTED_PROFILES+=("$profile")
    done
    ;;
esac

for profile in "${SELECTED_PROFILES[@]}"; do
  SELECTED_MANIFESTS+=("$ROOT_DIR/packages/$profile.txt")
done

[[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }
[[ -n "$DEVICE" ]] || { usage; exit 2; }
[[ -b "$DEVICE" ]] || { echo "Not a block device: $DEVICE" >&2; exit 1; }
DEVICE_TYPE="$(lsblk -dn -o TYPE "$DEVICE")"
if [[ "$DEVICE_TYPE" != "disk" ]]; then
  if [[ $NONINTERACTIVE -ne 1 || "$DEVICE_TYPE" != "loop" || "$DEVICE" != /dev/loop* ]]; then
    echo "--device must name a whole physical disk." >&2
    exit 1
  fi
fi

if lsblk -nrpo MOUNTPOINTS "$DEVICE" | grep -Eq '(^|[[:space:]])/($|[[:space:]])'; then
  echo "Refusing to erase the disk containing the running root filesystem." >&2
  exit 1
fi

[[ $CONFIRMED -eq 1 ]] || {
  echo "Refusing destructive install without --yes-really-erase." >&2
  exit 1
}

for cmd in debootstrap sgdisk mkfs.vfat mkfs.ext4 blkid mount umount chroot lsblk rsync curl sha256sum; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing build-host command: $cmd" >&2
    exit 1
  }
done

echo
echo "Vibrali will ERASE the following disk:"
lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN "$DEVICE"
echo
if ((${#SELECTED_PROFILES[@]} > 0)); then
  (
    IFS=,
    echo "Optional profiles: ${SELECTED_PROFILES[*]}"
  )
else
  echo "Optional profiles: none"
fi
echo

if [[ $NONINTERACTIVE -eq 1 ]]; then
  [[ "$DEVICE" == /dev/loop* ]] || { echo "CI mode is limited to loop devices." >&2; exit 1; }
  PASSWORD="${VIBRALI_PASSWORD:-}"
  [[ -n "$PASSWORD" ]] || { echo "VIBRALI_PASSWORD is required in CI mode." >&2; exit 1; }
  PASSWORD2="$PASSWORD"
else
  read -r -p "Type the full device path ($DEVICE) to continue: " typed
  [[ "$typed" == "$DEVICE" ]] || { echo "Cancelled."; exit 1; }
  read -r -s -p "Password for user $USERNAME: " PASSWORD
  echo
  read -r -s -p "Repeat password: " PASSWORD2
  echo
  [[ -n "$PASSWORD" && "$PASSWORD" == "$PASSWORD2" ]] || {
    echo "Passwords did not match." >&2
    exit 1
  }
fi

part() {
  if [[ "$DEVICE" =~ [0-9]$ ]]; then
    printf '%sp%s' "$DEVICE" "$1"
  else
    printf '%s%s' "$DEVICE" "$1"
  fi
}

EFI_PART="$(part 2)"
ROOT_PART="$(part 3)"
MOUNTS=()

cleanup() {
  set +e
  for ((i=${#MOUNTS[@]}-1; i>=0; i--)); do
    mountpoint -q "${MOUNTS[$i]}" && umount "${MOUNTS[$i]}"
  done
}
trap cleanup EXIT

echo "Unmounting any automounted partitions on $DEVICE..."
while read -r node mountpoint_path; do
  [[ -n "${mountpoint_path:-}" ]] || continue
  umount "$node"
done < <(lsblk -nrpo NAME,MOUNTPOINTS "$DEVICE")

echo "Creating GPT layout..."
sgdisk --zap-all "$DEVICE"
sgdisk --new=1:1MiB:+1MiB --typecode=1:ef02 --change-name=1:BIOS_BOOT "$DEVICE"
sgdisk --new=2:0:+512MiB --typecode=2:ef00 --change-name=2:VIBRALI_EFI "$DEVICE"
sgdisk --new=3:0:0 --typecode=3:8300 --change-name=3:VIBRALI_ROOT "$DEVICE"

if command -v partprobe >/dev/null 2>&1; then
  partprobe "$DEVICE" || true
fi
if [[ "$DEVICE_TYPE" == "loop" ]] && command -v partx >/dev/null 2>&1; then
  partx -u "$DEVICE" || true
fi
if command -v udevadm >/dev/null 2>&1; then
  udevadm settle || true
fi

for _ in $(seq 1 20); do
  [[ -b "$EFI_PART" && -b "$ROOT_PART" ]] && break
  if command -v udevadm >/dev/null 2>&1; then
    udevadm settle || true
  fi
  sleep 0.5
done

[[ -b "$EFI_PART" && -b "$ROOT_PART" ]] || {
  echo "Partitions did not appear as expected." >&2
  exit 1
}

echo "Formatting filesystems..."
mkfs.vfat -F 32 -n VIBRALI_EFI "$EFI_PART"
mkfs.ext4 -F -L VIBRALI_ROOT "$ROOT_PART"

mkdir -p "$TARGET"
mount "$ROOT_PART" "$TARGET"
MOUNTS+=("$TARGET")
mkdir -p "$TARGET/boot/efi"
mount "$EFI_PART" "$TARGET/boot/efi"
MOUNTS+=("$TARGET/boot/efi")

echo "Installing Vibrali $SUITE base system..."
debootstrap --arch=amd64 "$SUITE" "$TARGET" "$MIRROR"

cat > "$TARGET/etc/apt/sources.list" <<EOF
deb $MIRROR $SUITE main contrib non-free non-free-firmware
deb $MIRROR $SUITE-updates main contrib non-free non-free-firmware
deb https://security.debian.org/debian-security $SUITE-security main contrib non-free non-free-firmware
EOF

for fs in dev dev/pts proc sys run; do
  mkdir -p "$TARGET/$fs"
  mount --bind "/$fs" "$TARGET/$fs"
  MOUNTS+=("$TARGET/$fs")
done

cp --dereference /etc/resolv.conf "$TARGET/etc/resolv.conf"

[[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || {
  echo "Invalid username: $USERNAME" >&2
  exit 1
}
[[ "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]] || {
  echo "Invalid hostname: $HOSTNAME" >&2
  exit 1
}

mapfile -t PACKAGES < <(
  cat "${SELECTED_MANIFESTS[@]}" |
    sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' |
    sort -u
)

echo "Installing Vibrali packages..."
chroot "$TARGET" apt-get update
chroot "$TARGET" env DEBIAN_FRONTEND=noninteractive apt-get install -y "${PACKAGES[@]}"

echo "Applying Vibrali identity and desktop defaults..."
rsync -rlptD --chown=0:0 "$ROOT_DIR/config/rootfs/" "$TARGET/"
chmod 0755 "$TARGET/usr/local/bin/vibrali-session-init" "$TARGET/usr/local/bin/vibrali-info" "$TARGET/usr/local/bin/neofetch"

NEOFETCH_URL="https://raw.githubusercontent.com/dylanaraps/neofetch/7.1.0/neofetch"
NEOFETCH_SHA256="3dc33493e54029fb1528251552093a9f9a2894fcf94f9c3a6f809136a42348c7"
NEOFETCH_TMP="$(mktemp)"
curl -fsSL "$NEOFETCH_URL" -o "$NEOFETCH_TMP"
printf "%s  %s\n" "$NEOFETCH_SHA256" "$NEOFETCH_TMP" | sha256sum -c -
install -Dm0755 "$NEOFETCH_TMP" "$TARGET/usr/local/lib/vibrali/neofetch"
rm -f "$NEOFETCH_TMP"

echo "$HOSTNAME" > "$TARGET/etc/hostname"
cat > "$TARGET/etc/hosts" <<EOF
127.0.0.1 localhost
127.0.1.1 $HOSTNAME
::1 localhost ip6-localhost ip6-loopback
EOF

echo "Creating user $USERNAME..."
chroot "$TARGET" useradd -m -s /bin/zsh "$USERNAME"
printf '%s:%s\n' "$USERNAME" "$PASSWORD" | chroot "$TARGET" chpasswd
chroot "$TARGET" usermod -aG sudo,plugdev "$USERNAME"
chroot "$TARGET" passwd -l root
chroot "$TARGET" chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

ROOT_UUID="$(blkid -s UUID -o value "$ROOT_PART")"
EFI_UUID="$(blkid -s UUID -o value "$EFI_PART")"

cat > "$TARGET/etc/fstab" <<EOF
UUID=$ROOT_UUID / ext4 defaults,noatime 0 1
UUID=$EFI_UUID /boot/efi vfat umask=0077 0 1
EOF

echo "Configuring portable Vibrali boot..."
mkdir -p "$TARGET/etc/default/grub.d"
chroot "$TARGET" grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Vibrali --removable --no-nvram --recheck

if chroot "$TARGET" grub-install --target=i386-pc --recheck "$DEVICE"; then
  echo "Legacy BIOS boot installed."
else
  echo "Warning: legacy BIOS GRUB install failed; UEFI boot remains configured." >&2
fi

chroot "$TARGET" update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/vibrali/vibrali.plymouth 200
chroot "$TARGET" update-alternatives --set default.plymouth /usr/share/plymouth/themes/vibrali/vibrali.plymouth
chroot "$TARGET" gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
chroot "$TARGET" update-initramfs -u -k all
chroot "$TARGET" update-grub
chroot "$TARGET" systemctl enable NetworkManager
chroot "$TARGET" systemctl enable lightdm

# Each installed device should create its own runtime identity on first boot.
: > "$TARGET/etc/machine-id"
rm -f "$TARGET/var/lib/dbus/machine-id"

cat > "$TARGET/etc/motd" <<'EOF'
Vibrali Security Linux
Portable. Persistent. Yours.

Use security tooling only on systems you own or are authorized to test.
EOF

chroot "$TARGET" apt-get clean
sync

PASSWORD=""
PASSWORD2=""

echo
echo "Vibrali installation complete."
echo "Target: $DEVICE"
echo "Root:   $ROOT_PART"
echo "EFI:    $EFI_PART"
echo
echo "You can now shut down the host, move the USB to another x86_64 PC,"
echo "select the USB from its firmware boot menu, and boot the same writable system."
