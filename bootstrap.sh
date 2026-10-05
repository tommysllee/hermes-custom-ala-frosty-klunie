#!/usr/bin/env bash
# ===========================================================================
#  ONE-COMMAND INSTALLER — Business AI Agent
#
#  Usage (single line, paste into terminal):
#
#    curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/bootstrap.sh | bash
#
#  This script:
#    1. Downloads the required files from the repository
#    2. Runs install.sh with full setup
#    3. Cleans up after itself
#
#  Options:
#    --test       dry run — checks only, changes nothing
#    --no-docker  skip Docker components
#
# ===========================================================================
set -uo pipefail

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main}"

# Colors (only when attached to a terminal)
if [ -t 1 ]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; NC=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; NC=""
fi

UPDATE_CACHE=(-H "Cache-Control: no-cache")

info()  { printf '  %s\n' "$*"; }
ok()    { printf '  %s\u2713%s %s\n' "$GREEN" "$NC" "$*"; }
warn()  { printf '  %s!\u2717 %s%s\n' "$RED" "$*" "$NC"; }
title() { printf '\n'; printf '  %s\u250c%s\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2510%s\n' "$BLUE" "$NC"; }
box()   { printf '  %s\u2502%s  %-57s%s%s\u2502%s\n' "$BLUE" "$NC" "$1" "$BLUE" "" "$NC"; }
bottom(){ printf '  %s\u2514\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2518%s\n' "$BLUE" "$NC"; }

# --- parse arguments -------------------------------------------------------
DRY_RUN=0
EXTRA_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --test|--tes) DRY_RUN=1; EXTRA_ARGS+=("--test") ;;
    *) EXTRA_ARGS+=("$arg") ;;
  esac
done

# --- prerequisite: curl or wget -------------------------------------------
if command -v curl >/dev/null 2>&1; then
  FETCH="curl -fsSL ${UPDATE_CACHE[*]}"
elif command -v wget >/dev/null 2>&1; then
  FETCH="wget -qO- --no-cache"
else
  echo "ERROR: curl or wget is required. Install one first:"
  echo "  sudo apt install curl   (Debian/Ubuntu)"
  echo "  sudo yum install curl   (RHEL/CentOS)"
  exit 1
fi

# --- header ----------------------------------------------------------------
clear 2>/dev/null || true
title
box "  ONE-COMMAND INSTALLER — Business AI Agent"
box ""
box "  This takes 15-30 minutes. Safe to leave unattended."
bottom
echo

# --- working directory -----------------------------------------------------
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/agent-install-XXXXXX")"
cleanup() {
  rm -rf "$WORK_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# --- files required for a complete install ---------------------------------
# NOTE: keep this list in sync with the files actually present in the repo.
FILES="install.sh installer.env bootstrap.sh scripts/extra-features.sh scripts/extra-features.sh docs/BACKUP.md docs/LINUX.md docs/TAILSCALE.md docs/DECOMPOSITION.md docs/PROMPT_FOR_AI_AGENT.md"

info "Downloading installer files..."
echo

FAILED=0
DOWNLOADED=0
for file in $FILES; do
  target="$WORK_DIR/$file"
  mkdir -p "$(dirname "$target")"
  if $FETCH "$REPO_RAW/$file" > "$target" 2>/dev/null && [ -s "$target" ]; then
    ok "  $file"
    DOWNLOADED=$((DOWNLOADED + 1))
  else
    warn "  $file — not available"
    FAILED=$((FAILED + 1))
    rm -f "$target"
  fi
done

echo
if [ "$FAILED" -gt 2 ]; then
  warn "Too many files failed to download ($FAILED)."
  info "Check your internet connection, then try again."
  exit 1
fi
ok "$DOWNLOADED files ready"
echo

# --- locate install.sh -----------------------------------------------------
INSTALLER="$WORK_DIR/install.sh"
if [ ! -f "$INSTALLER" ]; then
  warn "install.sh did not download — cannot continue."
  exit 1
fi
chmod +x "$INSTALLER"
[ -f "$WORK_DIR/scripts/extra-features.sh" ] && chmod +x "$WORK_DIR/scripts/extra-features.sh"
[ -f "$WORK_DIR/scripts/extra-features.sh" ] && chmod +x "$WORK_DIR/scripts/extra-features.sh"

# --- run the installer -----------------------------------------------------
if [ "$DRY_RUN" = "1" ]; then
  exec bash "$INSTALLER" --test
else
  bash "$INSTALLER" "${EXTRA_ARGS[@]:-}"
  STATUS=$?
  echo
  if [ "$STATUS" -eq 0 ]; then
    title
    box "  COMPLETE"
    bottom
    echo
    info "Follow the final steps shown above."
    info "If anything is unclear, contact your technician."
  else
    echo
    warn "The installer reported a problem (code $STATUS)."
    info "Take a screenshot of the messages above and send it"
    info "to your technician."
  fi
  echo
  exit "$STATUS"
fi
