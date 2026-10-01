#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/dist/.ci}"
SIZE="${VIBRALI_ENCRYPTED_CI_SIZE:-16G}"
RAW="$OUT/vibrali-encrypted-ci.raw"
QCOW="$OUT/vibrali-encrypted-ci.qcow2"
MOUNT="$OUT/encrypted-root"
CRYPT_NAME="vibrali-ci-root"
LUKS_PASSWORD="${VIBRALI_LUKS_PASSWORD:-vibrali-ci-luks}"
LOOP=""
CHROOT_MOUNTS=()

fail() {
  echo "encrypted CI image build failed: $*" >&2
  exit 1
}

[[ $EUID -eq 0 ]] || fail "run this builder as root"

for cmd in truncate losetup cryptsetup mount umount mountpoint qemu-img install chroot grep; do
  command -v "$cmd" >/dev/null 2>&1 || fail "missing command: $cmd"
done

mkdir -p "$OUT" "$MOUNT"
rm -f "$RAW" "$QCOW"

close_crypt_mapping() {
  local attempt close_log
  cryptsetup status "$CRYPT_NAME" >/dev/null 2>&1 || return 0

  close_log="$(mktemp /tmp/vibrali-crypt-close.XXXXXX)"
  sync
  command -v udevadm >/dev/null 2>&1 && udevadm settle || true

  for attempt in {1..10}; do
    if cryptsetup close "$CRYPT_NAME" 2>"$close_log"; then
      rm -f "$close_log"
      return 0
    fi
    command -v udevadm >/dev/null 2>&1 && udevadm settle || true
    sleep 1
  done

  echo "encrypted CI image build failed: mapper $CRYPT_NAME is still in use after cleanup retries" >&2
  cat "$close_log" >&2 || true
  rm -f "$close_log"

  echo "Remaining mounts under $MOUNT:" >&2
  findmnt -R "$MOUNT" >&2 || true
  echo "Device-mapper state:" >&2
  command -v dmsetup >/dev/null 2>&1 && dmsetup info -c "$CRYPT_NAME" >&2 || true
  echo "Processes holding /dev/mapper/$CRYPT_NAME:" >&2
  command -v fuser >/dev/null 2>&1 && fuser -vm "/dev/mapper/$CRYPT_NAME" >&2 || true
  return 1
}

