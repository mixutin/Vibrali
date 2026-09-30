# Building Vibrali

Debian 13 is the reference build host.

Install dependencies:

```bash
sudo apt update
sudo apt install live-build debootstrap squashfs-tools xorriso isolinux syslinux-common qemu-system-x86
```

Build with:

```bash
./scripts/build.sh
```

Clean generated state with `./scripts/clean.sh`, validate with
`./scripts/validate.sh`, and test the resulting ISO with `./scripts/run-qemu.sh`.

The build script uses a disposable workspace under `.work/` and places images in
`build/`.
