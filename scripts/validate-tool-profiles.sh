#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_packages() {
  local profile="$1"
  shift
  local manifest="$ROOT/packages/$profile.txt"
  local package

  [[ -f "$manifest" ]] || {
    echo "missing tool profile manifest: $manifest" >&2
    exit 1
  }

  for package in "$@"; do
    if ! grep -Fxq "$package" "$manifest"; then
      echo "packages/$profile.txt: missing advertised package: $package" >&2
      exit 1
    fi
  done
}

require_packages base   build-essential curl git jq openssh-client python3 python3-venv ripgrep rsync tmux wget

require_packages desktop   firefox-esr network-manager starship thunar-archive-plugin xarchiver   xfce4 xfce4-clipman xfce4-screenshooter xfce4-terminal zenity zsh

require_packages network   masscan ncat nmap openvpn socat tcpdump tshark whois wireguard-tools wireshark-common

require_packages web   ffuf gobuster nikto sqlmap wfuzz

require_packages auth-audit   hashcat hydra john

require_packages pwn   clang gcc make python3-pwntools

require_packages reverse   apktool gdb lldb ltrace qemu-user strace

require_packages crypto   openssl pari-gp python3-sympy python3-z3

require_packages forensics   autopsy binwalk foremost libimage-exiftool-perl sleuthkit testdisk yara

require_packages wireless   aircrack-ng bully hcxtools reaver

require_packages directory-services   krb5-user ldap-utils python3-impacket

require_packages defensive   chkrootkit lynis

echo "advertised tool profile contracts: ok"
