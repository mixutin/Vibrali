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

## Storage recommendation

A quality USB SSD or NVMe enclosure is recommended. Cheap flash drives can have poor
random-write performance and limited endurance under a full desktop Linux workload.

## Encryption

LUKS2 full-root encryption is planned. It must remain portable and must not require a
specific computer's TPM to unlock the drive.
