#!/usr/bin/env bash
# Phase 6: Headless browser -- Playwright + Chromium.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

log_step "Playwright"
if npx playwright --version &>/dev/null 2>&1; then
  log_info "Playwright already available ($(npx playwright --version 2>/dev/null))."
else
  run npm install -g playwright
  log_success "Playwright installed globally."
fi

log_step "Chromium browser + system dependencies"
run npx playwright install --with-deps chromium
log_success "Chromium installed with all system dependencies."

log_step "Headless browser setup complete"
log_success "Playwright + Chromium ready."
log_info "Test with: npx playwright screenshot https://example.com /tmp/test.png"
