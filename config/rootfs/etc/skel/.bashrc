export EDITOR=vim
export PAGER=less
export PATH="$HOME/.local/bin:$PATH"

alias ll='ls -alF'
alias ports='ss -tulpn'
alias myip='ip -brief address'
alias vib='fastfetch --config "$HOME/.config/fastfetch/config.jsonc"'

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

if [[ $- == *i* && -z "${VIBRALI_FETCH_SHOWN:-}" ]]; then
  export VIBRALI_FETCH_SHOWN=1
  fastfetch --config "$HOME/.config/fastfetch/config.jsonc" 2>/dev/null || true
fi
