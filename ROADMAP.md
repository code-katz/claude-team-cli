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
- [x] 135-test suite covering the CLI commands, both coordinator modes, and the install path

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

**Local profile overrides** is the highest-value unbuilt item on this list. Details in the section below.

Also queued: generating the `/name` slash command for a new persona. `claude-team sync` copies slash commands but cannot generate one, because `commands/` is hand-maintained by design. Adding a persona still means copying an existing command file and swapping the body in.

---

## Aspirational — Looking for Feedback

These are directions we're exploring. If any of them would change how you use the tool, [open an issue](https://github.com/code-katz/claude-team-cli/issues). Real usage feedback shapes what gets built next.

**Local profile overrides (top priority)**
A `~/.claude/team/local/` directory for per-user customizations without forking the repo. Override any persona's behavior for your specific workflow without touching the upstream source.

This moved from "exploring" to "next thing we want to build" during v2. `claude-team sync` fixed the symptom, which was an edit landing in one installed copy out of three. It did not fix the cause: the only place to customize a persona is a tracked file that the next `git pull` overwrites. Until overrides exist, "make Akira work the way my team works" is something you have to redo after every update. Customizing the team is the whole point of the product, so this is the gap worth closing first.

**Team-scoped profiles**
`claude-team init` creates a `.claude-team/` config at the project root, so team conventions are shared across developers on the same repo. Consistent team member behaviors without everyone managing their own `~/.claude/team/` independently.

**Session handoff briefing**
When switching team members mid-task, the coordinator generates a structured briefing so the incoming specialist doesn't start cold: decisions made this session, open questions, and a direct question addressed to the new team member by name.

---

## Revision History

| Date | Type | Description |
|---|---|---|
| 2026-04-09 | snapshot | Initial ROADMAP.md — v0.6 shipping, aspirational backlog identified |
| 2026-07-29 | snapshot | Renumbered to v2.0 current, v1.0 shipped; pre-release `0.x` numbers retired. Corrected test count to 135. Local profile overrides promoted to top priority. |
