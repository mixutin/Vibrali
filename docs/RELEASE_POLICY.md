# Vibrali release policy

This document defines how Vibrali versions, release channels, support and artifact retention work.

## Versioning

Vibrali uses semantic versioning for public releases:

- `vMAJOR.MINOR.PATCH` — stable release.
- `vMAJOR.MINOR.PATCH-rc.N` — release candidate.
- `vMAJOR.MINOR.PATCH-beta.N` — beta.
- `vMAJOR.MINOR.PATCH-dev.N` — development preview.

Before `v1.0.0`, compatibility may still change between minor versions. After 1.0, breaking installer/image behavior should require a major-version change unless it is necessary to fix a critical security or data-loss issue.

## Channels

### Rolling preview

`main` is the rolling development channel. It receives completed work after review and automated validation. It is useful for contributors and testers, but it is not a promise of long-term compatibility.

### Preview

Development, beta and release-candidate tags are preview releases. They are intended for testing the full install/update/recovery path before stable promotion.

### Stable

Stable tags have no prerelease suffix. A stable release must pass the release checklist, automated image verification, installer smoke tests and QEMU persistence checks, plus the physical-hardware gates required by the roadmap.

Vibrali does not currently provide a separate package repository. The installed system follows Debian package sources, while Vibrali-specific image releases are versioned through GitHub Releases.

## Support policy

Before `v1.0.0`, the latest release and current `main` are the supported development targets.

Starting with `v1.0.0`:

- the latest stable release is supported;
- the immediately previous stable minor release receives best-effort migration/recovery guidance until the next stable minor release has been available for 30 days;
- preview releases are supported only for reproducing and fixing bugs in that preview line;
- older previews are not maintained once a newer preview supersedes them.

Support means project-level fixes, documentation and release guidance. Debian packages remain governed by Debian's own security/support lifecycle, and third-party tools retain their upstream support policies.

## Image retention

Git tags and release notes are permanent project history.

For binary assets:

- keep all stable release assets;
- keep the latest release candidate for the active version line;
- keep the latest beta and development preview when useful for regression comparison;
- older prerelease binary assets may be removed if storage limits become a problem, but their tags, source and release notes should remain.

A release must never silently replace an already-published binary under the same version tag. If an artifact is wrong, publish a new version.

## Release notes

Every public release should include:

- release channel and version;
- supported architecture;
- major changes;
- installation notes;
- known issues;
- security-impacting changes;
- hardware assumptions or newly verified hardware;
- checksum/signature instructions;
- upgrade/recovery notes when applicable.

Stable releases should explicitly call out any known portability limitations.

## Reproducibility

Vibrali aims for reviewable, repeatable image construction rather than claiming byte-for-byte reproducibility before that is demonstrated.

Each release is built from a Git tag by the repository workflow. The build records the source commit, Debian suite, package manifests and pinned external-tool metadata. Release artifacts are checksum-verified and structurally inspected before publication.

A future release may only be described as reproducible in the strict sense after independent builds have demonstrated matching outputs or an explicitly documented reproducibility level.
