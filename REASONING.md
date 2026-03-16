# Reasoning & Design Decisions

Why things are the way they are.

---

## Architecture

### Why modular scripts instead of one big script?

Each phase (`01-system.sh` through `08-caddy.sh`) is independent and idempotent. This means:

- Re-run any phase without re-running everything.
- Skip phases that don't apply (`--skip-browser` on a server that doesn't need headless Chrome).
- Debug one phase at a time.
- Different servers can run different subsets.

### Why three config methods (flags > env > interactive)?

Different use cases need different approaches:

- **Flags**: CI/CD, scripted provisioning, one-off overrides.
- **Env file**: Repeatable setups. Clone repo, fill `.env`, run. Good for documenting a specific server's config.
- **Interactive**: First-time setup when you're exploring options.

Priority order ensures flags always win, env provides defaults, and interactive fills gaps.

### Why a bootstrap `install.sh`?

The setup scripts reference each other (`source lib/utils.sh`, read from `config/`), so they need the full repo. The bootstrap script handles cloning, then hands off to `setup.sh`. One-liner from a fresh server:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/numanaral/dotfiles/main/install.sh) --all
```

---

## Phase 1: System Hardening

### Why 4GB swap?

The server has 8GB RAM. Swap prevents OOM kills during memory spikes (e.g., Docker builds, LibreOffice conversions, ML model loading). 4GB is enough to absorb spikes without thrashing. Configurable via `SETUP_SWAP_SIZE`.

### Why passwordless sudo?

This is a personal dev/tool server, not a shared production environment. Typing passwords for every `apt install` or `docker` command is friction with no security benefit when you're the only user.

### Why disable root SSH login?

Root is the most targeted account in brute-force attacks. Disabling it forces attackers to guess both a username and a key. The non-root user has sudo, so nothing is lost.

### Why allow HTTP (port 80)?

Cloudflare proxy connects to the origin server over HTTP. Caddy listens on port 80 and Cloudflare handles public HTTPS termination. Port 80 is also needed if you ever want Let's Encrypt ACME challenges for direct HTTPS (without Cloudflare).

---

## Phase 2: Shell

### Why Zsh + Oh My Zsh + Powerlevel10k?

- **Zsh**: Better completion, globbing, and scripting than bash.
- **Oh My Zsh**: Plugin ecosystem (git, autosuggestions, syntax highlighting) without manual config.
- **Powerlevel10k**: Fast prompt with git status, execution time, exit codes, and context-aware segments. The rainbow theme with powerline separators gives information density without clutter.

### Why these plugins?

- **git**: Aliases and completion for the tool you use most.
- **zsh-autosuggestions**: Ghost text from history. Accept with right arrow. Saves typing.
- **zsh-syntax-highlighting**: Red = typo, green = valid command. Catch errors before hitting enter.

### Why fzf?

Fuzzy finder for history (`Ctrl+R`), files, and directories. Dramatically faster than scrolling through history or typing `find`.

### Why `cdnvm` (auto-switch Node on cd)?

Different projects use different Node versions. Forgetting to `nvm use` before `npm install` causes subtle breakage. This function reads `.nvmrc` on every `cd` and switches automatically.

---

## Phase 3: Dev Tools

### Why GitHub CLI (`gh`)?

- Authenticate once, push/pull via SSH everywhere.
- Create PRs, view issues, manage repos from the terminal.
- `gh ssh-key add` registers the server's key with GitHub in one command.

### Why generate an SSH key on the server?

Git operations over SSH are faster and don't require token management. The key is generated during setup and added to GitHub automatically via `gh`.

### Why these git aliases?

Selected from years of daily use:

- `cob`: Creates branches with your username prefix (`numanaral/feature-name`). Keeps branch ownership clear.
- `cleanlocal`: Prunes branches whose remote is gone. Keeps local repo clean.
- `pp`: Auto-detects `main` vs `master` and pulls. No more "which branch is default?"
- `view pr`: Opens the PR creation page in browser for the current branch.

---

## Phase 4: Languages

### Why pyenv for Python (not apt)?

System Python is for the OS. Pyenv lets you install any version without conflicting with system packages. `pyenv global 3.12` sets the default; projects can override with `.python-version`.

### Why nvm for Node (not apt)?

Same reasoning. Apt gives you one version. Nvm lets you switch per-project. The `.nvmrc` + `cdnvm` combo means you never think about it.

### Why Yarn?

Some projects use Yarn (lockfile compatibility). Installing it globally via npm means it's always available. Yarn Classic (v1) is used because it's the most widely compatible.

### Why no fallback Node version?

Nvm makes installing additional versions trivial (`nvm install 20`). Pre-installing a fallback adds complexity for a 5-second manual step.

---

## Phase 5: Media Tools

### Why all these tools?

This server runs backend processing for multiple projects:

| Tool | Purpose | Example use |
|------|---------|-------------|
| **FFmpeg** | Audio/video transcoding | Convert audio formats, extract audio from video |
| **ImageMagick** | Image manipulation | Resize, crop, convert image formats |
| **ExifTool** | Metadata read/write | Strip GPS data, read camera info |
| **Poppler** | PDF processing | Extract text/images from PDFs, render PDF pages |
| **LibreOffice** | Document conversion | PPTX/DOCX to PDF, headless batch conversion |
| **libvips** | Fast image processing | Thumbnail generation (10x faster than ImageMagick for resizing) |
| **Pandoc** | Format conversion | Markdown to HTML/PDF/DOCX |
| **wkhtmltopdf** | HTML to PDF | Render web pages to PDF with CSS support |

### Why LibreOffice Impress specifically?

Only the Impress component is installed (`libreoffice-impress`), not the full suite. This saves ~500MB of disk while still supporting PPTX conversion.

### Why install fonts?

LibreOffice needs fonts to render documents correctly. `fonts-crosextra-carlito` and `fonts-crosextra-caladea` are metric-compatible replacements for Calibri and Cambria (the most common fonts in Office documents).

---

## Phase 6: Headless Browser

### Why Playwright + Chromium?

Playwright is the modern standard for browser automation. It handles:

- Web scraping with JavaScript rendering.
- Screenshot/PDF generation of web pages.
- E2E testing of web applications.

Only Chromium is installed (not Firefox/WebKit) to save disk space. `--with-deps` installs all system libraries Chromium needs.

---

## Phase 7: Docker Extras

### Why Docker Compose plugin (not standalone)?

Docker Compose v2 is a Docker CLI plugin (`docker compose` instead of `docker-compose`). It's faster, maintained by Docker, and the standalone version is deprecated.

### Why lazydocker?

Terminal UI for Docker. See all containers, logs, stats, and images in one view. Much faster than typing `docker ps`, `docker logs`, `docker stats` repeatedly.

---

## Phase 8: Caddy

### Why Caddy over Nginx?

For this use case (personal server, few services, behind Cloudflare):

| | Caddy | Nginx |
|---|-------|-------|
| Config per service | 3 lines | 15-30 lines |
| Auto-HTTPS | Built-in | Requires certbot + cron |
| Reload on config change | `systemctl reload caddy` | Same, but config is more error-prone |
| Reverse proxy | One line | Server block + proxy_pass + headers |

Nginx wins for high-traffic production with complex routing, load balancing, or caching. For a personal tool server with 3-5 services, Caddy's simplicity is the right trade-off.

### Why `http://` in the Caddyfile?

