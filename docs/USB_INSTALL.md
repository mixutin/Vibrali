# Installing Vibrali to USB

Vibrali creates a full writable system directly on removable storage. The selected disk is completely erased.

## Fast release install

For normal installs, use the release-backed guided installer:

~~~bash
curl -fsSL https://mixutin.github.io/Vibrali/install.sh | bash
~~~

The USB release image is prebuilt, checksum-verified and locked until the installer asks
you to choose a new password. This is substantially faster than bootstrapping every
package locally.

## Source install

The steps below describe the slower developer/source installation path.

## Recommended hardware

Use a USB 3.x SSD or an NVMe/SATA SSD in a good USB enclosure. A 64 GB device is a
reasonable development minimum; 128 GB or more leaves room for tools, captures, VMs and
CTF files.

## Build-host dependencies

On Debian or Ubuntu:

~~~bash
sudo apt update
sudo apt install debootstrap gdisk dosfstools e2fsprogs grub2-common
~~~

The installer also expects standard util-linux tools such as lsblk, blkid, mount and
chroot.

## Identify the target

Use:

~~~bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN,MOUNTPOINTS
~~~

Identify the entire removable disk, for example /dev/sdb. Do not pass a partition such
as /dev/sdb1.

**The target disk is erased.**

## Install

~~~bash
sudo ./scripts/install-to-usb.sh \
  --device /dev/sdX \
  --username vibrali \
  --hostname vibrali \
  --yes-really-erase
~~~

The script displays the target model/size/serial and requires the full device path to be
typed again before partitioning. It then prompts for the initial user's password.

## What the installer creates

~~~text
GPT
├── 1 MiB BIOS Boot partition
├── 512 MiB FAT32 EFI System Partition
└── ext4 root filesystem using the remaining space
~~~

The Vibrali base is bootstrapped into the root filesystem from Debian 13 package repositories. Vibrali package manifests and branding are then applied, a normal user is created, and GRUB is configured for portable UEFI boot.

Legacy BIOS GRUB is attempted as well.

## First boot

Shut the host down cleanly after installation, move the drive to the target computer,
open its firmware boot menu and select the USB device.

During early development, disable Secure Boot.

Once booted, Vibrali behaves like a normal full Linux installation: use APT normally, create files, install development environments and upgrade the kernel.

## Important portability notes

Do not install a host-specific initramfs optimization that removes drivers for hardware
not present on the current PC.

Avoid depending on firmware NVRAM boot entries. Vibrali intentionally uses the standard
removable EFI path.

For sensitive work, wait for the planned LUKS2 installer mode or manually encrypt
sensitive project data.
