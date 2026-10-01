# Secure Boot architecture

Vibrali now installs a Debian-signed shim/GRUB removable-media chain, but does not yet
claim general Secure Boot hardware support. Signed artifacts are verified during install;
real-firmware validation remains a separate release gate.

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

## Implementation gate

Before Vibrali claims Secure Boot support, all of the following must be proven:

1. ~~signed shim and signed GRUB are installed on the removable EFI path;~~ implemented and verified during install;
2. the normal Debian kernel boots with Secure Boot enabled;
3. the same USB boots with Secure Boot enabled on multiple supported PCs;
4. kernel/initramfs/GRUB upgrades preserve that boot path;
5. failure behavior for unsigned third-party modules is documented;
6. recovery instructions restore the signed removable-media path.

Until the remaining boot and hardware checks pass, project documentation should describe
the signed boot chain as implemented but Secure Boot hardware compatibility as not yet
validated.
