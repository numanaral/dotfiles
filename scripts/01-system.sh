#!/usr/bin/env bash
# Phase 1: System hardening -- swap, user, firewall, SSH hardening.
# Must be run as root on a fresh server.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

require_root

SETUP_USER="${SETUP_USER:-}"
SETUP_SWAP_SIZE="${SETUP_SWAP_SIZE:-4G}"

SETUP_USER=$(prompt_if_empty "$SETUP_USER" "Username to create" "numanaral")

log_step "System updates"
run apt-get update -y
run apt-get upgrade -y

log_step "Swap file ($SETUP_SWAP_SIZE)"
if swapon --show | grep -q '/swapfile'; then
  log_info "Swap already active, skipping."
else
  run fallocate -l "$SETUP_SWAP_SIZE" /swapfile
  run chmod 600 /swapfile
  run mkswap /swapfile
  run swapon /swapfile
  ensure_line /etc/fstab "/swapfile none swap sw 0 0"
  log_success "Swap enabled ($SETUP_SWAP_SIZE)."
fi

log_step "Create user: $SETUP_USER"
if id "$SETUP_USER" &>/dev/null; then
  log_info "User $SETUP_USER already exists."
else
  run adduser --disabled-password --gecos "" "$SETUP_USER"
  log_success "User $SETUP_USER created."
fi

run usermod -aG sudo "$SETUP_USER"

if getent group docker &>/dev/null; then
  run usermod -aG docker "$SETUP_USER"
  log_info "Added $SETUP_USER to docker group."
fi

# Passwordless sudo for convenience on a personal server.
if [ ! -f "/etc/sudoers.d/$SETUP_USER" ]; then
  run bash -c "echo '$SETUP_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$SETUP_USER"
  run chmod 440 "/etc/sudoers.d/$SETUP_USER"
  log_success "Passwordless sudo configured."
fi

log_step "Copy SSH authorized_keys to $SETUP_USER"
USER_HOME="/home/$SETUP_USER"
run mkdir -p "$USER_HOME/.ssh"
if [ -f /root/.ssh/authorized_keys ]; then
  run cp /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
  run chown -R "$SETUP_USER:$SETUP_USER" "$USER_HOME/.ssh"
  run chmod 700 "$USER_HOME/.ssh"
  run chmod 600 "$USER_HOME/.ssh/authorized_keys"
  log_success "SSH keys copied."
else
  log_warn "No /root/.ssh/authorized_keys found. You may need to add keys manually."
fi

log_step "Firewall (ufw)"
if has_cmd ufw; then
  run ufw allow OpenSSH
  run ufw allow 80/tcp
  run ufw allow 443/tcp
  run ufw --force enable
  log_success "Firewall enabled (SSH + HTTP + HTTPS)."
else
  run apt-get install -y ufw
  run ufw allow OpenSSH
  run ufw allow 80/tcp
  run ufw allow 443/tcp
  run ufw --force enable
  log_success "UFW installed and enabled."
fi

log_step "Disable root SSH login"
SSHD_CONFIG="/etc/ssh/sshd_config"
if grep -q "^PermitRootLogin yes" "$SSHD_CONFIG" || grep -q "^#PermitRootLogin" "$SSHD_CONFIG"; then
  run sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
  run sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
  run systemctl restart sshd
  log_success "Root login disabled. Password auth disabled."
else
  log_info "Root login already disabled."
fi

log_step "System hardening complete"
log_success "User: $SETUP_USER"
log_success "Swap: $SETUP_SWAP_SIZE"
log_success "Firewall: SSH(22) + HTTP(80) + HTTPS(443)"
log_success "SSH: root login disabled, password auth disabled"
echo ""
log_warn "IMPORTANT: Test SSH as $SETUP_USER before closing this session!"
log_warn "  ssh $SETUP_USER@$(hostname -I | awk '{print $1}')"
