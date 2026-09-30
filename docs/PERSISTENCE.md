# Persistence

Vibrali's primary installation is natively persistent.

There is no special persistence partition, persistence.conf file or OverlayFS requirement
for the normal USB installation. The Linux root partition is a standard writable ext4
filesystem.

This means normal system operations persist, including:

- package installation and upgrades,
- kernel updates,
- /etc configuration,
- /var application state,
- user home directories,
- development environments,
- security-tool databases and projects.

## Live mode

A future Live/rescue image may optionally support Debian Live persistence, but that mode
is separate from the main Vibrali workstation design.

## Portable storage policy

Vibrali uses several conservative defaults for a workstation that lives on removable
storage:

- the ext4 root uses `noatime` to avoid access-time writes,
- `fstrim.timer` is enabled so supported SSDs/USB bridges receive periodic TRIM,
- compressed zram swap is enabled instead of a default disk swap partition,
- persistent journal growth is bounded to avoid unbounded log writes.

The default zram configuration uses LZ4 and a maximum device size of 25% of RAM. This is
compressed memory, not preallocated disk space.

Continuous ext4 `discard` is intentionally not a default because USB storage bridges
vary widely in discard support. Scheduled fstrim is easier to tolerate across portable
hardware.

## Storage recommendation

A quality USB SSD or NVMe enclosure is recommended. Cheap flash drives can have poor
random-write performance and limited endurance under a full desktop Linux workload.

The source installer enforces a 12 GiB technical floor. For the actual Vibrali
pentesting-workstation experience, 64 GB is the practical minimum and 128 GB or more is
preferred when keeping captures, wordlists, development toolchains and lab images on the
drive.

See [WORKSTATION.md](WORKSTATION.md) for persistent work folders, SSH/Git state, storage
health checks and backup guidance.

## Encryption

LUKS2 full-root encryption is planned. It must remain portable and must not require a
specific computer's TPM to unlock the drive.
