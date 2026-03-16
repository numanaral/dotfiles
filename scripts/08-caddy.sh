#!/usr/bin/env bash
# Phase 8: Caddy reverse proxy -- install + configure behind Cloudflare.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

CONFIG_DIR="$(cd "$SCRIPT_DIR/../config" && pwd)"

SETUP_DOMAIN="${SETUP_DOMAIN:-}"
SETUP_DOMAIN=$(prompt_if_empty "$SETUP_DOMAIN" "Base domain (e.g. numanaral.dev)" "numanaral.dev")

log_step "Install Caddy"
if has_cmd caddy; then
  log_info "Caddy already installed ($(caddy version 2>/dev/null))."
else
  run sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
  run bash -c "curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg"
  run bash -c "curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list"
  run sudo apt-get update
  run sudo apt-get install -y caddy
  log_success "Caddy installed."
fi

log_step "Configure Caddyfile"
CADDYFILE="/etc/caddy/Caddyfile"

if [ -f "$CONFIG_DIR/Caddyfile.template" ]; then
  run sudo bash -c "sed 's|{{DOMAIN}}|$SETUP_DOMAIN|g' '$CONFIG_DIR/Caddyfile.template' > '$CADDYFILE'"
  log_success "Caddyfile written to $CADDYFILE."
else
  log_warn "Caddyfile.template not found. Writing default config."
  run sudo bash -c "cat > '$CADDYFILE' << EOF
http://server.$SETUP_DOMAIN {
    redir https://$SETUP_DOMAIN permanent
}
EOF"
fi

log_step "Enable and start Caddy"
run sudo systemctl enable caddy
run sudo systemctl restart caddy

if sudo systemctl is-active --quiet caddy; then
  log_success "Caddy is running."
else
  log_error "Caddy failed to start. Check: sudo journalctl -u caddy --no-pager -n 20"
fi

log_step "Caddy setup complete"
log_success "Reverse proxy configured for $SETUP_DOMAIN."
log_info "Add new services by editing $CADDYFILE and running: sudo systemctl reload caddy"
