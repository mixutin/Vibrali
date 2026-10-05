# QEMU / KVM image

Each tagged Vibrali release builds a full-system QEMU image alongside the USB image.

Download `vibrali-qemu-amd64.qcow2.zst` from the latest GitHub release and decompress it:

~~~bash
zstd -d vibrali-qemu-amd64.qcow2.zst
~~~

For fast local desktop testing, build only the mandatory base + desktop profiles:

~~~bash
sudo ./scripts/build-dev-vm.sh
~~~

That produces `dist-dev/vibrali-dev.qcow2` from the current source tree. The default
development disk is 16 GiB and uses `vibrali` / `vibrali`. Override
`VIBRALI_DEV_VM_SIZE`, `VIBRALI_DEV_VM_PROFILES` or
`VIBRALI_DEV_VM_PASSWORD` when needed.

Boot with the repository helper:

~~~bash
./scripts/run-qemu-vm.sh /path/to/vibrali-qemu-amd64.qcow2
~~~

The helper uses KVM when available, boots through OVMF/UEFI, starts the guest at
1920x1080 by default, enables fit-to-window rendering, and forwards host TCP port 2222
to guest SSH port 22. When `remote-viewer` is installed it uses SPICE automatically;
Vibrali includes `spice-vdagent` so the guest can follow viewer resize events.

Override the display size or resources when needed:

~~~bash
VIBRALI_VM_WIDTH=2560 VIBRALI_VM_HEIGHT=1440 \
VIBRALI_VM_RAM_MB=12288 VIBRALI_VM_CPUS=6 \
  ./scripts/run-qemu-vm.sh /path/to/vibrali-qemu-amd64.qcow2
~~~

Set `VIBRALI_VM_SPICE=off` to force the built-in GTK display. The GTK path still uses
the requested virtual resolution and `zoom-to-fit=on`, which avoids the tiny fixed
framebuffer experience common with bare QEMU defaults.

The development VM image uses `vibrali` / `vibrali` for its initial login.
Change that password immediately.

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
