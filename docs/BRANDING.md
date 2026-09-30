# Vibrali branding

Vibrali uses its own visible operating-system identity while retaining accurate upstream
provenance.

User-facing branding includes:

- `/etc/os-release` and `/etc/lsb-release`,
- console and SSH issue strings,
- GRUB distribution name,
- Plymouth boot splash,
- LightDM greeter,
- XFCE wallpaper and theme defaults,
- terminal palette and Starship prompt,
- Fastfetch and Neofetch presentation,
- desktop/application icon assets.

`ID_LIKE=debian` and `VIBRALI_BASE=Debian 13` remain in os-release intentionally.
They describe compatibility and provenance; they are not presented as the distro name.

Do not remove third-party copyright or license notices from packages.
