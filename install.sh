#!/usr/bin/env bash
# =============================================================================
#  install.sh — Dotfile manager  (Hyprland + Wayland + zsh)
#
#  Commands:  bootstrap · install · update · rollback · status
#
#  bootstrap   Install base system (base-devel → yay → core pkgs)
#  install     Deploy configs (assumes bootstrap done or --install-packages)
#  update      Re-deploy only changed files
#  rollback    Restore last backed-up files
#  status      Show current install state
#
#  Idempotent · State-aware · Rollback-capable · Dry-run-ready
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ── Resolve script root (safe against symlinks) ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# ── Colors ────────────────────────────────────────────────────────────────────
C_RESET='\033[0m';    C_BOLD='\033[1m';      C_DIM='\033[2m'
C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_BLUE='\033[0;34m'
C_RED='\033[0;31m';   C_CYAN='\033[0;36m';   C_MAGENTA='\033[0;35m'

# ── Logging ───────────────────────────────────────────────────────────────────
info()    { echo -e "${C_BLUE}${C_BOLD}  =>${C_RESET} $*"; }
ok()      { echo -e "${C_GREEN}${C_BOLD}  ✓${C_RESET}  $*"; }
skip()    { echo -e "${C_DIM}  -  $*${C_RESET}"; }
warn()    { echo -e "${C_YELLOW}${C_BOLD}  !${C_RESET}  $*"; }
err()     { echo -e "${C_RED}${C_BOLD}  ✗${C_RESET}  $*" >&2; }
section() { echo -e "\n${C_CYAN}${C_BOLD}---  $*  ---${C_RESET}"; }
changed() { echo -e "${C_MAGENTA}${C_BOLD}  ~${C_RESET}  $*"; }
ask()     { echo -en "${C_YELLOW}${C_BOLD}  ?${C_RESET}  $*"; }

# =============================================================================
#  STATE  (single source of truth — all paths derived from STATE_DIR)
# =============================================================================
STATE_DIR="$HOME/.local/state/dotfiles"

_sf()           { echo "$STATE_DIR/$1"; }
state::init()   { mkdir -p "$STATE_DIR"; }
state::log()    { $FLAG_DRY_RUN && return; echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$(_sf changes.log)"; }
state::get()    { local f; f="$(_sf "$1")"; [[ -f "$f" ]] && cat "$f" || echo ""; }
state::set()    { $FLAG_DRY_RUN && return; echo "$2" > "$(_sf "$1")"; }
state::exists() { [[ -f "$(_sf "$1")" ]]; }
state::append() { $FLAG_DRY_RUN && return; echo "$2" >> "$(_sf "$1")"; }
state::clear()  { $FLAG_DRY_RUN && return; > "$(_sf "$1")"; }

state::set_lock() {
  $FLAG_DRY_RUN && return
  cat > "$(_sf install.lock)" <<EOF
installed_at=$(date '+%Y-%m-%d %H:%M:%S')
profile=$PROFILE
symlink=$FLAG_SYMLINK
script_dir=$SCRIPT_DIR
EOF
  state::log "LOCK set (profile=$PROFILE)"
}

# =============================================================================
#  FLAGS
# =============================================================================
FLAG_INSTALL_PKGS=false
FLAG_SYMLINK=false
FLAG_NO_BACKUP=true
FLAG_DRY_RUN=false
FLAG_FORCE=false
FLAG_YES=false
PROFILE="default"
COMMAND="auto"

# =============================================================================
#  CLI
# =============================================================================
usage() {
  cat <<EOF

Usage:  $(basename "$0") [COMMAND] [OPTIONS]

Commands:
  (none)              Full auto: bootstrap + install (recommended for new users)
  bootstrap           Install base system from scratch (base-devel -> yay -> core)
  install             Deploy dotfiles
  update              Re-deploy only changed files
  rollback            Restore last backed-up files
  status              Show current install state

Options:
  --install-packages  Install packages via yay/pacman
  --symlink           Use symlinks instead of copies for configs
  --no-backup         Skip backup (overwrite directly)
  --dry-run           Show what would be done, do nothing
  --force             Ignore install lock, re-run fully
  --yes               Non-interactive mode
  --profile NAME      Use a named profile (default: "default")
  -h, --help          This message

Quick start (just clone and run):
  git clone https://github.com/YOUR_USER/dotfiles-hyprland.git
  cd dotfiles-hyprland && ./install.sh

EOF
  exit 0
}

for arg in "$@"; do
  case "$arg" in
    bootstrap|install|update|rollback|status|auto) COMMAND="$arg" ;;
    --install-packages) FLAG_INSTALL_PKGS=true ;;
    --symlink)          FLAG_SYMLINK=true ;;
    --no-backup)        FLAG_NO_BACKUP=true ;;
    --dry-run)          FLAG_DRY_RUN=true ;;
    --force)            FLAG_FORCE=true ;;
    --yes)              FLAG_YES=true ;;
    --profile=*)        PROFILE="${arg#--profile=}" ;;
    -h|--help)          usage ;;
    *) err "Unknown argument: $arg"; usage ;;
  esac
