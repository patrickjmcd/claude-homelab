#!/bin/bash
# =============================================================================
# Claude Homelab Uninstaller
# =============================================================================
# Removes symlinks from ~/.claude/ created by setup-symlinks.sh.
# Does NOT delete ~/.claude-homelab/.env (credentials) or the repo clone
# unless --purge is passed.
#
# Usage:
#   bash scripts/uninstall.sh           # remove symlinks only
#   bash scripts/uninstall.sh --purge   # also delete ~/.claude-homelab/ and ~/claude-homelab/
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PURGE=false
for arg in "$@"; do
    [[ "$arg" == "--purge" ]] && PURGE=true
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOMELAB_DIR="$HOME/.claude-homelab"

removed=0
skipped=0

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

remove_symlink() {
    local target="$1"
    if [[ -L "$target" ]]; then
        local points_to
        points_to="$(readlink -f "$target" 2>/dev/null || true)"
        # Only remove symlinks that point into this repo
        if [[ "$points_to" == "$REPO_ROOT"* ]]; then
            rm "$target"
            log_success "Removed: $target"
            ((removed++))
        else
            log_warn "Skipped (points elsewhere): $target → $points_to"
            ((skipped++))
        fi
    fi
}

echo ""
echo -e "${BLUE}=== Claude Homelab Uninstaller ===${NC}"
echo ""

# --- Skills ---
log_info "Removing skill symlinks..."
if [[ -d "$CLAUDE_DIR/skills" ]]; then
    while IFS= read -r -d '' link; do
        remove_symlink "$link"
    done < <(find "$CLAUDE_DIR/skills" -maxdepth 1 -type l -print0 2>/dev/null)
fi

# --- Agents ---
log_info "Removing agent symlinks..."
if [[ -d "$CLAUDE_DIR/agents" ]]; then
    while IFS= read -r -d '' link; do
        remove_symlink "$link"
    done < <(find "$CLAUDE_DIR/agents" -maxdepth 1 -type l -print0 2>/dev/null)
fi

# --- Commands ---
log_info "Removing command symlinks..."
if [[ -d "$CLAUDE_DIR/commands" ]]; then
    # Top-level .md symlinks
    while IFS= read -r -d '' link; do
        remove_symlink "$link"
    done < <(find "$CLAUDE_DIR/commands" -maxdepth 1 -type l -print0 2>/dev/null)
    # Namespaced directory symlinks (homelab/, notebooklm/, etc.)
    while IFS= read -r -d '' link; do
        remove_symlink "$link"
    done < <(find "$CLAUDE_DIR/commands" -maxdepth 1 -mindepth 1 -type l -print0 2>/dev/null)
fi

echo ""
log_success "Removed $removed symlink(s)${skipped:+, skipped $skipped (not from this repo)}"

# --- Purge ---
if [[ "$PURGE" == true ]]; then
    echo ""
    log_warn "--purge: deleting ~/.claude-homelab/ (including .env) and ~/claude-homelab/"
    echo -n "Are you sure? This deletes your credentials. [y/N] "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$HOMELAB_DIR"
        log_success "Deleted $HOMELAB_DIR"
        # Only delete the repo clone if it matches — don't rm a checkout the user pointed at
        if [[ "$REPO_ROOT" == "$HOME/claude-homelab" ]]; then
            rm -rf "$REPO_ROOT"
            log_success "Deleted $REPO_ROOT"
        else
            log_warn "Repo is at $REPO_ROOT (not ~/claude-homelab) — not deleted"
        fi
    else
        log_warn "Purge cancelled — credentials and repo left intact"
    fi
fi

echo ""
echo -e "${GREEN}Done.${NC} Restart Claude Code to deactivate the skills."
echo ""
