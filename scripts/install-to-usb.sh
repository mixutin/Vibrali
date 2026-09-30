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
DRY_RUN=0
ENCRYPT_ROOT=0
CRYPT_NAME="vibrali-root"
LUKS_PASSWORD=""
MIN_DEVICE_GIB=12
RECOMMENDED_DEVICE_GIB=64
MIN_DEVICE_BYTES=$((MIN_DEVICE_GIB * 1024 * 1024 * 1024))
RECOMMENDED_DEVICE_BYTES=$((RECOMMENDED_DEVICE_GIB * 1024 * 1024 * 1024))

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
  --dry-run           Validate target/options and print the install plan without changes
  --encrypt-root      Encrypt root with LUKS2; keeps /boot and EFI unencrypted
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
    --dry-run) DRY_RUN=1; shift ;;
    --encrypt-root) ENCRYPT_ROOT=1; shift ;;
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

command -v lsblk >/dev/null 2>&1 || {
  echo "Missing required command: lsblk" >&2
  exit 1
}

[[ -n "$DEVICE" ]] || { usage; exit 2; }
[[ -b "$DEVICE" ]] || { echo "Not a block device: $DEVICE" >&2; exit 1; }

DEVICE_TYPE="$(lsblk -dn -o TYPE "$DEVICE" | tr -d '[:space:]')"
if [[ "$DEVICE_TYPE" != "disk" ]]; then
  ALLOW_LOOP=0
  if [[ "$DEVICE_TYPE" == "loop" && "$DEVICE" == /dev/loop* ]]; then
    if [[ $NONINTERACTIVE -eq 1 || $DRY_RUN -eq 1 ]]; then
      ALLOW_LOOP=1
    fi
  fi
  if [[ $ALLOW_LOOP -ne 1 ]]; then
    echo "--device must name a whole physical disk." >&2
    exit 1
  fi
fi

if lsblk -nrpo MOUNTPOINTS "$DEVICE" | grep -Eq '(^|[[:space:]])/($|[[:space:]])'; then
  echo "Refusing to erase the disk containing the running root filesystem." >&2
  exit 1
fi

DEVICE_SIZE_BYTES="$(lsblk -bdn -o SIZE "$DEVICE" | tr -d '[:space:]')"
[[ "$DEVICE_SIZE_BYTES" =~ ^[0-9]+$ ]] || {
  echo "Could not determine target size for $DEVICE." >&2
  exit 1
}
if (( DEVICE_SIZE_BYTES < MIN_DEVICE_BYTES )); then
  echo "Target is too small: Vibrali requires at least ${MIN_DEVICE_GIB} GiB." >&2
  exit 1
fi

DEVICE_RM="$(lsblk -dn -o RM "$DEVICE" | tr -d '[:space:]')"
DEVICE_TRAN="$(lsblk -dn -o TRAN "$DEVICE" | tr -d '[:space:]')"
if [[ "$DEVICE_TYPE" != "loop" && "$DEVICE_RM" != "1" && "$DEVICE_TRAN" != "usb" ]]; then
  echo "Warning: $DEVICE does not report itself as removable or USB storage." >&2
  echo "Verify the model, serial and device path carefully before continuing." >&2
fi

echo
if [[ $DRY_RUN -eq 1 ]]; then
  echo "Vibrali installer preflight (DRY RUN — no changes will be made):"
else
  echo "Vibrali will ERASE the following disk:"
