# Vibrali rescue ISO

The rescue image is a Debian live system intended for repairing Vibrali installations and launching a fresh source install without modifying the rescue medium itself.

## Included recovery capabilities

The rescue profile includes:

- partition inspection and repair with GParted, Parted and GPT fdisk;
- ext4, XFS and Btrfs filesystem tools;
- LUKS, LVM and mdraid tooling;
- TestDisk/PhotoRec recovery utilities;
- SMART and NVMe health inspection;
- NetworkManager plus ping, DNS, traceroute, MTR and Ethernet diagnostics;
- XFCE with a desktop **Install Vibrali** launcher.

The installer launcher runs the same repository source installer used by developers. The live image carries the required Vibrali scripts, package manifests, root filesystem overlay, assets and pinned external-tool manifest under `/usr/share/vibrali-source`.

## Build

Install live-build and rsync on a Debian build host:

~~~bash
sudo apt update
sudo apt install live-build rsync
~~~

Then run:

~~~bash
sudo ./scripts/build-rescue-iso.sh
~~~

The default output is:

~~~text
dist/vibrali-rescue-amd64.iso
dist/vibrali-rescue-amd64.iso.sha256
~~~

The generated image is an amd64 hybrid ISO suitable for optical media or USB imaging.

## Scope

This image is rescue/install media, not the normal portable Vibrali workstation. The main Vibrali product remains the fully writable USB installation produced by the release image or source installer.
