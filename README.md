<p align="center">
  <img src="publish/images/Team_dark_Banner.png" alt="claude-team-cli" width="100%">
</p>

<p align="center">
  <img src="publish/images/Icon_Stacked.png" alt="Code Katz team icons" width="100%">
</p>

# claude-team-cli

> Your AI development team. Eighteen specialists, one CLI, zero meetings.

[![CI](https://github.com/code-katz/claude-team-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/code-katz/claude-team-cli/actions/workflows/ci.yml) ![License: MIT](https://img.shields.io/badge/license-MIT-blue) ![Bash 4+](https://img.shields.io/badge/bash-4%2B-green) ![Works with Claude Code](https://img.shields.io/badge/works%20with-Claude%20Code-8A2BE2)

---

## The Idea

You know that feeling when you're deep in a coding session and you wish you had a senior engineer looking over your shoulder? Someone who actually knows this domain cold and will tell you straight when something's off?

That's what this is.

`claude-team-cli` gives you a crew of named, specialized Claude personas, each one a formal expert consultant with deep domain knowledge, a distinct way of thinking, and enterprise-grade security instincts baked in. You pick who's on the task, and Claude shows up as that person.

Need to define requirements? Call River. Design an API? Akira. Building a component that has to be accessible and secure? That's Sasha's world. Need a mockup before anyone writes code? Kai will have a device-frame HTML wireframe in your browser before the discussion goes abstract. Data pipelines or ML ops? Jordan. Dashboards and metrics? Casey. Security review or threat model? Morgan. Designing your deployment pipeline? Alex. Writing tests? Robin's got it. Planning a launch? Toni. Making sure everything actually ships on time? Quinn. Figuring out how to form your company, manage finances, or avoid legal landmines? That's Sage. Need a logo, an icon set, or marketing art? Iris. Building a tabletop game? Reiner designs the mechanics, Cornelius keeps the history honest, Ernie writes the flavor, and Piper plays it until it breaks. Building inside a genre? Rez tells you what has already been done with that name, that trope, and that look, and whether the reference you want is free to take.

### How it works in practice

It's genuinely conversational. You open Claude Code and say:

> "Hey, I'm building an auth flow. Akira, what should I think about here?"

And Claude responds as Akira: systems-first, asking about consistency requirements, flagging JWT expiry patterns, pushing back if you're about to store something in the wrong place.

Or you're in planning mode and say:

> "River, help me write the requirements for this feature."

And River takes over: asking what problem you're actually solving, who the user is, what success looks like, what's explicitly out of scope.

You can switch mid-session. You can have Toni frame the messaging for a feature that Akira designed and Robin tested. They don't overlap; each stays in their lane and hands off cleanly.

The team also keeps you honest about *how* you're working, not just *what* you're building. Before jumping into a complex task, they'll ask: *"Want to plan this first or go straight to edits?"* It's a small check-in that saves a lot of backtracking.

### See the Difference

The same prompt. Two very different responses.

> *"I want to design a test coverage strategy for this application, including pre-commit tests, post-data-load validation, and a framework that can scale as the app grows."*

**Without a team member active:**

> **Claude:** Great idea! Here's a general test coverage strategy:
> - **Unit tests** for individual functions and components
> - **Integration tests** to verify modules work together
> - **End-to-end tests** for critical user flows
> - Use a pre-commit hook to run unit tests before each commit
> - Set up a CI/CD pipeline to run the full suite on every push
> - Consider a testing framework like Jest, Pytest, or whatever fits your stack

**With Robin active:**

> **Robin:** Before I sketch the strategy, I need to understand the failure modes. What's the worst thing that could silently go wrong in this application? Bad data reaching a user, a broken calculation, a stale cache? That determines where the test boundary actually sits.
>
> A few things I'm flagging immediately: pre-commit hooks catch code defects, but for a data-dependent application, the riskiest failures happen after data loads, not before commits. Those need a separate test layer entirely, with assertions against the data itself, not just the code.
>
> Can you walk me through the data flow? I want to see where transformations happen before I recommend where to put the seams.

Generic Claude gives you a checklist. Robin reframes the problem, identifies the real risk, and asks a question you probably hadn't considered.

---

## Who This Is For

Solo developers and small teams doing work that spans multiple domains, without a roomful of specialists to pull into a conversation.

If you're the only engineer on a project, or one of a small team where everyone wears multiple hats, `claude-team-cli` gives you access to expert-level thinking in domains outside your primary strength: the ones around your code as well as the ones inside it, from threat models to launch messaging to whether the name you just picked already belongs to somebody. Not generic AI help. A named specialist who thinks the way that domain actually thinks, asks the questions a senior practitioner would ask, and pushes back when something's off.

---

## The Team at a Glance

Specialists for building and shipping a product, and a studio below for tabletop game work. Same profile structure, same generator, one roster: the framework is not limited to software, and neither is the team.

| Name | Role | Ask them about |
|---|---|---|
| River | Product Manager | Requirements, discovery, roadmaps, prioritization |
| Akira | Backend Engineering | APIs, databases, auth, system architecture |
| Sasha | Frontend Engineering | UI components, accessibility, web performance |
| Jordan | Data & ML | Pipelines, ML ops, data warehousing, model governance |
| Casey | Data Analyst | Dashboards, KPIs, BI architecture, data storytelling |
| Morgan | Security Engineering | Threat modeling, compliance, IAM, penetration testing |
| Alex | DevOps & Platform | CI/CD, Kubernetes, infrastructure, SRE |
| Robin | QA & Testing | Test strategy, coverage, CI quality gates, security testing |
| Toni | Product Marketing | Positioning, messaging, GTM, competitive intel |
| Quinn | Project Manager & Scrum Master | Sprint planning, delivery tracking, backlog, release coordination |
| Sage | Business Advisor | Business formation, financial ops, legal awareness, fundraising |
| Kai | UX Design & Visual Art | Wireframes, mockups, visual design, layout, design systems |
| Iris | Brand & Illustration | Logos, icon sets, illustration, marketing graphics, asset licensing |
| Rez | Cyberpunk Genre Advisor | Genre precedent, name and term collisions, homage versus cliché, what to read or watch |

Full profiles for the whole roster are in [TEAM.md](TEAM.md).

### The Game Development Team

A four-person studio for card and board game projects. The four hold their lanes and hand off by name: Reiner designs the systems, Cornelius verifies the history, Ernie writes the words, and Piper tries to break it all.

| Name | Role | Ask them about |
|---|---|---|
| Reiner | Tabletop Game Designer | Mechanics, decision-space, balance intent, scenario and encounter design |
| Cornelius | Military Historian | WW2 order of battle, weapons, tactics, chronology, operational significance |
| Ernie | WW2 Narrative Author | Flavor text, mission briefings, card copy, historical prose |
| Piper | Tabletop Playtester | Session reports, dominant lines, balance swings, first-play confusion |

Rez sits in the roster above rather than in this studio, and works alongside it. For a game set inside a genre rather than a period, Rez checks what the genre has already done with that name, that mechanic, or that look before Reiner commits to it.

---

## Installation

### Quick install

```bash
git clone https://github.com/code-katz/claude-team-cli.git
cd claude-team-cli
bash install.sh
```

This installs:
- Team member profiles to `~/.claude/team/`
- Slash commands to `~/.claude/commands/`
- Delegation subagents to `~/.claude/agents/`
- A `SessionStart` hook in `~/.claude/settings.json`, which injects worktree and branch context at the start of every session
- The `claude-team` CLI to `~/.local/bin/` (symlinked, so repo updates apply immediately)

Keep the clone. The CLI is a symlink into it and the hook points at it by absolute path, so moving or deleting the clone breaks both. Re-run `bash install.sh` after moving it, or just `claude-team install-hook` to re-point the hook.

Make sure `~/.local/bin` is on your `PATH`:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

### First run

Open Claude Code and type `/river` to switch the session to the Product Manager, or any other name from the roster. Outside a session, `claude-team list` shows every specialist and `claude-team status` shows who is active.

---

## The Coordinator

Turn on the coordinator and Claude will ask you who should be on each task before diving in, and tap you on the shoulder when the work drifts into a different domain. It's like having a project manager who routes work to the right person automatically.

It also suggests which Claude Code mode to use. Claude Code has three: **plan mode** (no edits until you approve), **ask before edits** (pauses for approval on each change), and **edit automatically** (full speed ahead). Before starting anything substantial, the coordinator names the right one and presents all three. You pick.

---

## Works Well With

The team works best with these companion tools installed alongside it. Each one fills a gap that comes up naturally when working with specialists across sessions.

| Project | What it does | Command |
|---|---|---|
| [claude-devlog-skill](https://github.com/code-katz/claude-devlog-skill) | Structured development changelog that captures what each specialist decided across sessions | `/devlog` |
| [claude-roadmap-skill](https://github.com/code-katz/claude-roadmap-skill) | Living product roadmap with revision history; River's planning sessions feed directly into roadmap updates | `/roadmap` |
| [claude-plans-skill](https://github.com/code-katz/claude-plans-skill) | Archives finalized implementation plans that capture the approach each specialist helped design | `/plans` |
| [claude-todo-skill](https://github.com/code-katz/claude-todo-skill) | Lightweight task scratchpad for capturing action items from any specialist session | `/todo` |
| [claude-publish-agent](https://github.com/code-katz/claude-publish-agent) | Publish markdown to blogging platforms; Toni helps with positioning, then you publish it | `/publish` |
| [claude-conductor](https://github.com/code-katz/claude-conductor) | Track and coordinate parallel Claude Code sessions; see who's doing what, who's blocked, and merge order | `/conductor` |
| [claude-illustrate-skill](https://github.com/code-katz/claude-illustrate-skill) | Brand assets with a render-and-inspect loop; Iris brings the taste, this brings the mechanics. Logos and icons need no image backend | `/illustrate` |

All are invocable as slash commands once installed. They also auto-trigger on natural language: "log this", "update the roadmap", "we shipped X", "archive this plan", "add a todo", "show sessions", "design a logo".

```bash
# Install the six single-file companion skills (claude-illustrate-skill is cloned below)
mkdir -p ~/.claude/skills/{devlog,roadmap,plans,todo,publish,conductor}
curl -o ~/.claude/skills/devlog/SKILL.md \
  https://raw.githubusercontent.com/code-katz/claude-devlog-skill/main/SKILL.md
curl -o ~/.claude/skills/roadmap/SKILL.md \
  https://raw.githubusercontent.com/code-katz/claude-roadmap-skill/main/SKILL.md
curl -o ~/.claude/skills/plans/SKILL.md \
  https://raw.githubusercontent.com/code-katz/claude-plans-skill/main/SKILL.md
curl -o ~/.claude/skills/todo/SKILL.md \
  https://raw.githubusercontent.com/code-katz/claude-todo-skill/main/SKILL.md
curl -o ~/.claude/skills/publish/SKILL.md \
  https://raw.githubusercontent.com/code-katz/claude-publish-agent/main/SKILL.md
curl -o ~/.claude/skills/conductor/SKILL.md \
  https://raw.githubusercontent.com/code-katz/claude-conductor/main/skills/conductor/SKILL.md
```

`claude-illustrate-skill` is cloned rather than curled, because its backend guides and reference docs live in sibling files that `SKILL.md` reads on demand:

```bash
git clone https://github.com/code-katz/claude-illustrate-skill.git \
  ~/.claude/skills/illustrate
```

---

## Coordinator: Proactive Team Check-Ins

The coordinator is an optional behavior layer that makes Claude actively manage two things: **who's on the task** and **how you're working**.

### Team member check-ins

At the start of each task, Claude identifies the best-fit team member based on what you're asking and confirms with you before proceeding:

> *"This looks like an API design question. Akira would be the right lead. Want to activate Akira, or someone else?"*

When the conversation shifts domain mid-session, Claude flags it and suggests a switch rather than quietly changing behavior:

> *"We're moving into test strategy territory. Run `/robin` right here to switch this session to Robin, no restart needed. Or I can delegate the test matrix to Robin on their own tier model, without switching."*

### Mode suggestions: all three, every time

Claude Code has three operating modes. The coordinator knows when each fits and always presents all three, with a clear recommendation and reasoning, so you can confirm or override.

**Plan mode.** Claude reads and plans, touches nothing until you approve. The coordinator recommends this when:
- Scope is ambiguous, large, or spans multiple files or systems
- A new feature, refactor, or architectural change is involved
- Robin, River, Toni, Quinn, or Sage is the active team member

> *"I'd suggest plan mode here. New feature with open scope questions. Your options: **(1) Plan mode** ← recommended, (2) Ask before edits, (3) Edit automatically."*

**Ask before edits.** Claude pauses before each file edit or tool call for your go-ahead. Recommended when:
- The task is clear but touches sensitive or multiple files
- You want visibility without full planning overhead
- You're executing a post-plan phase

> *"Task is clear but touches a few files. I'd suggest ask before edits. Your options: (1) Plan mode, **(2) Ask before edits** ← recommended, (3) Edit automatically."*

**Edit automatically.** Claude edits without stopping. Recommended when:
- The change is small, targeted, and well-understood
- You've already planned and trust the approach

> *"Looks like a targeted fix. Edit automatically makes sense. Your options: (1) Plan mode, (2) Ask before edits, **(3) Edit automatically** ← recommended."*

If you override a suggestion for the current task, the coordinator won't repeat it immediately, but may recommend differently when you start something new.

### Parallel session planning

The coordinator watches for opportunities to split work into parallel Claude Code sessions. When a plan produces multiple independent streams, or you have a backlog of unrelated tasks, it suggests parallelizing:

> *"This breaks into 3 independent streams with no file overlap. Want me to generate parallel session prompts?"*

Each prompt includes a persona, a specific task, and an explicit file scope so sessions don't conflict. You can also request this on demand:

```
/parallel
```

**Example output:**

```
Session 1: API endpoints
Persona: /akira
Task: Implement the /battles and /units CRUD endpoints with SQLAlchemy models
Files: app/routers/battles.py, app/routers/units.py, app/models/

Session 2: Battle log UI
Persona: /sasha
Task: Build the BattleLog wizard component with steps for army select, kill tracking, and summary
Files: frontend/src/pages/BattleLog.jsx, frontend/src/components/

Session 3: Test coverage
Persona: /robin
Task: Write integration tests for the battles API and unit tests for the BattleLog wizard
Files: tests/test_battles.py, frontend/src/__tests__/BattleLog.test.jsx

Merge order: Session 1 first (defines API contracts), then Sessions 2 and 3 in any order.
```

Keep your current session open as the coordination session for questions, reviewing work, and committing.

### Lint check on new projects

When starting work on a new project or codebase, the coordinator verifies that a linter is configured for the project's stack. It checks for stack-appropriate lint config files (Ruff for Python, ESLint/Biome for JS/TS, SwiftLint for Swift, golangci-lint for Go, clippy for Rust, pre-commit for general use) and flags missing linters to the user before proceeding with any code changes.

### What the coordinator never does

- Switch team members on its own
- Change your operating mode (it suggests; you switch in the Claude Code UI)
- Interrupt mid-response (check-ins happen at natural breaks only)

### Workflow modes: casual and prod

The coordinator ships in two modes. **Casual is the default** — if you run `coordinator on` or select it during `bash install.sh`, you get casual mode.

**Casual mode** handles team member routing, mode suggestions, and lint checks, but does not enforce branch registration or block code changes. Right for personal projects, learning, and anyone committing directly to `main`.

**Prod mode** is an explicit opt-in. Claude blocks code changes until a branch is registered, requires worktrees for parallel sessions, enforces a rebase-then-push ship workflow, and prompts for an MR/PR before closing a session. Right for team projects, pull requests, and anywhere branching discipline matters.

Enable and switch modes at any time — including mid-session via slash commands:

```bash
claude-team coordinator on    # casual mode — the default
claude-team coordinator prod  # production mode — opt-in
claude-team coordinator off   # disable
claude-team status            # shows: on (casual), on (prod), or off
```

```
/prod-mode     # switch to prod mid-session
/casual-mode   # switch to casual mid-session
```

During `bash install.sh`, the installer prompts `[casual/prod/n]` — the default is casual.

---

## Branch Hygiene: One Branch Per Session

> **Prod mode only.** Branch hygiene enforcement is active when `claude-team coordinator prod` is set. Casual mode users commit directly to `main` — this section is not required for your setup.

Without structure, work accumulates on `main`. Sessions start without knowing what was in progress. Branches get abandoned. Features land on the wrong base.

Branch hygiene enforces a simple contract: register a branch before writing code, work on it for the session, and close it explicitly when the work is done. The coordinator reads this state at session start, so Claude always knows what it is building and where it belongs.

### The workflow

```bash
# Before writing anything, register your branch
claude-team branch start feat/user-auth

# Link it to an archived plan for full traceability
claude-team branch start feat/user-auth --plan my-plan-slug

# Check what's active at any point
claude-team branch status
# Active branch: feat/user-auth (my-project)
# Linked plan: my-plan-slug

# After merging your PR
claude-team branch done
# ✓ Branch feat/user-auth marked as merged.
#   To delete the local branch:
#   git branch -d feat/user-auth

# Or if you are abandoning the work instead
claude-team branch abandon
```

### Protecting main

One command installs a pre-commit hook that blocks accidental commits directly to `main` or `master`:

```bash
# Install once per repo
claude-team branch guard install

# Remove if needed
claude-team branch guard remove
```

### How it integrates

The `--plan` flag links a branch to an archived plan from the [plans skill](https://github.com/code-katz/claude-plans-skill). The coordinator reads `~/.claude/branches/INDEX.md` at session start: if an active branch is registered, it surfaces it immediately. If none is registered, it warns you before any code is written. Use the `/branch` slash command mid-session to check your current branch status without leaving Claude Code.

Branch state persists across sessions and across projects. Use `claude-team branch list` to see the full index.

---

## Usage

```bash
# See your team — the canonical roster
claude-team list

# Read any team member's full profile
claude-team show river
claude-team show morgan
claude-team show cornelius

# Activate any team member (run `claude-team list` for every name)
claude-team use river      # River (Product Manager)
claude-team use akira      # Akira (Backend Engineering)
claude-team use piper      # Piper (Tabletop Playtester)

# Check who's active + coordinator state
claude-team status

# Toggle proactive team check-ins
claude-team coordinator on    # casual mode (no branch enforcement)
claude-team coordinator prod  # prod mode (branch enforcement on)
claude-team coordinator off   # disable

# Return to default Claude behavior
claude-team reset

# Propagate profile edits: regenerate subagents, reinstall all three copies
claude-team sync

# Install slash commands (if you skipped install.sh or need to re-install)
claude-team install-commands

# Open a dedicated session with a persona baked in, on their tier model
claude-team launch akira                          # new session as Akira
claude-team launch akira --task "..."             # start with an initial prompt
claude-team launch akira --worktree feat/api      # launch inside an isolated worktree
claude-team launch akira --model claude-sonnet-5  # override the persona's tier default
claude-team launch akira --dry-run                # print the launch command, don't run it

# Worktree sessions — an isolated git worktree per work stream, so parallel
# sessions never switch branches underneath each other in a shared checkout
claude-team session start feat/my-feature         # create the worktree and register it
claude-team session status                        # show this session's worktree and branch
claude-team session list                          # show every registered session
claude-team session done                          # finish and clean up the worktree

# Branch hygiene — see the Branch Hygiene section for the full workflow
claude-team branch start feat/my-feature          # register before writing any code
claude-team branch done                           # mark merged
claude-team branch abandon                        # mark abandoned
claude-team branch status                         # show active branch for this project
claude-team branch list                           # show full branch index
claude-team branch guard install                  # block accidental commits on main
```

After activating a team member with `claude-team use`, **start a new Claude Code session** to apply the profile. To switch mid-session without restarting, use the slash commands (`/river`, `/akira`, etc.) directly in Claude Code.

**Slash commands that ship with this repo** (installed by `install.sh`, no companion skills required):

```bash
/river /akira /sasha ...   # switch this session to any specialist on the roster
/team                      # show the roster and who is currently active
/parallel                  # generate a parallel session plan with persona + task + file scope
/branch                    # show active branch status; propose a branch name if none is registered
/session                   # show worktree session status
/prod-mode  /casual-mode   # switch coordinator mode mid-session
/silicon-valley            # satire mode; /silicon-valley-off to leave
```

**Companion skill commands** (available only after installing the companion skills above):

```bash
/conductor  # track and coordinate parallel Claude Code sessions
/devlog     # log a decision, milestone, or insight to DEVLOG.md
/roadmap    # update or read the project ROADMAP.md
/plans      # archive or retrieve finalized implementation plans
/todo       # manage per-project task checklist
/publish    # publish markdown to a blogging platform
/illustrate # generate brand assets with a render-and-inspect loop
```

`/devlog` and `/roadmap` ship here as thin wrappers, but they still need their companion skill installed to do anything.

---

## How It Works

`claude-team use <name>` injects the team member's profile into your global `~/.claude/CLAUDE.md` between marker comments:

```
<!-- CLAUDE-TEAM:START -->
# Robin: QA & Testing Consultant
...
<!-- CLAUDE-TEAM:END -->
```

This file is read by Claude Code at the start of every session, shaping Claude's behavior for the duration of that session. `claude-team reset` removes the injected block and restores your previous configuration.

Your existing `~/.claude/CLAUDE.md` content is preserved. The team member profile is added and removed cleanly without modifying anything else.

---

## Customizing the Team

There are two supported ways to change how a persona behaves, and both keep one source of truth:

- **Open a pull request.** If the change makes the persona better for everyone, send it upstream. See [CONTRIBUTING.md](CONTRIBUTING.md).
- **Fork the repo.** If the change is specific to how you or your team work, fork and own your copy. `git pull` from upstream when you want the improvements.

There is deliberately no third option. A per-user override layer was on the roadmap and was retired: it would mean two competing definitions of a persona, and no reliable way to tell whether Akira is behaving like upstream Akira or like your local edit. One source of truth is worth more than the convenience.

Practically: edit `profiles/<name>.md` in your clone, run `claude-team sync`, and never hand-edit anything under `~/.claude/`.

---

## Adding Your Own Team Members

1. Create a new profile file in `profiles/`:

```bash
cp profiles/robin.md profiles/yourname.md
```

2. Edit it to define the persona, expertise, security focus, and communication style.

3. Keep the `## Greeting` section, and write one line for your persona. It is the sentence they say when someone runs `/yourname`. This is required: `scripts/generate-agents.sh` refuses to run without it, so a missing greeting stops the install rather than shipping a broken slash command.

4. Optionally add a model tier in `profiles/tiers.conf`.

5. Install it everywhere:

```bash
claude-team sync
```

6. Activate it:

```bash
claude-team use yourname
```

See `examples/CLAUDE.md.example` for a reference of what an activated profile looks like in context.

### Editing an existing persona

Edit the profile in the clone, then run `claude-team sync`. Do not edit `~/.claude/team/*.md` directly.

Each persona is installed as three self-contained files, and `profiles/` is the only source of truth:

| File | Used by | Kept in sync by |
|---|---|---|
| `~/.claude/team/<name>.md` | `claude-team show`, `claude-team use` | copied from `profiles/` |
| `~/.claude/agents/<name>.md` | delegation ("have robin review this diff") | regenerated from `profiles/` |
| `~/.claude/commands/<name>.md` | the `/<name>` slash command | regenerated from `profiles/` |

Editing the installed profile updates the first and silently leaves the other two stale, with nothing to warn you. `sync` regenerates both derived files and reinstalls all three.

Both `agents/` and `commands/` are generated by `scripts/generate-agents.sh`, which `sync` runs for you. Never edit them by hand; the next sync overwrites your change. The test suite fails if either drifts from its profile.

A profile needs a `## Greeting` section, holding the one line the persona says when you switch to it with `/<name>`. The generator refuses to run without it, so a new persona cannot ship a slash command that ends in a bare separator. `## Greeting` is excised from the delegation subagent, which is invoked rather than switched to and has nobody to greet.

---

## Project Structure

```
claude-team-cli/
├── README.md
├── TEAM.md                   # full profiles for the whole roster
├── WRITING.md                # plain technical English standard
├── CONTRIBUTING.md
├── ROADMAP.md
├── DEVLOG.md
├── install.sh
├── bin/
│   ├── claude-team           # CLI script
│   └── team-session-start    # SessionStart hook entry point
├── profiles/                 # the only source of truth for every persona
│   ├── <name>.md             # one file per specialist
│   ├── coordinator.md        # casual-mode check-in behavior layer
│   ├── coordinator-prod.md   # prod-mode layer: branch enforcement, MR/PR flow
│   └── tiers.conf            # persona to model tier mapping
├── commands/                 # generated: one command per persona + 10 workflow commands
├── agents/                   # generated: one delegation subagent per persona
├── scripts/
│   └── generate-agents.sh    # regenerates commands/ and agents/ from profiles/
├── hooks/
│   └── hooks.json            # hook registration, plugin-system layout
├── .claude-plugin/
│   └── plugin.json           # plugin manifest
├── tests/
│   └── run.sh                # test suite (bash tests/run.sh)
├── docs/
│   └── proposals/            # design proposals
└── examples/
    └── CLAUDE.md.example     # reference for an activated profile
```

---

## Requirements

- macOS or Linux
- Bash 4+ (macOS ships Bash 3.2 at `/bin/bash`; install a current Bash with `brew install bash`)
- [Claude Code](https://claude.ai/code)
- `git` — the install path starts with `git clone`, and `branch` and `session` shell out to it
- `python3` — required only to register the `SessionStart` hook automatically. Without it, `claude-team install-hook` prints the manual `settings.json` edit instead of failing

---

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the living roadmap with current priorities and aspirational bets.

For the full version history, see [DEVLOG.md](DEVLOG.md).

The `0.4` through `0.7` numbers used during development are retired. v1 is the first generation of the tool. v2 is what ships today.

### v2.0 (current)

**A team you can rely on across sessions and edits**

v1 gave you the team. v2 makes the team dependable: every session gets its own persona, and every profile edit reaches every installed copy.

**Session-scoped personas** — the `/akira`-style commands no longer touch global state, so parallel sessions each keep their own persona with no cross-talk. `claude-team use` still exists for pinning a global default and now says so out loud.

**One persona edit, every copy updated** — `claude-team sync` regenerates the delegation subagents and reinstalls all three installed persona files in one step. Before this, editing a profile updated one of three copies and left the rest stale with no warning, so `/akira` and `claude-team use akira` could quietly disagree about who Akira is.

**`claude-team launch <persona>`** — open a dedicated Claude Code session with the persona baked in as system prompt, on its tier model (Fable 5 for the deep-reasoning personas, Opus 4.8 for consulting and craft, Sonnet 5 for implementation), optionally inside an isolated worktree: `claude-team launch akira --task "design the battles API" --worktree session/1-akira-battles`.

**Delegation subagents** — one generated agent per persona lets any session hand work to a specialist ("have Robin review this diff") without switching. Regenerate from profiles with `claude-team sync`.

**Worktree-isolated `/parallel`** — session plans create a git worktree per session and never switch branches; the coordination session merges in dependency order.

**Session context on install** — `install.sh` registers the SessionStart hook, which injects worktree and branch context at the start of every session. If the clone moves, `claude-team install-hook` re-points it.

**Plain technical English from the coding six** — Akira, Sasha, Robin, Alex, Morgan, and Jordan write to a fourteen-rule standard adapted from the plain-language principles of ASD-STE100. Named actors, one instruction per sentence, no filler, and no loss of precision. See [WRITING.md](WRITING.md).

**Tested on Linux and macOS** — shellcheck plus the full suite run in CI on every push and pull request, covering the CLI commands, both coordinator modes, and the install path.

**Plugin-shaped layout** — `commands/`, `agents/`, and `hooks/hooks.json` sit at the paths Claude Code's plugin system expects, and `.claude-plugin/plugin.json` describes the package. Publishing to a plugin marketplace is not planned: the plugin system namespaces commands, so `/akira` would become `/claude-team:akira`, and it cannot put `claude-team` in your shell, which `launch` and `session` need. `bash install.sh` is the install path. See [Installation](#installation).

### v1.0

**The specialist roster, the coordinator, and branch hygiene**

- **Sage (Business Advisor):** business formation, financial ops, legal awareness, fundraising literacy, compliance basics. Clear professional-advice boundary: Sage flags exactly when to consult a licensed attorney, CPA, or financial advisor.
- **Kai (UX Design & Visual Art):** wireframes, HTML/CSS mockups, visual design. Kai writes the markup and hands raster work to Iris; no image backend ships in the box. Clear boundary with Sasha: Kai designs the visual target, Sasha implements it in production code.
- **Two-mode coordinator:** casual mode (default) applies no branch enforcement, so you commit directly to `main`. Prod mode is an opt-in that requires a branch before any code, with worktree isolation and an MR/PR workflow.
- `/prod-mode` and `/casual-mode` slash commands for mid-session toggling
- `claude-team branch` and `claude-team session` command families
- Parallel sessions: independent work streams, each with a dedicated team member, scoped task, and explicit file boundary

### Later — Exploring with the Community

Nothing is queued. v2.0 shipped or retired everything that was on this list. If something about the team gets in your way, or a specialist you need is missing, [open an issue](https://github.com/code-katz/claude-team-cli/issues).
