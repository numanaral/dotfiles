#!/usr/bin/env bash
# Phase 7: Docker extras -- Docker Compose plugin, lazydocker.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

log_step "Docker Compose plugin"
if docker compose version &>/dev/null 2>&1; then
  log_info "Docker Compose already installed ($(docker compose version --short 2>/dev/null))."
else
  run sudo apt-get update
  run sudo apt-get install -y docker-compose-plugin
  log_success "Docker Compose plugin installed."
fi

log_step "lazydocker"
if has_cmd lazydocker; then
  log_info "lazydocker already installed."
else
  LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
  if [ -z "$LAZYDOCKER_VERSION" ]; then
    log_warn "Could not fetch lazydocker version. Skipping."
  else
    ARCH=$(uname -m)
    SKIP_LAZYDOCKER=""
    case "$ARCH" in
      x86_64) ARCH="x86_64" ;;
      aarch64) ARCH="arm64" ;;
      *) log_warn "Unsupported architecture: $ARCH. Skipping lazydocker."; SKIP_LAZYDOCKER=1 ;;
    esac

    if [ -z "$SKIP_LAZYDOCKER" ]; then
      run curl -Lo /tmp/lazydocker.tar.gz \
        "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION#v}_$(uname -s)_${ARCH}.tar.gz"
      run mkdir -p "$HOME/.local/bin"
      run tar xf /tmp/lazydocker.tar.gz -C "$HOME/.local/bin" lazydocker
      run rm -f /tmp/lazydocker.tar.gz
      log_success "lazydocker installed to ~/.local/bin/lazydocker."
    fi
  fi
fi

log_step "Docker extras setup complete"
log_success "Docker Compose + lazydocker ready."
