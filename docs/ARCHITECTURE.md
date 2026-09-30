# Architecture

Vibrali initially uses Debian `live-build`.

The project separates three concerns:

1. **Base system** — Debian packages and live boot infrastructure.
2. **Vibrali layer** — package profiles, branding, defaults and hooks.
3. **Persistent state** — an optional writable overlay on removable media.

The compressed live root remains read-only. Runtime changes use an overlay filesystem.
With persistence enabled, selected state is stored on a partition labeled
`persistence`.

Debian gives Vibrali a mature live-image toolchain, package provenance, broad hardware
support and an independent base that can be customized incrementally.
