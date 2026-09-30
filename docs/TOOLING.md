# Vibrali tooling

Vibrali installs tools from audited Debian 13 repositories first.

Current profiles:

- base — kernel, firmware, compilers, Python, Git and system utilities
- desktop — XFCE, LightDM and NetworkManager
- network — Nmap, Masscan, packet capture, tunnelling and protocol utilities
- web — SQLMap, Nikto, ffuf, Gobuster, Wfuzz and reconnaissance tools
- auth-audit — Hashcat, John, Hydra and password-auditing utilities
- pwn — compilers, pwntools and exploit-development dependencies
- reverse — GDB, LLDB, QEMU user-mode, APKTool, Valgrind and binary utilities
- crypto — OpenSSL, PARI/GP, SymPy, gmpy2, PyCryptodome and Z3
- forensics — Binwalk, Sleuth Kit, Autopsy, YARA and filesystem/media utilities
- wireless — Aircrack-ng, hcxtools, Reaver, Bully and wireless utilities
- directory-services — Impacket, LDAP/Kerberos clients and remote-access tools
- defensive — Lynis and local integrity/rootkit inspection helpers

The native installer always installs the `base` and `desktop` manifests and supports optional security profiles with `--profiles all|none|name1,name2`. Use `--list-profiles` to see the available optional profiles.

## External tools

Some important security tools are not packaged in Debian 13. Those should eventually be
installed from their official upstream releases with pinned versions and checksums.

Planned external integrations include tools such as Burp Suite Community, Ghidra, Rizin,
modern Go/Rust reconnaissance utilities and optional CTF-specific environments.

Vibrali should not curl arbitrary community install scripts into root. External tooling
must have a reviewable source, version and verification path.


## Profile contract validation

`scripts/validate-tool-profiles.sh` protects the advertised starter-tool contract.
It verifies that representative packages for each profile remain in their intended
manifest. This is a source-level contract only; release and physical-hardware tests are
still required before claiming a tool works correctly at runtime.


## Verified external tools

Non-Debian artifacts are declared in `external-tools/manifest.txt`. The manifest records
an exact version, official HTTPS source, SHA-256, license identifier and artifact type.

`scripts/fetch-external-tool.sh` is the only generic download path for these entries. It
verifies both new downloads and cached copies before returning a path to the caller, and
it never executes the downloaded file. See `external-tools/README.md` for the policy and
review checklist.

Verified pinned entries currently include Neofetch 7.1.0 and GEF 2026.01. GEF is installed from the exact tagged `gef.py` bytes under `/usr/local/lib/vibrali/gef.py`; Vibrali's default `.gdbinit` sources that local verified copy rather than running GEF's network installer.

## Profile reference

See [TOOL_PROFILES.md](TOOL_PROFILES.md) for profile purposes, representative runtime checks and source-installer selection examples.
