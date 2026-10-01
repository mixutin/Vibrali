<div align="center">

# ⚡ Vibrali

### Your full pentesting Linux workstation, carried on a USB drive.

**Plug in. Boot. Work. Unplug. Everything is still there.**

[![Validate](https://github.com/mixutin/Vibrali/actions/workflows/validate.yml/badge.svg)](https://github.com/mixutin/Vibrali/actions/workflows/validate.yml)
[![Website](https://img.shields.io/badge/site-Vibrali-00d9ff)](https://mixutin.github.io/Vibrali/)
[![Release](https://img.shields.io/github/v/release/mixutin/Vibrali?include_prereleases&label=release)](https://github.com/mixutin/Vibrali/releases)
[![Status](https://img.shields.io/badge/channel-rolling%20preview-825cff)](ROADMAP.md)

</div>

---

## What is Vibrali?

**Vibrali** is a portable Linux distribution for authorized pentesting, CTFs, reverse
engineering, digital forensics and security research.

The main Vibrali experience is **not a read-only Live ISO with a persistence overlay**.
Vibrali installs a normal, fully writable Linux system directly onto removable storage.

That means the USB behaves much more like an external SSD:

- the root filesystem is normally writable,
- apt install and apt upgrade work normally,
- kernel and initramfs updates persist,
- /etc, /var, /opt and /home are genuinely writable,
- development environments and toolchains stay installed,
- and the same system can be booted on different x86_64 PCs.

> Use Vibrali only on systems and networks you own or have explicit permission to test.

## Portable disk architecture

~~~text
                    VIBRALI USB
                         |
              GPT partition table
                         |
        +----------------+------------------+
        |                |                  |
   BIOS boot         EFI System         Linux root
     1 MiB             512 MiB            rest
      EF02              FAT32              ext4
        |                |                  |
   legacy GRUB     EFI/BOOT/BOOTX64.EFI     /
                                             |
                         +-------------------+---------------+
                         |                   |               |
                       /etc                /var            /home
                    system config       packages/logs    projects/data
~~~

The EFI bootloader is installed in **removable-media mode** rather than depending on one
computer's firmware NVRAM entry. That is important for moving the drive between PCs.

## What persists?

Everything on the root filesystem persists because this is a normal installation.

Examples:

- installed APT packages,
- Python virtual environments,
- Rust and Go toolchains,
- Burp projects and browser profiles,
- SSH keys and Git configuration,
- CTF challenge files,
- packet captures,
- wordlists,
- Docker/container state when installed,
- desktop settings,
- kernel updates and drivers.

There is no persistence.conf or OverlayFS layer in the primary installation mode.

## Starter toolset

| Area | Examples |
| --- | --- |
| Network | Nmap, tcpdump, Wireshark/TShark, Socat, Netcat, DNS tools |
| Web | curl, wget, jq, Firefox ESR |
| Reverse engineering | GDB, LLDB, binutils, strace, ltrace |
| Development | GCC, Clang, make, Python 3, pip, virtualenv |
| Forensics | binwalk, Sleuth Kit, ExifTool, foremost, TestDisk |
| Wireless | Aircrack-ng, iw, wireless-tools, rfkill |
| Workflow | Git, tmux, ripgrep, fd, rsync, OpenSSH |

Tool manifests live under packages/. The plan is to grow these into modular profiles
for web, network, pwn, reversing, crypto, forensics and wireless work.

## Install to a USB

**Warning: the selected target device is erased.**

The fastest path is the guided release installer:

~~~bash
curl -fsSL https://mixutin.github.io/Vibrali/install.sh | bash
~~~

It downloads the latest prebuilt image, verifies SHA-256, displays the target disk model,
size and serial, requires an explicit destructive confirmation, writes with progress,
and then asks you to set the Vibrali password and hostname.

Prefer downloading and reviewing the script first if you do not normally pipe scripts
from the network into a shell.

The source-based debootstrap installer remains available for developers:

~~~bash
sudo ./scripts/install-to-usb.sh --device /dev/sdX --yes-really-erase
~~~

See [docs/USB_INSTALL.md](docs/USB_INSTALL.md) before using physical media. After
installation, [docs/WORKSTATION.md](docs/WORKSTATION.md) covers the persistent work
folders, SSH/Git setup, storage-health checks and backups.

## Default desktop

Vibrali boots into a preconfigured XFCE environment with its own wallpaper, logo,
LightDM greeter, Plymouth splash and GRUB identity. Arc Dark, Papirus Dark, JetBrains
Mono and a cyan/violet terminal palette provide the default visual language.

Interactive shells use Zsh + Starship and show a branded Fastfetch summary. Fastfetch,
legacy Neofetch 7.1.0, Screenfetch and Inxi are available out of the box.

On the first XFCE login, Vibrali shows a welcome/status checklist with network state,
free storage, kernel/hostname information and the exact security-tool profiles installed
on that USB. The screen can be reopened later from the application menu or with
`vibrali-welcome --show`.

The desktop also includes persistent clipboard history, Xfce screenshots and Thunar
archive integration. Bash and Zsh provide small workflow helpers such as `netstate`,
`vprofiles`, `mkcd` and a localhost-only `serve` command for quick local file serving.

## QEMU / KVM

Tagged releases also publish a compressed QCOW2 image. See [docs/VM.md](docs/VM.md).

## Website

Project site: **https://mixutin.github.io/Vibrali/**

GitHub Pages is deployed automatically from `site/`. Release buttons resolve the newest
GitHub release dynamically.

## Portability

Vibrali is being designed for a broad x86_64 hardware target rather than one specific
PC. The installer uses UUID-based mounts and installs GRUB to the standard removable EFI
path.

For the first development builds, **Secure Boot should be disabled**. Signed boot support
is a later milestone.

A fast USB 3.x SSD or NVMe enclosure is strongly preferred over a cheap flash drive.
A full Linux installation generates considerably more writes than a conventional Live
USB.

## Live/recovery mode

A Live image can still be useful for rescue, diagnostics and installing Vibrali, but it
is secondary to the normal writable USB installation.

The existing live-build work remains experimental while the native USB workflow becomes
the primary target.

## Repository layout

~~~text
Vibrali/
├── assets/                 branding
├── config/                 shared and live/recovery configuration
├── docs/                   architecture and installation docs
├── external-tools/          pinned verified non-Debian artifacts
├── packages/               native-system package manifests
├── scripts/                installer, image build and validation helpers
├── site/                   GitHub Pages website + curl installer
├── .github/workflows/      CI, Pages and release automation
├── ROADMAP.md
└── README.md
~~~

## Development

Run:

~~~bash
./scripts/validate.sh
~~~

before opening a pull request.

Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the system design and
[ROADMAP.md](ROADMAP.md) for upcoming work. User-facing help lives in
[docs/FAQ.md](docs/FAQ.md), [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) and
[docs/RECOVERY.md](docs/RECOVERY.md). Contributors should start with
[CONTRIBUTING.md](CONTRIBUTING.md) and [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## License

Project-specific source and configuration are GPL-3.0-only. Packaged software retains
its upstream license.


Encrypted source installs: see [docs/ENCRYPTION.md](docs/ENCRYPTION.md).


Secure Boot design: see [docs/SECURE_BOOT.md](docs/SECURE_BOOT.md).


Rescue media: see [docs/RESCUE_ISO.md](docs/RESCUE_ISO.md).
