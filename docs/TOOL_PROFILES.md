# Vibrali tool profiles

Vibrali keeps the workstation modular. The source installer always installs the `base` and `desktop` profiles; security profiles can be selected individually or installed together with `--profiles all`.

The package manifests under `packages/` are authoritative. This document explains what each profile is for and the representative command used by release smoke tests.

| Profile | Purpose | Representative runtime check | Package highlights |
| --- | --- | --- | --- |
| `base` | Portable Debian foundation and development shell | `python3 --version` | Git, curl/wget, jq, compilers, Python, SSH client, tmux, rsync, firmware, kernel |
| `desktop` | XFCE workstation and browser | `firefox-esr` present | XFCE, LightDM, NetworkManager, Firefox ESR, terminal, clipboard, archive tools |
| `network` | Network discovery, capture and tunnelling | `nmap --version` | Nmap, Masscan, tcpdump/TShark, Ncat, Socat, OpenVPN, WireGuard, proxychains |
| `web` | Web reconnaissance and testing | `sqlmap --version` + pinned Burp artifact | Burp Suite Desktop, SQLMap, ffuf, Gobuster, Nikto, Wfuzz, WhatWeb, dirsearch |
| `auth-audit` | Password/hash authentication auditing | `hashcat --version` | Hashcat, John, Hydra, HashID, Crunch |
| `pwn` | Exploit development and CTF binaries | `gcc --version` | GCC, Clang, make, pwntools, Ruby |
| `reverse` | Native/mobile reverse engineering and debugging | `gdb --version` + pinned Cutter artifact | Cutter/Rizin, GDB, LLDB, strace/ltrace, binutils, QEMU user-mode, APKTool, Valgrind |
| `crypto` | Cryptography/math scripting | `openssl version` | OpenSSL, PARI/GP, SymPy, gmpy2, PyCryptodome, Z3 |
| `forensics` | Filesystem/media/file analysis | `yara --version` | YARA, Sleuth Kit, Autopsy, Binwalk, ExifTool, foremost, TestDisk |
| `wireless` | Wi-Fi assessment workflows | `aircrack-ng` present | Aircrack-ng, hcxtools, Reaver, Bully, iw, rfkill, macchanger |
| `directory-services` | LDAP/Kerberos/SMB/AD client tooling | Python `impacket` import | Impacket, LDAP utilities, Kerberos client, Remmina |
| `defensive` | Local host inspection | `lynis` present | Lynis, chkrootkit |
| `containers` | Rootless container/lab workflows | `podman --version` | Podman, Buildah, Skopeo, podman-compose, fuse-overlayfs |
| `dev-runtimes` | Optional CTF/dev language runtimes | `go version`, `rustc --version`, `node --version` | Go, Rust/Cargo, Node.js/npm |
| `wordlists` | Wordlist generation and packaged dictionaries | CeWL/Crunch/CUPP + dictionary files | CeWL, Crunch, CUPP, large American/British dictionaries, French dictionary |

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
  --profiles web,network,forensics,containers,dev-runtimes,wordlists \
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

The full QEMU release smoke test goes further. Release images are built with all profiles, then the guest checks a broad runtime matrix across the shipped CLI toolset: core network scanners/capture clients, web tools, password-audit tools, compilers/pwntools/binutils, reverse-engineering/debuggers, forensics utilities, wireless clients, directory-service clients, defensive tooling and wordlist generators/dictionary files. A failed command check blocks publication.

A command-presence/runtime smoke check is not a claim that every feature of a tool works on every machine. Wireshark capture permissions for the normal desktop user, wireless monitor mode, GPU acceleration, USB adapters, graphical acceleration and similar hardware-dependent behavior still require physical validation.

## External tools

Tools that are not available from the selected Debian release should not be added through arbitrary installer scripts. They belong in Vibrali's pinned external-tool framework with a fixed version, official source, checksum and license context.

See [TOOLING.md](TOOLING.md) and `external-tools/README.md`.


## Rootless container persistence

The `containers` profile uses Podman so a normal Vibrali user can keep container images, volumes and lab state under the persistent home directory without enabling a privileged Docker daemon by default. The QEMU smoke test creates a rootless Podman volume on the first boot and requires it to still exist on the second boot.
