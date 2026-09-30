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

The native installer currently installs all profiles. A profile selector is planned.

## External tools

Some important security tools are not packaged in Debian 13. Those should eventually be
installed from their official upstream releases with pinned versions and checksums.

Planned external integrations include tools such as Burp Suite Community, Ghidra, Rizin,
modern Go/Rust reconnaissance utilities and optional CTF-specific environments.

Vibrali should not curl arbitrary community install scripts into root. External tooling
must have a reviewable source, version and verification path.
