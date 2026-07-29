#!/usr/bin/env bash
# install.sh — Install claude-team-cli profiles and CLI
# Usage: bash install.sh
#
# What this does:
#   1. Copies team member profiles to ~/.claude/team/
#   2. Installs the claude-team CLI to ~/.local/bin/
#   3. Checks that ~/.local/bin is on your PATH
#   4. Optionally enables the coordinator (proactive team check-ins)

set -euo pipefail

# Bash 4+ required. macOS ships Bash 3.2 at /bin/bash for licensing reasons;
# a current Bash is one 'brew install bash' away.
if [[ -z "${BASH_VERSINFO:-}" ]] || (( BASH_VERSINFO[0] < 4 )); then
  echo "error: install.sh requires Bash 4 or newer (this is ${BASH_VERSION:-not bash})." >&2
  echo "macOS ships Bash 3.2; install a current Bash with: brew install bash" >&2
  echo "Then run: bash install.sh" >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_SRC="$REPO_DIR/profiles"
PROFILES_DST="$HOME/.claude/team"
COMMANDS_SRC="$REPO_DIR/commands"
COMMANDS_DST="$HOME/.claude/commands"
BIN_SRC="$REPO_DIR/bin/claude-team"
BIN_DST="$HOME/.local/bin/claude-team"
BRANCHES_INDEX="$HOME/.claude/branches/INDEX.md"
WORKTREES_ROOT="$HOME/.claude/worktrees"

bold()  { printf '\033[1m%s\033[0m' "$*"; }
green() { printf '\033[32m%s\033[0m' "$*"; }
yellow(){ printf '\033[33m%s\033[0m' "$*"; }
dim()   { printf '\033[2m%s\033[0m' "$*"; }

echo ""
echo "$(bold "claude-team-cli installer")"
echo "────────────────────────────────────"
echo ""

