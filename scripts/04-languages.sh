#!/usr/bin/env bash
# Phase 4: Languages -- Python (pyenv), Node (nvm), Yarn.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

SETUP_PYTHON_VERSION="${SETUP_PYTHON_VERSION:-3.12}"
SETUP_NODE_VERSION="${SETUP_NODE_VERSION:-22}"

log_step "Pyenv prerequisites"
apt_install \
  build-essential \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libncursesw5-dev \
  xz-utils \
  tk-dev \
  libxml2-dev \
  libxmlsec1-dev \
  libffi-dev \
  liblzma-dev

log_step "Pyenv"
if [ -d "$HOME/.pyenv" ]; then
  log_info "Pyenv already installed."
else
  run bash -c "curl -fsSL https://pyenv.run | bash"
  log_success "Pyenv installed."
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null || true

log_step "Python $SETUP_PYTHON_VERSION"
if pyenv versions --bare 2>/dev/null | grep -q "^${SETUP_PYTHON_VERSION}"; then
  log_info "Python $SETUP_PYTHON_VERSION already installed."
else
  LATEST=$(pyenv install --list 2>/dev/null | grep -E "^\s+${SETUP_PYTHON_VERSION}\.[0-9]+$" | tail -1 | tr -d ' ')
  if [ -z "$LATEST" ]; then
    log_warn "Could not find Python $SETUP_PYTHON_VERSION.x. Installing $SETUP_PYTHON_VERSION directly."
    LATEST="$SETUP_PYTHON_VERSION"
  fi
  log_info "Installing Python $LATEST..."
  run pyenv install "$LATEST"
  run pyenv global "$LATEST"
  log_success "Python $LATEST installed and set as global."
fi

log_step "NVM"
export NVM_DIR="$HOME/.nvm"
if [ -d "$NVM_DIR" ]; then
  log_info "NVM already installed."
else
  run bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
  log_success "NVM installed."
fi

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

log_step "Node $SETUP_NODE_VERSION"
if nvm ls "$SETUP_NODE_VERSION" &>/dev/null 2>&1; then
  log_info "Node $SETUP_NODE_VERSION already installed."
else
  run nvm install "$SETUP_NODE_VERSION"
  log_success "Node $SETUP_NODE_VERSION installed."
fi

run nvm alias default "$SETUP_NODE_VERSION"
run nvm use "$SETUP_NODE_VERSION"

log_step "Yarn"
if has_cmd yarn; then
  log_info "Yarn already installed ($(yarn --version))."
else
  run npm install -g yarn
  log_success "Yarn installed."
fi

log_step "Languages setup complete"
log_success "Python $(pyenv version-name 2>/dev/null || echo "$SETUP_PYTHON_VERSION") via pyenv."
log_success "Node $(node --version 2>/dev/null || echo "$SETUP_NODE_VERSION") via nvm (default)."
log_success "Yarn $(yarn --version 2>/dev/null || echo "installed")."
