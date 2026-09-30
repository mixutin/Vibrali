# Release pipeline

Pushing a version tag such as `v0.1.0` runs the Build and Release workflow.

The workflow:

1. validates shell and repository configuration,
2. builds a normal Vibrali installation in a loopback disk,
3. converts it into a compressed QEMU QCOW2,
4. locks the USB image's `vibrali` account,
5. compresses the portable USB disk image,
6. publishes SHA-256 checksums,
7. and creates a GitHub Release.

Large assets are automatically split into sub-2 GB chunks for hosting. The web installer
understands split USB images and reconstructs them before checksum verification.

The QEMU development image retains the documented initial password. The USB release image
does not: the guided installer sets a new password after flashing.