# 1. Install profiles (+ model tiers)
echo "Installing profiles to $PROFILES_DST ..."
mkdir -p "$PROFILES_DST"
cp "$PROFILES_SRC"/*.md "$PROFILES_DST/"
if [[ -f "$PROFILES_SRC/tiers.conf" ]]; then cp "$PROFILES_SRC/tiers.conf" "$PROFILES_DST/"; fi
echo "$(green "✓") Profiles installed:"
for f in "$PROFILES_DST"/*.md; do
  echo "    $(dim "$f")"
done
echo ""

# 1b. Install delegation subagents
AGENTS_SRC="$REPO_DIR/agents"
AGENTS_DST="$HOME/.claude/agents"
if [[ -d "$AGENTS_SRC" ]]; then
  echo "Installing persona subagents to $AGENTS_DST ..."
  mkdir -p "$AGENTS_DST"
  cp "$AGENTS_SRC"/*.md "$AGENTS_DST/"
  echo "$(green "✓") Subagents installed (delegate with, e.g., \"have robin review this diff\")"
  echo ""
fi

# 2. Install slash commands
echo "Installing slash commands to $COMMANDS_DST ..."
mkdir -p "$COMMANDS_DST"
cp "$COMMANDS_SRC"/*.md "$COMMANDS_DST/"
echo "$(green "✓") Slash commands installed:"
for f in "$COMMANDS_DST"/*.md; do
  echo "    $(dim "$f")"
done
echo ""

# 3. Install CLI (symlink so updates in the repo take effect immediately)
echo "Installing CLI to $BIN_DST ..."
mkdir -p "$(dirname "$BIN_DST")"
ln -sf "$BIN_SRC" "$BIN_DST"
chmod +x "$BIN_SRC"
echo "$(green "✓") CLI symlinked: $(dim "$BIN_DST → $BIN_SRC")"
echo ""

# 3b. Register the SessionStart hook. hooks/hooks.json only applies on the
# plugin install path, where CLAUDE_PLUGIN_ROOT resolves, so this path needs
# the absolute hook path written into settings.json. The CLI owns the merge,
# so the logic lives in one place and the test suite exercises this same path.
# Non-fatal: the hook is an enhancement, and an unparseable pre-existing
# settings.json must not abandon an install whose core is already in place.
echo "Registering the SessionStart hook ..."
"$BIN_SRC" install-hook || echo "$(yellow "!") Hook not registered. Fix the error above, then run: claude-team install-hook"
echo ""

# 4. Create branch index if it doesn't exist
if [[ ! -f "$BRANCHES_INDEX" ]]; then
  mkdir -p "$(dirname "$BRANCHES_INDEX")"
  printf '# Branch Index\n\n| Date | Project | Branch | Plan Slug | Status | Notes |\n|---|---|---|---|---|---|\n' \
    > "$BRANCHES_INDEX"
  echo "$(green "✓") Branch index created: $(dim "$BRANCHES_INDEX")"
else
  echo "$(green "✓") Branch index already exists: $(dim "$BRANCHES_INDEX")"
fi
echo ""

# 5. Create worktrees root
mkdir -p "$WORKTREES_ROOT"
echo "$(green "✓") Worktrees root ready: $(dim "$WORKTREES_ROOT")"
echo ""

# 6. PATH check
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo "$(green "✓") ~/.local/bin is already on your PATH."
else
  echo "$(yellow "!") ~/.local/bin is not on your PATH."
  echo ""
  echo "  Add it by appending one of the following to your shell config:"
  echo ""
  echo "    $(dim "# ~/.zshrc or ~/.bashrc")"
  echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo ""
  echo "  Then reload your shell:"
  echo "    source ~/.zshrc   $(dim "# or ~/.bashrc")"
fi

# 7. Coordinator setup
echo ""
echo "$(bold "Coordinator") — proactive team check-ins"
echo ""
echo "  $(bold "casual") (default): commit directly to main — no branch enforcement."
echo "  $(bold "prod"):             branch required before any code; worktrees + MR/PR flow."
echo ""
printf "  Enable the coordinator now? [casual/prod/n] (default: casual) "
read -r coord_answer
coord_answer="${coord_answer:-casual}"

# Delegate to the CLI just installed: it owns the marker-block editing
# (atomic replace-or-append), so the logic lives in exactly one place and
# this path is the same one the test suite exercises.
case "$(echo "$coord_answer" | tr '[:upper:]' '[:lower:]')" in
  prod)
    "$BIN_SRC" coordinator prod
    ;;
  n|no)
    echo "  $(dim "Skipped. Enable later with: claude-team coordinator on")"
    ;;
  *)
    "$BIN_SRC" coordinator on
    ;;
esac

echo ""
echo "$(bold "Done!") Your Claude dev team is ready."
echo ""
echo "Quick start:"
echo "  claude-team list                   $(dim "# see your team")"
echo "  claude-team use robin              $(dim "# activate Robin (Testing)")"
echo "  claude-team use akira              $(dim "# activate Akira (Backend)")"
echo "  claude-team use sasha              $(dim "# activate Sasha (Frontend)")"
echo "  claude-team use toni               $(dim "# activate Toni (Product Marketing)")"
echo "  claude-team use river              $(dim "# activate River (Product)")"
echo "  claude-team use sage               $(dim "# activate Sage (Business Advisor)")"
echo "  claude-team use kai                $(dim "# activate Kai (UX Design)")"
echo "  claude-team use iris               $(dim "# activate Iris (Brand & Illustration)")"
echo "  claude-team coordinator on         $(dim "# casual mode (commit to main, no branch enforcement)")"
echo "  claude-team coordinator prod       $(dim "# prod mode (branch required before code)")"
echo "  claude-team coordinator off        $(dim "# disable coordinator")"
echo "  claude-team reset                  $(dim "# return to default Claude")"
echo ""
echo "Parallel sessions (worktrees — preferred for multi-session work):"
echo "  claude-team session start feat/<name>  $(dim "# create isolated worktree + branch")"
echo "  claude-team session status             $(dim "# show current session details")"
echo "  claude-team session done               $(dim "# close session, remove worktree")"
echo "  claude-team session list               $(dim "# list all active sessions")"
echo ""
echo "Branch hygiene (single-session):"
echo "  claude-team branch start feat/<name>   $(dim "# register a branch before working")"
echo "  claude-team branch done                $(dim "# mark merged, print delete commands")"
echo "  claude-team branch abandon             $(dim "# mark abandoned")"
echo "  claude-team branch guard install       $(dim "# block accidental commits on main")"
echo ""
echo "Slash commands $(dim "(switch personas mid-session, no restart needed)"):"
echo "  /robin   /akira   /sasha   /toni   /river   /sage   /kai   /iris   /team   /branch   /session"
echo ""
