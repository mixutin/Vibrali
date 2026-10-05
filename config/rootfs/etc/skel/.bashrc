export EDITOR=vim
export PAGER=less
export BROWSER=brave-browser
export PATH="$HOME/.local/bin:$PATH"

HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend checkwinsize

alias ll='ls -alF'
alias la='ls -A'
alias lt='ls -lah --sort=time'
alias ports='ss -tulpn'
alias myip='ip -brief address'
alias netstate='nmcli device status'
alias vib='fastfetch --config "$HOME/.config/fastfetch/config.jsonc"'

mkcd() {
  if [[ $# -ne 1 ]]; then
    echo "usage: mkcd DIR" >&2
    return 2
  fi
  mkdir -p -- "$1" && cd -- "$1"
}

serve() {
  local port="${1:-8000}"
  python3 -m http.server --bind 127.0.0.1 "$port"
}

vprofiles() {
  if [[ -r /etc/vibrali/profiles ]]; then
    cat /etc/vibrali/profiles
  else
    printf '%s\n' base desktop
  fi
}

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

if [[ $- == *i* && -z "${VIBRALI_FETCH_SHOWN:-}" ]]; then
  export VIBRALI_FETCH_SHOWN=1
  fastfetch --config "$HOME/.config/fastfetch/config.jsonc" 2>/dev/null || true
fi
