# Powerlevel10k instant prompt. Must stay near the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

export PATH=$HOME/bin:/usr/local/bin:$PATH

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)" 2>/dev/null || true

# nvm
export NVM_DIR="$HOME/.nvm"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Editor: vim on SSH, code locally.
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='code'
fi

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export PATH="$HOME/.local/bin:$PATH"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Auto-switch node version based on .nvmrc when cd-ing.
cdnvm() {
  builtin cd "$@"
  nvm_path=$(nvm_find_up .nvmrc | tr -d '\n')

  if [[ ! $nvm_path = *[^[:space:]]* ]]; then
    declare default_version
    default_version=$(nvm version default)
    if [[ $default_version == "N/A" ]]; then
      nvm alias default node
      default_version=$(nvm version default)
    fi
    if [[ $(nvm current) != "$default_version" ]]; then
      nvm use default
    fi
  elif [[ -s $nvm_path/.nvmrc && -r $nvm_path/.nvmrc ]]; then
    declare nvm_version
    nvm_version=$(< "$nvm_path"/.nvmrc)
    declare locally_resolved_nvm_version
    locally_resolved_nvm_version=$(nvm ls --no-colors "$nvm_version" | tail -1 | tr -d '\->*' | tr -d '[:space:]')
    if [[ "$locally_resolved_nvm_version" == "N/A" ]]; then
      nvm install "$nvm_version"
    elif [[ $(nvm current) != "$locally_resolved_nvm_version" ]]; then
      nvm use "$nvm_version"
    fi
  fi
}
alias cd='cdnvm'
cd "$PWD"

# Prompt context: show user@host only on SSH.
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"
  fi
}

# History search with arrow keys.
bindkey '\e[A' history-beginning-search-backward
bindkey '\e[B' history-beginning-search-forward
bindkey '\C-h' backward-kill-line
bindkey '\e[3;5~' kill-line

TIMEFMT=$'%J\n%U user\n%S system\n%P cpu\n%*E total'
