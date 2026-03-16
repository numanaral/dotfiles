#!/usr/bin/env bash
# Phase 2: Shell setup -- zsh, Oh My Zsh, Powerlevel10k, plugins, fzf.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

CONFIG_DIR="$(cd "$SCRIPT_DIR/../config" && pwd)"

log_step "Install zsh"
apt_install zsh

log_step "Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
  log_info "Oh My Zsh already installed."
else
  run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  log_success "Oh My Zsh installed."
fi

log_step "Powerlevel10k theme"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
  log_info "Powerlevel10k already installed."
else
  run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  log_success "Powerlevel10k installed."
fi

log_step "Zsh plugins"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  log_info "zsh-autosuggestions already installed."
else
  run git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  log_info "zsh-syntax-highlighting already installed."
else
  run git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

log_step "Install fzf"
apt_install fzf

log_step "Copy config files"
for conf in .zshrc .zsh_aliases .p10k.zsh; do
  if [ -f "$CONFIG_DIR/$conf" ]; then
    if [ -f "$HOME/$conf" ]; then
      run cp "$HOME/$conf" "$HOME/${conf}.backup.$(date +%Y%m%d%H%M%S)"
      log_info "Backed up existing $conf."
    fi
    run cp "$CONFIG_DIR/$conf" "$HOME/$conf"
    log_success "Copied $conf."
  fi
done

log_step "Set zsh as default shell"
if [ "$SHELL" != "$(which zsh)" ]; then
  run sudo chsh -s "$(which zsh)" "$(whoami)"
  log_success "Default shell set to zsh."
else
  log_info "Zsh is already the default shell."
fi

log_step "Shell setup complete"
log_success "Zsh + Oh My Zsh + Powerlevel10k + plugins installed."
log_info "Run 'p10k configure' for full theme customization."
