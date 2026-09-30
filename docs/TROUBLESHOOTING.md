# Troubleshooting Vibrali

This page is for the normal writable USB installation. Start with the least destructive
checks and keep the device model/serial visible whenever disk commands are involved.

## USB does not appear in the firmware boot menu

1. Disable Secure Boot for current development builds.
2. Try the firmware's one-time boot menu rather than changing permanent boot order.
3. Try another USB port, preferably a direct motherboard/laptop port.
4. Check the EFI fallback loader from another Linux system:

~~~bash
sudo mount /dev/disk/by-label/VIBRALI_EFI /mnt
ls -l /mnt/EFI/BOOT/BOOTX64.EFI
sudo umount /mnt
~~~

If the loader is missing, follow [RECOVERY.md](RECOVERY.md).

## GRUB starts but Linux does not boot

At the GRUB menu, first try an older installed kernel under the advanced options if one is
available.

From rescue media, check the root filesystem, finish interrupted package configuration,
regenerate all initramfs images and update GRUB using [RECOVERY.md](RECOVERY.md).

## Emergency shell or missing root filesystem

From the emergency shell, inspect what storage the kernel sees:

~~~bash
cat /proc/partitions
blkid
~~~

If the Vibrali root is visible but its UUID differs from `/etc/fstab`, repair the UUID
entries from rescue media rather than replacing them with unstable `/dev/sdX` names.

## XFCE or LightDM does not start

Switch to a text console with Ctrl+Alt+F2/F3 and log in.

Check the display manager:

~~~bash
systemctl status lightdm --no-pager
journalctl -b -u lightdm --no-pager
systemctl --failed
~~~

Confirm free space:

~~~bash
df -h /
df -i /
~~~

A completely full root filesystem can prevent desktop sessions from starting.

## NetworkManager or Wi-Fi problems

Check device state:

~~~bash
nmcli general
nmcli device
rfkill list
ip -brief link
~~~

Unblock Wi-Fi if it was soft-blocked:

~~~bash
sudo rfkill unblock wifi
~~~

Look for firmware/driver messages:

~~~bash
sudo dmesg | grep -Ei 'firmware|wifi|wlan|iwlwifi|ath|rtw|mt76'
~~~

Do not assume a missing interface is a NetworkManager problem; the adapter may need
firmware or a driver not yet in Vibrali's tested hardware set.

## Wired networking problems

~~~bash
nmcli device
ip -brief address
ip route
~~~

Check whether the USB Ethernet adapter appears:

~~~bash
lsusb
sudo dmesg | tail -n 100
~~~

## DNS problems

Separate connectivity from DNS resolution:

~~~bash
ip route
ping -c 1 1.1.1.1
getent hosts debian.org
cat /etc/resolv.conf
~~~

A working IP ping with failed name resolution points to DNS configuration rather than a
general link failure.

## Storage feels unexpectedly slow

Check whether the drive negotiated USB 3.x and whether the filesystem is nearly full:

~~~bash
lsusb -t
df -h /
lsblk -o NAME,SIZE,MODEL,TRAN,ROTA,MOUNTPOINTS
~~~

Cheap flash drives can be dramatically slower than USB SSDs for package installation and
browser/tool databases.

Check zram and TRIM scheduling:

~~~bash
swapon --show
zramctl
systemctl status zramswap.service --no-pager
systemctl status fstrim.timer --no-pager
~~~

## APT upgrade was interrupted

~~~bash
sudo dpkg --audit
sudo dpkg --configure -a
sudo apt-get -f install
sudo apt update
~~~

Then regenerate boot artifacts after kernel/initramfs package problems:

~~~bash
sudo update-initramfs -u -k all
sudo update-grub
~~~

## Installer diagnostics

A successful source installation stores its log at:

~~~text
/var/log/vibrali-install.log
~~~

The source installer also prints the host-side temporary log path. Preserve that log if
post-install verification fails.

## Before reporting a portability problem

Record:

~~~bash
vibrali-info
uname -a
lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN,FSTYPE,LABEL,UUID,MOUNTPOINTS
lspci -nnk
lsusb
systemctl --failed
~~~

Do not publish private SSH keys, browser data, VPN credentials, capture contents or other
sensitive project material with a bug report.