cleanup() {
  set +e
  local i
  for ((i=${#CHROOT_MOUNTS[@]}-1; i>=0; i--)); do
    mountpoint -q "${CHROOT_MOUNTS[$i]}" && umount -R "${CHROOT_MOUNTS[$i]}"
  done
  mountpoint -q "$MOUNT" && umount -R "$MOUNT"
  close_crypt_mapping || true
  [[ -z "$LOOP" ]] || losetup -d "$LOOP" 2>/dev/null || true
}
trap cleanup EXIT

truncate -s "$SIZE" "$RAW"
LOOP="$(losetup --find --show "$RAW")"

echo "Building encrypted Vibrali CI disk on $LOOP..."
VIBRALI_PASSWORD=vibrali VIBRALI_LUKS_PASSWORD="$LUKS_PASSWORD" \
  "$ROOT/scripts/install-to-usb.sh" \
    --device "$LOOP" \
    --username vibrali \
    --hostname vibrali \
    --profiles none \
    --encrypt-root \
    --yes-really-erase \
    --non-interactive

EFI_PART="${LOOP}p2"
BOOT_PART="${LOOP}p3"
CRYPT_PART="${LOOP}p4"

printf '%s' "$LUKS_PASSWORD" | cryptsetup open --key-file - "$CRYPT_PART" "$CRYPT_NAME"
mount "/dev/mapper/$CRYPT_NAME" "$MOUNT"
mount "$BOOT_PART" "$MOUNT/boot"
mount "$EFI_PART" "$MOUNT/boot/efi"

KEY_DIR="$MOUNT/etc/cryptsetup-keys.d"
KEY_FILE="$KEY_DIR/vibrali-root.key"
mkdir -p "$KEY_DIR"
printf 'vibrali-ci-auto-unlock-key\n' > "$KEY_FILE"
chmod 0600 "$KEY_FILE"

printf '%s' "$LUKS_PASSWORD" |
  cryptsetup luksAddKey --batch-mode --key-file - "$CRYPT_PART" "$KEY_FILE"

LUKS_UUID="$(cryptsetup luksUUID "$CRYPT_PART")"
cat > "$MOUNT/etc/crypttab" <<EOF
$CRYPT_NAME UUID=$LUKS_UUID /etc/cryptsetup-keys.d/vibrali-root.key luks,initramfs
EOF

mkdir -p "$MOUNT/etc/cryptsetup-initramfs"
cat > "$MOUNT/etc/cryptsetup-initramfs/conf-hook" <<'EOF'
KEYFILE_PATTERN=/etc/cryptsetup-keys.d/*.key
EOF
chmod 0600 "$MOUNT/etc/cryptsetup-initramfs/conf-hook"

# The initramfs intentionally contains a CI-only unlock key. Keep the generated
# image private even on a shared build host.
if grep -q '^UMASK=' "$MOUNT/etc/initramfs-tools/initramfs.conf"; then
  sed -i 's/^UMASK=.*/UMASK=0077/' "$MOUNT/etc/initramfs-tools/initramfs.conf"
else
  printf '\nUMASK=0077\n' >> "$MOUNT/etc/initramfs-tools/initramfs.conf"
fi

install -Dm0755 "$ROOT/scripts/ci/vibrali-ci-probe" "$MOUNT/usr/local/sbin/vibrali-ci-probe"
install -Dm0644 "$ROOT/scripts/ci/vibrali-ci-probe.service" "$MOUNT/etc/systemd/system/vibrali-ci-probe.service"
mkdir -p "$MOUNT/etc/systemd/system/graphical.target.wants"
ln -sfn /etc/systemd/system/vibrali-ci-probe.service \
  "$MOUNT/etc/systemd/system/graphical.target.wants/vibrali-ci-probe.service"

for source in /dev /proc /sys /run; do
  target="$MOUNT$source"
  mkdir -p "$target"
  mount --rbind "$source" "$target"
  mount --make-rslave "$target"
  CHROOT_MOUNTS+=("$target")
done

kernel_pkg="$(chroot "$MOUNT" dpkg-query -W -f='${binary:Package}\n' 'linux-image-[0-9]*-amd64' 2>/dev/null | sort -V | tail -n 1)"
[[ -n "$kernel_pkg" ]] || fail "could not identify installed Debian kernel package"

echo "Reinstalling $kernel_pkg to exercise encrypted kernel/initramfs hooks..."
chroot "$MOUNT" apt-get update
chroot "$MOUNT" env DEBIAN_FRONTEND=noninteractive apt-get install --reinstall -y "$kernel_pkg"

echo "Regenerating encrypted initramfs and GRUB..."
chroot "$MOUNT" update-initramfs -u -k all
chroot "$MOUNT" update-grub
printf '%s\n' "$kernel_pkg" > "$MOUNT/etc/vibrali/ci-encrypted-kernel-package"

latest_initrd="$(find "$MOUNT/boot" -maxdepth 1 -type f -name 'initrd.img-*' | sort -V | tail -n 1)"
[[ -n "$latest_initrd" ]] || fail "no initramfs found after regeneration"
INITRAMFS_KEY_PATH="cryptroot/keyfiles/$CRYPT_NAME.key"
chroot "$MOUNT" lsinitramfs "/boot/${latest_initrd##*/}" | grep -Fxq "$INITRAMFS_KEY_PATH" ||
  fail "CI LUKS key was not embedded in initramfs at $INITRAMFS_KEY_PATH"

for ((i=${#CHROOT_MOUNTS[@]}-1; i>=0; i--)); do
  mountpoint -q "${CHROOT_MOUNTS[$i]}" && umount -R "${CHROOT_MOUNTS[$i]}"
done
CHROOT_MOUNTS=()

sync
umount -R "$MOUNT"
close_crypt_mapping || fail "could not close encrypted CI mapper after unmount"
losetup -d "$LOOP"
LOOP=""

qemu-img convert -p -f raw -O qcow2 -c "$RAW" "$QCOW"
rm -f "$RAW"

echo "Encrypted CI image: $QCOW"
