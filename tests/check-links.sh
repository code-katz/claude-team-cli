#!/usr/bin/env bash
# tests/check-links.sh — external link drift check (network-dependent, opt-in)
#
# Usage: bash tests/check-links.sh
#
# NOT part of tests/run.sh. run.sh documents "no external dependencies
# required" as an invariant, because a hermetic, offline suite is what makes
# it safe to run on every push without flaking on a transient DNS failure or a
# rate limit. This check needs the network, so it stays a separate script and
# a separate, non-blocking CI job (see .github/workflows/ci.yml) rather than
# folding into the suite that gates the merge.
#
# What this catches: GitHub silently 301-redirects a renamed org or repo to
# its new location, so a stale reference still "resolves" in a browser and
# reads as correct in review. ROADMAP.md once pointed at
# github.com/d6veteran/claude-roadmap-skill; the org was renamed to
# code-katz, and the old URL kept working (via the redirect) for four review
# passes before anyone noticed the byline no longer matched. Curl sees the
# redirect on the first request; a human skimming rendered Markdown cannot,
# because Markdown does not render where a link actually goes.
#
# What this deliberately does NOT flag: a '.git'-suffixed clone URL
# (`git clone https://github.com/<owner>/<repo>.git`) also 301s, to the same
# owner/repo with the suffix stripped -- that is normal GitHub front-end
# behavior for every repository, not drift. A redirect only fails this check
# when the destination owner/repo differs from the source. Verified against
# this repo's own URLs before this script was written:
#   github.com/code-katz/claude-team-cli.git -> 301 -> code-katz/claude-team-cli  (same repo, passes)
#   github.com/d6veteran/claude-roadmap-skill -> 301 -> code-katz/claude-roadmap-skill (different owner, fails)

set -uo pipefail

if [[ -z "${BASH_VERSINFO:-}" ]] || (( BASH_VERSINFO[0] < 4 )); then
  echo "error: tests/check-links.sh requires Bash 4 or newer (this is ${BASH_VERSION:-not bash})." >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASS=0
FAIL=0
ERRORS=()
ok()   { PASS=$((PASS + 1)); printf "  \033[32m✓\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); ERRORS+=("$1"); printf "  \033[31m✗\033[0m %s\n" "$1"; }

echo ""
echo "claude-team external link check (network-dependent, opt-in)"
echo "────────────────────────────────"
echo ""

if ! command -v curl >/dev/null 2>&1; then
  echo "  skipped: curl is not on PATH"
  exit 0
fi

# A canary request first, so a sandboxed or offline machine gets one clear
# skip line instead of every single URL below reported as a false failure.
if ! curl -sS --max-time 5 -o /dev/null "https://github.com" 2>/dev/null; then
  echo "  skipped: no network access to github.com"
  exit 0
fi

# owner/repo from a github.com or raw.githubusercontent.com URL: '.git' and
# any trailing path stripped, lowercased, since GitHub slugs are
# case-insensitive. Comparing this instead of the raw URL is what tells a
# harmless '.git'-suffix redirect apart from a real org/repo rename.
owner_repo() {
  sed -E 's#^https://(github\.com|raw\.githubusercontent\.com)/##; s#\.git($|/.*$)#\1#; s#^([^/]+/[^/]+).*#\1#' <<< "$1" \
    | tr '[:upper:]' '[:lower:]'
}

declare -A referenced_in
while IFS=$'\t' read -r file url; do
  [[ -n "$url" ]] || continue
  if [[ -n "${referenced_in[$url]:-}" ]]; then
    referenced_in["$url"]="${referenced_in[$url]}, $file"
  else
    referenced_in["$url"]="$file"
  fi
done < <(
  git -C "$REPO_DIR" grep -noE 'https://(github\.com|raw\.githubusercontent\.com)/[A-Za-z0-9_.~/-]+' -- '*.md' \
    | grep -Ev '^(profiles|commands|agents)/' \
    | sed -E 's/^([^:]+):[0-9]+:/\1\t/'
)

if [[ ${#referenced_in[@]} -eq 0 ]]; then
  fail "found at least one github.com URL to check (found none — has every doc lost its links?)"
else
  ok "found ${#referenced_in[@]} unique GitHub URLs to check"
fi

for url in "${!referenced_in[@]}"; do
  code=$(curl -s -o /dev/null --max-time 10 -w '%{http_code}' -I "$url" 2>/dev/null)
  [[ -n "$code" ]] || code="000"
  case "$code" in
    2??)
      ok "$url resolves ($code)"
      ;;
    3??)
      location=$(curl -s -o /dev/null --max-time 10 -D - -I "$url" 2>/dev/null \
        | grep -i '^location:' | head -1 | sed -E 's/^[Ll]ocation: *//; s/\r$//')
      if [[ -n "$location" && "$(owner_repo "$url")" == "$(owner_repo "$location")" ]]; then
        ok "$url redirects to $location (same repo — harmless, e.g. a .git suffix)"
      else
        fail "$url ($code) redirects to '${location:-<no Location header>}', a different repo — referenced in: ${referenced_in[$url]}. Update the doc to point at the final destination."
      fi
      ;;
    000)
      fail "$url did not respond (network error or timeout) — referenced in: ${referenced_in[$url]}"
      ;;
    *)
      fail "$url returned $code — referenced in: ${referenced_in[$url]}"
      ;;
  esac
done

echo ""
echo "────────────────────────────────"
TOTAL=$((PASS + FAIL))
printf "%d/%d checks passed" "$PASS" "$TOTAL"
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
