# Vibrali troubleshooting

This guide covers common failures in the portable full-install workflow.

## Before changing anything

Identify the Vibrali device carefully:

~~~bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN,FSTYPE,LABEL,UUID,MOUNTPOINTS
~~~

Do not run repair or formatting commands against a device unless you are certain it is the Vibrali drive.

## USB does not appear in firmware boot menu

1. Disable Secure Boot for current development releases.
2. Try another USB port, preferably a direct motherboard/laptop port rather than a hub.
3. Confirm the disk has a FAT32 EFI System Partition.
4. Mount the EFI partition and confirm `EFI/BOOT/BOOTX64.EFI` exists.
5. Try the firmware's one-time boot menu rather than relying on saved NVRAM entries.

Vibrali intentionally installs the UEFI bootloader in removable-media fallback mode.

## GRUB appears but Linux does not boot

At the GRUB menu, edit the boot entry temporarily and remove optional/custom kernel parameters first.

From a rescue environment, mount the Vibrali root filesystem and inspect:

~~~bash
cat /mnt/vibrali/etc/fstab
ls -l /mnt/vibrali/boot
~~~

Confirm the root UUID in `fstab` matches the actual root partition:

~~~bash
blkid
~~~

If the kernel or initramfs is missing/broken, use the recovery procedure in [RECOVERY.md](RECOVERY.md).

## Emergency shell says root filesystem cannot be found

Compare `blkid` output with `/etc/fstab`. The portable design depends on UUIDs, not `/dev/sdX` names.

If a filesystem UUID changed after manual reformatting, update `fstab`, rebuild initramfs if crypt/storage configuration changed, then regenerate GRUB configuration.

## Desktop login does not appear

From a TTY:

~~~bash
systemctl status lightdm
systemctl status NetworkManager
journalctl -b -u lightdm
~~~

Verify the desktop packages/profile are installed and that the root filesystem is not full:

~~~bash
df -h /
~~~

## Network interface is missing

Inspect detected hardware and firmware messages:

~~~bash
ip link
lspci -nnk
lsusb
dmesg | grep -Ei 'firmware|wifi|wlan|ethernet|network'
~~~

A portable installation cannot guarantee every proprietary firmware/driver combination. Record the chipset, USB ID/PCI ID and result in the hardware compatibility notes.

## Wi-Fi is present but cannot connect

Check NetworkManager:

~~~bash
nmcli device
nmcli radio
rfkill
~~~

If Wi-Fi is blocked, clear only the relevant software block after confirming local policy allows it:

~~~bash
rfkill unblock wifi
~~~

## System became slow after many writes

Check free space and I/O errors:

~~~bash
df -h
journalctl -k -b | grep -Ei 'error|reset|uas|usb|ext4|nvme'
~~~

Cheap flash drives can perform poorly under a full writable Linux workload. USB SSD/NVMe storage is strongly preferred.

## APT update/upgrade fails

Confirm time, DNS, network and disk space:

~~~bash
date
nmcli general status
getent hosts deb.debian.org
df -h /
sudo apt update
~~~

Do not delete package databases to "fix" APT unless you understand the recovery consequence. Capture the exact error first.

## Release installer fails before writing

Check:

- network connectivity;
- GitHub release availability;
- enough temporary storage for the compressed/reconstructed image;
- `zstd`, `curl`, `sha256sum`, `lsblk` and required host utilities.

Checksum failures are intentional hard stops. Do not bypass checksum verification.

## Release installer fails while writing

Re-check the target model/serial and inspect kernel logs for disconnects or I/O errors:

~~~bash
dmesg --follow
~~~

A flaky enclosure, cable, hub or flash device can cause partial writes. Re-run only after confirming the target and hardware are stable.

## Gather a useful bug report

Include:

~~~bash
uname -a
cat /etc/os-release
lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN,FSTYPE,LABEL,UUID
lspci -nnk
lsusb
systemctl --failed
~~~

Also include the Vibrali release/tag, whether the install came from a release image or source installer, and the exact point where the failure occurred. Remove secrets, private IP information and credentials before posting logs.
