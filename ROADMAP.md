# Vibrali Roadmap

## Phase 0 — Native USB foundation

- [x] Define full-install USB architecture
- [x] GPT layout with BIOS + EFI + writable Linux root
- [x] Debian bootstrap installer
- [x] Portable removable-media GRUB setup
- [x] UUID-based fstab
- [x] User/password provisioning
- [x] Package manifests
- [x] Destructive-target safety checks
- [ ] Complete first physical USB installation
- [ ] Boot-test on multiple x86_64 PCs

## Phase 1 — Developer preview

- [ ] Verify UEFI portability across vendors
- [ ] Verify legacy BIOS boot
- [ ] Add first-boot welcome flow
- [ ] Add Vibrali desktop branding
- [ ] Tune XFCE defaults
- [ ] Add QEMU raw-disk integration test
- [ ] Publish checksums and installation notes

## Phase 2 — Portable workstation hardening

- [ ] LUKS2 encrypted root option
- [ ] TPM-independent encrypted portability
- [ ] Recovery key workflow
- [ ] SSD/flash endurance tuning
- [ ] zram default
- [ ] Safe filesystem recovery documentation
- [ ] Secure Boot support
- [ ] Signed boot artifacts

## Phase 3 — Security tooling

- [x] base and desktop manifests
- [x] web profile
- [x] network profile
- [x] pwn profile
- [x] reverse profile
- [x] crypto profile
- [x] forensics profile
- [x] wireless profile
- [x] authentication-audit profile
- [x] directory-services profile
- [ ] optional profile selector
- [ ] pinned upstream tool framework
- [ ] large optional wordlist profile

## Phase 4 — Hardware and UX

- [ ] Wi-Fi compatibility matrix
- [ ] USB Ethernet compatibility matrix
- [ ] Intel/AMD CPU microcode validation
- [ ] GPU compatibility notes
- [ ] HiDPI and multi-monitor defaults
- [ ] laptop power-management tuning
- [ ] custom wallpaper, theme and terminal profile

## Phase 5 — Distribution

- [ ] Bootable installer/rescue ISO
- [ ] Prebuilt portable raw image
- [ ] Graphical USB installer
- [ ] Versioned releases
- [ ] Automated release pipeline
- [ ] Stable and rolling channels
- [ ] ARM64 research
