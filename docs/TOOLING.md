# Vibrali tooling

Vibrali installs tools from audited Debian 13 repositories first.

Current profiles:

- base — kernel, firmware, compilers, Python, Git and system utilities
- desktop — XFCE, LightDM and NetworkManager
- network — Nmap, Masscan, packet capture, tunnelling and protocol utilities
- web — Burp Suite Desktop, SQLMap, Nikto, ffuf, Gobuster, Wfuzz and reconnaissance tools
- auth-audit — Hashcat, John, Hydra and password-auditing utilities
- pwn — compilers, pwntools and exploit-development dependencies
- reverse — Cutter/Rizin, GDB, LLDB, QEMU user-mode, APKTool, Valgrind and binary utilities
- crypto — OpenSSL, PARI/GP, SymPy, gmpy2, PyCryptodome and Z3
- forensics — Binwalk, Sleuth Kit, Autopsy, YARA and filesystem/media utilities
- wireless — Aircrack-ng, hcxtools, Reaver, Bully and wireless utilities
- directory-services — Impacket, LDAP/Kerberos clients and remote-access tools
- defensive — Lynis and local integrity/rootkit inspection helpers
- containers — rootless Podman, Buildah, Skopeo and compose-compatible lab tooling
- dev-runtimes — optional Go, Rust/Cargo and Node.js/npm toolchains
- wordlists — CeWL, Crunch, CUPP and packaged large language dictionaries

The native installer always installs the `base` and `desktop` manifests and supports optional security profiles with `--profiles all|none|name1,name2`. Use `--list-profiles` to see the available optional profiles.

## External tools

Some important security tools are not packaged in Debian 13. Vibrali installs selected
ones from official upstream releases with pinned versions and exact checksums.

Current pinned integrations include Burp Suite Desktop, Cutter/Rizin, Subfinder,
Volatility 3, GEF and Neofetch. Ghidra remains a separate roadmap integration until its
reviewed pinned path lands on `main`.

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

Verified pinned entries include Neofetch 7.1.0, GEF 2026.01, Subfinder 2.16.0,
Volatility 3 2.28.2, Burp Suite Desktop 2026.9 and Cutter 2.5.0. GEF is installed from
the exact tagged `gef.py` bytes under `/usr/local/lib/vibrali/gef.py`; Vibrali's default
`.gdbinit` sources that local verified copy rather than running GEF's network installer.

## Profile reference

See [TOOL_PROFILES.md](TOOL_PROFILES.md) for profile purposes, representative runtime checks and source-installer selection examples.


## Packet capture privileges

When the `network` profile is installed, Vibrali enables Debian's supported non-root Wireshark capture mode. The installer pre-seeds `wireshark-common`, gives `dumpcap` only the Linux network-capture capabilities provided by the Debian package, and adds the Vibrali user to the `wireshark` group. The post-install verifier checks both the group membership and capabilities.

Normal Ethernet/Wi-Fi interface capture should therefore use Wireshark/TShark/dumpcap without running the full UI as root. USB packet capture is different and may still require elevated capture privileges; Vibrali does not make Wireshark globally setuid. Release QEMU CI performs a real one-packet loopback capture as the normal `vibrali` user.

The same QEMU probe also transfers a marker over localhost between Socat and Ncat, so their basic client/server workflow is tested rather than merely checking that the binaries exist.

## 32-bit exploit development

The `pwn` profile includes `gcc-multilib` and `libc6-dev-i386` on amd64. Release CI compiles and executes a minimal `-m32` ELF to verify the 32-bit toolchain. This supports common x86 CTF/exploit-development binaries without changing Vibrali's native x86_64 system architecture.


## Phase 2 installability evidence

The package manifests are the authoritative Debian-profile inputs used by both source and
release-image builds. Non-Debian tools are not merely listed: the installer calls
`scripts/fetch-external-tool.sh` for each shipped external artifact, verifies the pinned
SHA-256, and installs the verified file into the target filesystem.

The remaining Phase 2 work is intentionally narrower: Ghidra is still tracked separately,
and hardware-dependent workflows such as wireless monitor mode require physical devices.
Release smoke tests verify installed command/artifact contracts, but GUI interaction and
hardware-specific capabilities still need release and physical validation.


### Modern recon

The `network` profile also installs ProjectDiscovery Subfinder from its pinned upstream
release archive. Vibrali verifies the exact SHA-256 from the versioned release before
extracting the amd64 binary into `/usr/local/bin/subfinder`. This keeps the tool current
without using an unpinned `go install` or arbitrary installer script.


### Memory forensics

The `forensics` profile installs Volatility 3 from a pinned PyPI wheel. Vibrali verifies
the exact wheel SHA-256 before installation and uses `pip --no-index --no-deps` inside an
isolated venv with Debian-packaged support libraries exposed through
`--system-site-packages`. This avoids downloading unpinned transitive Python packages at
install time. The external-tool audit checks the pinned Volatility version against PyPI.


### Burp Suite Desktop

The `web` profile installs PortSwigger's unified Burp Suite Desktop 2026.9 JAR from
the official release endpoint. The exact upstream SHA-256 is pinned in
`external-tools/manifest.txt`, and the installer places the verified JAR under
`/opt/vibrali/burpsuite/` with a stable `burpsuite` launcher. Current Burp releases use
one desktop build for Community and Professional; choose Community Edition in Burp when
starting without a Professional license.

### Cutter / Rizin

The `reverse` profile installs Cutter 2.5.0 from the official x86_64 AppImage with its
published SHA-256. Cutter bundles the Rizin analysis engine, so Vibrali exposes a stable
`cutter` launcher while keeping the upstream artifact intact under
`/opt/vibrali/cutter/`.

### Wordlists

The optional `wordlists` profile stays within Debian packages: CeWL, Crunch and CUPP
provide generators, while the packaged American/British large dictionaries and French
dictionary live under `/usr/share/dict`. Keeping this profile optional avoids making
the minimal install carry extra dictionary data.
