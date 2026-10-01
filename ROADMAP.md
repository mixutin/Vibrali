# Vibrali Roadmap

Vibrali is a **portable, fully writable Debian-based pentesting workstation installed directly onto removable storage**.

The product goal is simple:

> **Plug in. Boot. Work. Unplug. Everything is still there.**

Think of the target experience as a **Kali-style security workstation on a USB SSD**: the operating system, pentesting tools, shells, browser state, project files, captures, wordlists, development environments, updates and personal configuration all travel with the drive.

Vibrali is not primarily a read-only Live ISO with an OverlayFS persistence layer. The main installation is a normal writable Linux system that happens to live on removable storage.

Use Vibrali only on systems and networks you own or are explicitly authorized to test.

---

## Definition of done for Vibrali 1.0

Vibrali 1.0 is complete when a user can:

- [ ] Download a published Vibrali image from the official release page
- [ ] Verify the image checksum/signature
- [ ] Flash/install Vibrali safely to a supported USB SSD or fast USB drive
- [ ] Boot the same drive on multiple x86_64 UEFI computers
- [ ] Log into a polished XFCE desktop without manual repair
- [ ] Connect to wired and common Wi-Fi networks
- [ ] Use the expected pentesting/tooling profiles immediately
- [ ] Install and upgrade packages normally with APT
- [ ] Persist files, tools, configs, browser data and projects across reboots
- [ ] Update the kernel/initramfs and still boot on another supported computer
- [ ] Recover from common boot/filesystem problems using documented steps
- [ ] Optionally use encrypted portable storage without depending on one computer's TPM
- [ ] Reproduce release images from the repository
- [ ] Pass automated validation and release smoke tests
- [ ] Have at least one versioned release tested on real hardware from multiple vendors

---

## Phase 0 — Portable Debian foundation

Goal: make Vibrali behave like a normal Debian workstation installed on removable media.

- [x] Define full-install USB architecture
- [x] Use GPT partitioning
- [x] Add BIOS Boot partition
- [x] Add FAT32 EFI System Partition
- [x] Add writable ext4 Linux root
- [x] Bootstrap Debian system with debootstrap
- [x] Configure normal writable `/`, `/etc`, `/var`, `/opt` and `/home`
- [x] Use UUID-based mounts instead of fixed `/dev/sdX` names
- [x] Install UEFI GRUB in removable-media mode
- [x] Attempt legacy BIOS GRUB installation
- [x] Create initial user/password
- [x] Lock root account
- [x] Reset machine-id for portable first boot
- [x] Add destructive-target safety checks
- [x] Add source installer
- [x] Add prebuilt raw-image builder
- [ ] Complete first documented physical USB installation
- [ ] Reboot the same physical installation at least 10 times without filesystem/boot failure
- [ ] Boot-test one installation on at least 3 different x86_64 computers

### Phase 0 exit gate

- [ ] Physical USB installation succeeds from start to desktop
- [ ] Same USB boots on at least 3 PCs
- [ ] Files and installed packages persist correctly after moving between PCs

---

## Phase 1 — Daily-driver desktop experience

Goal: after boot, the system should already feel like a finished security workstation.

- [x] XFCE desktop
- [x] LightDM login
- [x] NetworkManager
- [x] Vibrali wallpaper
- [x] Vibrali logo and desktop identity
- [x] Plymouth splash
- [x] GRUB identity
- [x] Dark visual theme
- [x] Terminal color profile
- [x] Zsh shell
- [x] Starship prompt
- [x] Fastfetch/Neofetch/Screenfetch/Inxi
- [x] First-boot welcome screen
- [x] First-boot checklist for networking, updates and profile verification
- [x] Desktop application menu categories for security tools
- [x] Sensible terminal aliases/functions for common workflows
- [x] File-manager defaults for removable workstation use
- [x] Browser defaults suitable for testing/research workflows
- [x] Clipboard and screenshot tooling
- [x] Archive/extraction tooling
- [x] Persistent SSH/Git developer setup documentation
- [x] HiDPI defaults
- [ ] Multi-monitor validation
- [ ] Suspend/resume validation
- [x] Laptop power-management tuning

### Phase 1 exit gate

- [ ] Fresh user can boot and start working without editing system configuration
- [ ] Desktop remains usable on laptop and desktop hardware
- [ ] Settings survive reboots and moving the drive between machines

---

## Phase 2 — Pentesting toolset

Goal: provide a broad Kali-like starter environment while keeping tooling modular and reviewable.

### Core profiles

