# Release pipeline

Pushing a version tag such as `v0.1.0` runs the Build and Release workflow. Maintainers can also create a one-shot preview branch named `release-preview/vMAJOR.MINOR.PATCH-dev.N`, `-beta.N`, or `-rc.N`; a push to that branch runs the same build/verification pipeline and publishes that prerelease tag at the exact branch commit.

The workflow:

1. validates shell and repository configuration,
2. builds a normal Vibrali installation in a loopback disk,
3. creates a disposable CI-only QCOW2 plus clean public QEMU/USB images,
4. locks the USB image's `vibrali` account,
5. writes SHA-256 checksums,
6. verifies checksums, compressed streams and image structure,
7. smoke-tests the release installer download/checksum contract,
8. boots the disposable QEMU image twice with OVMF to test UEFI boot and persistence,
9. removes the CI-only image,
10. splits oversized public assets when necessary,
11. signs `SHA256SUMS` keylessly with Sigstore/Cosign and verifies the GitHub Actions signer identity,
12. and creates a GitHub Release.

Artifact and smoke verification run **before** anything is published. A checksum mismatch,
corrupt zstd stream, missing expected partition, wrong filesystem signature, invalid QCOW2
header, installer download/reconstruction failure, QEMU boot failure or persistence failure
stops the workflow.

The fast release-installer tests also exercise direct downloads, multi-part reconstruction
and checksum rejection with local fixtures:

~~~bash
./scripts/test-release-installer.sh
~~~

After building release images, pass the output directory to additionally validate the real
USB artifact/manifest contract:

~~~bash
./scripts/test-release-installer.sh dist
~~~

Image structure verification can be run manually with:

~~~bash
./scripts/verify-release-artifacts.sh dist
~~~

Large assets are automatically split into sub-2 GB chunks for hosting. The web installer
understands split USB images and reconstructs them before checksum verification.

The guided installer prefers GitHub's latest stable release. Before the first stable release exists, it falls back to the newest published preview release. Permanent 404 responses are not retried as transient network failures, so a repository with no published image fails quickly with an explicit message instead of repeatedly requesting a missing checksum file.

The QEMU development image retains the documented initial password. The USB release image
does not: the guided installer sets a new password after flashing.


## Rolling build validation

A separate `Rolling Build Test` workflow runs every Sunday at 04:23 UTC and can also be
started manually. It performs the full build and verification path without publishing a
release:

1. validates the repository and ShellCheck rules,
2. builds the USB and QEMU images,
3. verifies hashes, compression and image structure,
4. smoke-tests the release installer against the built USB artifact,
5. boots the disposable QEMU CI image twice with OVMF,
6. and verifies the same persistence/service/tool checks used by release builds.

The workflow has read-only repository permissions. It does not create tags, releases or
upload public artifacts. Concurrent rolling builds share one concurrency group, so a stale
run is cancelled rather than allowed to accumulate behind a newer run.

## Release policy and operator checklist

Release channels, semantic versioning, support windows and binary-retention rules are defined in [RELEASE_POLICY.md](RELEASE_POLICY.md).

Before publishing any public image, complete [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md). Draft release notes from [RELEASE_NOTES_TEMPLATE.md](RELEASE_NOTES_TEMPLATE.md) so hardware assumptions and known issues are stated explicitly.


## Verify a published release

Each public release publishes two verification files:

- `SHA256SUMS` — SHA-256 hashes for the original compressed USB and QEMU images.
- `SHA256SUMS.sigstore.json` — a Sigstore bundle containing the checksum-manifest signature, short-lived signing certificate and transparency-log proof.

Install a current Cosign release, then download those two files plus the image you want to verify. First verify that the checksum manifest was signed by Vibrali's GitHub Actions release workflow:

~~~bash
cosign verify-blob SHA256SUMS \
  --bundle SHA256SUMS.sigstore.json \
  --certificate-identity-regexp '^https://github\.com/mixutin/Vibrali/\.github/workflows/release\.yml@refs/(tags/v.+|heads/.+)$' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com'
~~~

Then verify the downloaded image against the authenticated checksum manifest:

~~~bash
sha256sum -c SHA256SUMS --ignore-missing
~~~

For a split USB release, concatenate the numbered parts in order before running the checksum command:

~~~bash
cat vibrali-usb-amd64.img.zst.part-* > vibrali-usb-amd64.img.zst
sha256sum -c SHA256SUMS --ignore-missing
~~~

The Sigstore signature authenticates the checksum manifest; the SHA-256 check then authenticates the image bytes named by that manifest. Keyless signing uses an ephemeral certificate tied to the GitHub Actions OIDC identity rather than a long-lived private signing key stored in the repository.
