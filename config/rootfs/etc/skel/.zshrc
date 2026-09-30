export EDITOR=vim
export PAGER=less
export PATH="$HOME/.local/bin:$PATH"

autoload -Uz compinit && compinit
setopt autocd interactivecomments histignorealldups appendhistory sharehistory
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

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
  python3 -m http.server "$port" --bind 127.0.0.1
}

vprofiles() {
  if [[ -r /etc/vibrali/profiles ]]; then
    cat /etc/vibrali/profiles
  else
    printf '%s\n' base desktop
  fi
}

eval "$(starship init zsh)"

if [[ -o interactive && -z "${VIBRALI_FETCH_SHOWN:-}" ]]; then
  export VIBRALI_FETCH_SHOWN=1
  fastfetch --config "$HOME/.config/fastfetch/config.jsonc" 2>/dev/null || true
fi
