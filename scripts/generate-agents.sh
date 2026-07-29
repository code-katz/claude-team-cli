#!/usr/bin/env bash
# generate-agents.sh — Generate subagents and slash commands from persona profiles.
#
# profiles/<name>.md is the single source of truth for each persona. This script
# derives both installed surfaces from it, plus the model tier in
# profiles/tiers.conf. Re-run after editing any profile or tier:
#
#   bash scripts/generate-agents.sh
#
#   agents/<name>.md    Delegation subagent. Lets any session delegate to a
#                       persona ("have Robin review this diff") without
#                       switching its own persona.
#   commands/<name>.md  /<name> slash command. The full-session takeover
#                       surface: the profile wrapped in a switch preamble, with
#                       Required Interactive Behaviors excised and the profile's
#                       greeting appended as the trailer.
#
# Both surfaces are generated here, in one script, because bin/claude-team sync
# calls this path before it copies profiles/, agents/, and commands/ into
# ~/.claude. A separate command generator would not be called there, so a synced
# slash command would lag the profile edit that prompted the sync.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILES="$REPO_DIR/profiles"
AGENTS="$REPO_DIR/agents"
COMMANDS="$REPO_DIR/commands"
TIERS="$PROFILES/tiers.conf"

# Everything above the "## Greeting" heading, with the blank line that separates
# them dropped. The greeting is the slash command trailer, so it must not reach
# agents/ and must not appear twice in commands/.
profile_body() {
  awk '
    /^## Greeting$/ { exit }
    NF == 0         { blanks = blanks $0 "\n"; next }
                    { printf "%s", blanks; blanks = ""; print }
  ' "$1"
}

# The greeting sentence: the first non-blank line under the "## Greeting"
# heading. This is the only part of a slash command that a profile cannot derive.
profile_greeting() {
  awk '
    /^## Greeting$/ { found = 1; next }
    found && NF     { print; exit }
  ' "$1"
}

# The profile body without its "## Required Interactive Behaviors" section. The
# section ends where "## Signature Question" begins; no profile puts another
# heading between the two. Reads the body on stdin.
strip_interactive_behaviors() {
  awk '
    /^## Required Interactive Behaviors$/ { skip = 1 }
    /^## Signature Question$/             { skip = 0 }
    !skip
  '
}

mkdir -p "$AGENTS" "$COMMANDS"

generated=0
for profile in "$PROFILES"/*.md; do
  name=$(basename "$profile" .md)
  case "$name" in coordinator*) continue ;; esac

  # Split "Name — Role" at the FIRST em dash (mirrors bin/claude-team), so a
  # role may itself contain one without being truncated.
  title=$(grep -m1 '^# ' "$profile" | sed 's/^# //')
  role="${title#*— }"
  display="${title%% —*}"
  model=$(awk -v p="$name" '$1 == p { print $2; exit }' "$TIERS" 2>/dev/null || echo "")

  body=$(profile_body "$profile")
  greeting=$(profile_greeting "$profile")
  if [[ -z "$greeting" ]]; then
    echo "error: $profile has no '## Greeting' section, so /$name would have no trailer." >&2
    exit 1
  fi

  # The slash command description already ends in "persona", which makes a
  # trailing "Consultant" or "Manager" in the role redundant. Keep that word
  # when dropping it would leave one word: "Product Manager" must not become
  # "Product".
  short_role="$role"
  case "$role" in
    *" Consultant" | *" Manager")
      case "${role% *}" in *" "*) short_role="${role% *}" ;; esac
      ;;
  esac

  {
    printf -- '---\n'
    printf 'name: %s\n' "$name"
    printf 'description: %s, %s. Delegate %s questions, designs, and reviews to this persona when the main session should stay in its own role.\n' \
      "$display" "$role" "$(echo "$role" | tr '[:upper:]' '[:lower:]')"
    [[ -n "$model" ]] && printf 'model: %s\n' "$model"
    printf -- '---\n\n'
    printf '<!-- GENERATED from profiles/%s.md by scripts/generate-agents.sh; edit the profile, not this file. -->\n\n' "$name"
    printf '%s\n' "$body"
    printf '\n---\n\n'
    printf 'You are running as a delegated subagent. Do the requested work within your domain, then return a concise, structured result: findings or recommendations first, supporting detail after. If the request falls outside your domain, say which team member fits and return what you can within your own lane.\n'
  } > "$AGENTS/$name.md"

  {
    printf -- '---\n'
    printf 'description: Switch this session to %s, the %s persona\n' "$display" "$short_role"
    printf 'disable-model-invocation: true\n'
    printf -- '---\n\n'
    printf 'This switch is scoped to THIS session only. Do NOT run `claude-team use` and do NOT modify `~/.claude/CLAUDE.md`. Other parallel sessions keep their own personas.\n\n'
    printf 'You are now switching to %s. Adopt the following persona immediately and completely for the rest of this session. This overrides any previous persona:\n\n' "$display"
    printf -- '---\n\n'
    printf '%s\n' "$body" | strip_interactive_behaviors
    printf -- '\n---\n\n'
    printf '%s\n' "$greeting"
  } > "$COMMANDS/$name.md"

  generated=$((generated + 1))
done

echo "Generated $generated agents in $AGENTS/ and $generated slash commands in $COMMANDS/"
