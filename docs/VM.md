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
