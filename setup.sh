#!/usr/bin/env bash
# Main entry point for server setup.
# Supports flags, .env file, and interactive prompts.
#
# Usage:
#   ./setup.sh                              # Interactive mode
#   ./setup.sh --all                        # Run all phases
#   ./setup.sh --system --shell --languages # Run specific phases
#   ./setup.sh --skip-browser --skip-caddy  # Skip specific phases
#   ./setup.sh --dry-run --all              # Preview without executing
#
# Config priority: flags > .env > interactive prompts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib/utils.sh"

# Phase flags (empty = not specified via flag).
FLAG_ALL=""
FLAG_SYSTEM=""
FLAG_SHELL=""
FLAG_DEV_TOOLS=""
FLAG_LANGUAGES=""
FLAG_MEDIA_TOOLS=""
FLAG_BROWSER=""
FLAG_DOCKER_EXTRAS=""
FLAG_CADDY=""

SKIP_SYSTEM=""
SKIP_SHELL=""
SKIP_DEV_TOOLS=""
SKIP_LANGUAGES=""
SKIP_MEDIA_TOOLS=""
SKIP_BROWSER=""
SKIP_DOCKER_EXTRAS=""
SKIP_CADDY=""

export DRY_RUN="false"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Phases:
  --all               Run all phases
  --system            Phase 1: System hardening
  --shell             Phase 2: Shell setup
  --dev-tools         Phase 3: Dev tools
  --languages         Phase 4: Languages
  --media-tools       Phase 5: Media tools
  --browser           Phase 6: Headless browser
  --docker-extras     Phase 7: Docker extras
  --caddy             Phase 8: Caddy reverse proxy

Skip:
  --skip-system       Skip Phase 1
  --skip-shell        Skip Phase 2
  --skip-dev-tools    Skip Phase 3
  --skip-languages    Skip Phase 4
  --skip-media-tools  Skip Phase 5
  --skip-browser      Skip Phase 6
  --skip-docker-extras Skip Phase 7
  --skip-caddy        Skip Phase 8

Config:
  --user NAME         Username to create (SETUP_USER)
  --domain DOMAIN     Base domain (SETUP_DOMAIN)
  --swap SIZE         Swap size (SETUP_SWAP_SIZE, default: 4G)
  --python VER        Python version (SETUP_PYTHON_VERSION, default: 3.12)
  --node VER          Node version (SETUP_NODE_VERSION, default: 22)
  --git-name NAME     Git user name (SETUP_GIT_NAME)
  --git-email EMAIL   Git email (SETUP_GIT_EMAIL)
  --env FILE          Load env file (default: .env if exists)

Other:
  --dry-run           Show what would be done without executing
  -h, --help          Show this help
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)            FLAG_ALL=1 ;;
    --system)         FLAG_SYSTEM=1 ;;
    --shell)          FLAG_SHELL=1 ;;
    --dev-tools)      FLAG_DEV_TOOLS=1 ;;
    --languages)      FLAG_LANGUAGES=1 ;;
    --media-tools)    FLAG_MEDIA_TOOLS=1 ;;
    --browser)        FLAG_BROWSER=1 ;;
    --docker-extras)  FLAG_DOCKER_EXTRAS=1 ;;
    --caddy)          FLAG_CADDY=1 ;;
    --skip-system)        SKIP_SYSTEM=1 ;;
    --skip-shell)         SKIP_SHELL=1 ;;
    --skip-dev-tools)     SKIP_DEV_TOOLS=1 ;;
    --skip-languages)     SKIP_LANGUAGES=1 ;;
    --skip-media-tools)   SKIP_MEDIA_TOOLS=1 ;;
    --skip-browser)       SKIP_BROWSER=1 ;;
    --skip-docker-extras) SKIP_DOCKER_EXTRAS=1 ;;
    --skip-caddy)         SKIP_CADDY=1 ;;
    --user)           shift; export SETUP_USER="$1" ;;
    --domain)         shift; export SETUP_DOMAIN="$1" ;;
    --swap)           shift; export SETUP_SWAP_SIZE="$1" ;;
    --python)         shift; export SETUP_PYTHON_VERSION="$1" ;;
    --node)           shift; export SETUP_NODE_VERSION="$1" ;;
    --git-name)       shift; export SETUP_GIT_NAME="$1" ;;
    --git-email)      shift; export SETUP_GIT_EMAIL="$1" ;;
    --env)            shift; load_env "$1" ;;
    --dry-run)        export DRY_RUN="true" ;;
    -h|--help)        usage ;;
    *) die "Unknown option: $1. Use --help for usage." ;;
  esac
  shift
