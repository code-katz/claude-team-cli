# Roadmap — claude-team-cli

> Living product roadmap. Current priorities and forward bets.
> Updated by Claude using the [roadmap skill](https://github.com/d6veteran/claude-roadmap-skill).

---

## Current Roadmap

### Shipping Now — v2.0

**A team you can rely on across sessions, installs, and edits**

v1 delivered the roster and the coordinator. v2 closes the gaps that made the team unreliable in daily use: personas leaking between parallel sessions, a profile edit reaching one installed copy out of three, and session context missing entirely for anyone who installed from a clone instead of the plugin system.

- [x] Session-scoped personas: the `/name` commands no longer write global state, so parallel sessions never overwrite each other
- [x] `claude-team launch <persona>` — a dedicated session with the persona as system prompt, on its tier model, optionally in an isolated worktree
- [x] Seventeen delegation subagents generated from `profiles/`, so any session can hand work to a specialist without switching
- [x] Plugin packaging: commands, agents, hooks, and the CLI installed in one step
- [x] Worktree-isolated `/parallel`: session plans create a worktree per session and never switch branches in a shared checkout
- [x] `claude-team sync` — one command propagates a profile edit to all three installed copies
- [x] `claude-team install-hook` — the SessionStart hook now registers on the `install.sh` path, not only the plugin path
- [x] Plain technical English standard for the six coding specialists, documented in [WRITING.md](WRITING.md)
- [x] Slash commands generated from profiles, so a new persona means writing one file instead of three
- [x] Session handoff briefing: every persona defines a Handoff Brief, the coordinator asks for one at a switch, and it now reaches all four delivery surfaces including the `/name` slash commands
- [x] Parallel session prompts carry a Context field, so a session starts from what was already decided instead of re-deriving it
- [x] Automated test coverage across the CLI commands, both coordinator modes, and the install path, run on Linux and macOS in CI

### Shipped — v1.0

**The specialist roster, the coordinator, and branch hygiene**

- [x] `claude-team coordinator on` — casual mode, no branch enforcement
- [x] `claude-team coordinator prod` — prod mode, branch required before any code
- [x] `/prod-mode` and `/casual-mode` slash commands for mid-session toggling
- [x] `claude-team status` shows active mode: `on (casual)` or `on (prod)`
- [x] Branch hygiene infrastructure: `branch start`, `done`, `abandon`, `status`, `list`, `guard`
- [x] Session/worktree isolation: `session start`, `done`, `status`, `list`
- [x] Test suite covering all CLI commands and both coordinator modes
- [x] README refactor: casual/prod modes clearly explained, branch hygiene framed as prod-only
- [x] ROADMAP.md — this file

### Near-Term

**Local profile overrides are retired, not deferred.** They were the top item here through v2. Building them would create a second source of persona truth competing with the repo, and the confusion between core version and local customization costs more than the convenience buys. Team-scoped profiles (`claude-team init` writing `.claude-team/`) are retired for the same reason at project scope.

Customizing a persona has two supported paths, both of which keep one source of truth: open a pull request so everyone gets the improvement, or fork and own your copy. See [CONTRIBUTING.md](CONTRIBUTING.md).

Slash command generation shipped in v2.0 and is no longer queued. `scripts/generate-agents.sh` now writes both the delegation subagent and the `/name` slash command from the profile, so adding a persona means writing one profile.

---

## Aspirational — Looking for Feedback

Nothing is queued here right now. v2.0 shipped or retired everything that was.

That is an invitation, not a finish line. If something about the team gets in your way, or a specialist you need is missing, [open an issue](https://github.com/code-katz/claude-team-cli/issues). Real usage feedback shapes what gets built next.

---

## Revision History

| Date | Type | Description |
|---|---|---|
| 2026-04-09 | snapshot | Initial ROADMAP.md — v0.6 shipping, aspirational backlog identified |
| 2026-07-29 | snapshot | Renumbered to v2.0 current, v1.0 shipped; pre-release `0.x` numbers retired. Corrected test count to 135. Local profile overrides promoted to top priority. |
| 2026-07-29 | decision | Local profile overrides and team-scoped profiles retired. Both create a second source of persona truth competing with the repo. Supported paths are a pull request or a fork, documented in CONTRIBUTING.md. |
| 2026-07-29 | correction | Session handoff briefing moved from aspirational to shipped. It was built with the personas and the entry was stale; the real defect was that the brief never reached the `/name` slash commands. Parallel session prompts gained a Context field. Aspirational list is now empty. |
