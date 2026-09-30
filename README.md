<div align="center">

# ⚡ Vibrali

### Persistent USB Linux for pentesting, CTFs, reverse engineering and security research.

**Boot it. Carry it. Keep your tools.**

[![Validate](https://github.com/mixutin/Vibrali/actions/workflows/validate.yml/badge.svg)](https://github.com/mixutin/Vibrali/actions/workflows/validate.yml)
[![Debian](https://img.shields.io/badge/base-Debian%20Live-D70A53?logo=debian&logoColor=white)](https://www.debian.org/)
[![Status](https://img.shields.io/badge/status-early%20development-orange)](ROADMAP.md)

</div>

---

## What is Vibrali?

**Vibrali** is a USB-first Linux distribution for authorized penetration testing, CTFs,
reverse engineering, digital forensics and security research.

It is designed around **persistence**: your tools, notes, captures, configs and project
files can survive reboots while the base operating system stays portable.

The project takes inspiration from the engineering approach of
[Vibrix](https://github.com/mixutin/Vibrix), while using a mature Linux base so Vibrali
can become useful quickly.

> Use Vibrali only on systems and networks you own or have explicit permission to test.

## Design goals

- **USB first** — bootable removable workstation for x86_64 PCs.
- **Persistent** — optional writable state across reboots.
- **Reproducible** — images generated from version-controlled config.
- **Security focused** — networking, web, pwn, reversing and forensics.
- **Developer ready** — Python, C/C++, debuggers and common CLI tooling.
- **Recoverable** — live mode remains usable without persistence.
- **Transparent** — prefer distro packages and auditable build scripts.

## Architecture

```text
                    VIBRALI
                       │
              Debian Live base
                       │
        ┌──────────────┼──────────────┐
        │              │              │
    Live system     Toolsets      Persistence
        │              │              │
   UEFI / BIOS      network       workspace
   hardware         reverse       configs
   desktop          forensics     notes/data
```

The first implementation uses **Debian live-build**. That gets us to a bootable,
auditable ISO without reinventing the Linux base.

## Starter toolset

| Area | Examples |
| --- | --- |
| Network | Nmap, tcpdump, Wireshark/TShark, Socat, Netcat, DNS tools |
| Web | curl, wget, jq, Chromium, Firefox ESR |
| Reverse engineering | GDB, LLDB, binutils, strace, ltrace |
| Development | GCC, Clang, make, Python 3, pip, virtualenv |
| Forensics | binwalk, Sleuth Kit, ExifTool, foremost, TestDisk |
| Wireless utilities | iw, wireless-tools, rfkill |
| Workflow | Git, tmux, ripgrep, fd, rsync, OpenSSH |

Larger specialist suites will become optional profiles instead of bloating the base ISO.

## Repository layout

```text
Vibrali/
├── assets/                 branding
├── config/                 Debian live-build configuration
│   ├── hooks/live/
│   ├── includes.chroot/
│   └── package-lists/
├── docs/                   architecture and usage docs
├── scripts/                build and validation helpers
├── .github/workflows/      CI
├── ROADMAP.md
└── README.md
```

## Build

On Debian/Ubuntu:

```bash
sudo apt update
sudo apt install live-build debootstrap squashfs-tools xorriso isolinux syslinux-common
git clone https://github.com/mixutin/Vibrali.git
cd Vibrali
./scripts/build.sh
```

The ISO is copied to `build/`. See [docs/BUILDING.md](docs/BUILDING.md).

## Test in QEMU

```bash
./scripts/run-qemu.sh
```

## Persistent USB

A typical device contains the live image plus a second ext4 partition labeled
`persistence`. Its root contains:

```text
persistence.conf
```

with:

```text
/ union
```

Read [docs/PERSISTENCE.md](docs/PERSISTENCE.md) before partitioning a USB drive.

## Roadmap

Near-term work includes the first boot-tested ISO, custom branding, persistence testing,
tool profiles, hardware compatibility work, encrypted persistence, signed releases and
eventually a graphical USB creator. See [ROADMAP.md](ROADMAP.md).

## Contributing

Run `./scripts/validate.sh` before opening a pull request. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

Project-specific source and configuration are GPL-3.0-only. Packaged tools keep their
upstream licenses.
