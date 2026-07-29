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
  count=$(grep -c "$pattern" "$file" 2>/dev/null || echo 0)
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

# branch commands
echo "branch commands"

BRANCHES_INDEX="$TEST_HOME/.claude/branches/INDEX.md"

# status warns when no index exists
out=$(run_cmd branch status 2>&1)
assert_contains "branch status warns when no active branch" "none|No branch|no active|No active" "$out"

# start registers a branch
run_cmd branch start feat/test-branch >/dev/null
assert_file_has "branch start creates index"            "$BRANCHES_INDEX" "Branch Index"
assert_file_has "branch start writes branch name"       "$BRANCHES_INDEX" "feat/test-branch"
assert_file_has "branch start writes project name"      "$BRANCHES_INDEX" "claude-team-cli"
assert_file_has "branch start writes active status"     "$BRANCHES_INDEX" "active"

# status shows active branch
out=$(run_cmd branch status)
assert_contains "branch status shows active branch"     "feat/test-branch" "$out"

# start blocked when active already exists
assert_exits_nonzero "branch start blocked when active exists" "$CLI" branch start feat/duplicate

# done marks merged
out=$(run_cmd branch "done" 2>&1)
assert_contains "branch done output mentions merged"    "merged" "$out"
assert_file_has "branch done updates status in index"   "$BRANCHES_INDEX" "merged"

# status after done shows none
out=$(run_cmd branch status 2>&1)
assert_contains "branch status after done shows none"   "none|No branch|no active|No active" "$out"

# start with --plan links a plan slug
run_cmd branch start feat/with-plan --plan some-plan-slug >/dev/null
assert_file_has "branch start --plan writes plan slug"  "$BRANCHES_INDEX" "some-plan-slug"

# abandon marks abandoned
out=$(run_cmd branch abandon 2>&1)
assert_contains "branch abandon output mentions abandoned" "abandoned" "$out"
assert_file_has "branch abandon updates status in index"  "$BRANCHES_INDEX" "abandoned"

# list shows full table
run_cmd branch start feat/listable >/dev/null
out=$(run_cmd branch list 2>&1)
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
rm -rf "$GUARD_REPO"
echo ""

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

rm -rf "$SESSION_REPO"
echo ""

# Shared-state concurrency. ~/.claude/branches/INDEX.md and ~/.claude/CLAUDE.md
# are shared across every session on the machine, and parallel sessions are the
# product's headline feature, so concurrent access is the designed-for case.
# Measured on the unlocked code: 8 of 12 rows survived, and CLAUDE.md grew
# duplicate marker blocks when block_install took its append path against a
# writer that had not landed yet.
echo "shared-state concurrency"

CONC_HOME=$(mktemp -d)
CONC_INDEX="$CONC_HOME/.claude/branches/INDEX.md"
mkdir -p "$CONC_HOME/.claude"
CONC_ROOT=$(mktemp -d)
for i in 1 2 3 4 5 6 7 8; do
  git init -q "$CONC_ROOT/r$i"
  (cd "$CONC_ROOT/r$i" && git commit -q --allow-empty -m init)