- [x] `base`
- [x] `desktop`
- [x] `network`
- [x] `web`
- [x] `auth-audit`
- [x] `pwn`
- [x] `reverse`
- [x] `crypto`
- [x] `forensics`
- [x] `wireless`
- [x] `directory-services`
- [x] `defensive`
- [x] Optional profile selector
- [x] `--list-profiles`
- [x] `--profiles all|none|name1,name2`

### Network / enumeration

- [x] Confirm Nmap works out of the box
- [x] Confirm Masscan works out of the box
- [x] Confirm tcpdump works out of the box
- [x] Confirm Wireshark/TShark capture permissions
- [x] Confirm Socat/Netcat workflows
- [x] Add common DNS/WHOIS/recon helpers
- [x] Add useful VPN/tunnelling helpers
- [ ] Add optional modern recon tools from verified upstream releases

### Web testing

- [x] Verify Firefox ESR profile
- [x] Verify curl/wget/jq
- [x] Verify SQLMap
- [x] Verify Nikto
- [x] Verify ffuf
- [x] Verify Gobuster
- [x] Verify Wfuzz
- [ ] Add Burp Suite Community using pinned verified upstream release
- [x] Add Chromium-based testing browser
- [x] Add browser proxy/certificate setup documentation

### Password / authentication testing

- [x] Verify Hashcat
- [x] Verify John the Ripper
- [x] Verify Hydra
- [ ] Add optional large wordlist profile
- [x] Document GPU acceleration limitations/compatibility
- [x] Verify common Kerberos/LDAP tooling

### Exploit development / pwn

- [x] Verify GCC/Clang/make
- [x] Verify GDB
- [x] Add/verify GEF or pwndbg using pinned upstream source
- [x] Verify Python pwntools
- [x] Verify binutils/readelf/objdump
- [x] Add common debugging helpers
- [x] Add 32-bit development/runtime support where practical

### Reverse engineering

- [x] Verify GDB
- [x] Verify LLDB
- [x] Verify strace/ltrace
- [x] Verify QEMU user-mode
- [x] Verify APKTool
- [ ] Add Ghidra using pinned verified upstream release
- [ ] Add Rizin/Cutter or equivalent
- [x] Add Java runtime required by reverse-engineering tools

### Forensics

- [x] Verify Binwalk
- [x] Verify Sleuth Kit
- [x] Verify Autopsy
- [x] Verify YARA
- [x] Verify ExifTool
- [x] Verify foremost
- [x] Verify TestDisk/PhotoRec
- [ ] Add memory-forensics tooling with pinned versions where possible

### Wireless

- [x] Verify Aircrack-ng
- [x] Verify hcxtools
- [x] Verify Reaver
- [x] Verify Bully
- [ ] Verify monitor-mode workflow with supported adapters
- [ ] Create tested Wi-Fi adapter compatibility list

### Containers and lab tooling

- [x] Add optional Docker/Podman profile
- [x] Verify container state persists
- [x] Add common CTF/dev runtimes
- [x] Add optional Go toolchain
- [x] Add optional Rust toolchain
- [x] Add optional Node.js tooling
- [x] Add virtualenv/pipx workflow documentation

### Tool supply-chain rules

- [x] Create pinned external-tool framework
- [x] Require version pinning for non-Debian tools
- [x] Require SHA-256 or signature verification
- [x] Record upstream download URL/source
- [x] Avoid arbitrary root `curl | sh` installers
- [x] Add automated external-tool version audit
- [x] Add tool-license notes where redistribution matters

### Phase 2 exit gate

- [x] Every advertised tool/profile is installed or intentionally documented as optional
- [ ] Representative tools from every profile launch successfully in a release image
- [x] External tools have reproducible verified installation paths

---

## Phase 3 — Hardware portability

Goal: one USB should boot and remain usable across a broad range of x86_64 PCs.

### Boot compatibility

- [ ] Test UEFI boot on Intel desktop
- [ ] Test UEFI boot on AMD desktop
- [ ] Test UEFI boot on Intel laptop
- [ ] Test UEFI boot on AMD laptop
- [ ] Test legacy BIOS boot on at least one system
- [ ] Test systems where USB appears as SATA/SCSI/NVMe bridge storage
- [ ] Test boot after kernel upgrade
- [x] Test boot after initramfs regeneration
- [ ] Test boot after GRUB upgrade

### Firmware and CPU support

- [ ] Verify Intel microcode
- [ ] Verify AMD microcode
- [ ] Verify common Intel Wi-Fi firmware
- [ ] Verify common Realtek Wi-Fi firmware
- [ ] Verify common MediaTek Wi-Fi firmware
- [ ] Verify common USB Ethernet chipsets
- [x] Document proprietary firmware limitations

