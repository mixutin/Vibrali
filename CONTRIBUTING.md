# Contributing

Vibrali is intended for authorized security testing, CTFs, education and research.

## Workflow

1. Branch from `main`.
2. Keep changes focused.
3. Run `./scripts/validate.sh`.
4. Test image changes in QEMU when possible.
5. Explain new packages and their purpose in the pull request.

Prefer packages from Debian repositories and avoid opaque prebuilt binaries. Large
specialist tools should usually live in optional profiles rather than the base image.

Document changes that affect boot, persistence, networking or filesystem state.
