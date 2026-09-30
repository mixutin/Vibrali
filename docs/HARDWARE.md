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
- reliable cable/connector
- 64 GB practical minimum for the full workstation
- 128 GB or larger preferred for captures, wordlists, VMs and lab files

A device reporting as non-removable is not automatically unsafe: many USB SSD/NVMe bridges present that way. The installer therefore warns and shows model/serial/transport instead of relying on the removable bit alone.

## What still needs physical validation

- Intel desktop UEFI
- AMD desktop UEFI
- Intel laptop UEFI
- AMD laptop UEFI
- one legacy BIOS system
- Intel/Realtek/MediaTek Wi-Fi
- common USB Ethernet chipsets
- Intel/AMD graphics
- NVIDIA notes
- HiDPI
- multi-monitor
- Bluetooth/audio/input
- kernel/initramfs/GRUB upgrades followed by cross-machine boot

Update this document together with the corresponding ROADMAP item when evidence exists.