fi
lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN,RM "$DEVICE"
echo
if ((${#SELECTED_PROFILES[@]} > 0)); then
  (
    IFS=,
    echo "Optional profiles: ${SELECTED_PROFILES[*]}"
  )
else
  echo "Optional profiles: none"
fi
echo "Minimum target size:     ${MIN_DEVICE_GIB} GiB"
echo "Recommended target size: ${RECOMMENDED_DEVICE_GIB} GiB"
if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  echo "Root encryption:          LUKS2 (portable passphrase unlock; no TPM dependency)"
else
  echo "Root encryption:          disabled"
fi
if (( DEVICE_SIZE_BYTES < RECOMMENDED_DEVICE_BYTES )); then
  echo "Note: this target is below the recommended ${RECOMMENDED_DEVICE_GIB} GiB for a full pentesting workstation." >&2
fi
echo

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry run complete. No partition table, filesystem or data was changed."
  exit 0
fi

[[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }

[[ $CONFIRMED -eq 1 ]] || {
  echo "Refusing destructive install without --yes-really-erase." >&2
  exit 1
}

for cmd in debootstrap sgdisk mkfs.vfat mkfs.ext4 blkid mount umount chroot rsync curl sha256sum mktemp tee; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing build-host command: $cmd" >&2
    exit 1
  }
done

if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  command -v cryptsetup >/dev/null 2>&1 || {
    echo "Missing build-host command for --encrypt-root: cryptsetup" >&2
    exit 1
  }
fi

INSTALL_LOG="$(mktemp /tmp/vibrali-install.XXXXXX.log)"
exec > >(tee -a "$INSTALL_LOG") 2>&1
echo "Install log: $INSTALL_LOG"

if [[ $NONINTERACTIVE -eq 1 ]]; then
  [[ "$DEVICE" == /dev/loop* ]] || { echo "CI mode is limited to loop devices." >&2; exit 1; }
  PASSWORD="${VIBRALI_PASSWORD:-}"
  [[ -n "$PASSWORD" ]] || { echo "VIBRALI_PASSWORD is required in CI mode." >&2; exit 1; }
  PASSWORD2="$PASSWORD"
  if [[ $ENCRYPT_ROOT -eq 1 ]]; then
    LUKS_PASSWORD="${VIBRALI_LUKS_PASSWORD:-}"
    [[ -n "$LUKS_PASSWORD" ]] || { echo "VIBRALI_LUKS_PASSWORD is required with --encrypt-root in CI mode." >&2; exit 1; }
  fi
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

  if [[ $ENCRYPT_ROOT -eq 1 ]]; then
    read -r -s -p "LUKS2 root passphrase: " LUKS_PASSWORD
    echo
    read -r -s -p "Repeat LUKS2 passphrase: " LUKS_PASSWORD2
    echo
    [[ -n "$LUKS_PASSWORD" && "$LUKS_PASSWORD" == "$LUKS_PASSWORD2" ]] || {
      echo "LUKS2 passphrases did not match." >&2
      exit 1
    }
    LUKS_PASSWORD2=""
  fi
fi

verify_install() {
  local failures=0

  echo
  echo "Post-install verification:"

  if [[ -f "$TARGET/boot/efi/EFI/BOOT/BOOTX64.EFI" ]]; then
    echo "  [PASS] removable UEFI bootloader"
  else
    echo "  [FAIL] removable UEFI bootloader" >&2
    failures=$((failures + 1))
  fi

  if grep -Fq "UUID=$ROOT_UUID / ext4" "$TARGET/etc/fstab"; then
    echo "  [PASS] root filesystem UUID"
  else
    echo "  [FAIL] root filesystem UUID" >&2
    failures=$((failures + 1))
  fi

  if [[ $ENCRYPT_ROOT -eq 1 ]]; then
    if grep -Fq "$CRYPT_NAME UUID=$LUKS_UUID none luks" "$TARGET/etc/crypttab" &&
       grep -Fq "UUID=$BOOT_UUID /boot ext4" "$TARGET/etc/fstab"; then
      echo "  [PASS] LUKS2 root mapping and separate /boot"
    else
      echo "  [FAIL] LUKS2 root mapping or /boot UUID" >&2
      failures=$((failures + 1))
    fi
  fi

  if grep -Fq "UUID=$EFI_UUID /boot/efi vfat" "$TARGET/etc/fstab"; then
    echo "  [PASS] EFI filesystem UUID"
  else
    echo "  [FAIL] EFI filesystem UUID" >&2
    failures=$((failures + 1))
  fi

  if chroot "$TARGET" id "$USERNAME" >/dev/null 2>&1; then
    echo "  [PASS] user account: $USERNAME"
  else
    echo "  [FAIL] user account: $USERNAME" >&2
    failures=$((failures + 1))
  fi

  if [[ -s "$TARGET/etc/vibrali/profiles" ]]; then
    echo "  [PASS] installed profile registry"
  else
    echo "  [FAIL] installed profile registry" >&2
    failures=$((failures + 1))
  fi

  if [[ -x "$TARGET/usr/bin/dumpcap" ]]; then
    if chroot "$TARGET" id -nG "$USERNAME" | grep -qw wireshark &&
       chroot "$TARGET" getcap /usr/bin/dumpcap | grep -Fq cap_net_admin &&
       chroot "$TARGET" getcap /usr/bin/dumpcap | grep -Fq cap_net_raw; then
      echo "  [PASS] non-root Wireshark capture privileges"
    else
      echo "  [FAIL] non-root Wireshark capture privileges" >&2
      failures=$((failures + 1))
    fi
  fi

  if chroot "$TARGET" systemctl is-enabled NetworkManager >/dev/null 2>&1; then
    echo "  [PASS] NetworkManager enabled"
  else
    echo "  [FAIL] NetworkManager enabled" >&2
    failures=$((failures + 1))
  fi

  if chroot "$TARGET" systemctl is-enabled lightdm >/dev/null 2>&1; then
    echo "  [PASS] LightDM enabled"
  else
    echo "  [FAIL] LightDM enabled" >&2
    failures=$((failures + 1))
  fi

  if chroot "$TARGET" systemctl is-enabled fstrim.timer >/dev/null 2>&1; then
    echo "  [PASS] scheduled filesystem TRIM enabled"
  else
    echo "  [FAIL] scheduled filesystem TRIM enabled" >&2
    failures=$((failures + 1))
  fi

  if chroot "$TARGET" systemctl is-enabled zramswap.service >/dev/null 2>&1; then
    echo "  [PASS] zram swap enabled"
  else
    echo "  [FAIL] zram swap enabled" >&2
    failures=$((failures + 1))
  fi

  if [[ -s "$TARGET/etc/systemd/journald.conf.d/vibrali-portable.conf" ]]; then
    echo "  [PASS] portable journal limits"
  else
    echo "  [FAIL] portable journal limits" >&2
    failures=$((failures + 1))
  fi

  if chroot "$TARGET" systemctl is-enabled nftables.service >/dev/null 2>&1; then
    echo "  [PASS] nftables firewall enabled"
  else
    echo "  [FAIL] nftables firewall enabled" >&2
    failures=$((failures + 1))
  fi

  if chroot "$TARGET" systemctl is-enabled apparmor.service >/dev/null 2>&1; then
    echo "  [PASS] AppArmor enabled"
  else
    echo "  [FAIL] AppArmor enabled" >&2
    failures=$((failures + 1))
  fi

  if [[ $failures -ne 0 ]]; then
    echo "Post-install verification failed: $failures critical check(s) failed." >&2
    return 1
  fi

  echo "Post-install verification passed."
}

part() {
  if [[ "$DEVICE" =~ [0-9]$ ]]; then
    printf '%sp%s' "$DEVICE" "$1"
  else
    printf '%s%s' "$DEVICE" "$1"
  fi
}

EFI_PART="$(part 2)"
BOOT_PART=""
if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  BOOT_PART="$(part 3)"
  ROOT_PART="$(part 4)"
else
  ROOT_PART="$(part 3)"
fi
ROOT_DEVICE="$ROOT_PART"
MOUNTS=()

cleanup() {
  set +e
  for ((i=${#MOUNTS[@]}-1; i>=0; i--)); do
    mountpoint -q "${MOUNTS[$i]}" && umount "${MOUNTS[$i]}"
  done
  if [[ $ENCRYPT_ROOT -eq 1 ]] && cryptsetup status "$CRYPT_NAME" >/dev/null 2>&1; then
    cryptsetup close "$CRYPT_NAME" || true
  fi
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
if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  sgdisk --new=3:0:+1GiB --typecode=3:8300 --change-name=3:VIBRALI_BOOT "$DEVICE"
  sgdisk --new=4:0:0 --typecode=4:8309 --change-name=4:VIBRALI_CRYPT "$DEVICE"
else
  sgdisk --new=3:0:0 --typecode=3:8300 --change-name=3:VIBRALI_ROOT "$DEVICE"
fi

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
  if [[ $ENCRYPT_ROOT -eq 1 ]]; then
    [[ -b "$EFI_PART" && -b "$BOOT_PART" && -b "$ROOT_PART" ]] && break
  else
    [[ -b "$EFI_PART" && -b "$ROOT_PART" ]] && break
  fi
  if command -v udevadm >/dev/null 2>&1; then
    udevadm settle || true
  fi
  sleep 0.5
done

if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  [[ -b "$EFI_PART" && -b "$BOOT_PART" && -b "$ROOT_PART" ]] || {
    echo "Encrypted-install partitions did not appear as expected." >&2
    exit 1
  }
else
  [[ -b "$EFI_PART" && -b "$ROOT_PART" ]] || {
    echo "Partitions did not appear as expected." >&2
    exit 1
  }
fi

echo "Formatting filesystems..."
mkfs.vfat -F 32 -n VIBRALI_EFI "$EFI_PART"

if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  mkfs.ext4 -F -L VIBRALI_BOOT "$BOOT_PART"
  printf '%s' "$LUKS_PASSWORD" | cryptsetup luksFormat --type luks2 --batch-mode --key-file - "$ROOT_PART"
  printf '%s' "$LUKS_PASSWORD" | cryptsetup open --key-file - "$ROOT_PART" "$CRYPT_NAME"
  ROOT_DEVICE="/dev/mapper/$CRYPT_NAME"
fi
mkfs.ext4 -F -L VIBRALI_ROOT "$ROOT_DEVICE"

mkdir -p "$TARGET"
mount "$ROOT_DEVICE" "$TARGET"
MOUNTS+=("$TARGET")
mkdir -p "$TARGET/boot"
if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  mount "$BOOT_PART" "$TARGET/boot"
  MOUNTS+=("$TARGET/boot")
fi
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
if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  PACKAGES+=(cryptsetup-initramfs)
fi

echo "Installing Vibrali packages..."
chroot "$TARGET" apt-get update

if printf '%s\n' "${PACKAGES[@]}" | grep -Fxq wireshark-common; then
  printf '%s\n' 'wireshark-common wireshark-common/install-setuid boolean true' |
    chroot "$TARGET" debconf-set-selections
fi

chroot "$TARGET" env DEBIAN_FRONTEND=noninteractive apt-get install -y "${PACKAGES[@]}"

echo "Applying Vibrali identity and desktop defaults..."
rsync -rlptD --chown=0:0 "$ROOT_DIR/config/rootfs/" "$TARGET/"
chmod 0755 "$TARGET/usr/local/bin/vibrali-session-init" "$TARGET/usr/local/bin/vibrali-info" "$TARGET/usr/local/bin/vibrali-welcome" "$TARGET/usr/local/bin/vibrali-toolbox" "$TARGET/usr/local/bin/vibrali-firewall" "$TARGET/usr/local/bin/vibrali-display-scale" "$TARGET/usr/local/bin/neofetch"
chmod 0440 "$TARGET/etc/sudoers.d/90-vibrali"

mkdir -p "$TARGET/etc/vibrali"
printf '%s\n' base desktop > "$TARGET/etc/vibrali/profiles"
for profile in "${SELECTED_PROFILES[@]}"; do
  printf '%s\n' "$profile" >> "$TARGET/etc/vibrali/profiles"
done

NEOFETCH_SOURCE="$(bash "$ROOT_DIR/scripts/fetch-external-tool.sh" neofetch)"
install -Dm0755 "$NEOFETCH_SOURCE" "$TARGET/usr/local/lib/vibrali/neofetch"

GEF_SOURCE="$(bash "$ROOT_DIR/scripts/fetch-external-tool.sh" gef)"
install -Dm0644 "$GEF_SOURCE" "$TARGET/usr/local/lib/vibrali/gef.py"

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
if chroot "$TARGET" getent group wireshark >/dev/null 2>&1; then
  chroot "$TARGET" usermod -aG wireshark "$USERNAME"
fi
chroot "$TARGET" passwd -l root
chroot "$TARGET" chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

ROOT_UUID="$(blkid -s UUID -o value "$ROOT_DEVICE")"
EFI_UUID="$(blkid -s UUID -o value "$EFI_PART")"

if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  BOOT_UUID="$(blkid -s UUID -o value "$BOOT_PART")"
  LUKS_UUID="$(cryptsetup luksUUID "$ROOT_PART")"
  cat > "$TARGET/etc/crypttab" <<EOF
$CRYPT_NAME UUID=$LUKS_UUID none luks
EOF
  cat > "$TARGET/etc/fstab" <<EOF
UUID=$ROOT_UUID / ext4 defaults,noatime 0 1
UUID=$BOOT_UUID /boot ext4 defaults,noatime 0 2
UUID=$EFI_UUID /boot/efi vfat umask=0077 0 1
EOF
else
  cat > "$TARGET/etc/fstab" <<EOF
UUID=$ROOT_UUID / ext4 defaults,noatime 0 1
UUID=$EFI_UUID /boot/efi vfat umask=0077 0 1
EOF
fi

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
chroot "$TARGET" systemctl enable fstrim.timer
chroot "$TARGET" systemctl enable zramswap.service
chroot "$TARGET" systemctl enable nftables.service
chroot "$TARGET" systemctl enable apparmor.service

# Optional tooling may install background services. Keep network-facing/discovery daemons
# opt-in on a portable workstation that may be connected to untrusted networks.
for unit in tor.service tor@default.service avahi-daemon.service avahi-daemon.socket; do
  if chroot "$TARGET" systemctl list-unit-files "$unit" >/dev/null 2>&1; then
    chroot "$TARGET" systemctl disable "$unit" >/dev/null 2>&1 || true
  fi
done

# Each installed device should create its own runtime identity on first boot.
: > "$TARGET/etc/machine-id"
rm -f "$TARGET/var/lib/dbus/machine-id"

cat > "$TARGET/etc/motd" <<'EOF'
Vibrali Security Linux
Portable. Persistent. Yours.

Use security tooling only on systems you own or are authorized to test.
EOF

if ! verify_install; then
  install -Dm0600 "$INSTALL_LOG" "$TARGET/var/log/vibrali-install.log" || true
  echo "Installer log preserved at: $INSTALL_LOG" >&2
  exit 1
fi

chroot "$TARGET" apt-get clean
sync
install -Dm0600 "$INSTALL_LOG" "$TARGET/var/log/vibrali-install.log"

PASSWORD=""
PASSWORD2=""
LUKS_PASSWORD=""

echo
echo "Vibrali installation complete."
echo "Target: $DEVICE"
echo "Root partition: $ROOT_PART"
if [[ $ENCRYPT_ROOT -eq 1 ]]; then
  echo "Root mapper:    $ROOT_DEVICE"
  echo "Boot:           $BOOT_PART"
fi
echo "EFI:            $EFI_PART"
echo "Host install log: $INSTALL_LOG"
echo "USB install log:  /var/log/vibrali-install.log"
echo
echo "You can now shut down the host, move the USB to another x86_64 PC,"
echo "select the USB from its firmware boot menu, and boot the same writable system."