Cloudflare proxy (orange cloud ON) terminates TLS at the edge. Traffic from Cloudflare to the origin arrives over HTTP. If Caddy tried to serve HTTPS, it would conflict with Cloudflare's certificate. Using `http://` tells Caddy to listen on port 80 only.

### Why redirect `server.numanaral.dev`?

The A record (`server -> IP`) exists so CNAMEs can point to it. But nobody should visit `server.numanaral.dev` directly -- it's infrastructure, not a service. Redirecting to `numanaral.dev` keeps things clean.

---

## Config Files

### `.zshrc`

Loads in order: pyenv -> nvm -> Oh My Zsh -> p10k -> aliases -> fzf. The `cdnvm` function overrides `cd` to auto-switch Node versions. Editor is `vim` on SSH, `code` locally.

### `.zsh_aliases`

Organized by category (Python, Docker, Git, Navigation, Shell, System). Only includes aliases that save real keystrokes on commands used daily. Pinterest/work-specific aliases are excluded.

### `.gitconfig.template`

Uses `{{GIT_NAME}}` and `{{GIT_EMAIL}}` placeholders. The `03-dev-tools.sh` script substitutes these during setup. Includes `gh auth git-credential` for seamless GitHub HTTPS auth.

### `.p10k.zsh`

Generated by `p10k configure` wizard. Rainbow style, powerline separators, 1-line compact prompt, 12h time, instant prompt off. Shows: directory, git status (left), exit code, execution time, background jobs, pyenv, nvm, context, time (right).

### `Caddyfile.template`

Uses `{{DOMAIN}}` placeholder. Only contains the server redirect block. Service-specific blocks (like `ppt.numanaral.dev`) are added during deployment, not in the generic template.

---

## Security Model

This is a **personal dev/tool server**, not a shared production environment. The security model reflects that:

- **SSH key-only auth**: No passwords, no root login.
- **UFW firewall**: Only SSH (22), HTTP (80), HTTPS (443) open.
- **Cloudflare proxy**: Real server IP hidden behind Cloudflare. DDoS protection included.
- **Passwordless sudo**: Convenience over ceremony for a single-user server.
- **Docker group**: User can run Docker without sudo. Acceptable risk for a personal server.

For a production or shared server, you'd want: fail2ban, separate deploy user, no passwordless sudo, Docker rootless mode, and network policies.
