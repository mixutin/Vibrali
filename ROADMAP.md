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
- [ ] Desktop application menu categories for security tools
- [x] Sensible terminal aliases/functions for common workflows
- [x] File-manager defaults for removable workstation use
- [ ] Browser defaults suitable for testing/research workflows
- [x] Clipboard and screenshot tooling
- [x] Archive/extraction tooling
- [x] Persistent SSH/Git developer setup documentation
- [ ] HiDPI defaults
- [ ] Multi-monitor validation
- [ ] Suspend/resume validation
- [ ] Laptop power-management tuning

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

- [ ] Confirm Nmap works out of the box
- [ ] Confirm Masscan works out of the box
- [ ] Confirm tcpdump works out of the box
- [ ] Confirm Wireshark/TShark capture permissions
- [ ] Confirm Socat/Netcat workflows
- [ ] Add common DNS/WHOIS/recon helpers
- [ ] Add useful VPN/tunnelling helpers
- [ ] Add optional modern recon tools from verified upstream releases

### Web testing

- [ ] Verify Firefox ESR profile
- [ ] Verify curl/wget/jq
- [ ] Verify SQLMap
- [ ] Verify Nikto
- [ ] Verify ffuf
- [ ] Verify Gobuster
- [ ] Verify Wfuzz
- [ ] Add Burp Suite Community using pinned verified upstream release
- [ ] Add optional Chromium-based testing browser
- [ ] Add browser proxy/certificate setup documentation

### Password / authentication testing

- [ ] Verify Hashcat
- [ ] Verify John the Ripper
- [ ] Verify Hydra
- [ ] Add optional large wordlist profile
- [ ] Document GPU acceleration limitations/compatibility
- [ ] Verify common Kerberos/LDAP tooling

### Exploit development / pwn

- [ ] Verify GCC/Clang/make
- [ ] Verify GDB
- [ ] Add/verify GEF or pwndbg using pinned upstream source
- [ ] Verify Python pwntools
- [ ] Verify binutils/readelf/objdump
- [ ] Add common debugging helpers
- [ ] Add 32-bit development/runtime support where practical

### Reverse engineering

- [ ] Verify GDB
- [ ] Verify LLDB
- [ ] Verify strace/ltrace
- [ ] Verify QEMU user-mode
- [ ] Verify APKTool
- [ ] Add Ghidra using pinned verified upstream release
- [ ] Add Rizin/Cutter or equivalent
- [ ] Add Java runtime required by reverse-engineering tools

### Forensics

- [ ] Verify Binwalk
- [ ] Verify Sleuth Kit
- [ ] Verify Autopsy
- [ ] Verify YARA
- [ ] Verify ExifTool
- [ ] Verify foremost
- [ ] Verify TestDisk/PhotoRec
- [ ] Add memory-forensics tooling with pinned versions where possible

### Wireless

- [ ] Verify Aircrack-ng
- [ ] Verify hcxtools
- [ ] Verify Reaver
- [ ] Verify Bully
- [ ] Verify monitor-mode workflow with supported adapters
- [ ] Create tested Wi-Fi adapter compatibility list

### Containers and lab tooling

- [ ] Add optional Docker/Podman profile
- [ ] Verify container state persists
- [ ] Add common CTF/dev runtimes
- [ ] Add optional Go toolchain
- [ ] Add optional Rust toolchain
- [ ] Add optional Node.js tooling
- [ ] Add virtualenv/pipx workflow documentation

### Tool supply-chain rules

- [ ] Create pinned external-tool framework
- [ ] Require version pinning for non-Debian tools
- [ ] Require SHA-256 or signature verification
- [ ] Record upstream download URL/source
- [ ] Avoid arbitrary root `curl | sh` installers
- [ ] Add automated external-tool version audit
- [ ] Add tool-license notes where redistribution matters

### Phase 2 exit gate

- [ ] Every advertised tool/profile is installed or intentionally documented as optional
- [ ] Representative tools from every profile launch successfully in a release image
- [ ] External tools have reproducible verified installation paths

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
- [ ] Test boot after initramfs regeneration
- [ ] Test boot after GRUB upgrade

### Firmware and CPU support

- [ ] Verify Intel microcode
- [ ] Verify AMD microcode
- [ ] Verify common Intel Wi-Fi firmware
- [ ] Verify common Realtek Wi-Fi firmware
- [ ] Verify common MediaTek Wi-Fi firmware
- [ ] Verify common USB Ethernet chipsets
- [ ] Document proprietary firmware limitations

### Graphics and display

- [ ] Intel integrated graphics validation
- [ ] AMD integrated graphics validation
- [ ] AMD discrete graphics notes
- [ ] NVIDIA compatibility notes
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

- [ ] Create `docs/HARDWARE.md`
- [ ] Add known-good laptops/desktops
- [ ] Add known-problematic hardware
- [ ] Add Wi-Fi adapter matrix
- [ ] Add USB Ethernet matrix
- [ ] Add enclosure/USB SSD recommendations

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
- [ ] Test repeated package install/remove cycles
- [ ] Test filesystem recovery after unclean shutdown
- [x] Add automatic TRIM where supported
- [x] Tune mount options for SSD/flash workload
- [x] Add zram default
- [x] Review swap strategy
- [x] Review journald retention for removable media
- [ ] Review browser/cache write amplification
- [x] Document minimum/recommended device endurance
- [x] Add backup/export guidance for user data
- [ ] Add restore/recovery procedure