### Graphics and display

- [ ] Intel integrated graphics validation
- [ ] AMD integrated graphics validation
- [x] AMD discrete graphics notes
- [x] NVIDIA compatibility notes
- [ ] HiDPI validation
- [ ] External-monitor validation
- [ ] Multiple-monitor validation

### Input / peripheral support

- [ ] Laptop touchpad validation
- [ ] USB keyboard/mouse validation
- [ ] Bluetooth validation
- [ ] Audio input/output validation
- [ ] USB headset validation
- [ ] Common USB serial adapter validation

### Compatibility documentation

- [x] Create `docs/HARDWARE.md`
- [ ] Add known-good laptops/desktops
- [ ] Add known-problematic hardware
- [ ] Add Wi-Fi adapter matrix
- [ ] Add USB Ethernet matrix
- [x] Add enclosure/USB SSD recommendations

### Phase 3 exit gate

- [ ] One release image passes the published hardware matrix
- [ ] Moving the drive between tested machines does not require reinstalling the OS

---

## Phase 4 — Persistence, reliability and storage health

Goal: a Vibrali USB should survive real daily use, upgrades and abrupt environmental changes.

- [x] Normal writable root instead of OverlayFS
- [x] Persistent package installation
- [x] Persistent home directory
- [x] Persistent system configuration
- [x] Persistent kernel/initramfs updates
- [ ] Test APT full-upgrade on physical USB
- [x] Test repeated package install/remove cycles
- [ ] Test filesystem recovery after unclean shutdown
- [x] Add automatic TRIM where supported
- [x] Tune mount options for SSD/flash workload
- [x] Add zram default
- [x] Review swap strategy
- [x] Review journald retention for removable media
- [x] Review browser/cache write amplification
- [x] Document minimum/recommended device endurance
- [x] Add backup/export guidance for user data
- [x] Add restore/recovery procedure

### Phase 4 exit gate

- [ ] Physical test drive survives extended update/install/reboot testing
- [ ] Recovery steps are documented and verified

---

## Phase 5 — Encryption and security hardening

Goal: losing the USB should not automatically expose the user's projects and credentials.

- [x] Add optional LUKS2 encrypted root installation
- [ ] Ensure encrypted drive remains portable between computers
- [x] Do not require a specific TPM to unlock
- [x] Add recovery-key workflow
- [x] Verify encrypted boot through removable UEFI path
- [ ] Test kernel/initramfs updates on encrypted installs
- [x] Add secure password guidance
- [x] Review default services and listening ports
- [x] Disable unnecessary services
- [x] Review sudo defaults
- [x] Review SSH server defaults
- [x] Add firewall baseline
- [x] Add AppArmor baseline where practical
- [x] Add release threat-model document
- [x] Add reproducible checksum/signature verification instructions

### Secure Boot

- [x] Decide signing architecture
- [x] Add signed EFI/boot artifacts
- [ ] Test Secure Boot on real hardware
- [x] Document key rotation/recovery
- [x] Remove "disable Secure Boot" requirement for supported configurations

### Phase 5 exit gate

- [ ] Encrypted portable install works on multiple supported PCs
- [x] Security defaults and exceptions are documented

---

## Phase 6 — Installer and recovery experience

Goal: installing Vibrali should be safe enough for normal users and recoverable when things go wrong.

### Guided release installer

- [x] Release-backed installer
- [x] SHA-256 verification
- [x] Show disk model/size/serial
- [x] Explicit destructive confirmation
- [x] Write image with progress
- [x] Set user password after flashing
- [x] Set hostname after flashing
- [x] Improve error messages for failed writes
- [x] Verify interrupted-download recovery
- [x] Verify split-image reconstruction
- [x] Verify re-running installer safely

### Source installer

- [x] debootstrap installation
- [x] Selectable package profiles
- [x] Add dry-run mode
- [x] Add explicit minimum-size check
- [x] Add removable-device detection/warning
- [x] Add optional encrypted-root mode
- [x] Add install log
- [x] Add post-install verification summary

### Live / rescue system

- [ ] Build bootable Live/rescue ISO
- [ ] Include disk/partition repair tools
- [ ] Include network diagnostics
- [ ] Include filesystem recovery tools
- [ ] Add "install Vibrali" launcher
- [ ] Add graphical USB installer
- [x] Add recovery workflow for broken GRUB
- [x] Add recovery workflow for broken initramfs
- [x] Add recovery workflow for LUKS installs

