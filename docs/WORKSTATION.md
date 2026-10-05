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

## Default browser

Brave Browser is installed from Brave's official Debian/Ubuntu APT repository and is the
default for HTTP, HTTPS and HTML content. XFCE's Web Browser helper also points to Brave.
Firefox ESR and Chromium remain installed as alternate browsers for testing and
compatibility work.

The first XFCE session reinforces the Brave association with XDG defaults without
reapplying it on every login, so users can choose a different default later.

## Firefox ESR defaults

Vibrali keeps Firefox ESR available as a secondary browser and close to Debian defaults
while applying a small system policy:

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

## Web testing browsers, proxies and interception CAs

Vibrali ships Brave, Firefox ESR and Chromium. It deliberately does not force a
proxy or trust an interception certificate globally: those settings are target/lab
specific and a trusted interception CA can decrypt traffic for any site accepted by that
browser profile.

For a local proxy such as Burp or another authorized testing proxy listening on
`127.0.0.1:8080`:

- Firefox: Settings → Network Settings → Manual proxy configuration, then set HTTP/HTTPS
  proxy to `127.0.0.1` port `8080`.
- Chromium: launch a dedicated testing session with
  `chromium --user-data-dir="$HOME/.config/chromium-vibrali-test" --proxy-server=http://127.0.0.1:8080`.

Keep a separate browser profile for interception work so ordinary browsing does not
silently inherit a testing proxy.

To trust an interception CA, export the CA certificate from the proxy and import it only
into the dedicated browser profile. In Firefox use Settings → Privacy & Security →
Certificates → View Certificates → Authorities → Import. In Chromium use its certificate
manager from Settings/Security for the dedicated profile. Remove the CA when the lab or
engagement is finished. Vibrali never installs or trusts a proxy CA automatically.

For command-line clients, prefer an explicit per-command proxy rather than a global shell
export, for example:

~~~bash
curl --proxy http://127.0.0.1:8080 https://example.test/
~~~

Do not use `--insecure` as a permanent workaround for TLS errors; import the intended lab
CA into the specific tool/profile instead.

## Python environments and pipx

`python3-venv` and `pipx` are part of the base workstation. Keep project libraries
isolated from Debian's system Python:

~~~bash
python3 -m venv ~/Projects/demo/.venv
source ~/Projects/demo/.venv/bin/activate
python -m pip install --upgrade pip
~~~

For standalone Python CLI tools that are not Debian packages, use pipx as your normal
user so each tool gets its own environment:

~~~bash
pipx ensurepath
pipx install PACKAGE_NAME
pipx list
~~~

pipx state lives in the user's persistent home directory, so installed CLI tools follow
the USB. Prefer Debian packages or Vibrali's pinned external-tool framework for tools that
must be part of a reproducible release image.

## Display scaling

On the first XFCE login, Vibrali checks the primary display geometry with `xrandr` and uses
2x global GTK/XFCE scaling only when the display is clearly HiDPI (about 170 DPI or higher).
Otherwise it stays at 1x. The choice is stored in the persistent user profile and is not
reapplied on every login, so manual changes remain yours.

You can change it at any time:

~~~bash
vibrali-display-scale 1x
vibrali-display-scale 2x
vibrali-display-scale auto
~~~

The helper changes XFCE global window scaling and cursor size. Mixed-DPI multi-monitor
behavior is still a physical-hardware validation item; Vibrali does not force a per-output
layout or scaling arrangement.

## Laptop power profiles

Vibrali installs Debian's `power-profiles-daemon` as a conservative portable-laptop
baseline. It uses the kernel/platform capabilities exposed by the current computer instead
of shipping model-specific tuning that could follow the USB to incompatible hardware.

Check the active profile and the profiles supported by the current machine with:

~~~bash
powerprofilesctl get
powerprofilesctl list
~~~

The default is left at the daemon/platform's balanced behavior. Switch temporarily when
needed:

~~~bash
powerprofilesctl set power-saver
powerprofilesctl set balanced
powerprofilesctl set performance
~~~

Not every PC exposes every profile. Vibrali intentionally does not force USB autosuspend,
PCI runtime-power overrides, or laptop-vendor-specific rules by default because those can
interfere with external Wi-Fi adapters, USB Ethernet, capture hardware and other pentesting
peripherals. Suspend/resume remains a separate real-hardware validation item.

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
