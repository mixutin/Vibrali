export EDITOR=vim
export PAGER=less
export PATH="$HOME/.local/bin:$PATH"

autoload -Uz compinit && compinit
setopt autocd interactivecomments histignorealldups
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

alias ll='ls -alF'
alias ports='ss -tulpn'
alias myip='ip -brief address'
alias vib='fastfetch --config "$HOME/.config/fastfetch/config.jsonc"'

eval "$(starship init zsh)"

if [[ -o interactive && -z "${VIBRALI_FETCH_SHOWN:-}" ]]; then
  export VIBRALI_FETCH_SHOWN=1
  fastfetch --config "$HOME/.config/fastfetch/config.jsonc" 2>/dev/null || true
fi
