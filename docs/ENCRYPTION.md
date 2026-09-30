# Vibrali encrypted root

Vibrali's source installer can create an optional LUKS2-encrypted root filesystem.

This mode is intended for a portable workstation that may be lost or stolen. It keeps the
operating system, home directory, tools, browser profile, captures and project data inside
the encrypted root filesystem while preserving portable boot behavior.

## What is and is not encrypted

With `--encrypt-root`, the disk layout is:

~~~text
GPT
├── BIOS Boot                 1 MiB
├── EFI System                512 MiB FAT32
├── VIBRALI_BOOT              1 GiB ext4
└── VIBRALI_CRYPT             remaining space, LUKS2
    └── vibrali-root           ext4 /
~~~

The EFI System Partition and `/boot` are intentionally unencrypted. The kernel,
initramfs and GRUB files therefore remain readable to someone holding the USB. The root
filesystem and user data are encrypted.

Keeping `/boot` separate lets normal GRUB load the kernel and initramfs without needing
GRUB cryptodisk support. The initramfs then asks for the LUKS passphrase and mounts the
encrypted root.

## Install

On the Debian/Ubuntu build host, install the normal Vibrali source-build dependencies plus
cryptsetup:

~~~bash
sudo apt update
sudo apt install debootstrap gdisk dosfstools e2fsprogs grub2-common cryptsetup
~~~

Inspect the target first:

~~~bash
./scripts/install-to-usb.sh \
  --device /dev/sdX \
  --profiles all \
  --encrypt-root \
  --dry-run
~~~

Then install:

~~~bash
sudo ./scripts/install-to-usb.sh \
  --device /dev/sdX \
  --profiles all \
  --encrypt-root \
  --yes-really-erase
~~~

The installer asks separately for the desktop user's password and the LUKS2 root
passphrase. They may be different and generally should be.

## Portability model

Vibrali does not enroll a TPM key or bind the encrypted volume to a specific motherboard.
The LUKS2 UUID is stored in `/etc/crypttab`; early userspace requests the passphrase at
boot. This design is intended to remain portable across supported x86_64 computers.

Actual multi-machine encrypted boot remains a hardware-validation item in the roadmap
until tested on the published compatibility set.

## Recovery key

After the first successful boot, add a second passphrase dedicated to recovery:

~~~bash
sudo cryptsetup luksAddKey /dev/disk/by-partlabel/VIBRALI_CRYPT
~~~

Store that recovery passphrase separately from the USB.

Do not remove the original keyslot until the new recovery passphrase has been tested.

## Back up the LUKS header

A damaged LUKS header can make the encrypted data inaccessible even if the payload remains
intact. Create a header backup on a different trusted device:

~~~bash
sudo cryptsetup luksHeaderBackup \
  /dev/disk/by-partlabel/VIBRALI_CRYPT \
  --header-backup-file /path/on/separate-disk/vibrali-luks-header.img
~~~

The header backup contains sensitive keyslot metadata. Protect it like a secret and keep
it separate from the Vibrali USB.

See [RECOVERY.md](RECOVERY.md) for opening the encrypted volume and repairing initramfs or
GRUB from rescue media.

## Public release image

The guided public release image is currently unencrypted. Encryption is available through
the source installer only. This distinction remains explicit until the guided installer
has a supported encrypted-image workflow.
