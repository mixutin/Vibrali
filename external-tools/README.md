# External tool supply chain

Vibrali prefers audited Debian 13 packages. Tools that are not available from the
configured Debian repositories must enter the image through a reviewable pinned source.

## Manifest format

`manifest.txt` uses one pipe-delimited record per tool:

~~~text
name|version|https-url|sha256|license|kind
~~~

Rules enforced by `scripts/validate-external-tools.sh`:

- names are stable lowercase identifiers,
- versions are explicit and pinned,
- downloads must use HTTPS,
- every artifact has an exact lowercase SHA-256,
- a license identifier must be recorded,
- artifact kind is currently `file` or `archive`,
- tool names must be unique.

## Fetching a pinned artifact

~~~bash
bash ./scripts/fetch-external-tool.sh neofetch /tmp/vibrali-external
~~~

The fetcher refuses unknown tools, downloads only over HTTPS, verifies SHA-256 before
moving the artifact into the destination cache, and re-verifies cached artifacts before
reuse.

The fetch step never executes the downloaded artifact.

## Adding a tool

Before adding a non-Debian tool:

1. Prefer an official upstream release or official source repository.
2. Pin an exact version.
3. Record the official HTTPS URL.
4. Compute and review the artifact SHA-256.
5. Record the upstream license and confirm Vibrali may redistribute or fetch it as used.
6. Add a tool-specific installation step that consumes the verified artifact.
7. Keep installation reviewable; do not pipe arbitrary network content into a root shell.
8. Add a validation or smoke-test path for the installed tool.

Tools with unstable "latest" URLs or unverifiable install scripts should not be added to
release images.
