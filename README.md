# dotfiles

Reusable server setup scripts. Configurable via flags, `.env` file, or interactive prompts.

## Quick Start

```bash
git clone git@github.com:numanaral/dotfiles.git
cd dotfiles
cp .env.example .env   # fill in your values
```

### Run everything

```bash
# As root (Phase 1 creates your non-root user):
./setup.sh --all

# Then SSH as your new user and re-run phases 2-8:
./setup.sh --all --skip-system
```

### Run specific phases

```bash
./setup.sh --system --shell --languages
./setup.sh --caddy --domain numanaral.dev
./setup.sh --all --skip-browser --skip-caddy
```

### Dry run

```bash
./setup.sh --dry-run --all
```

## Phases

| # | Script | What it does |
|---|--------|-------------|
| 1 | `01-system.sh` | Swap, non-root user, UFW firewall, SSH hardening |
| 2 | `02-shell.sh` | Zsh, Oh My Zsh, Powerlevel10k, plugins, fzf |
| 3 | `03-dev-tools.sh` | git, make, curl, jq, htop, gh CLI, SSH key for GitHub |
| 4 | `04-languages.sh` | Python (pyenv), Node (nvm), Yarn |
| 5 | `05-media-tools.sh` | FFmpeg, ImageMagick, ExifTool, Poppler, LibreOffice, libvips, Pandoc, wkhtmltopdf |
| 6 | `06-browser.sh` | Playwright + Chromium headless |
| 7 | `07-docker-extras.sh` | Docker Compose plugin, lazydocker |
| 8 | `08-caddy.sh` | Caddy reverse proxy (behind Cloudflare) |

## Configuration

Priority: **flags > `.env` > interactive prompts**.

| Variable | Default | Description |
|----------|---------|-------------|
| `SETUP_USER` | `numanaral` | Non-root user to create |
| `SETUP_GIT_NAME` | `numanaral` | Git user name |
| `SETUP_GIT_EMAIL` | *(prompted)* | Git email |
| `SETUP_DOMAIN` | `numanaral.dev` | Base domain for Caddy |
| `SETUP_SWAP_SIZE` | `4G` | Swap file size |
| `SETUP_PYTHON_VERSION` | `3.12` | Python version for pyenv |
| `SETUP_NODE_VERSION` | `22` | Node.js version for nvm |
| `SETUP_NODE_FALLBACK_VERSION` | `20` | Fallback Node.js version |

## File Structure

```
dotfiles/
  setup.sh                  # Main entry point
  .env.example              # Config template
  scripts/
    01-system.sh ... 08-caddy.sh
    lib/utils.sh            # Shared helpers
  config/
    .zshrc                  # Shell config
    .zsh_aliases            # Aliases
    .gitconfig.template     # Git config (templated)
    .p10k.zsh               # Powerlevel10k theme
    Caddyfile.template      # Caddy config (templated)
```

## Adding a New Service

1. Add a CNAME in Cloudflare: `myapp` -> `server.numanaral.dev` (Proxy ON)
2. Edit `/etc/caddy/Caddyfile`:
   ```
   http://myapp.numanaral.dev {
       reverse_proxy localhost:8080
   }
   ```
3. Reload: `sudo systemctl reload caddy`
