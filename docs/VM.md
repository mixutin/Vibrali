# QEMU / KVM image

Each tagged Vibrali release builds a full-system QEMU image alongside the USB image.

Download `vibrali-qemu-amd64.qcow2.zst` from the latest GitHub release and decompress it:

~~~bash
zstd -d vibrali-qemu-amd64.qcow2.zst
~~~

Boot with QEMU/KVM:

~~~bash
qemu-system-x86_64 \
  -enable-kvm -cpu host -smp 4 -m 8G \
  -drive file=vibrali-qemu-amd64.qcow2,if=virtio,format=qcow2 \
  -nic user,model=virtio-net-pci
~~~

The development VM image uses `vibrali` / `vibrali` for its initial login.
Change that password immediately.

For UEFI testing, add your distribution's OVMF firmware arguments.

## Automated release boot test

The release builder creates a temporary CI-only QCOW2 from the same installed raw disk,
injects a small boot probe into that temporary image, then removes the probe before
building either public release artifact. The release workflow boots the temporary image
twice with OVMF and a fresh firmware variable store on each boot. Using a fresh NVRAM
store is intentional: it verifies Vibrali can start through the standard removable-media
EFI path rather than relying on a boot entry created by a previous run.

The guest-side probe activates only when QEMU presents the DMI serial `VIBRALI-CI`.
It is not present in the published USB or QEMU images. During the two release-test boots
the probe verifies:

- the `vibrali` user exists and has a usable password in the development VM image,
- NetworkManager and LightDM are active,
- XFCE is installed,
- the removable EFI loader is mounted and present,
- the root filesystem is writable,
- Nmap, SQLMap and GDB launch,
- writable state survives a clean reboot,
- and a small disposable Debian package installed on boot one is still installed on boot two.

The probe emits a serial success marker and powers the VM off cleanly. Any failed guest
check, missing marker, QEMU error or boot timeout fails the release workflow before assets
can be published. The temporary CI image is deleted before release upload.
