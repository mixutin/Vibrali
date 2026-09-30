# Portable workstation usage

Vibrali keeps the operating system, tools and user state on the same writable USB
installation. Treat the drive like a portable workstation rather than disposable Live
media.

## Persistent work folders

The XFCE session creates and bookmarks these folders in the user's home directory:

- `~/Projects` — source trees and longer-lived work
- `~/Captures` — packet captures and collected data
- `~/Labs` — CTFs, authorized test labs and temporary exercises
- `~/Tools` — user-installed tools and local builds
- `~/Wordlists` — user-managed wordlists

They live on the normal writable root filesystem and therefore move with the USB.

## Git configuration

Normal per-user Git configuration persists in `~/.gitconfig`:

~~~bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
~~~

Repositories under the home directory persist like any other files.

## SSH keys

SSH client configuration and keys under `~/.ssh` persist across reboots and across
computers because the home directory is on the Vibrali drive.

Create keys on Vibrali rather than copying keys from an unrelated host when possible:

~~~bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519
~~~

Private keys should remain mode 0600. For high-value credentials, use a hardware-backed
key or encrypted Vibrali installation once the LUKS2 mode is available.

## Security tool menu

XFCE's application menu includes a **Vibrali Security** section with submenus for the installed security-work profiles. Each launcher opens a normal terminal, lists representative commands detected on that USB, and then hands control to the user's normal shell.

The same helper is available directly:

~~~bash
vibrali-toolbox network
vibrali-toolbox web
vibrali-toolbox reverse
~~~

The toolbox does not run scans or tests automatically. It only surfaces installed commands.

## Firefox ESR defaults

Vibrali keeps Firefox ESR close to Debian defaults while applying a small system policy:

- the Vibrali site is the default homepage;
- Firefox telemetry is disabled;
- Firefox Studies are disabled;
- Pocket integration is disabled;
- default-browser nagging is disabled.

Proxy settings, interception certificates, saved credentials and target-specific configuration are intentionally left to the user. Vibrali does not install a trusted interception CA or enable a proxy automatically.

For removable-storage endurance, Vibrali also applies user-overridable Firefox defaults that reduce repetitive background writes:

- disk HTTP cache is disabled while memory cache remains enabled;
- session-restore state is written no more frequently than every 60 seconds during normal browsing;
- browser history, cookies, saved logins, extensions, certificates, downloads and the Firefox profile remain persistent on the USB.

These are `default` enterprise-policy preferences rather than locked preferences, so a user can change them in Firefox when a workflow benefits from disk caching or a shorter crash-recovery interval. Increasing the session-store interval can mean that the newest tab-state changes are not captured if Firefox or the computer crashes abruptly.

## Storage behavior

Vibrali intentionally avoids a disk-backed swap partition in the default layout. It uses
compressed zram swap instead, which reduces routine write pressure on removable storage.

The default storage policy also:

- mounts the ext4 root with `noatime`,
- enables the systemd `fstrim.timer` for devices/bridges that support discard,
- bounds persistent journal growth,
- leaves unsupported TRIM devices usable rather than requiring continuous `discard`.

Useful checks:

~~~bash
swapon --show
zramctl
systemctl status zramswap.service --no-pager
systemctl status fstrim.timer --no-pager
journalctl --disk-usage
~~~

## Device endurance

The 12 GiB source-installer limit is only an absolute technical floor. For the intended
pentesting-workstation use, use at least 64 GB, with 128 GB or more strongly preferred
for captures, wordlists, toolchains and lab images.

Prefer a USB SSD or an NVMe/SATA SSD in a reliable enclosure with published endurance
specifications. Cheap thumb drives often have poor random-write performance and limited
write endurance. Keep reasonable free space instead of filling the filesystem to 100%.

## Backing up the portable workstation

Back up the user home directory to another trusted filesystem regularly. For example,
with a backup disk mounted at `/media/$USER/BACKUP`:

~~~bash
mkdir -p "/media/$USER/BACKUP/vibrali-home"
rsync -aH --info=progress2 "$HOME/" "/media/$USER/BACKUP/vibrali-home/"
~~~

This intentionally does not use `--delete`; an accidental path mistake should not erase
an existing backup.

For a broader backup, also preserve system configuration that you intentionally changed:

~~~bash
sudo rsync -aH /etc/ "/media/$USER/BACKUP/vibrali-etc/"
~~~

The source installer log is stored at `/var/log/vibrali-install.log` and can be useful
when diagnosing a later installation or boot problem.

## Restoring user data

On a replacement or repaired Vibrali installation, copy the saved home data back while
logged in as the target user:

~~~bash
rsync -aH --info=progress2 "/media/$USER/BACKUP/vibrali-home/" "$HOME/"
~~~

Review restored SSH key permissions afterward:

~~~bash
chmod 700 ~/.ssh 2>/dev/null || true
find ~/.ssh -type f -name 'id_*' ! -name '*.pub' -exec chmod 600 {} + 2>/dev/null || true
~~~

Bootloader and filesystem repair procedures are tracked separately in the recovery
roadmap and should be performed from rescue media when the Vibrali root filesystem must
remain unmounted.
