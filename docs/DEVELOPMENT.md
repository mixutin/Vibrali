# Vibrali development and testing

## Fast repository validation

Run:

~~~bash
./scripts/validate.sh
shellcheck scripts/*.sh site/install.sh
~~~

The repository validation covers syntax, required files, package-manifest invariants, installer CLI behavior, release-installer fixtures, external-tool metadata and tool-profile contracts.

## Installer CLI tests

~~~bash
./scripts/test-installer-cli.sh
~~~

These tests are non-destructive and cover argument/profile behavior.

## Destructive-device safety tests

The repository includes loop-device safety coverage intended for CI/root-capable development environments. Use only disposable loop devices created by the test itself; never substitute a real disk.

## External-tool validation

~~~bash
./scripts/validate-external-tools.sh
~~~

External tools must remain pinned and checksum-verifiable.

## Tool profile validation

~~~bash
./scripts/validate-tool-profiles.sh
~~~

This checks source-level contracts for the advertised tool profiles.

## Release artifact verification

After building images into `dist/`:

~~~bash
./scripts/verify-release-artifacts.sh dist
./scripts/test-release-installer.sh dist
~~~

These verify hashes, compression, image structure and the guided installer's release-asset contract.

## QEMU release smoke test

The release workflow creates a disposable CI-only QEMU image and boots it with OVMF twice. The test proves UEFI fallback boot plus persisted state and selected service/tool contracts without shipping the CI probe in public images.

Run the repository's QEMU test helper from an environment with KVM/QEMU/OVMF dependencies installed:

~~~bash
sudo ./scripts/test-qemu-release.sh dist
~~~

Consult the script help/source for environment-specific requirements.

## Full release build

See [RELEASES.md](RELEASES.md). The GitHub release workflow is the canonical release path. A weekly rolling workflow exercises the same build/test chain without publishing.

## Physical USB testing

VM tests do not replace physical validation.

Before testing:

~~~bash
./scripts/install-to-usb.sh --device /dev/sdX --dry-run
~~~

Confirm model, serial, transport and size. For release-image testing, use the guided installer exactly as a user would.

Record results in a reproducible form and update hardware compatibility documentation only with observed results.