done

# ── Dry-run wrapper ───────────────────────────────────────────────────────────
run() {
  if $FLAG_DRY_RUN; then
    local IFS=' '
    echo -e "${C_DIM}     [dry] $*${C_RESET}"
    return 0
  else
    "$@"
  fi
}

# ── Interactive confirm (respects --yes and --dry-run) ────────────────────────
confirm() {
  $FLAG_DRY_RUN && return 0
  $FLAG_YES     && return 0
  ask "$1 [y/N] "; read -r reply; echo
  [[ "$reply" =~ ^[Yy]$ ]]
}

# =============================================================================
#  PACKAGE MANAGER ABSTRACTION
# =============================================================================
PKG_MANAGER="none"

_detect_pkg_manager() {
  command -v yay    &>/dev/null && PKG_MANAGER="yay"    && return
  command -v pacman &>/dev/null && PKG_MANAGER="pacman" && return
  PKG_MANAGER="none"
}

is_pkg_installed() {
  if command -v pacman &>/dev/null; then
    pacman -Qq "$1" &>/dev/null
  else
    command -v "$1" &>/dev/null
  fi
}

pkg_install() {
  local to_install=()
  for pkg in "$@"; do
    is_pkg_installed "$pkg" && skip "$pkg (installed)" || to_install+=("$pkg")
  done
  [[ ${#to_install[@]} -eq 0 ]] && return 0

  info "Installing: ${to_install[*]}"
  case "$PKG_MANAGER" in
    yay)    run yay    -S --needed --noconfirm "${to_install[@]}" ;;
    pacman) run sudo pacman -S --needed --noconfirm "${to_install[@]}" ;;
    none)   err "No package manager available."; return 1 ;;
  esac
  ok "${#to_install[@]} packages installed."
  state::log "PKGS installed: ${to_install[*]}"
}

# =============================================================================
#  DEPLOY HELPERS
# =============================================================================
safe_backup() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0

  if ! $FLAG_NO_BACKUP; then
    local bak="${target}.bak"
    [[ -e "$bak" ]] && rm -rf "$bak"
    run mv "$target" "$bak"
    state::append "backup.index" "$target|$bak"
    warn "Backed up: $(basename "$target") -> $bak"
  else
    run rm -rf "$target"
    skip "Removed (--no-backup): $target"
  fi
}

deploy_entry() {
  local src="$1" dst="$2"
  if [[ ! -e "$src" ]]; then warn "Not found, skipping: $src"; return 1; fi

  if ! $FLAG_FORCE && ! $FLAG_SYMLINK; then
    if [[ -e "$dst" ]] && diff -rq --no-dereference "$src" "$dst" &>/dev/null; then
      skip "Unchanged: $(basename "$dst")"; return 0
    fi
  fi

  safe_backup "$dst"

  if $FLAG_SYMLINK; then
    run ln -sf "$src" "$dst"; changed "Symlinked: $dst"
  else
    run cp -r "$src" "$dst"; changed "Copied:    $dst"
  fi
  state::log "DEPLOY $dst (symlink=$FLAG_SYMLINK)"
}

# =============================================================================
#  REQUIRED BINARIES CHECK
# =============================================================================
REQUIRED_BINS=(
  git hyprctl hyprpaper hypridle
  foot waybar mako btop
  thunar nwg-look
)

