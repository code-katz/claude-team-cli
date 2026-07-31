#!/usr/bin/env bash
# tests/run.sh — Test suite for claude-team CLI
#
# Usage: bash tests/run.sh
#
# Uses a temporary HOME to avoid touching ~/.claude/CLAUDE.md.
# No external dependencies required.

set -uo pipefail

# Bash 4+ required, same floor as the CLI under test.
if [[ -z "${BASH_VERSINFO:-}" ]] || (( BASH_VERSINFO[0] < 4 )); then
  echo "error: tests/run.sh requires Bash 4 or newer (this is ${BASH_VERSION:-not bash})." >&2
  echo "macOS ships Bash 3.2; install a current Bash with: brew install bash" >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$REPO_DIR/bin/claude-team"
PROFILES_DIR="$REPO_DIR/profiles"

# ─── Test state ──────────────────────────────────────────────────────────────

PASS=0
FAIL=0
ERRORS=()

# ─── Temp environment ────────────────────────────────────────────────────────

# The session tests create commits in throwaway repos. CI runners and fresh
# machines have no git identity configured, so the suite provides its own
# instead of depending on ambient config.
export GIT_AUTHOR_NAME="claude-team-tests" GIT_AUTHOR_EMAIL="tests@claude-team.invalid"
export GIT_COMMITTER_NAME="claude-team-tests" GIT_COMMITTER_EMAIL="tests@claude-team.invalid"

TEST_HOME=$(mktemp -d)
CLAUDE_MD="$TEST_HOME/.claude/CLAUDE.md"
mkdir -p "$TEST_HOME/.claude"
trap 'rm -rf "$TEST_HOME"' EXIT

run_cmd() {
  CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" "$@"
}

# The branch section needs a git repo to work in. A separate helper rather than
# a mid-file redefinition of run_cmd: redefining a function trips shellcheck
# (SC2218) and makes every earlier call ambiguous to a human reader too.
# $BRANCH_REPO is set by that section before anything calls this.
run_branch() {
  (cd "$BRANCH_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" "$@")
}

# ─── Assertion helpers ───────────────────────────────────────────────────────

