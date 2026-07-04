#!/usr/bin/env bash
# generate-agents.sh — Generate delegation subagents from persona profiles.
#
# profiles/<name>.md is the single source of truth for each persona.
# This script derives agents/<name>.md (Claude Code subagent format) from
# each profile plus the model tier in profiles/tiers.conf. Re-run after
# editing any profile or tier:
#
#   bash scripts/generate-agents.sh
#
# Subagents let any session DELEGATE to a persona ("have Robin review this
# diff") without switching its own persona; the /name slash commands remain
# the full-session takeover surface.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILES="$REPO_DIR/profiles"
AGENTS="$REPO_DIR/agents"
TIERS="$PROFILES/tiers.conf"

mkdir -p "$AGENTS"

generated=0
for profile in "$PROFILES"/*.md; do
  name=$(basename "$profile" .md)
  case "$name" in coordinator*) continue ;; esac

  title=$(grep -m1 '^# ' "$profile" | sed 's/^# //')
  role=$(echo "$title" | sed 's/.*— //')
  display=$(echo "$title" | sed 's/ —.*//')
  model=$(awk -v p="$name" '$1 == p { print $2; exit }' "$TIERS" 2>/dev/null || echo "")

  out="$AGENTS/$name.md"
  {
    printf -- '---\n'
    printf 'name: %s\n' "$name"
    printf 'description: %s, %s. Delegate %s questions, designs, and reviews to this persona when the main session should stay in its own role.\n' \
      "$display" "$role" "$(echo "$role" | tr '[:upper:]' '[:lower:]')"
    [[ -n "$model" ]] && printf 'model: %s\n' "$model"
    printf -- '---\n\n'
    printf '<!-- GENERATED from profiles/%s.md by scripts/generate-agents.sh; edit the profile, not this file. -->\n\n' "$name"
    cat "$profile"
    printf '\n---\n\n'
    printf 'You are running as a delegated subagent. Do the requested work within your domain, then return a concise, structured result: findings or recommendations first, supporting detail after. If the request falls outside your domain, say which team member fits and return what you can within your own lane.\n'
  } > "$out"
  generated=$((generated + 1))
done

echo "Generated $generated agents in $AGENTS/"