done
# Seed four registered branches, sequentially, so there is something to rewrite.
for i in 1 2 3 4; do
  (cd "$CONC_ROOT/r$i" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$CONC_HOME" "$CLI" branch start "feat/c$i" >/dev/null 2>&1)
done
# Four rewriters and four appenders at once. A rewriter reads the whole index,
# transforms it, and renames over it; an append landing inside that window is
# erased by the rename, however atomic the append itself was.
for i in 1 2 3 4; do
  (cd "$CONC_ROOT/r$i" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$CONC_HOME" "$CLI" branch done >/dev/null 2>&1) &
done
for i in 5 6 7 8; do
  (cd "$CONC_ROOT/r$i" && CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$CONC_HOME" "$CLI" branch start "feat/c$i" >/dev/null 2>&1) &
done
wait
assert_count    "concurrent writers keep every row"     "$CONC_INDEX" '^| 2'       8
assert_count    "concurrent rewrites all applied"       "$CONC_INDEX" '| merged |' 4
assert_count    "concurrent appends all survived"       "$CONC_INDEX" '| active |' 4
assert_file_has "concurrent writers keep the header"    "$CONC_INDEX" "Branch Index"
if [[ ! -d "$CONC_INDEX.lock" ]]; then ok "no lock directory remains after success"; else fail "no lock directory remains after success"; fi
rm -rf "$CONC_ROOT"

# CLAUDE.md has two independent marker blocks written by different commands.
# The duplicate-block count is the assertion that matters: block_install greps
# for its start marker, misses it against an unlanded concurrent write, and
# takes the append path, producing a second copy.
CONC_MD="$CONC_HOME/.claude/CLAUDE.md"
printf 'keep-this-line\n' > "$CONC_MD"
for _ in 1 2 3 4 5; do
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
for spec in "use akira:use" "reset:reset" "coordinator on:coordinator on"; do
  if run_notmp ${spec%%:*} >/dev/null 2>&1; then ok "${spec##*:} works when TMPDIR is unusable"
  else fail "${spec##*:} works when TMPDIR is unusable"; fi
done
if (cd "$TMP_REPO" && TMPDIR=/nonexistent-tmpdir CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TMP_HOME" "$CLI" branch start feat/notmp >/dev/null 2>&1); then
  ok "branch start works when TMPDIR is unusable"
else fail "branch start works when TMPDIR is unusable"; fi
if (cd "$TMP_REPO" && TMPDIR=/nonexistent-tmpdir CLAUDE_TEAM_PROFILES="$PROFILES_DIR" HOME="$TMP_HOME" "$CLI" branch done >/dev/null 2>&1); then
  ok "branch done works when TMPDIR is unusable"
else fail "branch done works when TMPDIR is unusable"; fi
if [[ -z "$(find "$TMP_HOME" -name '.claude-team.*' 2>/dev/null)" ]]; then
  ok "no temp file litter left in ~/.claude"
else fail "no temp file litter left in ~/.claude"; fi
rm -rf "$TMP_HOME" "$TMP_REPO"
echo ""

# launch + plugin surfaces
echo "launch + plugin surfaces"

out=$(run_cmd launch akira --dry-run 2>&1)
assert_contains "launch akira defaults to fable tier" "claude-fable-5" "$out"
assert_contains "launch dry-run shows append-system-prompt-file" "append-system-prompt-file" "$out"

out=$(run_cmd launch robin --dry-run 2>&1)
assert_contains "launch robin defaults to sonnet tier" "claude-sonnet-5" "$out"

out=$(run_cmd launch sage --dry-run 2>&1)
assert_contains "launch sage defaults to fable tier" "claude-fable-5" "$out"

out=$(run_cmd launch toni --dry-run 2>&1)
assert_contains "launch toni defaults to opus tier" "claude-opus-4-8" "$out"

out=$(run_cmd launch akira --model claude-haiku-4-5 --dry-run 2>&1)
assert_contains "launch --model overrides tier default" "claude-haiku-4-5" "$out"

out=$(run_cmd launch akira --task "review the auth flow" --dry-run 2>&1)
assert_contains "launch --task appends initial prompt" "review.*auth.*flow" "$out"

out=$(run_cmd launch nobody --dry-run 2>&1) || true
assert_contains "launch unknown persona errors" "No profile found" "$out"

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
fi

agent_files=("$REPO_DIR"/agents/*.md)
agent_count=${#agent_files[@]}
[[ -e "${agent_files[0]}" ]] || agent_count=0
if [[ "$agent_count" == "17" ]]; then ok "17 persona subagents generated"; else fail "17 persona subagents generated (got $agent_count)"; fi
assert_contains "akira agent carries model tier" "model: claude-fable-5" "$(cat "$REPO_DIR/agents/akira.md")"
assert_contains "iris agent carries model tier" "model: claude-opus-4-8" "$(cat "$REPO_DIR/agents/iris.md")"
assert_contains "agents marked as generated" "GENERATED from profiles" "$(cat "$REPO_DIR/agents/robin.md")"

# Regeneration drift: CI never runs generate-agents.sh, and the count check above
# only counts files. generate-agents.sh copies the profile into the agent verbatim
# except for the ## Greeting section, which belongs to the slash command. So every
# non-blank profile line above ## Greeting must appear verbatim in its agent.
# Catches a profile edited without regenerating.
stale=""
for profile in "$REPO_DIR"/profiles/*.md; do
  pname=$(basename "$profile" .md)
  case "$pname" in coordinator*) continue ;; esac
  agent="$REPO_DIR/agents/$pname.md"
  if [[ ! -f "$agent" ]]; then stale="$stale $pname(no-agent)"; continue; fi
  drift=$(awk '/^## Greeting$/ { exit } { print }' "$profile" \
      | grep -v '^[[:space:]]*$' | grep -F -x -v -c -f "$agent" - || true)
  [[ "$drift" == "0" ]] || stale="$stale $pname($drift)"
done
if [[ -z "$stale" ]]; then ok "generated agents match their profiles"
else fail "generated agents match their profiles (stale:$stale)"; fi

# Same drift check for commands/, which generate-agents.sh derives from the same
# profile: Required Interactive Behaviors excised, and the ## Greeting heading
# replaced by its sentence as the trailer. So every non-blank profile line outside
# those two sections, plus the greeting sentence, must appear verbatim in the
# slash command.
cdrift=""
for profile in "$REPO_DIR"/profiles/*.md; do
  pname=$(basename "$profile" .md)
  case "$pname" in coordinator*) continue ;; esac
  cmd="$REPO_DIR/commands/$pname.md"
  if [[ ! -f "$cmd" ]]; then cdrift="$cdrift $pname(no-command)"; continue; fi
  d=$(awk '/^## Required Interactive Behaviors$/{skip=1} /^## Signature Question$/{skip=0}
           /^## Greeting$/{next} !skip' "$profile" \
      | grep -v '^[[:space:]]*$' | grep -F -x -v -c -f "$cmd" - || true)
  [[ "$d" == "0" ]] || cdrift="$cdrift $pname($d)"
done
if [[ -z "$cdrift" ]]; then ok "generated commands match their profiles"
else fail "generated commands match their profiles (drift:$cdrift)"; fi

# The greeting is a persona-switch line ("Greet the user briefly as Robin"). A
# delegated subagent never switches the session, so it must not carry one.
if grep -q '^## Greeting$' "$REPO_DIR"/agents/*.md; then
  fail "greeting excluded from generated agents"
else
  ok "greeting excluded from generated agents"
fi

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
rm -rf "$SYNC_REPO" "$SYNC_HOME"

echo ""

# install.sh end to end into an isolated HOME: files land where the CLI
# expects them, and the coordinator prompt delegates to the CLI code path
echo "install.sh"

INSTALL_HOME=$(mktemp -d)
if (cd "$REPO_DIR" && echo "n" | HOME="$INSTALL_HOME" bash install.sh >/dev/null 2>&1); then
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

if (cd "$REPO_DIR" && echo "prod" | HOME="$INSTALL_HOME" bash install.sh >/dev/null 2>&1); then
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
rm -rf "$INSTALL_HOME"

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
