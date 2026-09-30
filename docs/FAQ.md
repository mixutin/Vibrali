# Vibrali FAQ

## Is Vibrali a Live USB?

Not in its primary mode. Vibrali installs a normal writable Debian system directly to removable storage. The root filesystem, packages, configuration and home directory persist normally.

## Is this just Kali Linux copied to a USB?

The intended experience is similar to carrying a Kali-style pentesting workstation on a USB, but Vibrali is built from Debian with its own package profiles, defaults, installer, branding and release process. It does not currently claim Kali package compatibility.

## Why not use a persistence overlay?

A normal writable installation makes APT upgrades, kernels, initramfs, `/etc`, `/var`, development toolchains and application state behave like a conventional workstation instead of a read-only base plus overlay.

## What storage should I use?

A USB 3.x SSD or NVMe/SATA SSD in a reliable enclosure is recommended. The source installer enforces its documented absolute minimum, but 64 GB or larger is the practical baseline for a full toolset and 128 GB+ is preferable for captures, wordlists and project data.

## Can I move one Vibrali drive between computers?

That is a core goal. Vibrali uses UUID-based mounts and removable-media UEFI boot so it does not depend on one host's `/dev/sdX` name or firmware NVRAM entry. Hardware compatibility still needs real-machine validation.

## Does Secure Boot work?

Not yet as a supported configuration. Current development guidance is to disable Secure Boot. Signed boot artifacts are a roadmap item.

## Is the USB encrypted?

Not by default yet. LUKS2 portable encrypted-root support is planned. Until then, treat an unencrypted Vibrali drive as readable by anyone who obtains the device.

## Are all security tools installed?

Release images currently target the full optional profile set. Source installs can select profiles. Some tools are supplied by Debian, while non-Debian integrations must use Vibrali's pinned and checksum-verified external-tool framework.

## Can I install normal Debian packages?

Yes. Vibrali's primary install is a normal writable Debian system, so APT package installation and upgrades persist.

## Can I use Docker, Rust, Go or Node.js?

The system can support normal development environments, but some of these are still roadmap items as preconfigured optional profiles. You can install additional software normally on your writable USB.

## Can I boot Vibrali in a VM?

Yes. Tagged releases are designed to publish a QCOW2 image, and the release pipeline also uses QEMU/OVMF smoke tests.

## What if the USB stops booting?

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) and [RECOVERY.md](RECOVERY.md). Common recovery includes checking UUIDs, rebuilding initramfs and reinstalling GRUB in removable-media mode.

## Is Vibrali safe to use on any network?

Security tools should only be used on systems and networks you own or have explicit permission to test. Vibrali is a workstation; authorization and legal scope remain the user's responsibility.

## What counts as Vibrali 1.0?

The concrete finish line is in [../ROADMAP.md](../ROADMAP.md). It includes public installation, persistent operation, multi-machine hardware testing, tool verification, recovery documentation, release validation and stable publication.
