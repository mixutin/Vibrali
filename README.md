<div align="center">

# ⚡ Vibrali

### Your full pentesting Linux workstation, carried on a USB drive.

**Plug in. Boot. Work. Unplug. Everything is still there.**

[![Validate](https://github.com/mixutin/Vibrali/actions/workflows/validate.yml/badge.svg)](https://github.com/mixutin/Vibrali/actions/workflows/validate.yml)
[![Debian](https://img.shields.io/badge/base-Debian%2013-D70A53?logo=debian&logoColor=white)](https://www.debian.org/)
[![Status](https://img.shields.io/badge/status-early%20development-orange)](ROADMAP.md)

</div>

---

## What is Vibrali?

**Vibrali** is a portable Linux distribution for authorized pentesting, CTFs, reverse
engineering, digital forensics and security research.

The main Vibrali experience is **not a read-only Live ISO with a persistence overlay**.
Vibrali installs a normal Debian system directly onto removable storage.

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

**Warning: the target device is erased.**

On a Debian/Ubuntu host, install the builder dependencies:

~~~bash
sudo apt update
sudo apt install debootstrap gdisk dosfstools e2fsprogs grub2-common
~~~

Then:

~~~bash
git clone https://github.com/mixutin/Vibrali.git
cd Vibrali
sudo ./scripts/install-to-usb.sh \
  --device /dev/sdX \
  --username vibrali \
  --yes-really-erase
~~~

The installer requires you to type the full device path again before it erases anything.

See [docs/USB_INSTALL.md](docs/USB_INSTALL.md) before using it on physical media.

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
├── packages/               native-system package manifests
├── scripts/                installer, build and validation helpers
├── .github/workflows/      CI
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
[ROADMAP.md](ROADMAP.md) for upcoming work.

## License

Project-specific source and configuration are GPL-3.0-only. Packaged software retains
its upstream license.
