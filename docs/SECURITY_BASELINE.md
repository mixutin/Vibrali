# Vibrali security baseline

Vibrali is a portable security workstation. It must remain useful for authorized testing while avoiding unnecessary exposure when the same USB is plugged into unfamiliar networks.

## Default account and privilege model

- The installer creates one normal user and adds it to `sudo`.
- The root account is locked.
- Interactive sudo authentication uses a short cached-authentication window rather than passwordless sudo.
- The USB release image does not ship with a usable default password; the guided installer sets one after flashing.
- The source installer requires the user to choose a password unless it is running the loop-device-only CI path.

Use a unique passphrase. For a drive that contains credentials, captures or client data, prefer a long passphrase and use encrypted storage once Vibrali's supported LUKS2 mode is available.

## SSH

Vibrali installs `openssh-client`, not `openssh-server`, in the mandatory base profile.

That means the workstation can make SSH connections but does not intentionally expose an SSH daemon by default. If you install an SSH server yourself, review its authentication and listening configuration before enabling it on untrusted networks.

## Firewall

Vibrali enables an nftables host firewall at boot.

Default policy:

- allow all outbound traffic;
- allow loopback;
- allow established/related inbound traffic;
- allow ICMP/IPv6 ICMP needed for normal networking and diagnostics;
- allow DHCP client replies;
- drop other unsolicited inbound traffic;
- drop routed/forwarded traffic by default.

Inspect it with:

~~~bash
sudo vibrali-firewall status
~~~

For an authorized lab that needs a local listener:

~~~bash
sudo vibrali-firewall allow tcp 4444
~~~

That exception is temporary and disappears when the baseline is reloaded or the system reboots.

To temporarily remove the Vibrali firewall for a controlled lab:

~~~bash
sudo vibrali-firewall off
~~~

Restore it with:

~~~bash
sudo vibrali-firewall on
~~~

Disabling the firewall can expose any service or listener bound to the workstation. Do it only when the network and engagement scope justify it.

## AppArmor

The mandatory base profile includes AppArmor and enables its system service. Debian-provided profiles are used where available.

Vibrali does not invent broad custom profiles for security tools merely to claim confinement. Penetration-testing and reverse-engineering tools often require unusual filesystem, ptrace, raw-socket or network access, so custom confinement must be tested per tool before becoming a default.

Useful checks:

~~~bash
systemctl status apparmor --no-pager
sudo aa-status
~~~

## Background services

Vibrali explicitly enables the services required for its normal workstation experience:

- NetworkManager
- LightDM
- nftables
- AppArmor
- zram swap
- scheduled filesystem TRIM

Optional packages may bring in daemons. The installer keeps Tor and Avahi/mDNS services disabled by default when their units are present. Users can start them deliberately for a lab or workflow that needs them.

Check active listeners at any time with:

~~~bash
sudo ss -lntup
systemctl --type=service --state=running
~~~

## Pentesting workflow tradeoff

A default-deny inbound firewall is intentionally stricter than some offensive-security distributions. It should not interfere with normal outbound scanning, web testing, VPN connections or client-side tooling.

Workflows that require the Vibrali machine to accept a new inbound connection—local web servers, reverse-shell listeners, temporary file receivers, some peer-to-peer tools—need an explicit temporary allow rule or a deliberate firewall pause.

This keeps the portable workstation safer on coffee-shop, conference, hotel and client networks without hiding the control from the operator.