ok()   { PASS=$((PASS + 1)); printf "  \033[32m✓\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); ERRORS+=("$1"); printf "  \033[31m✗\033[0m %s\n" "$1"; }

# Patterns are POSIX EREs (grep -E): alternation is plain '|', and BRE-only
# GNU extensions like '\|' must not be used (BSD grep rejects them).
assert_contains() {
  local name="$1" pattern="$2" output="$3"
  if grep -Eq "$pattern" <<< "$output"; then ok "$name"
  else fail "$name (expected: '$pattern')"; fi
}

assert_not_contains() {
  local name="$1" pattern="$2" output="$3"
  if ! grep -Eq "$pattern" <<< "$output"; then ok "$name"
  else fail "$name (must not contain: '$pattern')"; fi
}

assert_file_has() {
  local name="$1" file="$2" pattern="$3"
  if grep -q "$pattern" "$file" 2>/dev/null; then ok "$name"
  else fail "$name (file missing: '$pattern')"; fi
}

assert_file_lacks() {
  local name="$1" file="$2" pattern="$3"
  if ! grep -q "$pattern" "$file" 2>/dev/null; then ok "$name"
  else fail "$name (file must not contain: '$pattern')"; fi
}

assert_count() {
  local name="$1" file="$2" pattern="$3" expected="$4"
  local count
  # 'grep -c' prints 0 and ALSO exits 1 when nothing matches, so a trailing
  # '|| echo 0' appended a second zero and made count the two-line string
  # '0\n0'. Bash then failed to evaluate it as arithmetic, so an assert_count
  # with an expected 0 could never pass and reported a syntax error instead of a
  # comparison. Take grep's own 0 and only default when it printed nothing,
  # which is what a missing file does.
  count=$(grep -c "$pattern" "$file" 2>/dev/null)
  count=${count:-0}
  if [[ "$count" -eq "$expected" ]]; then ok "$name"
  else fail "$name (expected $expected x '$pattern', got $count)"; fi
}

assert_exits_nonzero() {
  local name="$1"; shift
  if CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$@" >/dev/null 2>&1; then
    fail "$name (expected non-zero exit)"
  else
    ok "$name"
  fi
}

# ─── Tests ───────────────────────────────────────────────────────────────────

echo ""
echo "claude-team test suite"
echo "────────────────────────────────"
echo ""

# help
echo "help"
out=$(run_cmd help)
assert_contains     "shows tool name"            "claude-team"       "$out"
assert_contains     "lists use command"          "use <name>"        "$out"
assert_contains     "lists install-commands"     "install-commands"  "$out"
# Every roster the CLI prints is derived from the profiles on disk. Four
# separate hardcoded copies had drifted, leaving help and the installer missing
# four to nine of the seventeen personas: nothing broke, but a new user could
# not discover team members that exist. A derived list cannot drift, and this
# asserts the derivation rather than the current text.
missing=""
for profile in "$PROFILES_DIR"/*.md; do
  pname=$(basename "$profile" .md)
  case "$pname" in coordinator*) continue ;; esac
  grep -q "claude-team use $pname " <<< "$out" || missing="$missing $pname"
done
if [[ -z "$missing" ]]; then ok "help lists every persona"
else fail "help lists every persona (missing:$missing)"; fi
out=$(run_cmd install-commands)
missing=""
for profile in "$PROFILES_DIR"/*.md; do
  pname=$(basename "$profile" .md)
  case "$pname" in coordinator*) continue ;; esac
  grep -q "/$pname" <<< "$out" || missing="$missing $pname"
done
if [[ -z "$missing" ]]; then ok "install-commands lists every persona"
else fail "install-commands lists every persona (missing:$missing)"; fi
assert_not_contains "the roster excludes the coordinator profiles" "use coordinator" "$out"
# The installer prints its own slash-command line; it must derive it too.
missing=""
for profile in "$PROFILES_DIR"/*.md; do
  pname=$(basename "$profile" .md)
  case "$pname" in coordinator*) continue ;; esac
  grep -q "coordinator\*" "$REPO_DIR/install.sh" || true
  grep -q "profiles/\*.md" "$REPO_DIR/install.sh" || missing="derived-loop-absent"
done
if [[ -z "$missing" ]]; then ok "installer derives its slash-command list from profiles"
else fail "installer derives its slash-command list from profiles"; fi
echo ""

# list
echo "list"
out=$(run_cmd list)
assert_contains     "shows Robin"        "Robin"       "$out"
assert_contains     "shows Akira"        "Akira"       "$out"
assert_contains     "shows Sasha"        "Sasha"       "$out"
assert_contains     "shows Toni"         "Toni"        "$out"
assert_contains     "shows River"        "River"       "$out"
assert_contains     "shows Alex"         "Alex"        "$out"
assert_contains     "shows Morgan"       "Morgan"      "$out"
assert_contains     "shows Jordan"       "Jordan"      "$out"
assert_contains     "shows Casey"        "Casey"       "$out"
assert_contains     "shows Quinn"        "Quinn"       "$out"
assert_contains     "shows Sage"         "Sage"        "$out"
assert_contains     "shows Kai"          "Kai"         "$out"
assert_contains     "shows Iris"         "Iris"        "$out"
assert_contains     "shows Reiner"       "Reiner"      "$out"
assert_contains     "shows Cornelius"    "Cornelius"   "$out"
assert_contains     "shows Ernie"        "Ernie"       "$out"
assert_contains     "shows Piper"        "Piper"       "$out"
assert_not_contains "excludes Coordinator" "Coordinator" "$out"
echo ""

# show
echo "show"
out=$(run_cmd show robin)
assert_contains "shows Robin profile"       "Robin — QA" "$out"
out=$(run_cmd show ROBIN)
assert_contains "case-insensitive show"     "Robin — QA" "$out"
assert_exits_nonzero "invalid name exits nonzero" "$CLI" show nobody
echo ""

# A profile name is an identifier, not a path. resolve_name is the single choke
# point for show, use, and launch. '../gtm' is the regression target because
# $PROFILES_DIR/../gtm.md genuinely exists and is lowercase, so it resolved
# before the fix. Traversal read nothing the caller could not already cat, but
# it let a non-profile reach the global pin and printed a success line with an
# empty name.
echo "name validation"
# Guard the guard: if gtm.md ever moves, every assertion below would pass for
# the wrong reason, because the traversal would resolve to nothing either way.
if [[ -f "$REPO_DIR/gtm.md" ]]; then ok "traversal target exists, so these tests are not vacuous"
else fail "traversal target exists, so these tests are not vacuous (gtm.md moved: repoint these tests)"; fi
assert_exits_nonzero "show rejects traversal to a real file"   "$CLI" show ../gtm
assert_exits_nonzero "use rejects traversal to a real file"    "$CLI" use ../gtm
assert_exits_nonzero "launch rejects traversal to a real file" "$CLI" launch ../gtm --dry-run
assert_exits_nonzero "show rejects a nested traversal"         "$CLI" show sub/../../gtm
assert_exits_nonzero "show rejects a leading dash"             "$CLI" show -n
assert_exits_nonzero "show rejects an empty name"              "$CLI" show ""
out=$(run_cmd show ../gtm 2>&1 || true)
assert_contains     "traversal reports an invalid name"      "Invalid profile name" "$out"
assert_not_contains "traversal discloses no outside content" "Go-to-Market"         "$out"
run_cmd use ../gtm >/dev/null 2>&1 || true
assert_file_lacks "a rejected name never reaches the global pin" "$CLAUDE_MD" "Go-to-Market"
# The character class must not be so tight that real names stop resolving.
out=$(run_cmd show coordinator-prod)
assert_contains "hyphenated name still resolves" "Claude Team CLI" "$out"
echo ""

# The coordinator is a behavior layer, not a team member: it has its own marker
# block, its own on/prod/off command, and both roster paths skip it. resolve_name
# did not, so 'claude-team use coordinator' resolved and installed the
# coordinator profile into the CLAUDE-TEAM block. 'status' then reported "Active
# team member: Claude Team CLI", and with the coordinator also enabled the file
# held two copies of the same instructions, one in each marker pair.
echo "the coordinator is not a team member"
assert_exits_nonzero "use rejects the coordinator"        "$CLI" use coordinator
assert_exits_nonzero "use rejects the prod coordinator"   "$CLI" use coordinator-prod
assert_exits_nonzero "launch rejects the coordinator"     "$CLI" launch coordinator --dry-run
out=$(run_cmd use coordinator 2>&1 || true)
assert_contains "the refusal points at the command that does work" "claude-team coordinator on" "$out"

# Its own HOME, so the assertion holds wherever this section sits in the file.
# Against the shared one it would depend on nothing earlier having installed a
# block, which is true today and is not a property this test should rely on.
COORD_HOME=$(mktemp -d)
mkdir -p "$COORD_HOME/.claude"
CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$COORD_HOME" "$CLI" use coordinator >/dev/null 2>&1 || true
assert_file_lacks "a rejected coordinator writes no persona block" \
  "$COORD_HOME/.claude/CLAUDE.md" "CLAUDE-TEAM:START"
rm -rf "$COORD_HOME"

# Guard the guard, in the other direction. The check belongs on 'use' and
# 'launch', which activate a name as a persona, and NOT in resolve_name, which
# 'show' also goes through: printing the coordinator profile is a legitimate
# thing to want, and coordinator-prod is the fixture the hyphenated-name test
# above uses, so blocking it there would break that test for an unrelated reason.
out=$(run_cmd show coordinator)
assert_contains "show still reads the coordinator profile"      "Active Coordination" "$out"
out=$(run_cmd show coordinator-prod)
assert_contains "show still reads the prod coordinator profile" "Claude Team CLI"     "$out"
echo ""

# use — basic injection
echo "use"
run_cmd use robin >/dev/null
assert_file_has  "use injects CLAUDE-TEAM block"  "$CLAUDE_MD" "CLAUDE-TEAM:START"
assert_file_has  "use injects Robin profile"       "$CLAUDE_MD" "Robin — QA"
assert_count     "use creates exactly 1 block"     "$CLAUDE_MD" "CLAUDE-TEAM:START" 1
# 'use' pins globally, so a greeting here would fire on every future session
# rather than at the moment of the switch. The body must still arrive whole.
assert_file_lacks "use excludes the greeting"      "$CLAUDE_MD" "^## Greeting"
assert_file_has   "use keeps the signature question" "$CLAUDE_MD" "Signature Question"
echo ""

# use — persona switch
echo "use (switch)"
run_cmd use akira >/dev/null
assert_file_has     "switch updates profile to Akira"  "$CLAUDE_MD" "Akira — Backend"
assert_file_lacks   "switch removes Robin content"     "$CLAUDE_MD" "Robin — QA"
assert_count        "switch leaves exactly 1 block"    "$CLAUDE_MD" "CLAUDE-TEAM:START" 1
echo ""

# use — idempotency (same member twice)
echo "use (idempotency)"
run_cmd use akira >/dev/null
assert_count "same member twice stays 1 block" "$CLAUDE_MD" "CLAUDE-TEAM:START" 1
echo ""

# coordinator block survives persona switch
echo "coordinator block survives persona switch"
printf '\n<!-- CLAUDE-COORDINATOR:START -->\nFake coordinator\n<!-- CLAUDE-COORDINATOR:END -->\n' >> "$CLAUDE_MD"
run_cmd use robin >/dev/null
assert_count "coordinator block survives use"         "$CLAUDE_MD" "CLAUDE-COORDINATOR:START" 1
assert_count "team block still present alongside coordinator" "$CLAUDE_MD" "CLAUDE-TEAM:START" 1
echo ""

# reset
echo "reset"
run_cmd reset >/dev/null
assert_file_lacks "reset removes CLAUDE-TEAM block"       "$CLAUDE_MD" "CLAUDE-TEAM:START"
assert_file_has   "reset preserves coordinator block"     "$CLAUDE_MD" "CLAUDE-COORDINATOR:START"
# clean up coordinator for next tests
awk '/CLAUDE-COORDINATOR:START/{found=1} found && /CLAUDE-COORDINATOR:END/{found=0; next} !found{print}' \
  "$CLAUDE_MD" > "${CLAUDE_MD}.tmp" && mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"
out=$(run_cmd reset)
assert_contains "reset when none active shows message" "No team member" "$out"
echo ""

# coordinator on/off
echo "coordinator on/off"
run_cmd coordinator on >/dev/null
assert_file_has "coordinator on injects block"       "$CLAUDE_MD" "CLAUDE-COORDINATOR:START"
assert_count    "coordinator on: exactly 1 block"    "$CLAUDE_MD" "CLAUDE-COORDINATOR:START" 1
out=$(run_cmd coordinator on)
assert_contains "coordinator on twice shows refresh" "refreshed" "$out"
assert_count    "coordinator on twice stays 1 block" "$CLAUDE_MD" "CLAUDE-COORDINATOR:START" 1
run_cmd coordinator off >/dev/null
assert_file_lacks "coordinator off removes block"    "$CLAUDE_MD" "CLAUDE-COORDINATOR:START"
out=$(run_cmd coordinator off)
assert_contains "coordinator off when already off"   "already off" "$out"
echo ""

# coordinator prod
echo "coordinator prod"
run_cmd coordinator prod >/dev/null
assert_file_has "coordinator prod injects block"      "$CLAUDE_MD" "CLAUDE-COORDINATOR:START"
assert_file_has "coordinator prod contains mode tag"  "$CLAUDE_MD" "CLAUDE-COORD-MODE: prod"
out=$(run_cmd coordinator prod)
assert_contains "coordinator prod twice shows refresh" "refreshed" "$out"
assert_count    "coordinator prod twice stays 1 block" "$CLAUDE_MD" "CLAUDE-COORDINATOR:START" 1
run_cmd coordinator off >/dev/null

# coordinator on installs casual
echo "coordinator on installs casual"
run_cmd coordinator on >/dev/null
assert_file_has "coordinator on injects casual tag"  "$CLAUDE_MD" "CLAUDE-COORD-MODE: casual"
run_cmd coordinator off >/dev/null
echo ""

# status
echo "status"
run_cmd use toni >/dev/null
out=$(run_cmd status)
assert_contains "status shows active member" "Toni" "$out"
run_cmd coordinator on >/dev/null
out=$(run_cmd status)
assert_contains "status shows coordinator casual" "casual" "$out"
run_cmd coordinator off >/dev/null
run_cmd coordinator prod >/dev/null
out=$(run_cmd status)
assert_contains "status shows coordinator prod"   "prod"  "$out"
run_cmd coordinator off >/dev/null
out=$(run_cmd status)
assert_contains "status shows coordinator off" "off" "$out"
echo ""

# error handling
echo "error handling"
assert_exits_nonzero "unknown command exits nonzero" "$CLI" badcommand
assert_exits_nonzero "use without name exits nonzero" "$CLI" use
assert_exits_nonzero "show without name exits nonzero" "$CLI" show
echo ""

# A profiles directory that does not exist at all -- a fresh machine, a typo'd
# CLAUDE_TEAM_PROFILES, a clone moved without a resync -- is a real, plausible
# state, previously untested on any command. require_profiles_dir guards only
# cmd_list; show, use, and launch all fall through to resolve_name's plain "no
# profile found" message instead, which is misleading here (it points at
# 'claude-team list', which would also fail, with a different message) but
# still exits nonzero and writes nothing. That fail-safe behavior, not the
# wording, is what this pins; assert_exits_nonzero is not reused here because
# it hardcodes the real PROFILES_DIR, and this needs a missing one instead.
echo "profiles directory entirely missing"

NO_PROFILES_BASE=$(mktemp -d)
NO_PROFILES="$NO_PROFILES_BASE/does-not-exist"
NOPROF_HOME=$(mktemp -d)
if CLAUDE_TEAM_PROFILES="$NO_PROFILES" HOME="$NOPROF_HOME" "$CLI" list >/dev/null 2>&1; then
  fail "list fails safely when the profiles dir is missing"
else
  ok "list fails safely when the profiles dir is missing"
fi
if CLAUDE_TEAM_PROFILES="$NO_PROFILES" HOME="$NOPROF_HOME" "$CLI" show robin >/dev/null 2>&1; then
  fail "show fails safely when the profiles dir is missing"
else
  ok "show fails safely when the profiles dir is missing"
fi
if CLAUDE_TEAM_PROFILES="$NO_PROFILES" HOME="$NOPROF_HOME" "$CLI" use robin >/dev/null 2>&1; then
  fail "use fails safely when the profiles dir is missing"
else
  ok "use fails safely when the profiles dir is missing"
fi
if CLAUDE_TEAM_PROFILES="$NO_PROFILES" HOME="$NOPROF_HOME" "$CLI" launch robin --dry-run >/dev/null 2>&1; then
  fail "launch fails safely when the profiles dir is missing"
else
  ok "launch fails safely when the profiles dir is missing"
fi
assert_file_lacks "a failed use writes nothing to CLAUDE.md when the profiles dir is missing" \
  "$NOPROF_HOME/.claude/CLAUDE.md" "CLAUDE-TEAM:START"
rm -rf "$NOPROF_HOME" "$NO_PROFILES_BASE"
echo ""

# content preservation: use/reset and coordinator on/off must round-trip the
# user's own CLAUDE.md byte-for-byte (leading blanks and trailing spaces
# included), and must not leave a stray trailing blank line behind.
echo "content preservation on block removal"

FIXTURE="$TEST_HOME/claude-md-fixture"
printf '\n# My Notes\n\nline with trailing spaces  \nlast line\n' > "$FIXTURE"

cp "$FIXTURE" "$CLAUDE_MD"
run_cmd use robin >/dev/null
run_cmd reset >/dev/null
if cmp -s "$CLAUDE_MD" "$FIXTURE"; then ok "use + reset round-trips user content byte-for-byte"
else fail "use + reset round-trips user content byte-for-byte"; fi

cp "$FIXTURE" "$CLAUDE_MD"
run_cmd coordinator on >/dev/null
run_cmd coordinator off >/dev/null
if cmp -s "$CLAUDE_MD" "$FIXTURE"; then ok "coordinator on + off round-trips user content byte-for-byte"
else fail "coordinator on + off round-trips user content byte-for-byte"; fi
echo ""

# branch index lookups must treat project and branch names as literal strings,
# not regexes: dots must not cross-match similarly named projects, and regex
# metacharacters like parentheses must not crash the lookup.
echo "branch index metachar regression"

META_BASE=$(mktemp -d)
mkdir -p "$META_BASE/my.app" "$META_BASE/myXapp" "$META_BASE/app(1)"
git init -q "$META_BASE/my.app" 2>/dev/null
git init -q "$META_BASE/myXapp" 2>/dev/null
git init -q "$META_BASE/app(1)" 2>/dev/null

(cd "$META_BASE/myXapp" && run_cmd branch start release/9.9.9 >/dev/null)
out=$(cd "$META_BASE/my.app" && run_cmd branch status 2>&1)
assert_contains     "dotted project does not cross-match similar project" "none|No branch|no active|No active" "$out"
assert_not_contains "dotted project does not see other project's branch"  "release/9\.9\.9" "$out"

(cd "$META_BASE/my.app" && run_cmd branch start release/1.2.3 >/dev/null)
out=$(cd "$META_BASE/my.app" && run_cmd branch status)
assert_contains "dotted branch name registers and resolves" "release/1\.2\.3" "$out"

if (cd "$META_BASE/app(1)" && run_cmd branch start feat/x >/dev/null 2>&1); then
  ok "paren project name does not crash branch start"
else
  fail "paren project name does not crash branch start"
fi
out=$(cd "$META_BASE/app(1)" && run_cmd branch status 2>&1)
assert_contains "paren project name resolves its branch" "feat/x" "$out"

(cd "$META_BASE/my.app"  && run_cmd branch "done" >/dev/null 2>&1)
(cd "$META_BASE/myXapp"  && run_cmd branch "done" >/dev/null 2>&1)
(cd "$META_BASE/app(1)"  && run_cmd branch abandon >/dev/null 2>&1)
rm -rf "$META_BASE"
echo ""

# title parsing: "Name — Role" splits at the FIRST em dash, so a role may
# itself contain one without being truncated.
echo "title parsing"
TITLE_DIR=$(mktemp -d)
cp "$PROFILES_DIR/robin.md" "$TITLE_DIR/robin.md"
printf '# Testy — Role One — Extended\n\nBody.\n' > "$TITLE_DIR/testy.md"
out=$(CLAUDE_TEAM_PROFILES="$TITLE_DIR" HOME="$TEST_HOME" "$CLI" list)
assert_contains "multi-dash title keeps the full role" "Role One — Extended" "$out"
rm -rf "$TITLE_DIR"
echo ""

# One stray '.md' with no H1 heading used to take out the whole roster.
# profile_title was 'grep -m1 | sed', and under 'set -euo pipefail' the grep's
# non-zero exit on no match killed the pipeline: 'list' exited 1 having printed
# zero personas, with EMPTY stderr, and 'help' exited 0 with a silently empty
# roster, because persona_roster runs inside process substitution where the
# failure is invisible. A notes file or an editor backup in the profiles
# directory was enough, and neither symptom said why.
echo "a titleless file in the profiles directory"

STRAY_DIR=$(mktemp -d)
cp "$PROFILES_DIR"/*.md "$STRAY_DIR/"
cp "$PROFILES_DIR/tiers.conf" "$STRAY_DIR/" 2>/dev/null || true
printf -- '- a scratch note with no H1 heading\n- second line\n' > "$STRAY_DIR/notes.md"
STRAY_ERR="$TEST_HOME/stray-list-stderr"
STRAY_HELP_ERR="$TEST_HOME/stray-help-stderr"

if stray_out=$(CLAUDE_TEAM_PROFILES="$STRAY_DIR" HOME="$TEST_HOME" "$CLI" list 2>"$STRAY_ERR"); then
  ok "list still exits 0 with a titleless file present"
else
  fail "list still exits 0 with a titleless file present"
fi
stray_missing=""
for profile in "$PROFILES_DIR"/*.md; do
  pname=$(basename "$profile" .md)
  case "$pname" in coordinator*) continue ;; esac
  grep -qi "$pname" <<< "$stray_out" || stray_missing="$stray_missing $pname"
done
if [[ -z "$stray_missing" ]]; then ok "list still shows every real persona"
else fail "list still shows every real persona (missing:$stray_missing)"; fi
assert_file_has "list names the file it skipped"        "$STRAY_ERR" "notes.md"
assert_count    "list names the skipped file once"      "$STRAY_ERR" "notes.md" 1

if stray_help=$(CLAUDE_TEAM_PROFILES="$STRAY_DIR" HOME="$TEST_HOME" "$CLI" help 2>"$STRAY_HELP_ERR"); then
  ok "help still exits 0 with a titleless file present"
else
  fail "help still exits 0 with a titleless file present"
fi
stray_missing=""
for profile in "$PROFILES_DIR"/*.md; do
  pname=$(basename "$profile" .md)
  case "$pname" in coordinator*) continue ;; esac
  grep -q "claude-team use $pname " <<< "$stray_help" || stray_missing="$stray_missing $pname"
done
if [[ -z "$stray_missing" ]]; then ok "help's roster is not silently truncated"
else fail "help's roster is not silently truncated (missing:$stray_missing)"; fi
assert_file_has "help names the file it skipped" "$STRAY_HELP_ERR" "notes.md"
# The skip must not swallow a real persona whose title merely sits lower down.
assert_not_contains "the titleless file is not listed as a persona" "notes" "$stray_out"
rm -rf "$STRAY_DIR"
rm -f "$STRAY_ERR" "$STRAY_HELP_ERR"
echo ""

# branch commands
echo "branch commands"

BRANCHES_INDEX="$TEST_HOME/.claude/branches/INDEX.md"

# Own fixture, like every other git-touching section. This block used to run
# against the ambient CWD and assert the literal string "claude-team-cli" as the
# project name, so it failed in a differently-named clone and failed ten ways
# when the suite was run from outside a git repo at all. Both are ordinary:
# 'claude-team session start' puts contributors in a worktree named for the
# branch, not the repo.
BRANCH_REPO=$(mktemp -d)
BRANCH_PROJECT=$(basename "$BRANCH_REPO")
git init -q "$BRANCH_REPO"
git -C "$BRANCH_REPO" commit -q --allow-empty -m init

# status warns when no index exists
out=$(run_branch branch status 2>&1)
assert_contains "branch status warns when no active branch" "none|No branch|no active|No active" "$out"

# start registers a branch
run_branch branch start feat/test-branch >/dev/null
assert_file_has "branch start creates index"            "$BRANCHES_INDEX" "Branch Index"
assert_file_has "branch start writes branch name"       "$BRANCHES_INDEX" "feat/test-branch"
assert_file_has "branch start writes project name"      "$BRANCHES_INDEX" "$BRANCH_PROJECT"
assert_file_has "branch start writes active status"     "$BRANCHES_INDEX" "active"

# status shows active branch
out=$(run_branch branch status)
assert_contains "branch status shows active branch"     "feat/test-branch" "$out"

# start blocked when active already exists
if (cd "$BRANCH_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" branch start feat/duplicate >/dev/null 2>&1); then
  fail "branch start blocked when active exists"
else
  ok "branch start blocked when active exists"
fi

# done marks merged
out=$(run_branch branch "done" 2>&1)
assert_contains "branch done output mentions merged"    "merged" "$out"
assert_file_has "branch done updates status in index"   "$BRANCHES_INDEX" "merged"

# status after done shows none
out=$(run_branch branch status 2>&1)
assert_contains "branch status after done shows none"   "none|No branch|no active|No active" "$out"

# start with --plan links a plan slug
run_branch branch start feat/with-plan --plan some-plan-slug >/dev/null
assert_file_has "branch start --plan writes plan slug"  "$BRANCHES_INDEX" "some-plan-slug"

# abandon marks abandoned
out=$(run_branch branch abandon 2>&1)
assert_contains "branch abandon output mentions abandoned" "abandoned" "$out"
assert_file_has "branch abandon updates status in index"  "$BRANCHES_INDEX" "abandoned"

# list shows full table
run_branch branch start feat/listable >/dev/null
out=$(run_branch branch list 2>&1)
assert_contains "branch list shows header"              "Branch Index" "$out"
assert_contains "branch list shows branch entry"        "feat/listable" "$out"

# guard install and remove
GUARD_REPO=$(mktemp -d)
git init "$GUARD_REPO" >/dev/null 2>&1
mkdir -p "$GUARD_REPO/.git/hooks"
_hook="$GUARD_REPO/.git/hooks/pre-commit"
(cd "$GUARD_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" branch guard install >/dev/null 2>&1)
if [[ -f "$_hook" ]]; then ok "branch guard install creates hook"; else fail "branch guard install creates hook"; fi
if [[ -x "$_hook" ]]; then ok "branch guard hook is executable"; else fail "branch guard hook is executable"; fi
if grep -q "claude-team" "$_hook" 2>/dev/null; then ok "branch guard hook has claude-team marker"; else fail "branch guard hook has claude-team marker"; fi
(cd "$GUARD_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" branch guard remove >/dev/null 2>&1)
if [[ ! -f "$_hook" ]]; then ok "branch guard remove deletes hook"; else fail "branch guard remove deletes hook"; fi

# install must refuse to clobber a pre-commit hook it did not create, rather
# than overwrite someone's own hook silently. Compared as files, not as a
# command-substitution string: $(cat ...) strips the trailing newline that
# printf wrote, so a string comparison against it fails even when the file on
# disk is byte-for-byte untouched.
_foreign_hook_src="$TEST_HOME/foreign-hook-fixture"
printf '#!/bin/sh\necho "pre-existing custom hook"\n' > "$_foreign_hook_src"
cp "$_foreign_hook_src" "$_hook"
chmod +x "$_hook"
if (cd "$GUARD_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" branch guard install >/dev/null 2>&1); then
  fail "branch guard install refuses to overwrite a foreign hook"
else
  ok "branch guard install refuses to overwrite a foreign hook"
fi
if cmp -s "$_hook" "$_foreign_hook_src"; then
  ok "branch guard install leaves the foreign hook untouched"
else
  fail "branch guard install leaves the foreign hook untouched"
fi
rm -f "$_foreign_hook_src"
rm -rf "$GUARD_REPO"
echo ""

rm -rf "$BRANCH_REPO"

# session commands
echo "session commands"

SESSION_REPO=$(mktemp -d)
git init "$SESSION_REPO" >/dev/null 2>&1
git -C "$SESSION_REPO" commit --allow-empty -m "init" >/dev/null 2>&1

SESSION_WORKTREES="$TEST_HOME/.claude/worktrees"
SESSION_INDEX="$TEST_HOME/.claude/branches/INDEX.md"

# session status warns when no session marker
out=$(cd "$SESSION_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session status 2>&1)
assert_contains "session status warns when no session" "none|No.*session|not in|Not in" "$out"

# session start creates worktree directory
(cd "$SESSION_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session start feat/session-test >/dev/null 2>&1)
SESSION_WT="$SESSION_WORKTREES/$(basename "$SESSION_REPO")/feat-session-test"
if [[ -d "$SESSION_WT" ]]; then ok "session start creates worktree directory"; else fail "session start creates worktree directory"; fi

# session start writes .claude-session marker
if [[ -f "$SESSION_WT/.claude-session" ]]; then ok "session start writes .claude-session marker"; else fail "session start writes .claude-session marker"; fi

# .claude-session has correct fields
assert_file_has "session marker has project field"     "$SESSION_WT/.claude-session" "^project="
assert_file_has "session marker has branch field"      "$SESSION_WT/.claude-session" "^branch=feat/session-test"
assert_file_has "session marker has worktree_path"     "$SESSION_WT/.claude-session" "^worktree_path="
assert_file_has "session marker has started_at"        "$SESSION_WT/.claude-session" "^started_at="

# session start registers branch in INDEX.md
assert_file_has "session start writes INDEX.md entry"  "$SESSION_INDEX" "feat/session-test"

# .claude-session must never be committable (worktree-local exclude)
if git -C "$SESSION_WT" status --porcelain 2>/dev/null | grep -q '.claude-session'; then
  fail "session marker is git-ignored in the worktree"
else
  ok "session marker is git-ignored in the worktree"
fi
assert_file_has "session start writes active status"   "$SESSION_INDEX" "feat/session-test.*active"

# session start blocked if branch already active
out=$(cd "$SESSION_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session start feat/session-test 2>&1)
assert_contains "session start blocked if already active" "already|active" "$out"

# session status reads marker from worktree
out=$(cd "$SESSION_WT" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session status 2>&1)
assert_contains "session status shows branch from marker" "feat/session-test" "$out"

# session list shows active session
out=$(cd "$SESSION_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session list 2>&1)
assert_contains "session list shows active branch" "feat/session-test" "$out"

# session done marks merged in INDEX.md and removes worktree
(cd "$SESSION_WT" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session "done" >/dev/null 2>&1)
assert_file_has "session done marks merged in index"   "$SESSION_INDEX" "feat/session-test.*merged"
if [[ ! -d "$SESSION_WT" ]]; then ok "session done removes worktree directory"; else fail "session done removes worktree directory"; fi

# session start with --plan writes plan slug
(cd "$SESSION_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session start feat/session-plan --plan my-plan-slug >/dev/null 2>&1)
SESSION_WT2="$SESSION_WORKTREES/$(basename "$SESSION_REPO")/feat-session-plan"
assert_file_has "session start --plan writes slug to marker" "$SESSION_WT2/.claude-session" "^plan_slug=my-plan-slug"

# session done must handle branch names containing regex metacharacters:
# the index rewrite matches them as literal strings, not patterns
(cd "$SESSION_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session start 'feat/(v1.2.3)' >/dev/null 2>&1)
SESSION_WT3="$SESSION_WORKTREES/$(basename "$SESSION_REPO")/feat-(v1.2.3)"
if [[ -d "$SESSION_WT3" ]]; then ok "session start handles metachar branch name"; else fail "session start handles metachar branch name"; fi
(cd "$SESSION_WT3" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session "done" >/dev/null 2>&1)
assert_file_has "session done marks metachar branch merged" "$SESSION_INDEX" "feat/(v1\.2\.3).*merged"
if [[ ! -d "$SESSION_WT3" ]]; then ok "session done removes metachar worktree"; else fail "session done removes metachar worktree"; fi

# session start reuses an EXISTING local branch instead of creating a new one
# from the default branch. The reused branch is given its own commit,
# diverged from the default branch, so the test can tell "reused" apart from
# "recreated fresh from default": without the divergence the two look
# identical whenever they happen to start at the same commit.
_reuse_parent=$(git -C "$SESSION_REPO" rev-parse HEAD)
_reuse_tree=$(git -C "$SESSION_REPO" rev-parse "HEAD^{tree}")
_reuse_commit=$(git -C "$SESSION_REPO" commit-tree "$_reuse_tree" -p "$_reuse_parent" -m "diverge for reuse test")
git -C "$SESSION_REPO" branch feat/reuse-existing "$_reuse_commit" >/dev/null 2>&1
(cd "$SESSION_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session start feat/reuse-existing >/dev/null 2>&1)
SESSION_WT4="$SESSION_WORKTREES/$(basename "$SESSION_REPO")/feat-reuse-existing"
if [[ -d "$SESSION_WT4" ]]; then ok "session start reuses an existing local branch"; else fail "session start reuses an existing local branch"; fi
if [[ "$(git -C "$SESSION_WT4" rev-parse HEAD 2>/dev/null)" == "$_reuse_commit" ]]; then
  ok "reused branch keeps its own commit, not a fresh one from the default branch"
else
  fail "reused branch keeps its own commit, not a fresh one from the default branch"
fi
(cd "$SESSION_WT4" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session "done" >/dev/null 2>&1)

rm -rf "$SESSION_REPO"
echo ""

# session done: uncommitted changes guard. This is the one check standing
# between "close a session" and permanently deleting whatever is in its
# worktree: cmd_session_done removes the worktree once it passes. It was
# entirely untested in either direction before this block -- not proven to
# block when it should, not proven to let a clean session through.
echo "session done: uncommitted changes guard"

# Modified TRACKED file: 'git diff' (unstaged) must catch it.
UNCOM_REPO=$(mktemp -d)
git init -q "$UNCOM_REPO"
printf 'orig\n' > "$UNCOM_REPO/tracked.txt"
git -C "$UNCOM_REPO" add tracked.txt
git -C "$UNCOM_REPO" commit -q -m init
(cd "$UNCOM_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session start feat/uncommitted-tracked >/dev/null 2>&1)
UNCOM_WT="$SESSION_WORKTREES/$(basename "$UNCOM_REPO")/feat-uncommitted-tracked"
printf 'modified\n' > "$UNCOM_WT/tracked.txt"
if (cd "$UNCOM_WT" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session "done" >/dev/null 2>&1); then
  fail "session done refuses a modified tracked file"
else
  ok "session done refuses a modified tracked file"
fi
if [[ -d "$UNCOM_WT" ]]; then ok "worktree survives a refused session done (modified tracked file)"
else fail "worktree survives a refused session done (modified tracked file)"; fi
rm -rf "$UNCOM_REPO"

# Staged new file: 'git diff --cached' must catch it.
STAGED_REPO=$(mktemp -d)
git init -q "$STAGED_REPO"
git -C "$STAGED_REPO" commit -q --allow-empty -m init
(cd "$STAGED_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session start feat/uncommitted-staged >/dev/null 2>&1)
STAGED_WT="$SESSION_WORKTREES/$(basename "$STAGED_REPO")/feat-uncommitted-staged"
printf 'new\n' > "$STAGED_WT/staged.txt"
git -C "$STAGED_WT" add staged.txt
if (cd "$STAGED_WT" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session "done" >/dev/null 2>&1); then
  fail "session done refuses a staged new file"
else
  ok "session done refuses a staged new file"
fi
if [[ -d "$STAGED_WT" ]]; then ok "worktree survives a refused session done (staged new file)"
else fail "worktree survives a refused session done (staged new file)"; fi
rm -rf "$STAGED_REPO"

# Gitignored file. The first fix for this bug used plain --porcelain, which
# omits ignored files, and 'git worktree remove' deletes them. A .env is
# gitignored precisely because it is secret, so it exists nowhere else. The fix
# moved the bug from untracked to ignored rather than closing the class.
IGN_REPO=$(mktemp -d)
git init -q "$IGN_REPO"
printf '.env\n' > "$IGN_REPO/.gitignore"
git -C "$IGN_REPO" add .gitignore
git -C "$IGN_REPO" commit -q -m init
(cd "$IGN_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session start feat/ignored >/dev/null 2>&1)
IGN_WT="$SESSION_WORKTREES/$(basename "$IGN_REPO")/feat-ignored"
printf 'SECRET_DB_PASSWORD=hunter2\n' > "$IGN_WT/.env"
if (cd "$IGN_WT" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session "done" >/dev/null 2>&1); then
  fail "session done refuses a gitignored file"
else
  ok "session done refuses a gitignored file"
fi
if [[ -f "$IGN_WT/.env" ]]; then ok "a gitignored secret survives a refused session done"
else fail "a gitignored secret survives a refused session done (THE FILE WAS DELETED)"; fi
rm -rf "$IGN_REPO"

# The tool's own .claude-session marker is gitignored in every worktree, so the
# --ignored guard must exempt it or no session could ever be closed.
CLEAN_REPO=$(mktemp -d)
git init -q "$CLEAN_REPO"
git -C "$CLEAN_REPO" commit -q --allow-empty -m init
(cd "$CLEAN_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session start feat/clean >/dev/null 2>&1)
CLEAN_WT="$SESSION_WORKTREES/$(basename "$CLEAN_REPO")/feat-clean"
if (cd "$CLEAN_WT" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session "done" >/dev/null 2>&1); then
  ok "a clean worktree still closes despite its ignored marker"
else
  fail "a clean worktree still closes despite its ignored marker"
fi
rm -rf "$CLEAN_REPO"

# Untracked new file. This is the case that lost data: 'git diff' and 'git diff
# --cached' are both blind to a file that was never added, so it passed the
# guard, and the '|| ... --force' fallback then overrode git's own refusal to
# remove a worktree holding untracked files. The worktree was deleted, the file
# with it, exit 0, and the index recorded the branch as merged. Writing a file
# and not staging it yet is the most ordinary state in a working session, so
# this was the common path, not an edge case.
UNTRACKED_REPO=$(mktemp -d)
git init -q "$UNTRACKED_REPO"
git -C "$UNTRACKED_REPO" commit -q --allow-empty -m init
(cd "$UNTRACKED_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session start feat/uncommitted-untracked >/dev/null 2>&1)
UNTRACKED_WT="$SESSION_WORKTREES/$(basename "$UNTRACKED_REPO")/feat-uncommitted-untracked"
printf 'irreplaceable\n' > "$UNTRACKED_WT/untracked.txt"
if (cd "$UNTRACKED_WT" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session "done" >/dev/null 2>&1); then
  fail "session done refuses an untracked new file"
else
  ok "session done refuses an untracked new file"
fi
if [[ -f "$UNTRACKED_WT/untracked.txt" ]]; then ok "untracked work survives a refused session done"
else fail "untracked work survives a refused session done (THE FILE WAS DELETED)"; fi
if [[ -d "$UNTRACKED_WT" ]]; then ok "worktree survives a refused session done (untracked new file)"
else fail "worktree survives a refused session done (untracked new file)"; fi
# The refusal must name the offending file, or the user cannot act on it.
out=$( (cd "$UNTRACKED_WT" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session "done" 2>&1) || true)
assert_contains "the refusal names the untracked file" "untracked.txt" "$out"
rm -rf "$UNTRACKED_REPO"
echo ""

# A '|' in any indexed field shifts every awk column after it, so the tool wrote
# rows it could never read back: status said none, done could not close them,
# and session done printed success while the row stayed active forever. git
# itself accepts '|' in a ref name, and "sprint-42 | scoped" is an ordinary plan
# slug, so this needed no adversary.
echo "index delimiter safety"
PIPE_REPO=$(mktemp -d)
git init -q "$PIPE_REPO"
git -C "$PIPE_REPO" commit -q --allow-empty -m init
if (cd "$PIPE_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" branch start 'feat/a|b' >/dev/null 2>&1); then
  fail "branch start rejects a pipe in the branch name"
else
  ok "branch start rejects a pipe in the branch name"
fi
if (cd "$PIPE_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" branch start feat/ok --plan 'sprint | scoped' >/dev/null 2>&1); then
  fail "branch start rejects a pipe in the plan slug"
else
  ok "branch start rejects a pipe in the plan slug"
fi
if (cd "$PIPE_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" session start 'feat/c|d' >/dev/null 2>&1); then
  fail "session start rejects a pipe in the branch name"
else
  ok "session start rejects a pipe in the branch name"
fi
# The rejection must happen before any worktree is created.
if [[ -z "$(find "$TEST_HOME/.claude/worktrees" -name 'feat-c*' 2>/dev/null)" ]]; then
  ok "a rejected session name leaves no orphan worktree"
else fail "a rejected session name leaves no orphan worktree"; fi
# A registered branch must still be readable back, which is what pipes broke.
(cd "$PIPE_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" branch start feat/readable >/dev/null 2>&1)
out=$( (cd "$PIPE_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" branch status) 2>&1)
assert_contains "a registered branch reads back from the index" "feat/readable" "$out"
rm -rf "$PIPE_REPO"
echo ""

# CLAUDE.md is a file the user is told to hand-edit, so its markers get damaged.
# block_install and block_remove both locate the block by scanning for START
# then END; with END missing they deleted everything from START to end of file,
# which is the user's own content, at exit 0.
echo "damaged marker blocks"
DMG_HOME=$(mktemp -d)
mkdir -p "$DMG_HOME/.claude"
printf '<!-- CLAUDE-TEAM:START -->\nstale block, END lost\n# my runbook\n- step one\n' > "$DMG_HOME/.claude/CLAUDE.md"
if CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$DMG_HOME" "$CLI" use akira >/dev/null 2>&1; then
  fail "use refuses a file with an unbalanced marker pair"
else
  ok "use refuses a file with an unbalanced marker pair"
fi
assert_file_has "user content below a damaged block survives" "$DMG_HOME/.claude/CLAUDE.md" "step one"
if CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$DMG_HOME" "$CLI" reset >/dev/null 2>&1; then
  fail "reset refuses a file with an unbalanced marker pair"
else
  ok "reset refuses a file with an unbalanced marker pair"
fi
assert_file_has "user content survives a refused reset" "$DMG_HOME/.claude/CLAUDE.md" "step one"
# Two STARTs is equally unsafe: matching is a substring test, so a marker quoted
# in the user's own prose is indistinguishable from the real one.
printf '<!-- CLAUDE-TEAM:START -->\nA\n<!-- CLAUDE-TEAM:END -->\n<!-- CLAUDE-TEAM:START -->\nB\n<!-- CLAUDE-TEAM:END -->\n' > "$DMG_HOME/.claude/CLAUDE.md"
if CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$DMG_HOME" "$CLI" use akira >/dev/null 2>&1; then
  fail "use refuses a file with duplicated marker pairs"
else
  ok "use refuses a file with duplicated marker pairs"
fi
rm -rf "$DMG_HOME"
echo ""

# Lock breaking. The CLI derives its host field from bash's own HOSTNAME, so
# these fixtures compute it the same way; a mismatch would make every planted
# lock look like it came from another machine and silently change which rule
# applies to it.
LOCK_HOST="${HOSTNAME:-$(uname -n 2>/dev/null || echo unknown)}"

# A PID that is certainly dead: start a child, reap it, then reuse its number.
# Linux and macOS both allocate PIDs increasing, so the number is not reissued
# within the life of this suite.
dead_pid() {
  local p
  sh -c 'exit 0' & p=$!
  wait "$p" 2>/dev/null
  printf '%s\n' "$p"
}

# Breaking a stale lock must have exactly one winner, and the way that is
# achieved is observable: a stale lock is taken over IN PLACE, by renaming its
# owner record aside, and the directory itself is never removed.
#
# Removing the directory is what could not be made safe, whichever way the
# removal was claimed, because removing it frees the lock path and a mkdir can
# land in that gap. Measured at 12 concurrent writers: 'rm -rf' lost updates in 6
# of 30 runs, claiming the removal by renaming the directory aside still lost
# them in 5 of 30, and adding a verify-and-rebuild cut it to 1 in 30. Taking over
# in place measured 0 in 40.
#
# A sentinel file inside the planted lock is what separates the two designs. If
# the lock was taken over in place, the sentinel is still there while the new
# owner holds it. If the directory was deleted and recreated, it is gone.
echo "lock breaking has a single winner"

BREAK_HOME=$(mktemp -d)
mkdir -p "$BREAK_HOME/.claude"
BREAK_MD="$BREAK_HOME/.claude/CLAUDE.md"
BREAK_LOCK="$BREAK_MD.lock"
# About 2 MB, so the new owner holds the lock for long enough to look at. The
# poll below spins in microseconds, so this only has to beat process startup.
break_line=$(printf '%*s' 4096 '' | tr ' ' 'x')
for ((_i = 0; _i < 500; _i++)); do printf '%s\n' "$break_line"; done > "$BREAK_MD"
printf 'keep-this-line\n' >> "$BREAK_MD"
mkdir -p "$BREAK_LOCK"
: > "$BREAK_LOCK/sentinel"
break_dead=$(dead_pid)
printf '%s %s %s\n' "$LOCK_HOST" "$break_dead" "$(date '+%s')" > "$BREAK_LOCK/owner"

( CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$BREAK_HOME" "$CLI" use akira >/dev/null 2>&1 ) &
break_pid=$!
break_saw_takeover=false
break_in_place=false
break_deadline=$((SECONDS + 20))
while (( SECONDS < break_deadline )); do
  break_owner=""
  2>/dev/null read -r break_owner < "$BREAK_LOCK/owner" || true
  # A record that no longer names the planted dead PID means the takeover is
  # done. It is briefly absent mid-claim, which is why emptiness is not the test.
  if [[ -n "$break_owner" && "$break_owner" != *" $break_dead "* ]]; then
    break_saw_takeover=true
    if [[ -e "$BREAK_LOCK/sentinel" ]]; then break_in_place=true; fi
    break
  fi
  # Nothing left to observe once the write has landed. Without this the loop
  # would spin to its deadline on a build that never takes the lock over.
  if grep -qF "CLAUDE-TEAM:START" "$BREAK_MD" 2>/dev/null; then break; fi
done
wait "$break_pid" 2>/dev/null
if [[ "$break_saw_takeover" == true ]]; then
  ok "the takeover was observed, so this test is not vacuous"
else
  fail "the takeover was observed, so this test is not vacuous (never saw the record change)"
fi
if [[ "$break_in_place" == true ]]; then
  ok "a stale lock is taken over in place, never deleted and recreated"
else
  fail "a stale lock is taken over in place, never deleted and recreated"
fi
assert_file_has "the contender still gets the lock and writes" "$BREAK_MD" "CLAUDE-TEAM:START"
assert_file_has "taking over a lock preserves user content"    "$BREAK_MD" "keep-this-line"
if [[ ! -d "$BREAK_LOCK" ]]; then ok "no lock directory remains after a takeover"
else fail "no lock directory remains after a takeover"; fi
break_left=$(find "$BREAK_HOME/.claude" -maxdepth 1 -name 'CLAUDE.md.lock*' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$break_left" == "0" ]]; then ok "a takeover leaves no lock litter beside the target"
else fail "a takeover leaves no lock litter beside the target (found $break_left)"; fi
rm -rf "$BREAK_HOME"

# SIGKILL between the rename and the removal is the one case the traps cannot
# cover, and it leaves an inert '<lock>.dead.<pid>' directory that nothing
# reads. The next break must sweep it, or a machine that crashes under load
# accumulates them beside the user's CLAUDE.md forever.
SWEEP_HOME=$(mktemp -d)
mkdir -p "$SWEEP_HOME/.claude"
SWEEP_MD="$SWEEP_HOME/.claude/CLAUDE.md"
SWEEP_LOCK="$SWEEP_MD.lock"
printf 'keep-this-line\n' > "$SWEEP_MD"
mkdir -p "$SWEEP_LOCK" "$SWEEP_LOCK.dead.999001" "$SWEEP_LOCK.dead.999002/nested"
printf 'leftover owner record\n' > "$SWEEP_LOCK.dead.999001/owner"
printf '%s %s %s\n' "$LOCK_HOST" "$(dead_pid)" "$(date '+%s')" > "$SWEEP_LOCK/owner"
CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$SWEEP_HOME" "$CLI" use akira >/dev/null 2>&1
sweep_left=$(find "$SWEEP_HOME/.claude" -maxdepth 1 -name 'CLAUDE.md.lock.dead.*' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$sweep_left" == "0" ]]; then ok "a break sweeps renamed-aside directories a killed winner left behind"
else fail "a break sweeps renamed-aside directories a killed winner left behind (found $sweep_left)"; fi
assert_file_has "the write still lands alongside the sweep" "$SWEEP_MD" "CLAUDE-TEAM:START"
rm -rf "$SWEEP_HOME"
echo ""

# Liveness must outrank the age rule. The 120-second age test used to run first
# and independently of kill -0, so a live holder that had been paused lost a lock
# it still held and both writers then reported success on a write only one of
# them kept. SIGSTOP, a laptop suspend mid-command, and a clock stepping forward
# all produce exactly that state.
echo "liveness outranks the lock age rule"

LIVE_HOME=$(mktemp -d)
mkdir -p "$LIVE_HOME/.claude"
LIVE_MD="$LIVE_HOME/.claude/CLAUDE.md"
LIVE_LOCK="$LIVE_MD.lock"
printf 'keep-this-line\n' > "$LIVE_MD"
mkdir -p "$LIVE_LOCK"
sleep 30 &
live_holder=$!
# Acquired far beyond LOCK_STALE_SECONDS, by a process that is still running.
printf '%s %s %s\n' "$LOCK_HOST" "$live_holder" "$(( $(date '+%s') - 100000 ))" > "$LIVE_LOCK/owner"
( CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$LIVE_HOME" "$CLI" use akira >/dev/null 2>&1 ) &
live_contender=$!
# One second is twenty poll intervals. The age-first order broke this lock on
# the first one.
sleep 1
if [[ -d "$LIVE_LOCK" ]] && [[ "$(cat "$LIVE_LOCK/owner" 2>/dev/null)" == *" $live_holder "* ]]; then
  ok "an ancient lock held by a live PID is not broken"
else
  fail "an ancient lock held by a live PID is not broken (the contender took it)"
fi
assert_file_lacks "the contender writes nothing while a live holder holds the lock" \
  "$LIVE_MD" "CLAUDE-TEAM:START"
kill "$live_contender" 2>/dev/null
wait "$live_contender" 2>/dev/null
kill "$live_holder" 2>/dev/null
wait "$live_holder" 2>/dev/null
rm -rf "$LIVE_HOME"

# The age rule still has to work where liveness cannot be established, which is
# the case it exists for: a lock recorded by another host, as happens when $HOME
# is shared over NFS and that machine crashed. The PID here is deliberately a
# LIVE one, so this fails if the host check ever stops gating the kill -0.
FOREIGN_HOME=$(mktemp -d)
mkdir -p "$FOREIGN_HOME/.claude"
FOREIGN_MD="$FOREIGN_HOME/.claude/CLAUDE.md"
printf 'keep-this-line\n' > "$FOREIGN_MD"
mkdir -p "$FOREIGN_MD.lock"
printf 'some-other-host %s %s\n' "$$" "$(( $(date '+%s') - 100000 ))" > "$FOREIGN_MD.lock/owner"
if CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$FOREIGN_HOME" "$CLI" use akira >/dev/null 2>&1; then
  ok "an ancient lock from another host is still broken by the age rule"
else
  fail "an ancient lock from another host is still broken by the age rule"
fi
assert_file_has "the write lands after breaking another host's ancient lock" \
  "$FOREIGN_MD" "CLAUDE-TEAM:START"
rm -rf "$FOREIGN_HOME"
# Shared-state concurrency. ~/.claude/branches/INDEX.md and ~/.claude/CLAUDE.md
# are shared by every session on the machine, so two sessions finishing at once
# must not lose each other's writes.
#
# This used to be a 12-writer storm against a planted stale lock, with CPU
# pressure, built to prove the locking rewrite under hostile conditions. It did
# that, and then cost 113 lines and most of the suite's runtime forever after.
# The realistic case is two or three parallel sessions, which is what this
# covers now. The lock implementation is unchanged; only the harness shrank.
echo "shared-state concurrency"

CONC_HOME=$(mktemp -d)
CONC_INDEX="$CONC_HOME/.claude/branches/INDEX.md"
mkdir -p "$CONC_HOME/.claude"
CONC_ROOT=$(mktemp -d)
for i in 1 2 3; do
  git init -q "$CONC_ROOT/r$i"
  (cd "$CONC_ROOT/r$i" && git commit -q --allow-empty -m init)
done
for i in 1 2 3; do
  (cd "$CONC_ROOT/r$i" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$CONC_HOME" "$CLI" branch start "feat/c$i" >/dev/null 2>&1) &
done
wait
assert_count    "concurrent writers keep every row"  "$CONC_INDEX" '^| 2'      3
assert_file_has "concurrent writers keep the header" "$CONC_INDEX" "Branch Index"
if [[ ! -d "$CONC_INDEX.lock" ]]; then ok "no lock directory remains after success"
else fail "no lock directory remains after success"; fi
rm -rf "$CONC_ROOT"

# CLAUDE.md holds two independent marker blocks written by different commands.
# The duplicate-block count is the assertion that matters: block_install greps
# for its start marker, misses it against an unlanded concurrent write, and
# takes the append path, producing a second copy.
CONC_MD="$CONC_HOME/.claude/CLAUDE.md"
printf 'keep-this-line\n' > "$CONC_MD"
for _ in 1 2 3; do
  (CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$CONC_HOME" "$CLI" use akira >/dev/null 2>&1) &
  (CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$CONC_HOME" "$CLI" coordinator on >/dev/null 2>&1) &
done
wait
assert_count "concurrent writers leave one team block"        "$CONC_MD" "CLAUDE-TEAM:START"        1
assert_count "concurrent writers leave one coordinator block" "$CONC_MD" "CLAUDE-COORDINATOR:START" 1
assert_count "concurrent writers keep user content"           "$CONC_MD" "keep-this-line"           1
rm -rf "$CONC_HOME"
echo ""

# Temp files must be created beside their destination, not in TMPDIR. A
# cross-device rename degrades to copy plus unlink, during which a reader can
# see a half-written index. An unusable TMPDIR proves the temp file is not
# there: bare mktemp cannot create a file at all under this setting.
echo "writes do not depend on TMPDIR"

TMP_HOME=$(mktemp -d)
mkdir -p "$TMP_HOME/.claude"
TMP_REPO=$(mktemp -d)
git init -q "$TMP_REPO"
(cd "$TMP_REPO" && git commit -q --allow-empty -m init)
run_notmp() {
  TMPDIR=/nonexistent-tmpdir CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TMP_HOME" "$CLI" "$@"
}
if run_notmp use akira >/dev/null 2>&1; then ok "use works when TMPDIR is unusable"
else fail "use works when TMPDIR is unusable"; fi
if run_notmp reset >/dev/null 2>&1; then ok "reset works when TMPDIR is unusable"
else fail "reset works when TMPDIR is unusable"; fi
if run_notmp coordinator on >/dev/null 2>&1; then ok "coordinator on works when TMPDIR is unusable"
else fail "coordinator on works when TMPDIR is unusable"; fi
if (cd "$TMP_REPO" && TMPDIR=/nonexistent-tmpdir CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TMP_HOME" "$CLI" branch start feat/notmp >/dev/null 2>&1); then
  ok "branch start works when TMPDIR is unusable"
else fail "branch start works when TMPDIR is unusable"; fi
# "done" is quoted throughout this suite so shellcheck does not read it as a
# loop terminator (SC1010).
if (cd "$TMP_REPO" && TMPDIR=/nonexistent-tmpdir CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TMP_HOME" "$CLI" branch "done" >/dev/null 2>&1); then
  ok "branch done works when TMPDIR is unusable"
else fail "branch done works when TMPDIR is unusable"; fi
if [[ -z "$(find "$TMP_HOME" -name '.claude-team.*' 2>/dev/null)" ]]; then
  ok "no temp file litter left in ~/.claude"
else fail "no temp file litter left in ~/.claude"; fi
rm -rf "$TMP_HOME" "$TMP_REPO"
echo ""

# An interrupted write must not leave its temp file behind. tmp_beside documents
# that it registers the file in _TMP_FILE for the cleanup traps, but every caller
# read it as tmp=$(tmp_beside ...), and command substitution runs the function in
# a subshell: the assignment landed in a child that then exited, the parent's
# _TMP_FILE stayed empty, and _cleanup could never remove anything. Reproduced as
# a 150 MB orphan beside CLAUDE.md after a SIGINT mid-rewrite.
echo "an interrupted write leaves no temp file behind"

INT_HOME=$(mktemp -d)
mkdir -p "$INT_HOME/.claude"
INT_MD="$INT_HOME/.claude/CLAUDE.md"
# A CLAUDE.md of about 8 MB. Bash defers a trap until the foreground child it is
# waiting on returns, so the signal only has to arrive before the rename, not
# inside a narrow window; the size is what makes the copy into the temp file long
# enough for that to be comfortable rather than tight.
int_line=$(printf '%*s' 4096 '' | tr ' ' 'x')
for ((_i = 0; _i < 2000; _i++)); do printf '%s\n' "$int_line"; done > "$INT_MD"

( CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$INT_HOME" "$CLI" use akira >/dev/null 2>&1 ) &
int_pid=$!
int_saw_tmp=false
int_deadline=$((SECONDS + 20))
while (( SECONDS < int_deadline )); do
  for _t in "$INT_HOME/.claude"/.claude-team.*; do
    if [[ -f "$_t" ]]; then int_saw_tmp=true; break 2; fi
  done
  if grep -qF "CLAUDE-TEAM:START" "$INT_MD" 2>/dev/null; then break; fi
done
if [[ "$int_saw_tmp" == true ]]; then
  kill -INT "$int_pid" 2>/dev/null
  ok "the temp file window was observed, so this test is not vacuous"
else
  fail "the temp file window was observed, so this test is not vacuous (the write finished first: enlarge the fixture)"
fi
wait "$int_pid" 2>/dev/null
# Assert what the design actually guarantees, which is that a reader sees the
# whole old file or the whole new one, never a partial write. Whether the rename
# beat the signal is timing, not correctness: seeing the temp file appear does
# not prove the signal arrived before tmp_commit, because the rename can land in
# the microseconds between the two. An earlier version asserted the write had
# not landed and failed on macOS for exactly that reason, where process spawn is
# slower and the window sits differently.
int_starts=$(grep -cF "CLAUDE-TEAM:START" "$INT_MD" 2>/dev/null || true)
int_ends=$(grep -cF "CLAUDE-TEAM:END" "$INT_MD" 2>/dev/null || true)
if [[ "$int_starts" == "$int_ends" && ( "$int_starts" == "0" || "$int_starts" == "1" ) ]]; then
  ok "an interrupted write leaves the file coherent, not half-written"
else
  fail "an interrupted write leaves the file coherent, not half-written ($int_starts start, $int_ends end)"
fi
# The user's own content must survive either outcome.
assert_count "an interrupted write preserves every user line" "$INT_MD" "^$int_line$" 2000
int_orphans=$(find "$INT_HOME/.claude" -maxdepth 1 -name '.claude-team.*' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$int_orphans" == "0" ]]; then ok "SIGINT mid-write leaves no temp file beside the target"
else fail "SIGINT mid-write leaves no temp file beside the target (found $int_orphans)"; fi
rm -rf "$INT_HOME"
echo ""

# launch + plugin surfaces
echo "launch + plugin surfaces"

# Tier assertions alone do not prove WHICH profile launch resolved: the model
# comes from a separate tiers.conf lookup keyed on the same name, so a launch
# that silently loaded the wrong persona's profile (a copy-paste bug, a stale
# alias table, anything that decouples the two lookups) would still show the
# right tier. Pin the printed --append-system-prompt-file path to the
# requested persona's own file too.
out=$(run_cmd launch akira --dry-run 2>&1)
assert_contains "launch akira defaults to fable tier" "claude-fable-5" "$out"
assert_contains "launch dry-run shows append-system-prompt-file" "append-system-prompt-file" "$out"
assert_contains "launch akira points at akira's own profile" "$PROFILES_DIR/akira\.md" "$out"

out=$(run_cmd launch robin --dry-run 2>&1)
assert_contains "launch robin defaults to sonnet tier" "claude-sonnet-5" "$out"
assert_contains "launch robin points at robin's own profile" "$PROFILES_DIR/robin\.md" "$out"

out=$(run_cmd launch sage --dry-run 2>&1)
assert_contains "launch sage defaults to fable tier" "claude-fable-5" "$out"
assert_contains "launch sage points at sage's own profile" "$PROFILES_DIR/sage\.md" "$out"

out=$(run_cmd launch toni --dry-run 2>&1)
assert_contains "launch toni defaults to opus tier" "claude-opus-4-8" "$out"
assert_contains "launch toni points at toni's own profile" "$PROFILES_DIR/toni\.md" "$out"

out=$(run_cmd launch akira --model claude-haiku-4-5 --dry-run 2>&1)
assert_contains "launch --model overrides tier default" "claude-haiku-4-5" "$out"

out=$(run_cmd launch akira --task "review the auth flow" --dry-run 2>&1)
assert_contains "launch --task appends initial prompt" "review.*auth.*flow" "$out"

out=$(run_cmd launch nobody --dry-run 2>&1) || true
assert_contains "launch unknown persona errors" "No profile found" "$out"
echo ""

# launch --worktree: creates the session's worktree on demand, then execs
# inside it. Before this block, no test -- dry-run or real -- exercised the
# flag at all. A stub 'claude' placed first on PATH captures the real
# (non-dry-run) exec so the worktree-creation side effect and the final argv
# can both be checked, without ever invoking the real Claude Code CLI.
echo "launch --worktree"

LAUNCH_NOGIT=$(mktemp -d)
if (cd "$LAUNCH_NOGIT" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" launch akira --worktree feat/x --dry-run >/dev/null 2>&1); then
  fail "launch --worktree outside a git repo dies"
else
  ok "launch --worktree outside a git repo dies"
fi
rm -rf "$LAUNCH_NOGIT"

LAUNCH_REPO=$(mktemp -d)
git init -q "$LAUNCH_REPO"
git -C "$LAUNCH_REPO" commit -q --allow-empty -m init
LAUNCH_WT="$TEST_HOME/.claude/worktrees/$(basename "$LAUNCH_REPO")/feat-launch-wt"

out=$(cd "$LAUNCH_REPO" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" launch akira --worktree feat/launch-wt --dry-run 2>&1)
assert_contains "launch --worktree dry-run reports the worktree would be created" "would create worktree" "$out"
assert_contains "launch --worktree dry-run targets the worktree dir, not \$PWD" "$LAUNCH_WT" "$out"
if [[ -d "$LAUNCH_WT" ]]; then fail "launch --worktree dry-run has no side effect"; else ok "launch --worktree dry-run has no side effect"; fi

FAKE_CLAUDE_DIR=$(mktemp -d)
cat > "$FAKE_CLAUDE_DIR/claude" <<'STUB'
#!/usr/bin/env bash
echo "FAKE-CLAUDE-INVOKED cwd=$PWD"
printf 'FAKE-CLAUDE-ARG: %s\n' "$@"
STUB
chmod +x "$FAKE_CLAUDE_DIR/claude"

out=$(cd "$LAUNCH_REPO" && PATH="$FAKE_CLAUDE_DIR:$PATH" CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" launch akira --worktree feat/launch-wt 2>&1)
assert_contains "launch --worktree really creates the worktree and execs there" "FAKE-CLAUDE-INVOKED cwd=$LAUNCH_WT" "$out"
assert_contains "launch --worktree execs with the requested persona's profile" "FAKE-CLAUDE-ARG: $PROFILES_DIR/akira.md" "$out"

# A second launch for the same branch must reuse the worktree already made,
# not call session start again -- that would hit "already has an active
# session" and die, taking the whole launch down with it.
if out2=$(cd "$LAUNCH_REPO" && PATH="$FAKE_CLAUDE_DIR:$PATH" CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TEST_HOME" "$CLI" launch akira --worktree feat/launch-wt 2>&1); then
  ok "launch --worktree reuses an existing worktree on a second call"
else
  fail "launch --worktree reuses an existing worktree on a second call"
fi
assert_contains "reused launch --worktree still execs in the same worktree" "FAKE-CLAUDE-INVOKED cwd=$LAUNCH_WT" "$out2"
assert_count "launch --worktree registers the branch exactly once" "$BRANCHES_INDEX" "feat/launch-wt" 1

rm -rf "$LAUNCH_REPO" "$FAKE_CLAUDE_DIR"
echo ""

if command -v python3 >/dev/null 2>&1; then
  if python3 -c "import json; json.load(open('$REPO_DIR/.claude-plugin/plugin.json'))" 2>/dev/null; then
    ok "plugin.json is valid JSON"
  else
    fail "plugin.json is valid JSON"
  fi
  if python3 -c "import json; d=json.load(open('$REPO_DIR/hooks/hooks.json')); assert 'SessionStart' in d['hooks']" 2>/dev/null; then
    ok "hooks.json is valid and registers SessionStart"
  else
    fail "hooks.json is valid and registers SessionStart"
  fi
else
  # A silent 'if command -v python3' guard with no else shrinks PASS+FAIL by
  # two on a python3-less machine with no indication why: the count just
  # differs from what CI reports, and nothing says these two checks did not
  # run. Both CI runners ship python3, so this branch never fires there; it
  # exists so a contributor on a minimal local machine sees a reason instead
  # of a smaller, unexplained number.
  printf "  \033[33m!\033[0m skipped (no python3): plugin.json / hooks.json JSON validity\n"
fi

# Count the personas rather than hardcoding a number. A literal 17 here would
# make every roster assertion below fail the day an eighteenth persona lands,
# which is the same hand-maintained-list problem these tests exist to catch.
PERSONA_COUNT=0
for _p in "$REPO_DIR"/profiles/*.md; do
  case "$(basename "$_p" .md)" in coordinator*) continue ;; esac
  PERSONA_COUNT=$((PERSONA_COUNT + 1))
done
agent_files=("$REPO_DIR"/agents/*.md)
agent_count=${#agent_files[@]}
[[ -e "${agent_files[0]}" ]] || agent_count=0
if [[ "$agent_count" == "$PERSONA_COUNT" ]]; then ok "every persona has a generated subagent"
else fail "every persona has a generated subagent (expected $PERSONA_COUNT, got $agent_count)"; fi
# description: is the field Claude Code reads to pick a subagent for automatic
# delegation. Collapsing it to one identical string across all seventeen would
# silently disable meaningful delegation, and a regenerate-and-diff check cannot
# see it: the generator would agree with itself. Only a content assertion can.
descdrift=""
while IFS=$'\t' read -r slug display _role; do
  grep -q "^description: $display," "$REPO_DIR/agents/$slug.md" || descdrift="$descdrift $slug"
done < <(
  for _pf in "$REPO_DIR"/profiles/*.md; do
    _sl=$(basename "$_pf" .md)
    case "$_sl" in coordinator*) continue ;; esac
    _ti=$(grep -m1 '^# ' "$_pf" | sed 's/^# //')
    printf '%s\t%s\t%s\n' "$_sl" "${_ti%% —*}" "${_ti#*— }"
  done
)
if [[ -z "$descdrift" ]]; then ok "each subagent description names its own persona"
else fail "each subagent description names its own persona (wrong:$descdrift)"; fi
assert_contains "akira agent carries model tier" "model: claude-fable-5" "$(cat "$REPO_DIR/agents/akira.md")"
assert_contains "iris agent carries model tier" "model: claude-opus-4-8" "$(cat "$REPO_DIR/agents/iris.md")"
assert_contains "agents marked as generated" "GENERATED from profiles" "$(cat "$REPO_DIR/agents/robin.md")"

# Regeneration drift. CI never runs generate-agents.sh by hand, so a profile
# edited without a resync, or a generated file hand-edited independent of its
# profile, must be caught here.
#
# The previous check re-implemented the generator's own stripping logic a
# second time, by hand, in this file, to predict what each generated file
# should contain, then tested that the profile's text was a SUBSET of it. Two
# things follow from "subset": extra or wrong content the generator (or a
# stray hand-edit) adds is invisible to it, and the prediction has to be kept
# in sync with the generator by hand forever. That second property is what let
# this same check assert a missing Handoff Brief section as correct: its
# hand-written awk mirrored the generator's own bug instead of the
# requirement.
#
# This regenerates every agent and slash command from the committed profiles
# into a scratch tree with the real generator, then diffs each one against the
# committed copy. It catches both directions of drift and cannot mirror a bug
# the generator does not have, because it IS the generator, not a second
# implementation of it. What it structurally cannot catch is the opposite
# failure: a generator whose transform is wrong but internally consistent, so
# a fresh regeneration reproduces the same wrong output already committed.
# That needs a content assertion instead, which is what the Handoff Brief
# presence checks below are.
REGEN_DIR=$(mktemp -d)
cp -R "$REPO_DIR"/profiles "$REPO_DIR"/scripts "$REGEN_DIR/"
if bash "$REGEN_DIR/scripts/generate-agents.sh" >/dev/null 2>&1; then
  ok "generate-agents.sh runs clean against the committed profiles"
else
  fail "generate-agents.sh runs clean against the committed profiles"
fi
stale=""
for profile in "$REPO_DIR"/profiles/*.md; do
  pname=$(basename "$profile" .md)
  case "$pname" in coordinator*) continue ;; esac
  if ! diff -q "$REPO_DIR/agents/$pname.md" "$REGEN_DIR/agents/$pname.md" >/dev/null 2>&1; then
    stale="$stale $pname(agent)"
  fi
  if ! diff -q "$REPO_DIR/commands/$pname.md" "$REGEN_DIR/commands/$pname.md" >/dev/null 2>&1; then
    stale="$stale $pname(command)"
  fi
done
if [[ -z "$stale" ]]; then ok "generated agents and commands match a fresh regeneration"
else fail "generated agents and commands match a fresh regeneration (stale:$stale)"; fi
rm -rf "$REGEN_DIR"

# The greeting is a persona-switch line ("Greet the user briefly as Robin"). A
# delegated subagent never switches the session, so it must not carry one.
if grep -q '^## Greeting$' "$REPO_DIR"/agents/*.md; then
  fail "greeting excluded from generated agents"
else
  ok "greeting excluded from generated agents"
fi

# The coordinator tells a user to run /<name> at the moment of a handoff, then
# asks that persona for a Handoff Brief. For years the brief lived inside
# Required Interactive Behaviors, which the slash command excises, so the
# persona being asked had never been told what one is. All four delivery
# surfaces must carry it.
hcount=$(grep -l '^## Handoff Brief$' "$REPO_DIR"/commands/*.md 2>/dev/null | wc -l | tr -d ' ')
assert_count_eq() { if [[ "$2" == "$3" ]]; then ok "$1"; else fail "$1 (expected $3, got $2)"; fi; }
assert_count_eq "every slash command carries the handoff brief" "$hcount" "$PERSONA_COUNT"
hcount=$(grep -l '^## Handoff Brief$' "$REPO_DIR"/agents/*.md 2>/dev/null | wc -l | tr -d ' ')
assert_count_eq "every subagent still carries the handoff brief" "$hcount" "$PERSONA_COUNT"
hcount=$(grep -l '^## Handoff Brief$' "$REPO_DIR"/profiles/*.md 2>/dev/null | wc -l | tr -d ' ')
assert_count_eq "every persona profile defines a handoff brief" "$hcount" "$PERSONA_COUNT"
run_cmd use akira >/dev/null 2>&1
assert_file_has "use carries the handoff brief into the global pin" "$CLAUDE_MD" "^## Handoff Brief"
run_cmd reset >/dev/null 2>&1

# A profile with no ## Handoff Brief would leave the stripper skipping to EOF,
# silently dropping every later section from the slash command. Generation must
# stop instead.
HB_REPO=$(mktemp -d)
cp -R "$REPO_DIR"/profiles "$REPO_DIR"/scripts "$HB_REPO/"
sed -i.bak '/^## Handoff Brief$/d' "$HB_REPO/profiles/akira.md" && rm -f "$HB_REPO/profiles/akira.md.bak"
if bash "$HB_REPO/scripts/generate-agents.sh" >/dev/null 2>&1; then
  fail "generator refuses a profile with no handoff brief"
else
  ok "generator refuses a profile with no handoff brief"
fi
rm -rf "$HB_REPO"

# team-session-start hook behavior
HOOK="$REPO_DIR/bin/team-session-start"
NOGIT_DIR=$(mktemp -d)
out=$(printf '{"session_id":"t1","cwd":"%s"}' "$NOGIT_DIR" | HOME="$TEST_HOME" "$HOOK")
if [[ -z "$out" ]]; then ok "session-start hook silent outside git repo"; else fail "session-start hook silent outside git repo"; fi
rm -rf "$NOGIT_DIR"

HOOK_REPO=$(mktemp -d)
git init -q "$HOOK_REPO" 2>/dev/null
out=$(printf '{"session_id":"t2","cwd":"%s"}' "$HOOK_REPO" | HOME="$TEST_HOME" "$HOOK")
assert_contains "session-start hook emits project context in repo" "Claude Team session context" "$out"

printf 'project=demo\nbranch=feat/hooked\n' > "$HOOK_REPO/.claude-session"
out=$(printf '{"session_id":"t3","cwd":"%s"}' "$HOOK_REPO" | HOME="$TEST_HOME" "$HOOK")
assert_contains "session-start hook detects worktree session" "feat/hooked" "$out"
rm -rf "$HOOK_REPO"

echo ""

# claude-team sync: a persona lives as three self-contained installed files, and
# the profile is the only one a human edits. One profile edit must reach the
# installed profile, the regenerated subagent, and the regenerated slash command.
# Runs against a throwaway clone so the edits never touch the real repo.
echo "claude-team sync"

SYNC_REPO=$(mktemp -d)
SYNC_HOME=$(mktemp -d)
cp -R "$REPO_DIR"/profiles "$REPO_DIR"/commands "$REPO_DIR"/agents \
      "$REPO_DIR"/scripts "$REPO_DIR"/bin "$SYNC_REPO/"
# Insert above ## Greeting, not at end of file: the greeting is the slash command
# trailer, and everything under that heading is excised from the other two copies.
awk '/^## Greeting$/ { print "SYNC-PROFILE-MARKER"; print "" } { print }' \
    "$SYNC_REPO/profiles/robin.md" > "$SYNC_REPO/profiles/robin.md.new"
mv "$SYNC_REPO/profiles/robin.md.new" "$SYNC_REPO/profiles/robin.md"

if HOME="$SYNC_HOME" bash "$SYNC_REPO/bin/claude-team" sync >/dev/null 2>&1; then
  ok "claude-team sync runs clean"
else
  fail "claude-team sync runs clean"
fi
assert_file_has "sync propagates a profile edit to the installed profile" \
  "$SYNC_HOME/.claude/team/robin.md" "SYNC-PROFILE-MARKER"
assert_file_has "sync regenerates the subagent from the edited profile" \
  "$SYNC_HOME/.claude/agents/robin.md" "SYNC-PROFILE-MARKER"
assert_file_has "sync regenerates the slash command from the edited profile" \
  "$SYNC_HOME/.claude/commands/robin.md" "SYNC-PROFILE-MARKER"
assert_file_has "sync installs tiers.conf" "$SYNC_HOME/.claude/team/tiers.conf" "akira"
# Three green checkmarks read as "all three are live now". Only the slash
# commands are: Claude Code registers subagents and hooks at session start.
out=$(HOME="$SYNC_HOME" bash "$SYNC_REPO/bin/claude-team" sync 2>&1)
assert_contains "sync says slash commands are live now"        "No restart needed" "$out"
assert_contains "sync says subagents wait for a new session"   "Next session"      "$out"
rm -rf "$SYNC_REPO" "$SYNC_HOME"

# A sync that fails part-way must say so. Measured on the unchecked version:
# 'set -e' already stopped it and already exited 1, so the exit code and the
# stopping were never the problem. What the user got was a raw 'cp: cannot
# overwrite directory' line, a green checkmark on the batch that HAD landed, and
# nothing naming the state that leaves behind: profiles new, subagents and slash
# commands still on the previous version. That divergence is the one thing this
# command exists to prevent and the one thing nothing else warns about.
#
# So of the assertions below, the three message checks are the real regression
# controls; the exit code and the stop-before-the-next-surface checks already
# held and are kept to pin them against a future '|| true'.
#
# The failure is forced with a DIRECTORY sitting where a file has to land, which
# fails for root too. A chmod would not: this suite may run as root, and there
# the permission bits are advisory, so a chmod-based fixture would pass
# vacuously on exactly the machine most likely to run it.
SYNCFAIL_REPO=$(mktemp -d)
SYNCFAIL_HOME=$(mktemp -d)
cp -R "$REPO_DIR"/profiles "$REPO_DIR"/commands "$REPO_DIR"/agents \
      "$REPO_DIR"/scripts "$REPO_DIR"/bin "$SYNCFAIL_REPO/"
mkdir -p "$SYNCFAIL_HOME/.claude/agents/robin.md"
if out=$(HOME="$SYNCFAIL_HOME" bash "$SYNCFAIL_REPO/bin/claude-team" sync 2>&1); then
  fail "sync exits nonzero when a surface cannot be copied"
else
  ok "sync exits nonzero when a surface cannot be copied"
fi
assert_contains "the sync failure names the divergence"    "surfaces may now hold different versions" "$out"
assert_contains "the sync failure says rerunning heals it" "rerun" "$out"
assert_contains "the sync failure names the failing copy"  "Failed to copy subagents" "$out"
# Stopping is the point: continuing is what produced the divergence silently.
assert_not_contains "a failed sync stops before the next surface" "Slash commands synced" "$out"
if [[ ! -f "$SYNCFAIL_HOME/.claude/commands/robin.md" ]]; then
  ok "a failed sync does not go on to install the later surface"
else
  fail "a failed sync does not go on to install the later surface"
fi
rm -rf "$SYNCFAIL_REPO" "$SYNCFAIL_HOME"

echo ""

# Messaging accuracy. Nothing asserted any of these strings before, so a
# checkmark could claim a capability that is not live yet and CI stayed green.
echo "session-scope messaging"

out=$(run_cmd install-hook 2>&1)
assert_contains "install-hook says the hook starts next session" "next Claude Code session" "$out"
out=$(run_cmd install-commands 2>&1)
assert_contains "install-commands still promises immediacy" "No new session required" "$out"
out=$(run_cmd use robin 2>&1)
assert_contains "use still asks for a new session" "Start a new Claude Code session" "$out"
run_cmd reset >/dev/null 2>&1
assert_file_has "installer names the restart requirement" "$REPO_DIR/install.sh" "Start a new Claude Code session"
assert_file_lacks "installer no longer claims the team is ready" "$REPO_DIR/install.sh" "dev team is ready"
echo ""

# install.sh end to end into an isolated HOME: files land where the CLI
# expects them, and the coordinator prompt delegates to the CLI code path.
#
# Runs from a throwaway copy of the repo, never from REPO_DIR. install.sh
# delegates to 'claude-team sync', which resolves its repo directory from the
# CLI's own path and regenerates agents/ and commands/ there. Run against the
# real clone, the suite rewrote its own tracked files: a genuine drift would
# fail the regeneration check earlier in this file and then be silently
# repaired here, so a second run came back green with nothing fixed.
echo "install.sh"

INSTALL_REPO=$(mktemp -d)
cp -R "$REPO_DIR"/profiles "$REPO_DIR"/commands "$REPO_DIR"/agents \
      "$REPO_DIR"/scripts "$REPO_DIR"/bin "$REPO_DIR"/install.sh "$INSTALL_REPO/"
INSTALL_HOME=$(mktemp -d)
if (cd "$INSTALL_REPO" && echo "n" | HOME="$INSTALL_HOME" bash install.sh >/dev/null 2>&1); then
  ok "install.sh runs clean with coordinator skipped"
else
  fail "install.sh runs clean with coordinator skipped"
fi
if [[ -f "$INSTALL_HOME/.claude/team/robin.md" ]]; then ok "install.sh installs profiles"; else fail "install.sh installs profiles"; fi
if [[ -f "$INSTALL_HOME/.claude/team/tiers.conf" ]]; then ok "install.sh installs tiers.conf"; else fail "install.sh installs tiers.conf"; fi
if [[ -f "$INSTALL_HOME/.claude/commands/robin.md" ]]; then ok "install.sh installs slash commands"; else fail "install.sh installs slash commands"; fi
if [[ -f "$INSTALL_HOME/.claude/agents/robin.md" ]]; then ok "install.sh installs subagents"; else fail "install.sh installs subagents"; fi
if [[ -L "$INSTALL_HOME/.local/bin/claude-team" ]]; then ok "install.sh symlinks the CLI"; else fail "install.sh symlinks the CLI"; fi
assert_file_has "install.sh registers the SessionStart hook" \
  "$INSTALL_HOME/.claude/settings.json" "team-session-start"
if ! grep -qF "CLAUDE-COORDINATOR:START" "$INSTALL_HOME/.claude/CLAUDE.md" 2>/dev/null; then
  ok "install.sh skips coordinator when told no"
else
  fail "install.sh skips coordinator when told no"
fi

if (cd "$INSTALL_REPO" && echo "prod" | HOME="$INSTALL_HOME" bash install.sh >/dev/null 2>&1); then
  ok "install.sh runs clean with coordinator prod"
else
  fail "install.sh runs clean with coordinator prod"
fi
assert_file_has "install.sh prod answer installs prod coordinator" "$INSTALL_HOME/.claude/CLAUDE.md" "CLAUDE-COORD-MODE: prod"
# install.sh above ran twice. The hook entry must be replaced, not stacked,
# or a reinstall would fire the hook once per install ever run.
hookrefs=$(grep -c "team-session-start" "$INSTALL_HOME/.claude/settings.json" 2>/dev/null || echo 0)
if [[ "$hookrefs" == "1" ]]; then
  ok "reinstall does not duplicate the SessionStart hook"
else
  fail "reinstall does not duplicate the SessionStart hook (found $hookrefs)"
fi

# The coordinator prompt used a bare 'read', which returns non-zero at end of
# file, and under 'set -e' that ended the installer right there: exit 1, no
# summary, coordinator unconfigured, and every earlier step already applied.
# 'bash install.sh < /dev/null' is what CI and any pipe look like.
EOF_HOME=$(mktemp -d)
if eof_out=$( (cd "$INSTALL_REPO" && HOME="$EOF_HOME" bash install.sh < /dev/null) 2>&1 ); then
  ok "install.sh exits 0 with stdin at end of file"
else
  fail "install.sh exits 0 with stdin at end of file"
fi
assert_contains "a non-interactive install still reaches its summary" "Done!" "$eof_out"
if [[ -f "$EOF_HOME/.claude/team/robin.md" ]]; then ok "a non-interactive install still installs profiles"
else fail "a non-interactive install still installs profiles"; fi
# End of file means nobody is present to consent, and the casual path writes a
# block into the user's own global CLAUDE.md. Skipping is the safe reading.
# This one also held before the fix, for the wrong reason: the installer died at
# the prompt and so never reached the coordinator either way. The assertions that
# actually separate the two are the exit code and the summary above.
if ! grep -qF "CLAUDE-COORDINATOR:START" "$EOF_HOME/.claude/CLAUDE.md" 2>/dev/null; then
  ok "end of file skips the coordinator instead of editing the global CLAUDE.md"
else
  fail "end of file skips the coordinator instead of editing the global CLAUDE.md"
fi
assert_contains "the installer says why it skipped the coordinator" "end of file" "$eof_out"
rm -rf "$EOF_HOME"

# Pressing Enter is a person choosing the default, and must still mean casual.
# Treating end of file as the default is what this separates it from.
ENTER_HOME=$(mktemp -d)
if (cd "$INSTALL_REPO" && printf '\n' | HOME="$ENTER_HOME" bash install.sh >/dev/null 2>&1); then
  ok "install.sh runs clean when the coordinator prompt gets a bare Enter"
else
  fail "install.sh runs clean when the coordinator prompt gets a bare Enter"
fi
assert_file_has "a bare Enter still means casual" "$ENTER_HOME/.claude/CLAUDE.md" "CLAUDE-COORD-MODE: casual"
rm -rf "$ENTER_HOME"

rm -rf "$INSTALL_HOME" "$INSTALL_REPO"

echo ""

# sync only ever copies. Deleting or renaming a persona in the clone therefore
# leaves its three installed files behind, and the roster is read from the
# installed profiles rather than from the repo, so the removed persona keeps
# appearing in 'claude-team list' and its '/<name>' command keeps resolving.
#
# Runs from a throwaway copy of the repo, never REPO_DIR, for the reason given
# in the install.sh block above: sync resolves its repo directory from the CLI's
# own path and regenerates agents/ and commands/ there, so running it against the
# real clone would rewrite this repo's own tracked files.
echo "sync reports personas left behind by a delete or rename"

SYNC_REPO=$(mktemp -d)
cp -R "$REPO_DIR"/profiles "$REPO_DIR"/commands "$REPO_DIR"/agents \
      "$REPO_DIR"/scripts "$REPO_DIR"/bin "$SYNC_REPO/"
SYNC_HOME=$(mktemp -d)
SYNC_CLI="$SYNC_REPO/bin/claude-team"
# HOME only, with no CLAUDE_TEAM_PROFILES: the point of this test is the default
# installed location, which is what sync compares the repo against.
out=$(HOME="$SYNC_HOME" "$SYNC_CLI" sync 2>&1)
assert_not_contains "a clean sync reports nothing left behind" "no longer in the repo" "$out"

# Guard the guard: if this persona is ever renamed, the removal below becomes a
# no-op and every assertion after it would pass for the wrong reason.
if [[ -f "$SYNC_REPO/profiles/piper.md" ]]; then
  ok "the persona to remove exists, so these tests are not vacuous"
else
  fail "the persona to remove exists, so these tests are not vacuous (piper renamed: repoint this test)"
fi
rm -f "$SYNC_REPO/profiles/piper.md" "$SYNC_REPO/agents/piper.md" "$SYNC_REPO/commands/piper.md"
out=$(HOME="$SYNC_HOME" "$SYNC_CLI" sync 2>&1)
assert_contains "sync names the persona left behind"     "piper"                 "$out"
assert_contains "sync says why it is still installed"    "no longer in the repo" "$out"
assert_contains "sync prints the command that clears it" "rm -f"                 "$out"

# Reported, not deleted. sync shares ~/.claude/commands and ~/.claude/agents with
# files it never wrote, and has no marker separating its own from a user's, so it
# must not rm on a guess about ownership.
if [[ -f "$SYNC_HOME/.claude/team/piper.md" ]]; then ok "sync deletes no leftover profile"
else fail "sync deletes no leftover profile (IT WAS DELETED)"; fi
if [[ -f "$SYNC_HOME/.claude/commands/piper.md" ]]; then ok "sync deletes no leftover slash command"
else fail "sync deletes no leftover slash command (IT WAS DELETED)"; fi
if [[ -f "$SYNC_HOME/.claude/agents/piper.md" ]]; then ok "sync deletes no leftover subagent"
else fail "sync deletes no leftover subagent (IT WAS DELETED)"; fi

# A persona still in the repo must not be reported, or the warning is noise.
# Scoped to the report line, not the whole run: say_session_scope prints
# "slash commands (/akira, /robin, ...)" on every sync, so asserting against all
# of $out would fail on text that has nothing to do with this check.
orphan_report=$(grep "no longer in the repo" <<< "$out" || true)
assert_not_contains "the report names only the removed persona" "robin" "$orphan_report"
# The leftover showing in the roster is the symptom the report exists to explain.
out=$(CLAUDE_TEAM_PROFILES="$SYNC_HOME/.claude/team" HOME="$SYNC_HOME" "$SYNC_CLI" list 2>&1)
assert_contains "the leftover persona still shows in list, which is the symptom" "Piper" "$out"
rm -rf "$SYNC_REPO" "$SYNC_HOME"
echo ""

# ─── Documentation drift ──────────────────────────────────────────────────────
#
# Five sessions in a row ran an open-ended "review the docs for drift" prompt
# and returned five different lists of findings. A review is a generator, not
# a check, and an unbounded generator does not converge. Every assertion below
# derives both sides from the filesystem or the source and compares them, so a
# passing suite is the answer to "what is the state of this repo" instead of
# one more guess at it. A check that hardcodes today's count or file list
# would only move the drift from the docs into the test, so none of the checks
# below do that; each was verified against this repo's actual history (a real
# commit that fixed a real drift) before being written, not against invented
# examples.

echo "CONTRIBUTING shellcheck command <-> ci.yml"

# CONTRIBUTING tells a contributor to run shellcheck locally "because it runs in
# CI, so running it here saves a round trip". That promise only holds while the
# two lists name the same files. CONTRIBUTING listed five and CI ran six, missing
# tests/check-links.sh, so a contributor could follow the documented steps, see a
# silent shellcheck, push, and fail the lint job on a file they were never told
# to check. A doc that is wrong about how to pass CI is worse than no doc.
#
# Both sides are read from the file that owns them and compared as sets, so
# neither can be updated alone.
sc_from() {
  grep -oE 'shellcheck( +[A-Za-z0-9_./-]+)+' "$1" | head -1 | tr ' ' '\n' | sed 1d | sort
}
ci_sc=$(sc_from "$REPO_DIR/.github/workflows/ci.yml")
doc_sc=$(sc_from "$REPO_DIR/CONTRIBUTING.md")
if [[ -n "$ci_sc" && -n "$doc_sc" ]]; then
  ok "found a shellcheck file list on both sides, so this test is not vacuous"
else
  fail "found a shellcheck file list on both sides, so this test is not vacuous (ci:$(wc -l <<< "$ci_sc") doc:$(wc -l <<< "$doc_sc"))"
fi
if [[ "$ci_sc" == "$doc_sc" ]]; then
  ok "CONTRIBUTING lints the same files CI does"
else
  fail "CONTRIBUTING lints the same files CI does (only in CI:$(comm -23 <(echo "$ci_sc") <(echo "$doc_sc") | tr '\n' ' ')| only in CONTRIBUTING:$(comm -13 <(echo "$ci_sc") <(echo "$doc_sc") | tr '\n' ' '))"
fi
# Both lists staying in step with each other but drifting from the repo is the
# failure a set comparison structurally cannot catch, so name the files too.
missing_sc=""
while read -r f; do
  [[ -z "$f" ]] && continue
  [[ -f "$REPO_DIR/$f" ]] || missing_sc="$missing_sc $f"
done <<< "$ci_sc"
if [[ -z "$missing_sc" ]]; then ok "every file in the shellcheck list exists"
else fail "every file in the shellcheck list exists (missing:$missing_sc)"; fi
echo ""

echo "commands/ <-> README shipped-commands"

# Every persona command (profiles/<name>.md, generated into
# commands/<name>.md) is represented collectively in README, as the pattern
# "/river /akira /sasha ..." plus the TEAM.md pointer and the roster table,
# not one line per persona. That collective form is a documented choice, not
# drift, so persona commands are excluded here; the roster itself is covered
# by the "help lists every persona" and "install-commands lists every
# persona" checks earlier in this file. The 10 "workflow" commands (every
# other file in commands/) have no collective stand-in: each one is named
# individually or it is invisible. /silicon-valley shipped as a command file
# and was not named anywhere in README until this check was written.
missing_from_readme=""
workflow_cmd_count=0
for f in "$REPO_DIR"/commands/*.md; do
  name=$(basename "$f" .md)
  [[ -f "$PROFILES_DIR/$name.md" ]] && continue
  workflow_cmd_count=$((workflow_cmd_count + 1))
  grep -qE "/${name}([^a-zA-Z0-9_-]|\$)" "$REPO_DIR/README.md" \
    || missing_from_readme="$missing_from_readme /$name"
done
# Guards the guard: if every command file ever turned out to be a persona
# command, the loop above would report a vacuous pass having checked nothing.
if [[ "$workflow_cmd_count" -gt 0 ]]; then ok "found workflow commands to check, so this test is not vacuous"
else fail "found workflow commands to check, so this test is not vacuous (found none)"; fi
if [[ -z "$missing_from_readme" ]]; then ok "every workflow command in commands/ is named in README"
else fail "every workflow command in commands/ is named in README (missing:$missing_from_readme)"; fi

# Reverse direction: README's "ships with this repo, no companion skill
# required" block is a specific structural claim about what commands/
# contains. If it names a command there, that command must be a real file, or
# the doc is advertising something the repo does not ship (a live-vs-companion
# command like /devlog or /roadmap is deliberately listed under "Companion
# skill commands" instead, so this block only ever names commands that should
# resolve to a file with no further caveat).
readme_ships_block=$(awk '
  /Slash commands that ship with this repo/ { seen = 1 }
  seen && /^```bash$/ {
    fence++
    if (fence == 1) { getline; while ($0 !~ /^```$/) { print; getline } }
    exit
  }
' "$REPO_DIR/README.md")
if [[ -n "$readme_ships_block" ]]; then ok "found the 'ships with this repo' block, so this test is not vacuous"
else fail "found the 'ships with this repo' block, so this test is not vacuous (heading text may have changed)"; fi
claimed_missing_file=""
while IFS= read -r tok; do
  [[ -n "$tok" ]] || continue
  cname="${tok#/}"
  [[ -f "$REPO_DIR/commands/$cname.md" ]] || claimed_missing_file="$claimed_missing_file $tok"
done < <(grep -oE '/[a-z][a-z-]*' <<< "$readme_ships_block" | sort -u)
if [[ -z "$claimed_missing_file" ]]; then ok "every command README claims ships with this repo has a real file"
else fail "every command README claims ships with this repo has a real file (no file for:$claimed_missing_file)"; fi
echo ""

echo "bin/claude-team dispatch <-> README Usage"

# claude-team session and claude-team launch shipped as real top-level
# commands and were absent from README entirely (not merely from one
# section), so the check searches the whole file rather than a single
# heading-bounded block: claude-team install-hook is genuine prior art for a
# command documented only in prose (Installation, Requirements, Roadmap), not
# inside the Usage code fence, and that placement is legitimate, not drift.
dispatch_missing=""
dispatch_cmd_count=0
while IFS= read -r cmd; do
  case "$cmd" in *'|'*|'*') continue ;; esac
  [[ "$cmd" == "help" ]] && continue
  dispatch_cmd_count=$((dispatch_cmd_count + 1))
  grep -qE "claude-team ${cmd}([^a-zA-Z0-9_-]|\$)" "$REPO_DIR/README.md" \
    || dispatch_missing="$dispatch_missing $cmd"
done < <(awk '/^case "\$\{1:-help\}" in$/{f=1;next} /^esac$/{f=0} f{print $1}' "$CLI" | sed 's/)$//')
if [[ "$dispatch_cmd_count" -ge 10 ]]; then ok "found the top-level dispatch table, so this test is not vacuous"
else fail "found the top-level dispatch table, so this test is not vacuous (found only $dispatch_cmd_count entries)"; fi
if [[ -z "$dispatch_missing" ]]; then ok "every top-level 'claude-team <command>' is documented in README"
else fail "every top-level 'claude-team <command>' is documented in README (missing:$dispatch_missing)"; fi

# 'branch' and 'session' are command families with their own internal
# dispatch. Checked one level deep, the same way and for the same reason as
# the top level: a subcommand a user can actually type should appear
# somewhere in README. Not recursed a further level into 'branch guard
# <install|remove>' -- the real defect this suite is guarding against was a
# whole missing top-level family, not a missing third-level action, and
# following the dispatch tree all the way down starts pinning README to the
# CLI's exact argument grammar rather than to its documented surface.
for fam in branch session; do
  fam_missing=""
  fam_sub_count=0
  while IFS= read -r sub; do
    case "$sub" in *'|'*|'*') continue ;; esac
    fam_sub_count=$((fam_sub_count + 1))
    grep -qE "claude-team ${fam} ${sub}([^a-zA-Z0-9_-]|\$)" "$REPO_DIR/README.md" \
      || fam_missing="$fam_missing $sub"
  done < <(awk -v fn="cmd_$fam() {" '
    $0 == fn { infn = 1 }
    infn { print }
    infn && /^}$/ { exit }
  ' "$CLI" | awk '/case "\$subcmd" in/{f=1;next} /esac/{f=0} f{print $1}' | sed 's/)$//')
  if [[ "$fam_sub_count" -ge 3 ]]; then ok "found $fam's subcommand dispatch, so this test is not vacuous"
  else fail "found $fam's subcommand dispatch, so this test is not vacuous (found only $fam_sub_count entries)"; fi
  if [[ -z "$fam_missing" ]]; then ok "every 'claude-team $fam <subcommand>' is documented in README"
  else fail "every 'claude-team $fam <subcommand>' is documented in README (missing:$fam_missing)"; fi
done
echo ""

echo "commands/ YAML frontmatter"

# claude plugin validate --strict rejects a command file with no frontmatter,
# and a missing frontmatter block is otherwise invisible: the slash command
# still works in a live session either way. Nine workflow commands (branch,
# casual-mode, devlog, prod-mode, roadmap, session, silicon-valley,
# silicon-valley-off, team) shipped without it. Checked structurally rather
# than by shelling out to 'claude plugin validate': that keeps this test
# hermetic on a machine that does not have the Claude Code CLI on PATH, CI
# included. See the CI workflow for the best-effort 'claude plugin validate'
# pass that runs in addition to this when that binary is available.
frontmatter_bad=""
for f in "$REPO_DIR"/commands/*.md; do
  cname=$(basename "$f")
  first_line=$(head -n1 "$f")
  if [[ "$first_line" != "---" ]]; then
    frontmatter_bad="$frontmatter_bad $cname(no-opening-marker)"
    continue
  fi
  close_line=$(awk 'NR>1 && /^---$/{print NR; exit}' "$f")
  if [[ -z "$close_line" ]]; then
    frontmatter_bad="$frontmatter_bad $cname(no-closing-marker)"
    continue
  fi
  sed -n "2,${close_line}p" "$f" | grep -q '^description:' \
    || frontmatter_bad="$frontmatter_bad $cname(no-description-key)"
done
if [[ -z "$frontmatter_bad" ]]; then ok "every commands/ file has YAML frontmatter with a description"
else fail "every commands/ file has YAML frontmatter with a description (bad:$frontmatter_bad)"; fi
echo ""

echo "TEAM.md persona parity with profiles/"

# TEAM.md is a hand-maintained copy: nothing regenerates it from profiles/,
# unlike agents/ and commands/. CONTRIBUTING.md tells a contributor adding or
# removing a persona to update it by hand in the same commit; nothing before
# this enforced that instruction. Compares both the count and the exact name
# set, because two equal counts do not prove the same seventeen names are
# present -- a renamed or swapped entry would pass a count-only check.
team_names=$(grep '^### ' "$REPO_DIR/TEAM.md" | sed -E 's/^### ([A-Za-z]+):.*/\1/' | tr '[:upper:]' '[:lower:]' | sort)
profile_names=$(for p in "$PROFILES_DIR"/*.md; do
  n=$(basename "$p" .md)
  case "$n" in coordinator*) continue ;; esac
  echo "$n"
done | sort)
team_count=$(grep -c . <<< "$team_names")
profile_count=$(grep -c . <<< "$profile_names")
if [[ "$team_count" -gt 0 && "$profile_count" -gt 0 ]]; then ok "found persona sections on both sides, so this test is not vacuous"
else fail "found persona sections on both sides, so this test is not vacuous (TEAM.md:$team_count profiles/:$profile_count)"; fi
if [[ "$team_count" == "$profile_count" ]]; then ok "TEAM.md persona section count matches profiles/"
else fail "TEAM.md persona section count matches profiles/ (TEAM.md has $team_count, profiles/ has $profile_count)"; fi
team_profile_diff=$(diff <(echo "$team_names") <(echo "$profile_names") || true)
if [[ -z "$team_profile_diff" ]]; then ok "TEAM.md persona names match profiles/ exactly"
else fail "TEAM.md persona names match profiles/ exactly (diff:$(tr '\n' ' ' <<< "$team_profile_diff"))"; fi
echo ""

echo "internal markdown links and file paths resolve"

# TODOS.md pointed a reader at 'publish/posts/image-prompts.md', which does
# not exist. DEVLOG.md and docs/proposals/ are excluded because both are
# historical-record documents by design: docs/proposals/image-generation.md
# says outright that its profiles/kai.md line citations "refer to the
# pre-change file and are left as written for the historical record," and
# that publish/style-guide.md was "deliberately deleted... so re-adding a
# per-repo brand file re-introduces what was removed on purpose." A dangling
# path in either is not drift; it is the record working as intended, so
# flagging it would train a maintainer to ignore this check rather than fix
# what it finds. generated/ persona content (profiles/, commands/, agents/)
# is excluded because those files are not project documentation, and were
# already seen to contain unrelated prose that happens to look path-shaped
# (Sage's "marketplace, freemium, one-time purchase").
#
# A backtick span counts as a path candidate only once it looks enough like
# one to be worth resolving: it must contain a slash (so a bare code term
# like `marketplace.json`, mentioned deliberately as NOT existing, is never a
# candidate), and it is stripped of a trailing ':<line>' or ':<line>-<line>'
# citation first, because 'bin/claude-team:15' is this repo's own convention
# for citing a source line and is not part of the path.
doc_files=$(git -C "$REPO_DIR" ls-files '*.md' \
  | grep -Ev '^(profiles|commands|agents)/' \
  | grep -v '^DEVLOG\.md$' \
  | grep -v '^docs/proposals/')
broken_paths=""
checked_paths=0
while IFS= read -r doc; do
  [[ -n "$doc" ]] || continue
  doc_full="$REPO_DIR/$doc"
  doc_dir=$(dirname "$doc_full")

  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    target="${target%%#*}"
    [[ -n "$target" ]] || continue
    checked_paths=$((checked_paths + 1))
    if [[ -e "$doc_dir/$target" || -e "$REPO_DIR/$target" ]]; then
      :
    else
      broken_paths="$broken_paths
  $doc: markdown link -> $target"
    fi
  done < <(grep -oE '\]\(([^()#[:space:]]+)' "$doc_full" | sed -E 's/^\]\(//' | grep -Ev '^(https?:|mailto:)')

  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    target=$(sed -E 's/:[0-9]+(-[0-9]+)?$//' <<< "$target")
    [[ "$target" == */* ]] || continue
    case "$target" in
      *'<'*|*'>'*|'~'*|*'$'*|*' '*|-*) continue ;;
    esac
    case "$target" in
      profiles/*|commands/*|agents/*|bin/*|scripts/*|hooks/*|tests/*|docs/*|examples/*|publish/*|.claude-plugin/*|.github/*) ;;
      *.md|*.sh|*.json|*.conf|*.yml|*.yaml|*.example) ;;
      *) continue ;;
    esac
    checked_paths=$((checked_paths + 1))
    if [[ -e "$doc_dir/$target" || -e "$REPO_DIR/$target" ]]; then
      :
    else
      broken_paths="$broken_paths
  $doc: \`$target\`"
    fi
  done < <(grep -oE '`[^`]+`' "$doc_full" | sed -E 's/^`//; s/`$//')
done <<< "$doc_files"
if [[ "$checked_paths" -gt 0 ]]; then ok "found $checked_paths path candidates to check, so this test is not vacuous"
else fail "found path candidates to check, so this test is not vacuous (found none)"; fi
if [[ -z "$broken_paths" ]]; then ok "every internal link and file-path reference resolves"
else fail "every internal link and file-path reference resolves (broken:$broken_paths)"; fi
echo ""

echo "no doc claims an unavailable plugin/marketplace install path"

# The literal historical claim, in the two forms it actually shipped in: '**
# Plugin packaging** -- install everything (commands, agents, hooks, CLI on
# PATH) via the plugin system' (README) and 'Plugin packaging: commands,
# agents, hooks, and the CLI installed in one step' (ROADMAP.md, corrected in
# README first and left standing here for weeks). Both are false as long as
# .claude-plugin/marketplace.json does not exist: there is no marketplace
# entry for '/plugin marketplace add' to read, and even with one, a
# plugin-only install runs claude-team sync for nobody, so PROFILES_DIR stays
# empty and require_profiles_dir kills every command. The check is
# conditional on that file's absence, so it stops applying the day the plugin
# path is actually built rather than needing to be deleted by hand.
#
# Matched only outside double-quoted spans, so a doc that QUOTES the retired
# claim to document the correction is not flagged: ROADMAP.md's Revision
# History row and CONTRIBUTING.md's "Fix the claim, not the file" paragraph
# both do exactly that, quoting the old wording on purpose. Verified against
# this file's own history: with the quoting removed, both lines DO match the
# pattern below, which is why stripping quoted spans first, rather than
# excluding files by name, is the mechanism -- a third file could quote the
# same retired claim tomorrow and would not need adding to an exclusion list.
# DEVLOG.md is the one exception excluded by name rather than by quoting,
# because it is an append-only historical log that narrates the old bug in
# unquoted prose ("has never been installable") as well as quoted excerpts,
# and a historical log is not asserting anything about the CURRENT state of
# the repo in the first place.
if [[ -e "$REPO_DIR/.claude-plugin/marketplace.json" ]]; then
  ok "marketplace.json exists, so a marketplace-install claim would be true (check not applicable)"
else
  banned_claim='(one[-[:space:]]step).*(plugin|marketplace)|(plugin|marketplace).*(one[-[:space:]]step)|via the plugin system.*install|install[a-zA-Z]*.*via the plugin system|plugin marketplace add|claude plugin install'
  banned_hits=""
  banned_files_checked=0
  while IFS= read -r doc; do
    [[ -n "$doc" ]] || continue
    [[ "$doc" == "DEVLOG.md" ]] && continue
    banned_files_checked=$((banned_files_checked + 1))
    stripped=$(sed -E 's/"[^"]*"//g' "$REPO_DIR/$doc")
    hit=$(grep -inE "$banned_claim" <<< "$stripped" || true)
    if [[ -n "$hit" ]]; then
      banned_hits="$banned_hits
  $doc: $(head -1 <<< "$hit")"
    fi
  done < <(git -C "$REPO_DIR" ls-files '*.md' | grep -Ev '^(profiles|commands|agents)/')
  if [[ "$banned_files_checked" -gt 0 ]]; then ok "found docs to check, so this test is not vacuous"
  else fail "found docs to check, so this test is not vacuous (found none)"; fi
  if [[ -z "$banned_hits" ]]; then
    ok "no doc claims a one-step plugin/marketplace install while marketplace.json is absent"
  else
    fail "no doc claims a one-step plugin/marketplace install while marketplace.json is absent (hits:$banned_hits)"
  fi
fi
echo ""

# ─── Summary ─────────────────────────────────────────────────────────────────

echo "────────────────────────────────"
TOTAL=$((PASS + FAIL))
printf "%d/%d tests passed" "$PASS" "$TOTAL"
if [[ "$FAIL" -gt 0 ]]; then
  printf " — \033[31m%d failed\033[0m\n" "$FAIL"
  echo ""
  for err in "${ERRORS[@]}"; do
    printf "  \033[31m✗\033[0m %s\n" "$err"
  done
  echo ""
  exit 1
else
  printf " — \033[32mall passed\033[0m\n"
  echo ""
  exit 0
fi
