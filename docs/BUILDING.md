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

## QEMU and release-image testing

The experimental `run-qemu.sh` helper still targets the Live ISO workflow. The primary
portable-disk release path now has an automated OVMF/QEMU integration test:

~~~bash
sudo ./scripts/build-release-images.sh dist
sudo ./scripts/test-qemu-release.sh dist/.ci/vibrali-qemu-ci.qcow2
~~~

The guest boots twice and reports persistence, desktop/network services and the security-tool runtime matrix over the serial console. Public images have the CI-only probe removed before compression.


## Build provenance

`build-release-images.sh` writes `BUILD_INFO.txt` and `PACKAGE_VERSIONS.txt` beside the image artifacts. `BUILD_INFO.txt` records the source commit, Debian suite, architecture, selected profiles, image size, CI reference/run identifiers when available, SHA-256 hashes of package/external-tool manifests and installer/build scripts, and the APT source configuration used in the image. `PACKAGE_VERSIONS.txt` records the exact installed Debian package/version set from the finished root filesystem.

Both files are included in `SHA256SUMS`, so published releases authenticate them through the same Sigstore-signed checksum manifest as the USB and QEMU images. This makes builds auditable and repeatable at the recorded-input level; it is not a claim of byte-for-byte reproducibility across changing Debian mirrors.
