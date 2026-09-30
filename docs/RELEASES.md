# Release pipeline

Pushing a version tag such as `v0.1.0` runs the Build and Release workflow.

The workflow:

1. validates shell and repository configuration,
2. builds a normal Vibrali installation in a loopback disk,
3. converts it into a compressed QEMU QCOW2,
4. locks the USB image's `vibrali` account,
5. compresses the portable USB disk image,
6. writes SHA-256 checksums,
7. verifies both checksums and compressed streams,
8. inspects the USB GPT plus FAT32/ext4 signatures and the QCOW2 header,
9. splits oversized assets when necessary,
10. and creates a GitHub Release.

Artifact verification runs **before** anything is published. A checksum mismatch, corrupt
zstd stream, missing expected partition, wrong root filesystem signature or invalid QCOW2
header fails the workflow.

The same verification can be run manually after building images:

~~~bash
./scripts/verify-release-artifacts.sh dist
~~~

Large assets are automatically split into sub-2 GB chunks for hosting. The web installer
understands split USB images and reconstructs them before checksum verification.

The QEMU development image retains the documented initial password. The USB release image
does not: the guided installer sets a new password after flashing.
