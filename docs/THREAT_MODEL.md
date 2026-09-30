# Vibrali threat model

This document defines the security assumptions for Vibrali 1.0 development.

## Assets

A Vibrali drive can contain:

- user credentials and SSH keys;
- Git configuration and source trees;
- browser profiles and session data;
- captures and forensic images;
- CTF/lab artifacts;
- client-authorized assessment data;
- locally installed tools and tool configuration.

Because the operating system and user data live on the same portable device, physical loss is an important threat.

## Trust boundaries

Vibrali crosses several boundaries repeatedly:

1. **build/release infrastructure** — source, Debian packages and pinned external artifacts become a bootable image;
2. **installer host** — a separate Linux system writes the Vibrali drive;
3. **firmware/boot environment** — many different PCs boot the same USB;
4. **local network** — the workstation may connect to trusted labs, client networks or hostile public networks;
5. **target/test environment** — security tools interact with systems the user is authorized to assess;
6. **physical custody** — the USB can be lost, stolen or attached to an untrusted computer.

## Security goals

Vibrali should:

- avoid erasing the wrong disk during installation;
- verify downloaded release bytes before writing them;
- avoid usable default credentials on physical USB releases;
- avoid depending on one machine's firmware NVRAM or TPM;
- minimize unexpected listening services;
- apply a conservative inbound firewall baseline;
- use AppArmor where Debian provides practical profiles;
- keep external tooling pinned and checksum-verifiable;
- make recovery possible without replacing UUID-based portability with host-specific paths;
- eventually support portable LUKS2 encryption for data at rest.

## Non-goals

Vibrali 1.0 is not intended to:

- make a compromised host firmware trustworthy;
- protect secrets from a malicious machine while the user unlocks and actively uses them;
- provide anonymity by default;
- automatically route traffic through Tor;
- automatically install interception certificates;
- make offensive-security tools safe to run outside an authorized scope;
- guarantee support for every x86_64 PC or peripheral.

## Current important limitations

### Data at rest

Supported full-root LUKS2 encryption is still a roadmap item. Until it is implemented and tested, loss of an unencrypted drive can expose its contents.

### Secure Boot

Signed boot support is not yet complete. Current development builds expect Secure Boot to be disabled on tested systems.

### Physical hardware coverage

QEMU/OVMF verifies the image and persistence path, but it does not prove broad laptop/desktop driver compatibility. Hardware claims require physical evidence in `docs/HARDWARE.md`.

### Third-party tools

Debian packages follow Debian's supply chain. Non-Debian integrations must use Vibrali's pinned external-tool framework. A vulnerability in an included third-party tool can still affect the workstation.

## Release expectations

A public release should fail closed when:

- source validation fails;
- a release checksum does not match;
- compressed artifacts are corrupt;
- expected disk/filesystem structure is missing;
- the release-installer contract fails;
- QEMU boot/persistence smoke tests fail.

Physical release gates remain separate because virtual-machine success cannot establish real hardware compatibility.
