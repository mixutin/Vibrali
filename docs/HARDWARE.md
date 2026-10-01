# Vibrali hardware compatibility

Vibrali targets portable x86_64 systems and is designed to boot the same installation across multiple computers. This file records **observed** hardware results only.

Do not add a device to a known-good table based on specifications alone. VM results do not count as physical hardware validation.

## Test record format

For each physical test, record:

- Vibrali release/tag or commit
- computer manufacturer/model
- CPU
- firmware mode (UEFI or legacy BIOS)
- Secure Boot state
- GPU
- Wi-Fi chipset
- Ethernet chipset
- USB storage device/enclosure
- boot result
- desktop/login result
- wired/Wi-Fi result
- suspend/resume result if tested
- notes/workarounds

## Known-good computers

No physical systems have been recorded yet.

| System | CPU | Firmware | Network | Storage/enclosure | Vibrali version | Result |
| --- | --- | --- | --- | --- | --- | --- |
| _Awaiting physical validation_ | — | — | — | — | — | — |

## Known-problematic computers

No physical incompatibilities have been recorded yet.

| System | Component | Vibrali version | Symptom | Workaround/status |
| --- | --- | --- | --- | --- |
| _None recorded_ | — | — | — | — |

## Wi-Fi adapter matrix

| Adapter/chipset | Interface | Monitor mode | Injection | Vibrali version | Notes |
| --- | --- | --- | --- | --- | --- |
| _Awaiting physical validation_ | — | — | — | — | — |

## USB Ethernet matrix

| Adapter/chipset | Link | DHCP | Vibrali version | Notes |
| --- | --- | --- | --- | --- |
| _Awaiting physical validation_ | — | — | — | — |

## Firmware coverage and limitations

Vibrali's base image carries Debian firmware packages for common Intel Wi-Fi, Realtek,
Atheros, Broadcom, AMD graphics and miscellaneous devices, plus both Intel and AMD CPU
microcode packages. These packages improve the chance that one installation can move
between unrelated PCs, but package presence is not the same thing as hardware validation.

Some important limits remain:

- Debian's device firmware is split across packages, including the `non-free-firmware`
  archive component. A device can require a package not included in the current Vibrali
  baseline.
- MediaTek/Ralink firmware is available in Debian 13 as `firmware-mediatek`, but it is
  not currently part of Vibrali's mandatory base. A machine that requires it may need
  `sudo apt install firmware-mediatek` once networking/package access is available.
- New hardware revisions can require firmware newer than the version in the stable Debian
  release. Backports may contain newer firmware, but switching to backports is a deliberate
  compatibility choice and is not assumed by the baseline image.
- Proprietary vendor utilities, Windows-only firmware updaters and motherboard firmware are
  outside the Vibrali image. Update device/UEFI firmware through the vendor-supported
  method when needed.
- Missing firmware can present as a device that exists in `lspci`/`lsusb` but has no
  usable interface, or as firmware-load errors in the kernel log.

Useful diagnostics after moving the USB to a new machine:

~~~bash
lspci -nnk
lsusb
journalctl -k -b | grep -Ei 'firmware|iwlwifi|rtl|rtw|ath|mt7|amdgpu|nouveau'
~~~

Do not mark Intel, Realtek, MediaTek, Ethernet or GPU roadmap validation complete merely
because the corresponding firmware package is installed; record a physical test result in
the matrices above.

## Graphics portability notes

### AMD discrete graphics

The baseline includes Debian's `firmware-amd-graphics`, which supplies firmware used by
the in-kernel Radeon/AMDGPU family. Vibrali intentionally relies on the normal Debian
kernel graphics stack for portable desktop use rather than pinning the installation to a
vendor compute stack.

That does not make every AMD discrete GPU validated. Display outputs, suspend/resume,
multi-monitor behavior, power management and compute runtimes vary by GPU generation and
host firmware. ROCm/OpenCL acceleration is not a baseline promise; validate it separately
on hardware where it matters.

### NVIDIA

Vibrali does not install the proprietary NVIDIA driver or CUDA stack by default. The
portable baseline may use the kernel's available open-source path where supported, but
actual compatibility depends on GPU generation and Debian's driver/firmware support.

Installing a proprietary NVIDIA DKMS driver is a machine-specific choice: it couples the
USB to a kernel module build and, under Secure Boot, can require Machine Owner Key
enrollment on each computer. That is deliberately outside the default portable trust
model. Record the exact GPU, driver choice, Secure Boot state and result in this hardware
document when tested.

## GPU acceleration and password-auditing portability

CPU-based Hashcat/John workflows are portable across the supported x86_64 baseline, but
GPU acceleration is host-specific. The USB can carry the applications and configuration;
the usable accelerator still depends on the current machine's GPU, kernel driver and
OpenCL/CUDA runtime.

Vibrali does not install a proprietary NVIDIA driver or CUDA stack by default. Doing so
would add kernel/DKMS and vendor-version coupling that can reduce portability between
unrelated PCs. AMD and Intel acceleration also depends on the runtime exposed by the
current host GPU/driver combination.

After moving the USB to a machine, inspect what Hashcat can actually use:

~~~bash
lspci -nnk | grep -A3 -E 'VGA|3D|Display'
hashcat -I
~~~

If no suitable backend is reported, Hashcat can still be used with the available CPU
backend where supported, or the machine can be configured with the appropriate vendor
runtime for that specific hardware. Record GPU/driver results in this hardware matrix
rather than assuming a setup that worked on one PC is portable to another.

## Storage and enclosure guidance

Prefer a real SSD over a low-end thumb drive.

Recommended characteristics:

- USB 3.x or faster
- UASP-capable enclosure where stable
- SSD/NVMe media with reasonable write endurance
- a bridge/enclosure that reliably passes flushes and, ideally, discard/TRIM
- adequate enclosure cooling for sustained package updates and large captures
- reliable cable/connector and enough host-port power for the drive
- 64 GB practical minimum for the full workstation
- 128 GB or larger preferred for captures, wordlists, VMs and lab files

Before trusting an enclosure for daily use, inspect the actual block device rather than
the marketing label:

~~~bash
lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN,ROTA,DISC-GRAN,DISC-MAX
findmnt -no SOURCE,FSTYPE,OPTIONS /
sudo fstrim -v /
~~~

A zero/unsupported discard capability is not automatically fatal, but it means the bridge
may not pass TRIM. Prefer a combination that survives repeated writes, clean unmounts,
reboots and reconnects without resets or filesystem errors. NVMe-to-USB bridges can also
thermal-throttle under sustained writes, so enclosure cooling matters for image builds,
large package upgrades and capture-heavy work.

A device reporting as non-removable is not automatically unsafe: many USB SSD/NVMe bridges
present that way. The installer therefore warns and shows model/serial/transport instead
of relying on the removable bit alone. Product-specific enclosure recommendations should
only be added after the exact bridge/firmware combination has been physically tested.

## What still needs physical validation

- Intel desktop UEFI
- AMD desktop UEFI
- Intel laptop UEFI
- AMD laptop UEFI
- one legacy BIOS system
- Intel/Realtek/MediaTek Wi-Fi
- common USB Ethernet chipsets
- Intel/AMD graphics
- HiDPI
- multi-monitor
- Bluetooth/audio/input
- kernel/initramfs/GRUB upgrades followed by cross-machine boot

Update this document together with the corresponding ROADMAP item when evidence exists.
