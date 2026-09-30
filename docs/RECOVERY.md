# Vibrali recovery

Vibrali is a normal writable Debian installation on removable storage. Standard Debian recovery techniques apply, with extra care to preserve portable UUID-based boot configuration.

This guide assumes a separate Linux rescue/live environment.

## Safety first

Identify the Vibrali disk and partitions:

~~~bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN,FSTYPE,LABEL,UUID,MOUNTPOINTS
~~~

The expected layout is:

1. BIOS Boot partition
2. FAT32 EFI System Partition
3. ext4 root filesystem

Examples below use `/dev/sdX2` for EFI and `/dev/sdX3` for root. Replace them with the actual device.

## Filesystem check after an unclean shutdown

Do not run `fsck` on a mounted filesystem.

~~~bash
sudo umount /dev/sdX3 2>/dev/null || true
sudo fsck.ext4 -f /dev/sdX3
~~~

If errors repeat, suspect failing media, cable/enclosure problems or unsafe power removal. Back up important data before continuing to use the device.

## Mount the installed system

~~~bash
sudo mount /dev/sdX3 /mnt
sudo mkdir -p /mnt/boot/efi
sudo mount /dev/sdX2 /mnt/boot/efi
~~~

For chroot repair:

~~~bash
for fs in dev dev/pts proc sys run; do
  sudo mount --bind /$fs /mnt/$fs
done
sudo cp --dereference /etc/resolv.conf /mnt/etc/resolv.conf
sudo chroot /mnt
~~~

Inside the chroot, `/` refers to the Vibrali installation.

## Repair broken initramfs

Inside the chroot:

~~~bash
apt update
apt install --reinstall initramfs-tools linux-image-amd64
update-initramfs -u -k all
update-grub
~~~

Confirm `/boot` contains a kernel and matching initramfs before rebooting.

## Repair UEFI GRUB

Inside the chroot, with the EFI partition mounted at `/boot/efi`:

~~~bash
apt install --reinstall grub-efi-amd64-bin grub2-common
grub-install \
  --target=x86_64-efi \
  --efi-directory=/boot/efi \
  --bootloader-id=Vibrali \
  --removable \
  --no-nvram \
  --recheck
update-grub
~~~

Confirm:

~~~bash
test -f /boot/efi/EFI/BOOT/BOOTX64.EFI
~~~

The `--removable --no-nvram` behavior is important: the USB should not depend on a firmware boot entry stored on the rescue computer.

## Repair legacy BIOS GRUB

If legacy BIOS support is needed and the disk still has the BIOS Boot partition:

~~~bash
apt install --reinstall grub-pc-bin grub2-common
grub-install --target=i386-pc --recheck /dev/sdX
update-grub
~~~

Use the whole disk, not a partition.

## Repair UUID mount configuration

Outside or inside the chroot, compare:

~~~bash
blkid
cat /mnt/etc/fstab
~~~

The root and EFI UUIDs in `fstab` must match the actual Vibrali partitions.

A standard unencrypted Vibrali install should resemble:

~~~text
UUID=<root-uuid> / ext4 defaults,noatime 0 1
UUID=<efi-uuid> /boot/efi vfat umask=0077 0 1
~~~

Do not replace UUIDs with `/dev/sdX` paths; device names can change between computers.

## Recover user files before reinstalling

If the OS is damaged but the filesystem is readable, mount the root partition and copy the user's home directory to another disk first:

~~~bash
sudo mount -o ro /dev/sdX3 /mnt
sudo rsync -aHAX --info=progress2 /mnt/home/<user>/ /path/to/backup/
~~~

Also consider preserving:

- `/etc` for configuration reference;
- `/opt` for locally installed software;
- selected `/var/lib` application state;
- `/var/log/vibrali-install.log` for installer diagnostics.

Do not restore an entire old `/etc` blindly onto a fresh release; selectively restore known configuration.

## Reinstall while preserving a backup

The current installer is destructive to the selected target disk. There is no supported in-place reinstall mode yet.

Recommended recovery flow:

1. back up user/project data to another disk;
2. verify the backup;
3. install/flash a fresh Vibrali image;
4. boot and update the fresh system;
5. restore user/project files;
6. reinstall any additional tools not included in the selected profiles;
7. restore configuration selectively.

## Cleanly leave the chroot

Exit the chroot, then unmount in reverse order:

~~~bash
exit
for fs in run sys proc dev/pts dev; do
  sudo umount /mnt/$fs 2>/dev/null || true
done
sudo umount /mnt/boot/efi
sudo umount /mnt
~~~

## LUKS recovery

Encrypted-root installation is not yet a supported Vibrali feature. Do not follow untested Vibrali-specific LUKS recovery instructions until the encrypted installer mode is implemented and documented.

If you manually encrypted a Vibrali-derived system, use the Debian/cryptsetup recovery process appropriate to your custom layout and make a backup before changing headers or keyslots.