### Phase 6 exit gate

- [ ] Normal release install path works from clean host to bootable USB
- [ ] Rescue media can repair the documented common failure cases

---

## Phase 7 — Automated testing and CI

Goal: catch installer, boot and tooling regressions before releases.

- [x] Repository validation script
- [x] ShellCheck CI
- [x] Package-manifest validation
- [x] Profile-discovery validation
- [x] Add Bash tests for installer argument parsing
- [x] Add destructive-device safety tests using fake/loop devices
- [x] Add raw-disk QEMU boot integration test
- [x] Verify EFI boot in QEMU
- [x] Verify writable root in QEMU
- [x] Verify persistence across QEMU reboot
- [x] Verify package installation persists across reboot
- [x] Verify user account/password behavior
- [x] Verify NetworkManager service
- [x] Verify LightDM/XFCE service
- [x] Verify representative security tools launch
- [x] Add image filesystem sanity checks
- [x] Add release checksum verification test
- [x] Add installer smoke test against release artifacts
- [x] Add scheduled rolling-build test

### Phase 7 exit gate

- [x] CI can prove a built image boots, persists state and reaches a usable system
- [x] Release workflow refuses to publish when required smoke tests fail

---

## Phase 8 — Release engineering

Goal: turn source code into trustworthy, installable versioned Vibrali releases.

- [x] Automated release workflow
- [x] Build compressed USB image
- [x] Build compressed QCOW2 image
- [x] Publish SHA-256 checksums
- [x] Split oversized release artifacts
- [x] GitHub Pages website
- [x] Dynamic latest-release links
- [x] Fix/verify green validation on `main`
- [ ] Publish first real versioned preview release
- [ ] Download and install that release on physical hardware
- [x] Add signed checksum file
- [x] Add release changelog template
- [x] Add known-issues section to releases
- [x] Define preview/beta/stable channels
- [x] Define support policy
- [x] Define versioning policy
- [x] Define image-retention policy
- [x] Verify release reproducibility/document build inputs
- [ ] Publish Vibrali 1.0

### Phase 8 exit gate

- [ ] A user can install the latest stable image using only public project documentation
- [ ] Published assets have verification metadata
- [ ] Release has passed physical multi-machine testing

---

## Phase 9 — Documentation and project polish

Goal: everything a user or contributor needs is understandable without reading the source first.

- [x] README
- [x] Architecture documentation
- [x] USB installation documentation
- [x] Persistence documentation
- [x] Tooling documentation
- [x] VM documentation
- [x] Release documentation
- [x] Branding documentation
- [x] Add hardware compatibility guide
- [x] Add troubleshooting guide
- [x] Add recovery guide
- [x] Add encrypted-install guide
- [x] Add contributor guide
- [x] Add development/test guide
- [x] Add release checklist
- [x] Add tool-profile reference
- [ ] Add screenshots to README/site
- [x] Add FAQ
- [ ] Review all docs against current behavior before 1.0

---

## Phase 10 — Vibrali 1.0 release gate

All items below must be checked before declaring Vibrali 1.0 complete.

- [x] Latest `main` CI is green
- [x] Release build is reproducible enough to document
- [ ] UEFI boot is verified on at least 3 different x86_64 computers
- [ ] Legacy BIOS support is either verified or explicitly removed from 1.0 support scope
- [ ] Networking works on the published compatibility set
- [ ] XFCE desktop starts reliably
- [ ] Core pentesting profiles are verified
- [ ] Package installs and updates persist
- [ ] Kernel upgrades persist and remain bootable
- [ ] User files/configs persist across machines
- [ ] Installer destructive safeguards are verified
- [x] Release checksum/signature verification is documented
- [ ] Recovery documentation is tested
- [x] Encryption status is clearly documented
- [x] No default credential remains on the physical USB release path
- [ ] First stable release notes list supported hardware assumptions
- [ ] First stable release image has been installed from the public download path
- [ ] Public website points to the stable release
- [ ] `v1.0.0` is published

---

## Post-1.0 ideas

These are useful, but they do not block Vibrali 1.0.

- [ ] ARM64 research
- [ ] ARM64 image
- [ ] Additional desktop environments
- [ ] Minimal/headless edition
- [ ] Preconfigured training/lab environments
- [ ] Offline package/tool cache
- [ ] Optional Tor/privacy workstation profile
- [ ] Additional encrypted data-volume modes
- [ ] Automated hardware-report submission
- [ ] GUI profile manager
- [ ] In-place release channel switcher
