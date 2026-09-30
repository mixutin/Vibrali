# Architecture

## Primary model: native USB installation

Vibrali's primary mode is a normal Debian installation onto a removable block device.
It does not depend on a compressed read-only root plus OverlayFS for persistence.

The target disk uses GPT:

~~~text
1  BIOS_BOOT      1 MiB      GPT type EF02
2  VIBRALI_EFI    512 MiB    FAT32 / EFI System Partition
3  VIBRALI_ROOT   remaining  ext4 / normal writable root
~~~

The root filesystem contains the same kind of persistent state as a conventional Debian
installation: /etc, /var, /opt, /home, installed packages, kernels and application data.

## Portable boot

UEFI GRUB is installed with removable-media semantics. This places the loader at the
standard EFI fallback path so booting does not depend on a firmware entry created on
the installation host.

A small BIOS Boot partition allows an i386-pc GRUB installation for older systems.

Mounts use filesystem UUIDs rather than /dev/sdX names because the device name can change
between computers.

## Hardware portability

The installed kernel and initramfs should remain generic and include broad storage, USB,
networking and input support. Hardware-specific tuning must not assume one host.

NetworkManager is used so interfaces can be rediscovered and configured on each machine.

## Identity

A portable installation should not inherit the build host's machine identity. The USB
gets its own hostname and user during installation and initializes its machine-id on boot.

## Recovery

A separate Live/rescue environment remains useful, but it is not the main persistence
mechanism. It can later become the graphical installer and recovery system.