check_required_bins() {
  section "Runtime validation"
  local missing=()
  for bin in "${REQUIRED_BINS[@]}"; do
    command -v "$bin" &>/dev/null && skip "$bin" || { warn "Missing: $bin"; missing+=("$bin"); }
  done
  [[ ${#missing[@]} -gt 0 ]] \
    && warn "${#missing[@]} missing — run: $(basename "$0") bootstrap" \
    || ok "All required binaries present."
}

# =============================================================================
#  COMMAND: bootstrap
#  Goal: raw Arch install → yay → packages → icons → theme → zsh
# =============================================================================
cmd_bootstrap() {
  section "Bootstrap — Arch base -> yay -> packages"

  ! command -v pacman &>/dev/null && { err "pacman not found. Arch only."; exit 1; }
  [[ "$EUID" -eq 0 ]]             && { err "Do not run as root. sudo is used internally."; exit 1; }
  sudo -v &>/dev/null             || { err "sudo not available or credentials failed."; exit 1; }
  ok "sudo access confirmed."

  if state::exists "bootstrap.done" && ! $FLAG_FORCE; then
    warn "Bootstrap already done: $(state::get 'bootstrap.done')"
    warn "Use --force to re-run."; return 0
  fi

  # ── B1: base-devel + git via pacman ────────────────────────────────────────
  section "B1 · base-devel + git"
  _detect_pkg_manager

  local BASE_DEPS=(base-devel git curl wget)
  local missing_base=()
  for pkg in "${BASE_DEPS[@]}"; do
    is_pkg_installed "$pkg" && skip "$pkg" || missing_base+=("$pkg")
  done

  if [[ ${#missing_base[@]} -gt 0 ]]; then
    info "pacman: installing ${missing_base[*]}"
    run sudo pacman -S --needed --noconfirm "${missing_base[@]}"
    ok "Base dependencies installed."
  else
    ok "Base dependencies already present."
  fi

  # ── B2: yay from AUR ──────────────────────────────────────────────────────
  section "B2 · yay (AUR helper)"

  if command -v yay &>/dev/null && ! $FLAG_FORCE; then
    skip "yay already installed."
  else
    info "Cloning and building yay-bin from AUR..."
    local tmp_dir; tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT
    run git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin"
    if ! $FLAG_DRY_RUN; then
      (cd "$tmp_dir/yay-bin" && makepkg -si --noconfirm)
    fi
    trap - EXIT
    run rm -rf "$tmp_dir"
    ok "yay installed."
    state::log "BOOTSTRAP yay installed"
  fi
  PKG_MANAGER="yay"

  # ── B3: core packages via yay ──────────────────────────────────────────────
  section "B3 · Core packages"

  pkg_install \
    git curl wget xdg-utils xdg-user-dirs \
    zsh zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search \
    hyprland hyprpaper hypridle hyprcursor hyprshot hyprlauncher hyprtoolkit \
    foot waybar mako btop \
    thunar xfconf \
    nwg-look \
    ttf-jetbrains-mono-nerd \
    noto-fonts noto-fonts-emoji \
    ttf-liberation \
    zen-browser \
    qogir-cursor-theme

  if command -v fc-cache &>/dev/null; then
    run fc-cache -fv &>/dev/null
    ok "Font cache rebuilt."
  fi

  # ── B4: yet-another-monochrome icon set ───────────────────────────────────
  section "B4 · Icon set (yet-another-monochrome)"

  local ICONS_DEST="$HOME/.local/share/icons/yet-another-monochrome-icon-set"

  if [[ -d "$ICONS_DEST" ]] && ! $FLAG_FORCE; then
    skip "Icons already installed at $ICONS_DEST"
  else
    info "Cloning yet-another-monochrome-icon-set..."
    local tmp_icons; tmp_icons="$(mktemp -d)"
    trap 'rm -rf "$tmp_icons"' EXIT
    run git clone --depth=1 https://bitbucket.org/dirn-typo/yet-another-monochrome-icon-set.git "$tmp_icons/yamis"
    if ! $FLAG_DRY_RUN; then
      [[ -d "$ICONS_DEST" ]] && rm -rf "$ICONS_DEST"
      mkdir -p "$ICONS_DEST"
      cp -r "$tmp_icons/yamis/." "$ICONS_DEST/"
      rm -rf "$ICONS_DEST/.git"
    fi
    trap - EXIT
    run rm -rf "$tmp_icons"
    ok "Icons installed -> $ICONS_DEST"
    state::log "BOOTSTRAP icons installed"
  fi

  # ── B5: Reversal-Dark GTK theme ───────────────────────────────────────────
  section "B5 · GTK theme (Reversal-Dark)"

  local THEME_DEST="$HOME/.local/share/themes/Reversal-Dark"

  if [[ -d "$THEME_DEST" ]] && ! $FLAG_FORCE; then
    skip "Theme already installed at $THEME_DEST"
  else
    info "Cloning and installing Reversal-gtk-theme..."
    local tmp_theme; tmp_theme="$(mktemp -d)"
    trap 'rm -rf "$tmp_theme"' EXIT
    run git clone --depth=1 https://github.com/yeyushengfan258/Reversal-gtk-theme.git "$tmp_theme/reversal"
    if ! $FLAG_DRY_RUN; then
      bash "$tmp_theme/reversal/install.sh" -d "$HOME/.local/share/themes" -t default
    fi
    trap - EXIT
    run rm -rf "$tmp_theme"
    ok "Theme installed -> $THEME_DEST"
    state::log "BOOTSTRAP theme installed"
  fi

  # ── B6: XDG user directories ───────────────────────────────────────────────
  section "B6 · XDG user directories"

  if command -v xdg-user-dirs-update &>/dev/null; then
    run xdg-user-dirs-update
    ok "XDG user directories created."
  else
    warn "xdg-user-dirs not found — skipping."
  fi

  # ── B7: zsh as default shell ───────────────────────────────────────────────
  section "B7 · Default shell -> zsh"

  if command -v zsh &>/dev/null; then
    local zsh_bin; zsh_bin="$(command -v zsh)"

    if ! grep -qF "$zsh_bin" /etc/shells 2>/dev/null; then
      info "Adding zsh to /etc/shells..."
      run bash -c "echo '$zsh_bin' | sudo tee -a /etc/shells > /dev/null"
    fi

    local current_shell; current_shell="$(getent passwd "$USER" | cut -d: -f7)"
    if [[ "$current_shell" != "$zsh_bin" ]]; then
      run chsh -s "$zsh_bin" "$USER"
      ok "Default shell -> zsh (re-login required)"
      state::log "SHELL changed to zsh"
    else
      skip "Shell already zsh."
    fi
  else
    warn "zsh not found — skipping shell change."
  fi

  # ── B8: git configuration (optional) ──────────────────────────────────────
  section "B8 · git configuration (optional)"

  local cur_name;  cur_name="$(git  config --global user.name  2>/dev/null || true)"
  local cur_email; cur_email="$(git config --global user.email 2>/dev/null || true)"

  if [[ -n "$cur_name" && -n "$cur_email" ]]; then
    skip "git identity already set: $cur_name <$cur_email>"
  elif $FLAG_YES; then
    warn "git identity not configured (optional). Set it later with:"
    warn "  git config --global user.name  'Your Name'"
    warn "  git config --global user.email 'your@email.com'"
  else
    info "git identity is not set. This is optional — press Enter to skip."
    local git_name="" git_email=""

    ask "git user.name  [Enter to skip]: "; read -r git_name
    ask "git user.email [Enter to skip]: "; read -r git_email

    if [[ -n "$git_name" || -n "$git_email" ]]; then
      [[ -n "$git_name"  ]] && run git config --global user.name  "$git_name"
      [[ -n "$git_email" ]] && run git config --global user.email "$git_email"
      run git config --global init.defaultBranch main
      run git config --global pull.rebase false
      run git config --global core.autocrlf input
      ok "git identity configured."
      state::log "GIT identity set: ${git_name:-<skip>} <${git_email:-<skip>}>"
      state::set "git.configured" "$(date '+%Y-%m-%d %H:%M:%S')"
    else
      skip "git identity skipped — configure manually later if needed."
    fi
  fi

  state::set "bootstrap.done" "$(date '+%Y-%m-%d %H:%M:%S')"
  state::log "BOOTSTRAP complete"

  echo ""
  ok "Bootstrap complete."
  echo ""
  echo -e "  ${C_BOLD}Next:${C_RESET}  $(basename "$0") install --install-packages"
  echo ""
}

# =============================================================================
#  COMMAND: status
# =============================================================================
cmd_status() {
  section "Dotfile Status"
  echo ""

  local lock; lock="$(_sf install.lock)"
  if [[ -f "$lock" ]]; then
    ok "Installed"
    while IFS='=' read -r key val; do
      printf "  ${C_BOLD}%-20s${C_RESET} %s\n" "$key" "$val"
    done < "$lock"
  else
    warn "Not installed (no lock file)"
  fi

  echo ""
  state::exists "bootstrap.done" \
    && ok   "Bootstrap done : $(state::get 'bootstrap.done')" \
    || warn "Bootstrap not done — run: $(basename "$0") bootstrap"

  echo ""
  state::exists "profile.current"   && info "Profile   : $(state::get 'profile.current')"
  state::exists "wallpaper.current" && info "Wallpaper : $(state::get 'wallpaper.current')"
  state::exists "git.configured"    && info "Git setup : $(state::get 'git.configured')"

  echo ""
  local bak; bak="$(_sf backup.index)"
  if [[ -f "$bak" ]]; then
    local n; n=$(wc -l < "$bak")
    [[ $n -gt 0 ]] \
      && info "Backups: $n entries  (run 'rollback' to restore)" \
      || skip "Backup index empty"
  else
    skip "No backup index"
  fi

  echo ""
  local log; log="$(_sf changes.log)"
  if [[ -f "$log" ]]; then
    info "Last 5 log entries:"
    tail -n5 "$log" | while read -r line; do
      echo -e "  ${C_DIM}$line${C_RESET}"
    done
  fi
  echo ""
}

# =============================================================================
#  COMMAND: rollback
# =============================================================================
cmd_rollback() {
  section "Rollback"

  local bak; bak="$(_sf backup.index)"
  [[ -f "$bak" ]] || { err "No backup index — nothing to rollback."; exit 1; }

  local n; n=$(wc -l < "$bak")
  [[ $n -eq 0 ]] && { warn "Backup index is empty."; exit 0; }

  confirm "Restore $n backed-up entries?" || { info "Aborted."; exit 0; }

  while IFS='|' read -r original backup; do
    if [[ -e "$backup" ]]; then
      [[ -e "$original" || -L "$original" ]] && run rm -rf "$original"
      run mv "$backup" "$original"
      ok "Restored: $original"
      state::log "ROLLBACK $original <- $backup"
    else
      warn "Backup missing, skipping: $backup"
    fi
  done < "$bak"

  run rm -f "$bak" "$(_sf install.lock)"
  state::log "ROLLBACK complete — lock removed"
  echo ""
  ok "Rollback complete. Log out and back in."
}

# =============================================================================
#  CORE DEPLOY  (shared by install + update)
# =============================================================================
run_deploy() {

  # ── 0 · Repo guard ────────────────────────────────────────────────────────
  section "0 · Repo check"
  if [[ ! -d "$SCRIPT_DIR/.config" ]]; then
    err "SCRIPT_DIR/.config not found. Run from the dotfiles repo root."
    err "SCRIPT_DIR=$SCRIPT_DIR"; exit 1
  fi
  ok "Repo valid: $SCRIPT_DIR"

  # ── 1 · Environment ───────────────────────────────────────────────────────
  section "1 · Environment"
  local OS_ID=""; [[ -f /etc/os-release ]] && OS_ID="$(. /etc/os-release && echo "$ID")"
  _detect_pkg_manager

  info "Distro       : ${OS_ID:-unknown}"
  info "Pkg manager  : $PKG_MANAGER"
  info "Session      : ${XDG_SESSION_TYPE:-tty}"
  info "Shell        : $(basename "$SHELL")"
  info "Profile      : $PROFILE"
  info "Symlink mode : $FLAG_SYMLINK"
  info "Dry-run      : $FLAG_DRY_RUN"

  if [[ "$OS_ID" != "arch" && "$OS_ID" != "manjaro" && \
        "$OS_ID" != "endeavouros" && "$OS_ID" != "cachyos" ]]; then
    warn "Distro '$OS_ID' is not Arch-based — package install disabled."
    FLAG_INSTALL_PKGS=false
  fi

  # ── 2 · Directories ───────────────────────────────────────────────────────
  section "2 · Directories"
  local DIRS=(
    "$HOME/.config"
    "$HOME/.local/bin"
    "$HOME/.local/share/icons"
    "$HOME/.local/share/themes"
    "$HOME/Pictures/Wallpapers"
    "$HOME/.cache"
    "$STATE_DIR"
  )
  for d in "${DIRS[@]}"; do
    [[ -d "$d" ]] && skip "$d" || { run mkdir -p "$d"; ok "Created: $d"; }
  done

  # ── 3 · Packages ──────────────────────────────────────────────────────────
  section "3 · Packages"
  if $FLAG_INSTALL_PKGS; then
    [[ "$PKG_MANAGER" == "none" ]] && { err "No package manager. Run bootstrap first."; } || \
    pkg_install \
      git curl wget xdg-utils xdg-user-dirs \
      zsh zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search \
      hyprland hyprpaper hypridle hyprcursor hyprshot hyprlauncher hyprtoolkit \
      foot waybar mako btop \
      thunar xfconf \
      nwg-look \
      ttf-jetbrains-mono-nerd \
      noto-fonts noto-fonts-emoji ttf-liberation \
      zen-browser qogir-cursor-theme
  else
    warn "Skipping packages (--install-packages not set)"
  fi

  # ── 4 · Configs ───────────────────────────────────────────────────────────
  section "4 · Configs"
  local base_cfg="$SCRIPT_DIR/.config"
  local profile_cfg="$SCRIPT_DIR/profiles/$PROFILE/.config"
  local -a CONFIG_APPS=(
    btop foot
    gtk-3.0 gtk-4.0
    hypr mako
    nwg-look Thunar
    waybar xfce4 xsettingsd zed
  )

  for app in "${CONFIG_APPS[@]}"; do
    local src="$base_cfg/$app"
    [[ -d "$profile_cfg/$app" ]] && src="$profile_cfg/$app" && info "Profile overlay: $app"
    [[ -d "$src" ]] && deploy_entry "$src" "$HOME/.config/$app"
  done

  # user-dirs.dirs (arquivo na raiz de .config, nao em subpasta)
  if [[ -f "$base_cfg/user-dirs.dirs" ]]; then
    deploy_entry "$base_cfg/user-dirs.dirs" "$HOME/.config/user-dirs.dirs"
  fi

  # ── 4a · Home dotfiles (.zshrc, .gtkrc-2.0) ──────────────────────────────
  section "4a · Home dotfiles"

  local -a HOME_DOTFILES=(.zshrc .gtkrc-2.0)
  for df in "${HOME_DOTFILES[@]}"; do
    local src="$SCRIPT_DIR/$df"
    [[ -f "$src" ]] && deploy_entry "$src" "$HOME/$df" || skip "$df not found in repo."
  done

  # ── 5 · Wallpapers ────────────────────────────────────────────────────────
  section "5 · Wallpapers"
  local WALL_SRC="$SCRIPT_DIR/Wallpapers"
  local WALL_DST="$HOME/Pictures/Wallpapers"

  if [[ -d "$WALL_SRC" ]]; then
    run mkdir -p "$WALL_DST"

    if command -v rsync &>/dev/null; then
      run rsync -rlpt "$WALL_SRC/" "$WALL_DST/"
    else
      find "$WALL_SRC" -maxdepth 1 -type f | while read -r wfile; do
        run cp "$wfile" "$WALL_DST/"
      done
    fi

    run chmod -R u+rw,go+r "$WALL_DST"

    local wall_count; wall_count="$(find "$WALL_DST" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' \) | wc -l)"
    local first_wall; first_wall="$(find "$WALL_DST" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' \) | shuf | head -n1)"

    if [[ -n "$first_wall" ]]; then
      local wall_name; wall_name="$(basename "$first_wall")"
      ok "Wallpaper -> $wall_name"
      info "$wall_count wallpaper(s) available in $WALL_DST"
      state::set "wallpaper.current" "$first_wall"

      # Apply via hyprpaper if running
      local hyprpaper_conf="$HOME/.config/hypr/hyprpaper.conf"
      if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null 2>&1; then
        if [[ -f "$hyprpaper_conf" ]]; then
          info "hyprpaper detected — update hyprpaper.conf to apply wallpaper."
        fi
      else
        skip "Hyprland not running — wallpaper will be applied on next login."
      fi
    else
      warn "No wallpapers (.png/.jpg) found in $WALL_DST."
    fi

    ok "Wallpapers synced -> $WALL_DST"
  else
    warn "No Wallpapers/ directory in repo — skipping."
  fi

  # ── 6 · Scripts -> ~/.local/bin ───────────────────────────────────────────
  section "6 · Scripts"
  local BIN_SRC="$SCRIPT_DIR/.local/bin"
  if [[ -d "$BIN_SRC" ]]; then
    local n=0
    for script in "$BIN_SRC"/*; do
      [[ -f "$script" ]] || continue
      local sname; sname="$(basename "$script")"
      local dst="$HOME/.local/bin/$sname"
      if $FLAG_SYMLINK; then
        run ln -sf "$script" "$dst"; changed "$sname"
      else
        if ! $FLAG_FORCE && [[ -f "$dst" ]] && cmp -s "$script" "$dst"; then
          skip "$sname (unchanged)"; continue
        fi
        safe_backup "$dst"; run cp "$script" "$dst"; changed "$sname"
      fi
      run chmod +x "$dst"; (( n++ )) || true
    done
    [[ $n -gt 0 ]] && ok "Scripts deployed: $n" && state::log "SCRIPTS deployed: $n"
  else
    skip "No .local/bin/ directory — skipping."
  fi

  # ── 7 · Themes ────────────────────────────────────────────────────────────
  section "7 · Themes"

  local THEME="Reversal-Dark"
  local ICONS="yet-another-monochrome-icon-set"
  local CURSOR="qogir-white-cursors"
  # local FONT="JetBrainsMono Nerd Font 11"

  # GTK 3 settings.ini
  local gtk3_settings="$HOME/.config/gtk-3.0/settings.ini"
  if [[ -f "$gtk3_settings" ]]; then
    run sed -i \
      -e "s|^gtk-theme-name=.*|gtk-theme-name=$THEME|" \
      -e "s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=$ICONS|" \
      -e "s|^gtk-cursor-theme-name=.*|gtk-cursor-theme-name=$CURSOR|" \
      # -e "s|^gtk-font-name=.*|gtk-font-name=$FONT|" \
      "$gtk3_settings"
    ok "gtk-3.0/settings.ini updated."
  else
    $FLAG_DRY_RUN || {
      mkdir -p "$(dirname "$gtk3_settings")"
      cat > "$gtk3_settings" <<EOF
[Settings]
gtk-theme-name=$THEME
gtk-icon-theme-name=$ICONS
gtk-cursor-theme-name=$CURSOR
# gtk-font-name=$FONT
gtk-application-prefer-dark-theme=1
EOF
    }
    ok "gtk-3.0/settings.ini written."
  fi

  # GTK 4 settings.ini
  local gtk4_settings="$HOME/.config/gtk-4.0/settings.ini"
  if [[ -f "$gtk4_settings" ]]; then
    run sed -i \
      -e "s|^gtk-theme-name=.*|gtk-theme-name=$THEME|" \
      -e "s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=$ICONS|" \
      -e "s|^gtk-cursor-theme-name=.*|gtk-cursor-theme-name=$CURSOR|" \
      # -e "s|^gtk-font-name=.*|gtk-font-name=$FONT|" \
      "$gtk4_settings"
    ok "gtk-4.0/settings.ini updated."
  else
    $FLAG_DRY_RUN || {
      mkdir -p "$(dirname "$gtk4_settings")"
      cat > "$gtk4_settings" <<EOF
[Settings]
gtk-theme-name=$THEME
gtk-icon-theme-name=$ICONS
gtk-cursor-theme-name=$CURSOR
# gtk-font-name=$FONT
gtk-application-prefer-dark-theme=1
EOF
    }
    ok "gtk-4.0/settings.ini written."
  fi

  # GTK 4 assets symlinks (Reversal provides them)
  local reversal_gtk4="$HOME/.local/share/themes/$THEME/gtk-4.0"
  if [[ -d "$reversal_gtk4" ]]; then
    run ln -sf "$reversal_gtk4/assets"       "$HOME/.config/gtk-4.0/assets"
    run ln -sf "$reversal_gtk4/gtk.css"      "$HOME/.config/gtk-4.0/gtk.css"
    run ln -sf "$reversal_gtk4/gtk-dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
    ok "GTK 4 assets symlinked from $THEME."
  else
    warn "Reversal gtk-4.0 not found at $reversal_gtk4 — run bootstrap first."
  fi

  # gsettings (dconf)
  if command -v gsettings &>/dev/null; then
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
      local current_user="${SUDO_USER:-$USER}"
      local user_bus; user_bus="$(ls "/run/user/$(id -u "$current_user")/bus" 2>/dev/null || true)"
      [[ -n "$user_bus" ]] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$user_bus"
    fi

    if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
      if ! $FLAG_DRY_RUN; then
        gsettings set org.gnome.desktop.interface gtk-theme    "$THEME"      2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme   "$ICONS"      2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR"     2>/dev/null || true
        # gsettings set org.gnome.desktop.interface font-name    "$FONT"       2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
      else
        echo -e "\033[2m     [dry] gsettings set gtk-theme=$THEME | icon-theme=$ICONS | cursor-theme=$CURSOR\033[0m"
      fi
      ok "gsettings: GTK=$THEME | Icons=$ICONS | Cursor=$CURSOR"
    else
      warn "D-Bus session not found — gsettings skipped."
      warn "Run manually after login:"
      warn "  gsettings set org.gnome.desktop.interface gtk-theme '$THEME'"
    fi
  fi

  # xsettingsd.conf
  local xset_conf="$HOME/.config/xsettingsd/xsettingsd.conf"
  if [[ -f "$xset_conf" ]]; then
    run sed -i \
      -e "s|^Net/ThemeName .*|Net/ThemeName \"$THEME\"|" \
      -e "s|^Net/IconThemeName .*|Net/IconThemeName \"$ICONS\"|" \
      -e "s|^Gtk/CursorThemeName .*|Gtk/CursorThemeName \"$CURSOR\"|" \
      "$xset_conf"
    ok "xsettingsd.conf updated."
    if pkill -HUP xsettingsd 2>/dev/null; then
      ok "xsettingsd reloaded — cursor/icons applied live."
    else
      skip "xsettingsd not running — will apply on next login."
    fi
  fi

  # .gtkrc-2.0
  local gtkrc2="$HOME/.gtkrc-2.0"
  if [[ -f "$gtkrc2" ]]; then
    run sed -i \
      -e "s|^gtk-theme-name=.*|gtk-theme-name=\"$THEME\"|" \
      -e "s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=\"$ICONS\"|" \
      -e "s|^gtk-cursor-theme-name=.*|gtk-cursor-theme-name=\"$CURSOR\"|" \
      "$gtkrc2"
    ok ".gtkrc-2.0 updated."
  fi

  # Xcursor default (XWayland)
  local xcursor_dst="$HOME/.local/share/icons/default"
  run mkdir -p "$xcursor_dst"
  $FLAG_DRY_RUN || cat > "$xcursor_dst/index.theme" <<XCURSOR
[Icon Theme]
Name=Default
Comment=Default cursor
Inherits=$CURSOR
XCURSOR
  ok "Xcursor default -> $CURSOR"

  # Hyprland cursor env vars
  local hyprland_conf="$HOME/.config/hypr/hyprland.conf"
  if [[ -f "$hyprland_conf" ]]; then
    if ! grep -q "XCURSOR_THEME" "$hyprland_conf"; then
      $FLAG_DRY_RUN || {
        echo "" >> "$hyprland_conf"
        echo "env = XCURSOR_THEME,$CURSOR" >> "$hyprland_conf"
        echo "env = XCURSOR_SIZE,24"       >> "$hyprland_conf"
      }
      ok "XCURSOR_THEME added to hyprland.conf."
    else
      skip "XCURSOR_THEME already present in hyprland.conf."
    fi
  fi

  state::log "THEMES applied: GTK=$THEME ICONS=$ICONS CURSOR=$CURSOR"

  # ── 8 · Validation ────────────────────────────────────────────────────────
  check_required_bins

  # ── Persist state ──────────────────────────────────────────────────────────
  state::set "profile.current" "$PROFILE"
  state::set_lock
}

# =============================================================================
#  COMMAND: install
# =============================================================================
cmd_install() {
  section "Install — profile: $PROFILE"

  if state::exists "install.lock" && ! $FLAG_FORCE; then
    warn "Already installed. Use 'update' to sync, or --force to re-run."
    exit 0
  fi

  state::clear "backup.index"
  run_deploy

  section "Done"
  echo ""
  printf "  ${C_BOLD}%-16s${C_RESET} %s\n" "Config"  "$HOME/.config"
  printf "  ${C_BOLD}%-16s${C_RESET} %s\n" "Profile" "$PROFILE"
  printf "  ${C_BOLD}%-16s${C_RESET} %s\n" "Deploy"  "$(if $FLAG_SYMLINK; then echo 'symlinks'; else echo 'copies'; fi)"
  printf "  ${C_BOLD}%-16s${C_RESET} %s\n" "Log"     "$(_sf changes.log)"
  echo ""
  echo -e "  ${C_BOLD}Next steps:${C_RESET}"
  echo -e "  ${C_DIM}1. Log out and back in (shell + session changes)${C_RESET}"
  echo -e "  ${C_DIM}2. Start Hyprland -> check waybar, mako, foot${C_RESET}"
  echo -e "  ${C_DIM}3. $(basename "$0") status — inspect state anytime${C_RESET}"
  echo ""
  echo -e "${C_YELLOW}${C_BOLD}  ! Note${C_RESET}"
  echo -e "  ${C_DIM}Cursor and icons may not apply 100% on the first login.${C_RESET}"
  echo -e "  ${C_DIM}If that happens, re-run after logging into Hyprland:${C_RESET}"
  echo -e ""
  echo -e "      ${C_CYAN}${C_BOLD}./install.sh update${C_RESET}"
  echo ""
}

# =============================================================================
#  COMMAND: auto  (default — full install for new users)
# =============================================================================
cmd_auto() {
  section "Auto — bootstrap + install (full setup)"

  ! command -v pacman &>/dev/null && { err "pacman not found. Arch-based distro only."; exit 1; }
  [[ "$EUID" -eq 0 ]]             && { err "Do not run as root. sudo is used internally."; exit 1; }

  echo ""
  echo -e "  ${C_BOLD}This will:${C_RESET}"
  echo -e "  ${C_DIM}1. Install yay (AUR helper) if needed${C_RESET}"
  echo -e "  ${C_DIM}2. Install all required packages${C_RESET}"
  echo -e "  ${C_DIM}3. Install icons and GTK theme${C_RESET}"
  echo -e "  ${C_DIM}4. Set zsh as default shell${C_RESET}"
  echo -e "  ${C_DIM}5. Deploy all configs, themes and wallpapers${C_RESET}"
  echo ""

  confirm "Proceed with full setup?" || { info "Aborted."; exit 0; }

  cmd_bootstrap || warn "Bootstrap completed with warnings — continuing with install..."

  FLAG_INSTALL_PKGS=true
  cmd_install
}

# =============================================================================
#  COMMAND: update
# =============================================================================
cmd_update() {
  section "Update — profile: $PROFILE"
  FLAG_FORCE=true
  run_deploy
  echo ""; ok "Update complete."; echo ""
}

# =============================================================================
#  ENTRYPOINT
# =============================================================================
state::init

[[ "$COMMAND" == "bootstrap" && "$EUID" -eq 0 ]] && { err "Do not run as root."; exit 1; }

case "$COMMAND" in
  auto)      cmd_auto ;;
  bootstrap) cmd_bootstrap ;;
  install)   cmd_install ;;
  update)    cmd_update ;;
  rollback)  cmd_rollback ;;
  status)    cmd_status ;;
  *)         err "Unknown command: $COMMAND"; usage ;;
esac
