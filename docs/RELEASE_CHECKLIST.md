# Vibrali release checklist

Use this checklist for every public Vibrali image release.

## Source readiness

- [ ] Target version is chosen according to [RELEASE_POLICY.md](RELEASE_POLICY.md).
- [ ] `main` validation is green.
- [ ] Rolling build validation is green or an equivalent full build was run.
- [ ] ROADMAP status matches what is actually implemented.
- [ ] User-facing documentation matches current behavior.
- [ ] Known issues are collected for the release notes.
- [ ] No development-only CI probe or test credential is present in public rootfs content.

## Security and supply chain

- [ ] Package manifests pass validation.
- [ ] External-tool manifest passes pin/checksum/license validation.
- [ ] No unreviewed root-level `curl | sh` installation path was introduced.
- [ ] USB release account is locked before publication.
- [ ] Public installer still requires explicit destructive confirmation.
- [ ] Release checksum file is generated.
- [ ] Signature status is stated accurately; do not claim signed artifacts until signing is implemented.

## Image build

- [ ] USB raw image builds successfully.
- [ ] QEMU QCOW2 image builds successfully.
- [ ] Compressed streams pass integrity verification.
- [ ] USB image has expected GPT, EFI and root filesystem structure.
- [ ] QCOW2 metadata is valid.
- [ ] Oversized assets are split only after verification.

## Automated smoke tests

- [ ] Release installer reconstructs direct and split image fixtures.
- [ ] Release installer rejects an invalid checksum.
- [ ] Built USB artifact satisfies the installer download/checksum contract.
- [ ] OVMF/QEMU boot reaches the CI probe.
- [ ] Second QEMU boot proves persisted state.
- [ ] NetworkManager is enabled in the test image.
- [ ] LightDM is enabled in the test image.
- [ ] Representative tool commands required by the smoke test are present.

## Physical release gates

These cannot be replaced by VM checks.

- [ ] Image was installed from the same public path users will use.
- [ ] At least one supported USB SSD/drive completed installation.
- [ ] UEFI boot succeeded on the required hardware matrix.
- [ ] Wi-Fi/wired networking was exercised on tested hardware.
- [ ] Desktop login succeeded.
- [ ] User files persisted after reboot.
- [ ] APT package installation persisted after reboot.
- [ ] Kernel/initramfs update was tested when required by the release gate.
- [ ] Moving the same drive between tested systems did not require reinstalling Vibrali.

## Publication

- [ ] Version tag exactly matches release notes.
- [ ] Release notes contain changes, known issues and hardware assumptions.
- [ ] SHA-256 verification instructions are included.
- [ ] Assets and `SHA256SUMS` are attached.
- [ ] Website/latest-release path resolves to the intended release.
- [ ] Guided installer resolves the intended USB asset.
- [ ] Post-publish download was checksum-verified.

## After publication

- [ ] Test one fresh install from the published release.
- [ ] Record any newly verified hardware in the hardware compatibility document.
- [ ] File regressions as issues with release version, hardware and reproduction steps.
- [ ] Update ROADMAP checkmarks only for gates that have evidence.