### Phase 4 exit gate

- [ ] Physical test drive survives extended update/install/reboot testing
- [ ] Recovery steps are documented and verified

---

## Phase 5 — Encryption and security hardening

Goal: losing the USB should not automatically expose the user's projects and credentials.

- [ ] Add optional LUKS2 encrypted root installation
- [ ] Ensure encrypted drive remains portable between computers
- [ ] Do not require a specific TPM to unlock
- [ ] Add recovery-key workflow
- [ ] Verify encrypted boot through removable UEFI path
- [ ] Test kernel/initramfs updates on encrypted installs
- [ ] Add secure password guidance
- [ ] Review default services and listening ports
- [ ] Disable unnecessary services
- [ ] Review sudo defaults
- [ ] Review SSH server defaults
- [ ] Add firewall baseline
- [ ] Add AppArmor baseline where practical
- [ ] Add release threat-model document
- [ ] Add reproducible checksum/signature verification instructions

### Secure Boot

- [ ] Decide signing architecture
- [ ] Add signed EFI/boot artifacts
- [ ] Test Secure Boot on real hardware
- [ ] Document key rotation/recovery
- [ ] Remove "disable Secure Boot" requirement for supported configurations

### Phase 5 exit gate

- [ ] Encrypted portable install works on multiple supported PCs
- [ ] Security defaults and exceptions are documented

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
- [ ] Improve error messages for failed writes
- [ ] Verify interrupted-download recovery
- [ ] Verify split-image reconstruction
- [ ] Verify re-running installer safely

### Source installer

- [x] debootstrap installation
- [x] Selectable package profiles
- [x] Add dry-run mode
- [x] Add explicit minimum-size check
- [x] Add removable-device detection/warning
- [ ] Add optional encrypted-root mode
- [x] Add install log
- [x] Add post-install verification summary

### Live / rescue system

- [ ] Build bootable Live/rescue ISO
- [ ] Include disk/partition repair tools
- [ ] Include network diagnostics
- [ ] Include filesystem recovery tools
- [ ] Add "install Vibrali" launcher
- [ ] Add graphical USB installer
- [ ] Add recovery workflow for broken GRUB
- [ ] Add recovery workflow for broken initramfs
- [ ] Add recovery workflow for LUKS installs

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
- [ ] Add destructive-device safety tests using fake/loop devices
- [ ] Add raw-disk QEMU boot integration test
- [ ] Verify EFI boot in QEMU
- [ ] Verify writable root in QEMU
- [ ] Verify persistence across QEMU reboot
- [ ] Verify package installation persists across reboot
- [ ] Verify user account/password behavior
- [ ] Verify NetworkManager service
- [ ] Verify LightDM/XFCE service
- [ ] Verify representative security tools launch
- [ ] Add image filesystem sanity checks
- [ ] Add release checksum verification test
- [ ] Add installer smoke test against release artifacts
- [ ] Add scheduled rolling-build test

### Phase 7 exit gate

- [ ] CI can prove a built image boots, persists state and reaches a usable system
- [ ] Release workflow refuses to publish when required smoke tests fail

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
- [ ] Fix/verify green validation on `main`
- [ ] Publish first real versioned preview release
- [ ] Download and install that release on physical hardware
- [ ] Add signed checksum file
- [ ] Add release changelog template
- [ ] Add known-issues section to releases
- [ ] Define preview/beta/stable channels
- [ ] Define support policy
- [ ] Define versioning policy
- [ ] Define image-retention policy
- [ ] Verify release reproducibility/document build inputs
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
- [ ] Add hardware compatibility guide
- [ ] Add troubleshooting guide
- [ ] Add recovery guide
- [ ] Add encrypted-install guide
- [ ] Add contributor guide
- [ ] Add development/test guide
- [ ] Add release checklist
- [ ] Add tool-profile reference
- [ ] Add screenshots to README/site
- [ ] Add FAQ
- [ ] Review all docs against current behavior before 1.0

---

## Phase 10 — Vibrali 1.0 release gate

All items below must be checked before declaring Vibrali 1.0 complete.

- [ ] Latest `main` CI is green
- [ ] Release build is reproducible enough to document
- [ ] UEFI boot is verified on at least 3 different x86_64 computers
- [ ] Legacy BIOS support is either verified or explicitly removed from 1.0 support scope
- [ ] Networking works on the published compatibility set
- [ ] XFCE desktop starts reliably
- [ ] Core pentesting profiles are verified
- [ ] Package installs and updates persist
- [ ] Kernel upgrades persist and remain bootable
- [ ] User files/configs persist across machines
- [ ] Installer destructive safeguards are verified
- [ ] Release checksum/signature verification is documented
- [ ] Recovery documentation is tested
- [ ] Encryption status is clearly documented
- [ ] No default credential remains on the physical USB release path
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
