#!/usr/bin/env bash
# Phase 5: Media/processing tools -- FFmpeg, ImageMagick, ExifTool, etc.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

log_step "Media and processing tools"

apt_install \
  ffmpeg \
  imagemagick \
  libimage-exiftool-perl \
  poppler-utils \
  libreoffice-impress \
  libvips-tools \
  pandoc \
  wkhtmltopdf \
  fonts-crosextra-carlito \
  fonts-crosextra-caladea

run fc-cache -f 2>/dev/null || true

log_step "Media tools setup complete"
log_success "Installed:"
for cmd in ffmpeg convert exiftool pdftoppm libreoffice vips pandoc wkhtmltopdf; do
  if has_cmd "$cmd"; then
    log_success "  $cmd"
  else
    log_warn "  $cmd not found in PATH (may need full path)."
  fi
done
