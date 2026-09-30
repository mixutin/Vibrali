# Building and installing Vibrali

## Primary development path

Vibrali currently builds the target system directly onto a USB/SSD with debootstrap.

Install host dependencies:

~~~bash
sudo apt update
sudo apt install debootstrap gdisk dosfstools e2fsprogs grub2-common
~~~

Then follow [USB_INSTALL.md](USB_INSTALL.md).

## Validation

Run the fast repository checks with:

~~~bash
./scripts/validate.sh
~~~

The installer also has a root-only loop-device safety test that creates disposable sparse
disk images, verifies that `--dry-run` does not modify them, rejects an undersized target,
and confirms a real install cannot proceed without `--yes-really-erase`:

~~~bash
sudo ./scripts/test-installer-device-safety.sh
~~~

CI runs both layers. The safety test never points at a physical disk.

## Live/recovery image

The repository still contains early Debian live-build configuration. This is being kept
for the future installer/recovery environment, not as Vibrali's primary persistent
system.

The experimental live image can currently be built with:

~~~bash
sudo apt install live-build debootstrap squashfs-tools xorriso isolinux syslinux-common
./scripts/build.sh
~~~

## QEMU

The existing run-qemu helper targets the experimental ISO workflow. A native raw-disk
QEMU test path is on the roadmap.
