#!/usr/bin/env bash
# Shared helpers for setup scripts: logging, error handling, prompts.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

log_step() {
  echo ""
  echo -e "${BOLD}── $* ──${NC}"
}

die() {
  log_error "$@"
  exit 1
}

# Runs a command, logs it in dry-run mode, or executes it.
run() {
  if [ "${DRY_RUN:-false}" = "true" ]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} $*"
  else
    "$@"
  fi
}

# Checks if a command exists.
has_cmd() {
  command -v "$1" &>/dev/null
}

# Prompts the user for input if the value is empty.
# Usage: value=$(prompt_if_empty "$value" "Enter your email")
prompt_if_empty() {
  local value="$1"
  local prompt_msg="$2"
  local default="${3:-}"

  if [ -n "$value" ]; then
    echo "$value"
    return
  fi

  if [ -n "$default" ]; then
    read -rp "$(echo -e "${BLUE}?${NC} ${prompt_msg} [${default}]: ")" value
    echo "${value:-$default}"
  else
    read -rp "$(echo -e "${BLUE}?${NC} ${prompt_msg}: ")" value
    echo "$value"
  fi
}

# Prompts yes/no. Returns 0 for yes, 1 for no.
# Usage: if confirm "Install zsh?"; then ...
confirm() {
  local prompt_msg="$1"
  local default="${2:-y}"

  if [ "${DRY_RUN:-false}" = "true" ]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} Would ask: $prompt_msg [y/n]"
    return 0
  fi

  local yn
  if [ "$default" = "y" ]; then
    read -rp "$(echo -e "${BLUE}?${NC} ${prompt_msg} [Y/n]: ")" yn
    yn="${yn:-y}"
  else
    read -rp "$(echo -e "${BLUE}?${NC} ${prompt_msg} [y/N]: ")" yn
    yn="${yn:-n}"
  fi

  [[ "$yn" =~ ^[Yy] ]]
}

# Checks if running as root.
require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    die "This script must be run as root."
  fi
}

# Checks if NOT running as root.
require_non_root() {
  if [ "$(id -u)" -eq 0 ]; then
    die "This script should not be run as root. Run as your normal user."
  fi
}

# Loads .env file if it exists. Only sets vars that are not already set.
load_env() {
  local env_file="${1:-.env}"
  if [ -f "$env_file" ]; then
    log_info "Loading config from $env_file"
    while IFS='=' read -r key value; do
      [[ -z "$key" || "$key" =~ ^# ]] && continue
      key=$(echo "$key" | xargs)
      value=$(echo "$value" | xargs)
      if [ -z "${!key:-}" ]; then
        export "$key=$value"
      fi
    done < "$env_file"
  fi
}

# Idempotent apt install -- skips already-installed packages.
apt_install() {
  local to_install=()
  for pkg in "$@"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
      to_install+=("$pkg")
    fi
  done

  if [ ${#to_install[@]} -eq 0 ]; then
    log_info "All packages already installed: $*"
    return 0
  fi

  log_info "Installing: ${to_install[*]}"
  run sudo apt-get install -y --no-install-recommends "${to_install[@]}"
}

# Appends a line to a file if it doesn't already exist.
ensure_line() {
  local file="$1"
  local line="$2"
  if ! grep -qF "$line" "$file" 2>/dev/null; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      echo -e "${YELLOW}[DRY-RUN]${NC} append to $file: $line"
    else
      printf '%s\n' "$line" >> "$file"
    fi
  fi
}