done

# Load .env if it exists and wasn't loaded via --env flag.
if [ -f "$SCRIPT_DIR/.env" ]; then
  load_env "$SCRIPT_DIR/.env"
fi

# Determine which phases to run.
should_run() {
  local phase_flag="$1"
  local skip_flag="$2"

  [ -n "$skip_flag" ] && return 1
  [ -n "$FLAG_ALL" ] && return 0
  [ -n "$phase_flag" ] && return 0
  return 1
}

# If no phases specified and not --all, go interactive.
any_phase_specified() {
  [ -n "$FLAG_ALL" ] || [ -n "$FLAG_SYSTEM" ] || [ -n "$FLAG_SHELL" ] || \
  [ -n "$FLAG_DEV_TOOLS" ] || [ -n "$FLAG_LANGUAGES" ] || [ -n "$FLAG_MEDIA_TOOLS" ] || \
  [ -n "$FLAG_BROWSER" ] || [ -n "$FLAG_DOCKER_EXTRAS" ] || [ -n "$FLAG_CADDY" ]
}

INTERACTIVE="false"
if ! any_phase_specified; then
  INTERACTIVE="true"
fi

run_phase() {
  local num="$1"
  local name="$2"
  local script="$3"
  local phase_flag="$4"
  local skip_flag="$5"

  if [ "$INTERACTIVE" = "true" ]; then
    if confirm "Run Phase $num: $name?"; then
      phase_flag=1
    else
      return 0
    fi
  fi

  if should_run "$phase_flag" "$skip_flag" || [ -n "${phase_flag:-}" ]; then
    echo ""
    echo -e "\033[1m════════════════════════════════════════\033[0m"
    echo -e "\033[1m  Phase $num: $name\033[0m"
    echo -e "\033[1m════════════════════════════════════════\033[0m"
    bash "$SCRIPT_DIR/scripts/$script"
  fi
}

echo ""
echo -e "\033[1m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[1m║         Server Setup Script              ║\033[0m"
echo -e "\033[1m╚══════════════════════════════════════════╝\033[0m"
echo ""

if [ "$DRY_RUN" = "true" ]; then
  log_warn "DRY RUN MODE -- no changes will be made."
  echo ""
fi

run_phase 1 "System Hardening"   "01-system.sh"       "$FLAG_SYSTEM"       "$SKIP_SYSTEM"
run_phase 2 "Shell Setup"        "02-shell.sh"        "$FLAG_SHELL"        "$SKIP_SHELL"
run_phase 3 "Dev Tools"          "03-dev-tools.sh"    "$FLAG_DEV_TOOLS"    "$SKIP_DEV_TOOLS"
run_phase 4 "Languages"          "04-languages.sh"    "$FLAG_LANGUAGES"    "$SKIP_LANGUAGES"
run_phase 5 "Media Tools"        "05-media-tools.sh"  "$FLAG_MEDIA_TOOLS"  "$SKIP_MEDIA_TOOLS"
run_phase 6 "Headless Browser"   "06-browser.sh"      "$FLAG_BROWSER"      "$SKIP_BROWSER"
run_phase 7 "Docker Extras"      "07-docker-extras.sh" "$FLAG_DOCKER_EXTRAS" "$SKIP_DOCKER_EXTRAS"
run_phase 8 "Caddy Proxy"        "08-caddy.sh"        "$FLAG_CADDY"        "$SKIP_CADDY"

echo ""
log_success "Setup complete!"
echo ""
