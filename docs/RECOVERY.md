# Vibrali recovery

This guide covers recovery for the normal **unencrypted** Vibrali USB installation.

Vibrali does not yet ship a finished rescue ISO. Until that roadmap item is complete, use
a recent Debian or Ubuntu live environment. Do not perform filesystem repair on a
mounted Vibrali root filesystem.

## 1. Identify the Vibrali drive

Attach only the Vibrali drive you intend to repair when possible.

~~~bash
lsblk -o NAME,PATH,SIZE,FSTYPE,LABEL,UUID,MODEL,SERIAL,TRAN,MOUNTPOINTS
~~~

A standard Vibrali installation has:

- a small BIOS Boot partition,
- a FAT32 partition labeled `VIBRALI_EFI`,
- an ext4 partition labeled `VIBRALI_ROOT`.

If more than one device has those labels, do not use the label shortcuts below until you
have identified the correct device by model, serial and size.

## 2. Filesystem check after an unclean shutdown

Make sure the root partition is not mounted:

~~~bash
findmnt /dev/disk/by-label/VIBRALI_ROOT || true
sudo umount /dev/disk/by-label/VIBRALI_ROOT 2>/dev/null || true
~~~

Then check the ext4 filesystem:

~~~bash
sudo fsck.ext4 -f /dev/disk/by-label/VIBRALI_ROOT
~~~

The EFI filesystem can be checked separately:

~~~bash
sudo umount /dev/disk/by-label/VIBRALI_EFI 2>/dev/null || true
sudo fsck.vfat -a /dev/disk/by-label/VIBRALI_EFI
~~~

Read repair prompts carefully. If the drive is physically failing, clone/image it before
repeated repair attempts.

## 3. Mount the installed system

~~~bash
sudo mkdir -p /mnt/vibrali
sudo mount /dev/disk/by-label/VIBRALI_ROOT /mnt/vibrali
sudo mkdir -p /mnt/vibrali/boot/efi
sudo mount /dev/disk/by-label/VIBRALI_EFI /mnt/vibrali/boot/efi
~~~

Bind the runtime filesystems needed by a chroot:

~~~bash
for fs in dev dev/pts proc sys run; do
  sudo mount --bind "/$fs" "/mnt/vibrali/$fs"
done
~~~

If DNS is needed in the chroot:

~~~bash
sudo cp --dereference /etc/resolv.conf /mnt/vibrali/etc/resolv.conf
~~~

Enter the installed system:

~~~bash
sudo chroot /mnt/vibrali /bin/bash
~~~

## 4. Repair the removable UEFI bootloader

Inside the chroot:

~~~bash
grub-install \
  --target=x86_64-efi \
  --efi-directory=/boot/efi \
  --bootloader-id=Vibrali \
  --removable \
  --no-nvram \
  --recheck

update-grub
~~~

The important portability property is the removable-media EFI loader under
`/boot/efi/EFI/BOOT/BOOTX64.EFI`.

Check it:

~~~bash
test -f /boot/efi/EFI/BOOT/BOOTX64.EFI && echo "UEFI fallback loader present"
~~~

Do not add a dependency on a firmware NVRAM entry; the same USB must boot on different
computers.

## 5. Repair initramfs or a failed kernel update

Inside the chroot:

~~~bash
dpkg --configure -a
apt-get -f install
update-initramfs -u -k all
update-grub
~~~

List installed kernels if needed:

~~~bash
dpkg -l 'linux-image-*' | awk '$1 == "ii" {print $2, $3}'
~~~

If a package transaction was interrupted, finish it before regenerating the initramfs.

## 6. Repair UUID-based mounts

From the live environment, record the current UUIDs:

~~~bash
sudo blkid /dev/disk/by-label/VIBRALI_ROOT
sudo blkid /dev/disk/by-label/VIBRALI_EFI
~~~

Compare them with:

~~~bash
cat /mnt/vibrali/etc/fstab
~~~

The expected layout is:

~~~text
UUID=<root-uuid> /         ext4 defaults,noatime 0 1
UUID=<efi-uuid>  /boot/efi vfat umask=0077      0 1
~~~

Only edit `fstab` after confirming the UUIDs belong to the intended Vibrali drive.

## 7. Repair packages without reinstalling the workstation

Inside the chroot:

~~~bash
apt-get update
dpkg --audit
dpkg --configure -a
apt-get -f install
~~~

Avoid deleting `/home` or reformatting the root partition just to repair package state.

## 8. Exit and unmount cleanly

Exit the chroot, then unmount in reverse order:

~~~bash
exit

for fs in run sys proc dev/pts dev; do
  sudo umount "/mnt/vibrali/$fs" 2>/dev/null || true
done

sudo umount /mnt/vibrali/boot/efi
sudo umount /mnt/vibrali
sync
~~~

Remove the drive only after the filesystems are unmounted.

## Legacy BIOS repair

Legacy BIOS GRUB requires the **whole Vibrali disk**, not a partition. Identify it with
`lsblk` and the device serial first. Then, inside the mounted chroot:

~~~bash
grub-install --target=i386-pc --recheck /dev/sdX
update-grub
~~~

Replace `/dev/sdX` only after verifying it is the Vibrali disk. This command writes boot
code to the selected whole disk.

## Encryption

The planned LUKS2 installation mode is not implemented yet, so encrypted-root recovery is
not documented as supported behavior. When that feature lands, its unlock/recovery
workflow must be added here and tested before the roadmap item can be checked.
