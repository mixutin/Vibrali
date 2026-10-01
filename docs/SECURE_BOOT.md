# Secure Boot architecture

Vibrali now installs a Debian-signed shim/GRUB removable-media chain, but does not yet
claim general Secure Boot hardware support. Signed artifacts are verified during install;
real-firmware validation remains a separate release gate.

Secure Boot is no longer expected to be disabled as a prerequisite. On firmware that accepts the Debian-signed chain, leave it enabled. Disabling it is only a fallback diagnostic/workaround for hardware that has not yet passed Vibrali's compatibility validation.

## Decision

Use Debian's existing amd64 Secure Boot trust chain rather than creating a Vibrali-owned
platform key for the default installation:

~~~text
UEFI Secure Boot trust database
  -> Debian/Microsoft-trusted shim
     -> Debian-signed GRUB
        -> Debian-signed Debian kernel
           -> signed in-tree modules / appropriately signed DKMS modules
~~~

Debian 13 provides `shim-signed` and `grub-efi-amd64-signed`. The signed shim binary is
installed by the package as `/usr/lib/shim/shimx64.efi.signed`, and the signed GRUB
binary is available as `/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed`.

## Portable removable-media path

Vibrali must continue to boot without creating a firmware NVRAM entry on the current
computer. The intended Secure Boot layout on the EFI System Partition is therefore:

~~~text
/EFI/BOOT/BOOTX64.EFI   Debian-signed shim
/EFI/BOOT/grubx64.efi   Debian-signed GRUB
~~~

The installer invokes Debian's patched `grub-install` with `--uefi-secure-boot`,
`--removable` and `--no-nvram`. Debian's signed shim and signed GRUB packages therefore
populate the standard removable path without creating a firmware NVRAM dependency.

The installer then runs `sbverify --list` on both `BOOTX64.EFI` and `grubx64.efi`; a
missing or unsigned artifact is a hard post-install verification failure.

## Kernel and module policy

The normal Vibrali kernel should remain the Debian packaged kernel so the default boot
chain can rely on Debian's signatures.

Unsigned out-of-tree kernel modules must not silently weaken Secure Boot. When a user
installs a DKMS module that requires a Machine Owner Key (MOK), that becomes a per-machine
enrollment concern. Because Vibrali is specifically meant to move between computers,
Vibrali must not bind the default installation to a MOK enrolled on one computer.

For that reason:

- the default image should prefer Debian-signed kernel/module packages;
- a project-owned MOK is not part of the baseline boot path;
- hardware-specific DKMS/MOK setup is user-managed and may need enrollment on each target
  machine;
- Secure Boot support must not depend on TPM enrollment.

## Encrypted installs

LUKS2 root encryption and Secure Boot solve different problems. The encrypted source
installer may use the same signed EFI/GRUB chain once implemented. Its separate unencrypted
`/boot` remains compatible with this design; the initramfs prompts for the LUKS
passphrase after the signed boot chain loads it.

## Key rotation and recovery

Vibrali does not own the default Secure Boot signing keys. Trust rotation therefore
follows Debian's signed package updates and the platform firmware's trust database rather
than a Vibrali-specific key ceremony.

For the baseline portable chain:

- update `shim-signed`, `grub-efi-amd64-signed`, the Debian kernel and related boot
  packages through normal APT updates;
- after boot-package updates, preserve the removable/no-NVRAM install path by reinstalling
  GRUB with `--uefi-secure-boot --removable --no-nvram`;
- verify `EFI/BOOT/BOOTX64.EFI` and `EFI/BOOT/grubx64.efi` with `sbverify --list`;
- do not enroll a Vibrali-owned MOK as part of the default image;
- if a firmware trust-database update rejects an older shim, recover using current Debian
  signed packages from trusted rescue media, then rebuild the removable EFI chain.

A user-created MOK for a third-party DKMS module is separate from this baseline. Its
private key, certificate, enrollment and revocation are the user's responsibility, and a
MOK enrolled on one computer should not be treated as portable trust state for the USB.

The recovery procedure in [RECOVERY.md](RECOVERY.md) reinstalls current signed shim/GRUB
packages, rebuilds the removable path, and verifies both EFI signatures before rebooting.
This is also the recovery path after replacing obsolete signed boot artifacts.

## Automated OVMF Secure Boot smoke test

Release and rolling CI include a separate OVMF boot using the Secure Boot firmware image
and Microsoft-enrolled variable store provided by Ubuntu's `ovmf` package. The VM uses a
distinct SMBIOS serial so the guest probe requires the UEFI `SecureBoot` variable to be
set to `1` before reporting success.

This proves the published Debian-signed shim -> GRUB -> kernel path can execute under an
enrolled Secure Boot firmware in QEMU. It does **not** replace the real-hardware Secure
Boot matrix because vendor firmware policies and implementations still vary.

## Implementation gate

Before Vibrali claims Secure Boot support, all of the following must be proven:

1. ~~signed shim and signed GRUB are installed on the removable EFI path;~~ implemented and verified during install;
2. the normal Debian kernel boots with Secure Boot enabled;
3. the same USB boots with Secure Boot enabled on multiple supported PCs;
4. kernel/initramfs/GRUB upgrades preserve that boot path;
5. failure behavior for unsigned third-party modules is documented;
6. ~~recovery instructions restore the signed removable-media path.~~ documented and signature-checked.

Until the remaining boot and hardware checks pass, project documentation should describe
the signed boot chain as implemented but Secure Boot hardware compatibility as not yet
validated.
