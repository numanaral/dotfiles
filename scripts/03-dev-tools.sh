#!/usr/bin/env bash
# Phase 3: Dev tools -- CLI essentials, GitHub CLI, SSH key for GitHub.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

CONFIG_DIR="$(cd "$SCRIPT_DIR/../config" && pwd)"

SETUP_GIT_NAME="${SETUP_GIT_NAME:-}"
SETUP_GIT_EMAIL="${SETUP_GIT_EMAIL:-}"

log_step "Essential CLI tools"
apt_install \
  git \
  make \
  curl \
  wget \
  jq \
  htop \
  tree \
  unzip \
  zip \
  rsync \
  tmux \
  vim

log_step "GitHub CLI (gh)"
if has_cmd gh; then
  log_info "gh already installed ($(gh --version | head -1))."
else
  run bash -c '(type -p wget >/dev/null || apt-get install wget -y) \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat "$out" | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install gh -y'
  log_success "gh installed."
fi

log_step "Git configuration"
SETUP_GIT_NAME=$(prompt_if_empty "$SETUP_GIT_NAME" "Git user name" "numanaral")
SETUP_GIT_EMAIL=$(prompt_if_empty "$SETUP_GIT_EMAIL" "Git email")

if [ -f "$CONFIG_DIR/.gitconfig.template" ]; then
  run bash -c "sed -e 's|{{GIT_NAME}}|$SETUP_GIT_NAME|g' -e 's|{{GIT_EMAIL}}|$SETUP_GIT_EMAIL|g' '$CONFIG_DIR/.gitconfig.template' > '$HOME/.gitconfig'"
  log_success "Git config written to ~/.gitconfig."
else
  run git config --global user.name "$SETUP_GIT_NAME"
  run git config --global user.email "$SETUP_GIT_EMAIL"
  log_success "Git config set via git config."
fi

log_step "SSH key for GitHub"
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ -f "$SSH_KEY" ]; then
  log_info "SSH key already exists at $SSH_KEY."
else
  run ssh-keygen -t ed25519 -C "$SETUP_GIT_EMAIL" -f "$SSH_KEY" -N ""
  log_success "SSH key generated."
fi

log_step "GitHub authentication"
if gh auth status &>/dev/null; then
  log_info "Already authenticated with GitHub."
else
  log_info "Authenticate with GitHub to add your SSH key."
  log_info "This will open a browser or give you a code to enter at github.com/login/device."
  if [ "${DRY_RUN:-false}" != "true" ]; then
    gh auth login --git-protocol ssh --web
    gh ssh-key add "$SSH_KEY.pub" --title "$(hostname)"
    log_success "SSH key added to GitHub."
  fi
fi

log_step "Create ~/code directory"
run mkdir -p "$HOME/code"

log_step "Dev tools setup complete"
log_success "CLI tools, gh, git config, and GitHub SSH key configured."
