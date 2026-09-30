# Installing Vibrali to USB

Vibrali creates a full writable system directly on removable storage. The selected disk is completely erased.

## Fast release install

For normal installs, use the release-backed guided installer:

~~~bash
curl -fsSL https://mixutin.github.io/Vibrali/install.sh | bash
~~~

The USB release image is prebuilt, checksum-verified and locked until the installer asks
you to choose a new password. This is substantially faster than bootstrapping every
package locally. Release images contain the full optional security-tool profile set.

## Source install

The steps below describe the slower developer/source installation path.

## Recommended hardware

Use a USB 3.x SSD or an NVMe/SATA SSD in a good USB enclosure. The source installer
enforces a 12 GiB absolute minimum, but 64 GB is the practical recommendation for a
full pentesting workstation. 128 GB or more leaves much more room for tools, captures,
VMs, wordlists and CTF files.

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

## Choose package profiles

The source installer always installs the `base` and `desktop` manifests. Security-tool
manifests are optional profiles.

List the available profile names without root access or touching a disk:

~~~bash
./scripts/install-to-usb.sh --list-profiles
~~~

By default, source installs use `--profiles all`, matching the full release image. Use
`--profiles none` for only the mandatory core, or pass a comma-separated subset such as:

~~~bash
--profiles web,network,forensics
~~~

Profiles only control packages installed during the source bootstrap. They do not remove
packages from a prebuilt release image.

## Preflight without changing the disk

Before a source install, inspect the exact target and selected profiles with:

~~~bash
./scripts/install-to-usb.sh \
  --device /dev/sdX \
  --profiles all \
  --dry-run
~~~

Dry-run mode does not require root, does not require `--yes-really-erase`, and exits
before partitioning, formatting or mounting anything. It validates that the target is a
whole disk, refuses the running root disk, enforces the minimum device size, displays
model/serial/transport/removable metadata, and warns when a target does not look like
removable or USB storage.

## Install

Full profile set:

~~~bash
sudo ./scripts/install-to-usb.sh \
  --device /dev/sdX \
  --username vibrali \
  --hostname vibrali \
  --profiles all \
  --yes-really-erase
~~~

Smaller source install example:

~~~bash
sudo ./scripts/install-to-usb.sh \
  --device /dev/sdX \
  --profiles web,network \
  --yes-really-erase
~~~

The script displays the target model/size/serial/transport/removable status, shows the
selected optional profiles, checks the target size, and requires the full device path to
be typed again before partitioning. It then prompts for the initial user's password.

During a real source install, output is copied to a temporary host-side log under
`/tmp/vibrali-install.*.log`. On success, the log is also stored on the installed USB
at `/var/log/vibrali-install.log`.

Before reporting success, the installer verifies the removable UEFI bootloader, root and
EFI UUID entries in `fstab`, the requested user account, and that NetworkManager and
LightDM are enabled. A failed critical check makes the installer exit nonzero and keeps
the host log for troubleshooting.

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


## After installation

See [WORKSTATION.md](WORKSTATION.md) for the persistent work-folder layout, SSH/Git
configuration, zram/TRIM health checks and backup guidance.
