# Vibrali tool profiles

Vibrali keeps the workstation modular. The source installer always installs the `base` and `desktop` profiles; security profiles can be selected individually or installed together with `--profiles all`.

The package manifests under `packages/` are authoritative. This document explains what each profile is for and the representative command used by release smoke tests.

| Profile | Purpose | Representative runtime check | Package highlights |
| --- | --- | --- | --- |
| `base` | Portable Debian foundation and development shell | `python3 --version` | Git, curl/wget, jq, compilers, Python, SSH client, tmux, rsync, firmware, kernel |
| `desktop` | XFCE workstation and browser | `firefox-esr` present | XFCE, LightDM, NetworkManager, Firefox ESR, terminal, clipboard, archive tools |
| `network` | Network discovery, capture and tunnelling | `nmap --version` | Nmap, Masscan, tcpdump/TShark, Ncat, Socat, OpenVPN, WireGuard, proxychains |
| `web` | Web reconnaissance and testing | `sqlmap --version` | SQLMap, ffuf, Gobuster, Nikto, Wfuzz, WhatWeb, dirsearch |
| `auth-audit` | Password/hash authentication auditing | `hashcat --version` | Hashcat, John, Hydra, HashID, Crunch |
| `pwn` | Exploit development and CTF binaries | `gcc --version` | GCC, Clang, make, pwntools, Ruby |
| `reverse` | Native/mobile reverse engineering and debugging | `gdb --version` | GDB, LLDB, strace/ltrace, binutils, QEMU user-mode, APKTool, Valgrind |
| `crypto` | Cryptography/math scripting | `openssl version` | OpenSSL, PARI/GP, SymPy, gmpy2, PyCryptodome, Z3 |
| `forensics` | Filesystem/media/file analysis | `yara --version` | YARA, Sleuth Kit, Autopsy, Binwalk, ExifTool, foremost, TestDisk |
| `wireless` | Wi-Fi assessment workflows | `aircrack-ng` present | Aircrack-ng, hcxtools, Reaver, Bully, iw, rfkill, macchanger |
| `directory-services` | LDAP/Kerberos/SMB/AD client tooling | Python `impacket` import | Impacket, LDAP utilities, Kerberos client, Remmina |
| `defensive` | Local host inspection | `lynis` present | Lynis, chkrootkit |

## Listing and selecting profiles

List available optional profiles:

~~~bash
./scripts/install-to-usb.sh --list-profiles
~~~

Install all profiles:

~~~bash
sudo ./scripts/install-to-usb.sh \
  --device /dev/sdX \
  --profiles all \
  --yes-really-erase
~~~

Install a subset:

~~~bash
sudo ./scripts/install-to-usb.sh \
  --device /dev/sdX \
  --profiles web,network,forensics \
  --yes-really-erase
~~~

Install only the mandatory `base` and `desktop` profiles:

~~~bash
sudo ./scripts/install-to-usb.sh \
  --device /dev/sdX \
  --profiles none \
  --yes-really-erase
~~~

## Runtime verification

Source validation checks that advertised representative packages remain in the correct manifests.

The full QEMU release smoke test goes further. Release images are built with all profiles, then the guest checks representative commands from every profile before the release workflow can publish.

A command-presence/runtime smoke check is not a claim that every feature of a tool works on every machine. Wireless monitor mode, GPU acceleration, USB adapters, graphical acceleration and similar hardware-dependent behavior still require physical validation.

## External tools

Tools that are not available from the selected Debian release should not be added through arbitrary installer scripts. They belong in Vibrali's pinned external-tool framework with a fixed version, official source, checksum and license context.

See [TOOLING.md](TOOLING.md) and `external-tools/README.md`.
