# claude-team-cli — Development Log

A living record of architectural decisions, milestones, key insights, and strategic direction.
Auto-maintained via Claude devlog skill. Entries are reverse-chronological.

---

## [2026-07-27] Game Development Team: four new personas, model re-tiering, no-emdash house style

**Category:** `milestone`
**Tags:** `personas`, `game-dev-team`, `tiers`, `house-style`, `readme`
**Risk Level:** `low`
**Breaking Change:** `behavioral` (launch model defaults changed for Morgan, Sage, Jordan)

### Summary

Expanded the team from twelve to sixteen with a Game Development Team for card and board game projects (PR #12), then grouped the four in the README as their own unit (PR #13). Along the way, every persona's default model was re-tiered to the highest tier that returns value for its kind of work, and Toni's no-emdash rule was promoted to house style across all sixteen profiles.

### Detail

**Four new personas (PR #12):**

- Reiner, Tabletop Game Designer (Fable 5): mechanics, player decision-space, elegance and complexity budgets, balance intent, LCG/co-op/deckbuilding structures, one-new-mechanic-per-scenario pacing, teach-through-play. Behaviors: the Decision Test, One New Thing, Loop Sketch.
- Cornelius, Military Historian (Opus 4.8): WW2 order of battle, weapons and calibres, tactics, doctrine, chronology, and the operational significance of positions, in the Ambrose/Ryan tradition. Behaviors: confirmed/disputed/wrong Fact Check, Why It Mattered, Sources & Confidence.
- Ernie, WW2 Narrative Author (Opus 4.8): flavor text, mission briefings, and card copy in the Pyle/Ambrose/Sledge tradition. Accuracy is mandatory, no taglines or second-person sales lines, historian or close-third GI register only. Behaviors: Fact then Meaning, Sensory Ground Truth, Kill Your Darlings.
- Piper, Tabletop Playtester (Sonnet 5): dominant-line hunting, balance swings and whiff-death, first-play confusion, teachability, and session reports. Behaviors: Break It, Session Report, First-Play Lens, Numbers Pass.
- Each shipped the full surface set: profile (single source of truth), tiers.conf entry, generated delegation agent, /name slash command, coordinator roster and routing entries in both modes, README roster/Meet the Team/Project Structure updates, plugin.json count, and test coverage (list assertions plus agent count 12 to 16).
- Lane boundaries drawn explicitly: Reiner vs River (game craft vs product strategy), Piper vs Robin (table playtesting vs software QA), Ernie vs Toni (in-world flavor vs marketing copy).

**Model re-tiering:** every persona now defaults to the highest tier that returns value.

- Promoted to Fable 5: Morgan (adversarial threat modeling), Sage (legal and financial exposure), Jordan (data platform architecture). All three do low-volume, high-stakes judgment work where the deepest reasoning pays for itself.
- Opus 4.8: Quinn, Toni, Casey, Kai, Cornelius, Ernie (judgment-heavy consulting and craft at moderate volume).
- Sonnet 5: Sasha, Alex, Robin, Piper (high-volume implementation and execution, where the top tier costs speed without proportionate gain).

**No-emdash house style:** Toni's "No emdashes in prose" rule is now the first How You Communicate bullet in all sixteen profiles, and every profile's prose was restructured (commas, colons, semicolons, parentheses, separate sentences) to contain none. Command files were rebuilt from profiles, agents regenerated, and examples/CLAUDE.md.example refreshed. Profile titles keep the "Name — Role" delimiter because bin/claude-team and scripts/generate-agents.sh parse it; normalizing Toni's " - " and Kai's "--" titles to that form also fixed Toni's and Kai's broken role display in claude-team list and their garbled generated agent descriptions.

**README grouping (PR #13):** The Team at a Glance now shows the core twelve plus a Game Development Team sub-section with its own table, and Meet the Team is followed by a dedicated Game Development Team section introducing the four as a unit with their lanes and by-name handoffs.

**Tests:** 103 (was 98). Four list assertions added, agent count assertion moved to 16, launch tier assertions updated (Sage now asserts Fable; Toni added as the Opus representative). install.sh runs clean.

### Decisions Made

- **Highest tier that returns value, not highest tier everywhere:** Fable 5 is reserved for low-volume, high-stakes judgment. Implementation personas stay on Sonnet 5 because bulk output at the top tier costs speed and tokens without proportionate quality gain.
- **New personas kept their requested tiers:** Reiner on Fable, Cornelius and Ernie on Opus, Piper on Sonnet, exactly as specified in the original request.
- **Titles keep the emdash delimiter:** the no-emdash rule targets prose punctuation, and the "Name — Role" H1 is a machine-parsed delimiter (get_active, cmd_list, generate-agents.sh all split on it). Going dash-free in titles would mean rewriting three parsers and the test patterns for a typographic preference the codified rule already exempts.
- **Coordinator rosters updated with the personas:** the task list did not mention the coordinators, but past persona additions (Sage in v0.4, Kai in v0.5) updated them, and a persona the coordinator cannot route to is only half installed.

### Related

- PR #12 (personas, re-tiering, house style), PR #13 (README grouping)
- [2026-07-04] v0.7 entry: introduced tiers.conf and the generated agents this work extends

---

## [2026-07-04] v0.7: Session-scoped personas, launcher with model tiers, plugin packaging

**Category:** `milestone`
**Tags:** `personas`, `launch`, `worktrees`, `plugin`, `subagents`, `fable-5`, `v0.7`
**Risk Level:** `medium`
**Breaking Change:** `behavioral` (persona slash commands no longer write ~/.claude/CLAUDE.md)

### Summary

Modernization against the July 2026 Claude Code harness. Personas are now session-scoped with three surfaces (slash commands, launcher, delegation subagents), /parallel creates a worktree per session instead of switching branches in a shared checkout, and the repo installs as a plugin.

### Detail

- Persona slash commands no longer run claude-team use, ending the race where parallel sessions overwrote each other's persona in the global CLAUDE.md. Each command gained frontmatter. claude-team use survives as a global pin with an explicit warning.
- claude-team launch <persona> [--task] [--worktree <branch>] [--model] [--dry-run]: dedicated sessions via --append-system-prompt-file, model from profiles/tiers.conf (Fable 5: Akira, River; Opus 4.8: Morgan, Sage, Jordan, Quinn, Toni, Casey, Kai; Sonnet 5: Sasha, Alex, Robin).
- agents/: twelve delegation subagents generated from profiles by scripts/generate-agents.sh; profiles remain the single source of truth.
- /parallel rewritten: coordination session creates one worktree per session via claude-team session start; prompts verify the worktree, rebase before done, and never contain git checkout; merges happen only in the coordination session in dependency order.
- Worktree base branch detected (origin/HEAD, then main/master/trunk, then current) instead of hardcoded main; this also fixed 11 latent test failures on machines where git init creates master.
- .claude-session markers are now excluded via the repo's common info/exclude: committed markers differed per session and produced add/add merge conflicts between session branches (found by claude-conductor's end-to-end drill).
- SessionStart hook (hooks/hooks.json + bin/team-session-start) injects worktree, branch, and roster context deterministically. Plugin manifest ships commands, agents, hooks, and the CLI on PATH; install.sh remains for manual setups and now also installs tiers.conf and agents.
- Coordinators: retired TodoWrite reference replaced with current task tools; permission modes updated; switching guidance leads with session-scoped /name commands. Tests: 98 (was 82).

### Decisions Made

- **Session-scoped by construction over global state:** the launcher injects personas as appended system prompt, so isolation needs no coordination and survives compaction.
- **Common info/exclude over committed .gitignore:** the marker is tool-local state; ignoring it repo-locally avoids polluting user gitignores while covering every worktree.
- **Commands stay commands:** commands and skills are the same mechanism in the current harness; generating a parallel skills/ tree would double-register every /name.

### Related

- code-katz/claude-conductor v1.1 (companion changes, drill that caught the marker bug)

---

## [2026-04-09] Casual/prod coordinator modes + README and roadmap overhaul

**Category:** `milestone`
**Tags:** `coordinator`, `branch-hygiene`, `casual-mode`, `prod-mode`, `readme`, `roadmap`, `v0.6`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary

Shipped v0.6: the coordinator now has two explicit workflow modes — casual (default, no branch enforcement) and prod (opt-in, full branch gates and MR/PR flow). Updated the README to surface the distinction clearly, created ROADMAP.md, and trimmed the README roadmap section to v0.4+.

### Detail

**Casual/prod coordinator modes:**
- `coordinator.md` (default) is now the casual variant: no branch hygiene enforcement, simplified session checklist, greeting shows current git branch instead of INDEX.md registered branch
- `coordinator-prod.md` is the full prod variant: all existing branch enforcement behavior preserved
- `claude-team coordinator on` installs casual; `claude-team coordinator prod` installs prod
- `claude-team status` shows `on (casual)` or `on (prod)`
- New `_coordinator_install()` helper in `bin/claude-team` eliminates duplicated inject logic
- `cmd_list()` updated to exclude all `coordinator*` profiles (was only excluding exact name `coordinator`)
- `/prod-mode` and `/casual-mode` slash commands added and installed
- `install.sh` prompts `[casual/prod/n]` instead of `Y/n` — default is casual
- 6 new tests added; 82 total, all passing

**README refactor:**
- "What's New" updated to lead with casual/prod modes instead of branch hygiene
- New "Workflow modes: casual and prod" subsection in the Coordinator section — appears before the enable commands, makes the default explicit, documents mid-session slash commands and installer prompt behavior
- Branch Hygiene section now opens with a prod-mode-only callout so casual users know to skip it
- Old buried 2-paragraph casual/prod explanation removed (replaced by the subsection)

**Roadmap:**
- README roadmap section trimmed to v0.4+; earlier history linked to DEVLOG.md
- "Later" reframed as aspirational with `open an issue` link for community feedback
- `ROADMAP.md` created — v0.6 shipping checklist, near-term items, aspirational backlog (local profile overrides, team-scoped profiles, session handoff briefing)

### Decisions Made

- **Orthogonal toggle over per-persona prod commands:** The user proposed `/akira-prod` style commands. Rejected in favor of `/prod-mode` as a standalone toggle — combining persona + mode in one command requires 12 files and creates maintenance overhead. `/akira` + `/prod-mode` achieves the same result orthogonally.
- **`coordinator on` = casual (new default):** Prior to v0.6, `coordinator on` installed branch enforcement behavior. Now it installs casual. The alternative (keeping `coordinator on` as prod, adding `coordinator casual`) preserves backward compatibility but inverts the intent — casual should be the path of least resistance for new users.
- **README trimmed to v0.4+:** The roadmap section was becoming a changelog. Trimming to recent versions and linking to DEVLOG reduces maintenance overhead while keeping reader-relevant history visible.

### Related

- Prompted by friction for casual users encountering branch enforcement gates
- PR: code-katz/claude-team-cli#6 (merged)
- Plan: `wobbly-launching-moth`

---

## [2026-03-29] Added Design System collaboration loop between Kai and Sasha

**Category:** `feature`
**Tags:** `sasha`, `kai`, `design-system`, `swiftui`, `ios`, `persona-collaboration`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
Added a "Design System Gate" behavior to Sasha and a "Design System Artifact" behavior to Kai, creating an automatic collaboration loop. Kai produces a structured design system specification before mockups; Sasha requires one before writing any SwiftUI UI code. Also added SwiftUI/iOS domain expertise to Sasha's profile.

### Detail
- Added `SwiftUI/iOS` bullet to Sasha's Domain Expertise: design tokens in Swift (enums, static constants), SwiftUI view modifiers, SF Symbols, system colors, safe area insets
- Added "Design System Gate" as Required Interactive Behavior #4 in `profiles/sasha.md`: before any SwiftUI/iOS UI work, Sasha checks for a design system file. If missing, halts and asks the user to involve Kai. If present, references tokens exclusively and flags gaps rather than hardcoding values.
- Added "Design System Artifact" as Required Interactive Behavior #4 in `profiles/kai.md`: before producing iOS/SwiftUI mockups, Kai delivers a design system spec (spacing scale, color tokens, corner radii, typography, opacity, shadows) in Swift-ready values (CGFloat, hex). Explicitly hands off to Sasha.
- Updated Kai's Handoff Brief to include the design system artifact in every handoff to Sasha.
- Copied both updated profiles to `~/.claude/team/` to sync installed versions.

### Decisions Made
- **Design system over mockups as primary fix:** The d20Mob SwiftUI app had solid code architecture (41 files, MVVM, good accessibility) but inconsistent visual quality due to ad hoc spacing/color/radius values. A design system enforces consistency systemically across all screens; mockups are screen-by-screen. Design system is the higher-leverage intervention.
- **Collaboration loop over single-persona fix:** Rather than making Sasha generate her own design system (outside her lane) or making Kai aware of code (outside her lane), the loop preserves lane-staying: Kai designs the system, Sasha enforces it.
- **Gate behavior (halt-and-flag) over soft suggestion:** Sasha halts work if no design system exists rather than proceeding with hardcoded values. Stronger enforcement prevents the drift that caused the original problem.

### Related
- d20Mob design system discussion that prompted this change (same session)
- Kai persona addition: [2026-03-29] entry below

---

## [2026-03-29] Added Kai (UX Design & Visual Art) as team member #12

**Category:** `feature`
**Tags:** `persona`, `kai`, `ux-design`, `image-generation`, `hugging-face-mcp`, `figma-mcp`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
Added Kai as the twelfth team member persona, covering UX design, visual art, mockup creation, and AI image generation. Clear boundary with Sasha: Kai designs the visual target, Sasha implements it in production code.

### Detail
- Created `profiles/kai.md` with full profile: Personality, Domain Expertise (10 items), Enterprise Security Focus (asset licensing, brand confidentiality, mockup data hygiene, prompt hygiene, font licensing), How You Communicate, Required Interactive Behaviors (Mockup-First, Mood Board Prompt, Device Frame Preview), Handoff Brief, Signature Question
- Created `commands/kai.md` (lighter slash command version following Sasha's pattern)
- Updated `profiles/coordinator.md`: roster, check-in examples, context shift signals
- Updated `README.md`: team table (twelve specialists), narrative, Meet the Team section, usage examples, project structure, roadmap v0.5
- Updated `install.sh`: quick start examples, slash command list
- Updated `tests/run.sh`: Kai assertion in list test. 42/42 tests pass.
- Kai knows Hugging Face MCP tools (FLUX.1-Krea-dev, Qwen-Image, FLUX.1-Kontext-Dev via `dynamic_space`) and Figma MCP tools (`get_design_context`, `use_figma`, `generate_diagram`, `get_screenshot`)
- Mockup convention matches d20Mob: self-contained HTML, embedded CSS, inline SVG, dark theme (#0e0e12), 393x852 iPhone device frames

### Decisions Made
- **New persona over extending Sasha:** Sasha's domain is frontend engineering (components, accessibility, CSS architecture, state management). Kai's domain is visual design (wireframes, mockups, brand, image generation). Combining them would blur the lane-staying boundary that makes every persona effective.
- **Kai over generic "Designer":** Named personas with specific expertise outperform generic roles. Kai has concrete tools (Hugging Face MCP, Figma MCP) and concrete outputs (device-frame HTML mockups, mood board prompts).
- **Three interactive behaviors:** Mockup-First (produce artifact before abstract discussion), Mood Board Prompt (structured spec before visual work), Device Frame Preview (all mockups in device frames at target resolution). These are the behaviors that differentiate Kai from a generic "make it look good" assistant.

### Related
- d20Mob mockups reference: `d20mob/docs/mockups/` (18 HTML files that established the mockup convention)

---

## [2026-03-27] Added no-emdash writing rule and parallel session support

**Category:** `feature`
**Tags:** `coordinator`, `parallel-sessions`, `writing-style`, `toni`, `content-rules`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
Added a global "no emdashes" writing style rule to the coordinator and a new `/parallel` slash command for generating parallel session plans. Also rewrote the lint blog post to eliminate emdashes.

### Detail
- Added "Writing Style" section to `profiles/coordinator.md` with global no-emdash rule: restructure sentences instead of character-swapping
- Added same rule to `profiles/toni.md` and `commands/toni.md` under "How You Communicate"
- Added "Parallel Sessions" section to `profiles/coordinator.md` with proactive detection of parallelizable work streams
- Created `commands/parallel.md` slash command that generates copy-paste session prompts with persona, task, and file scope
- Rewrote `publish/posts/post-12-lint.md` using commas, colons, semicolons, and parentheses instead of emdashes; recreated the gist
- Updated no-emdash rule in `claude-publish-agent/SKILL.md` and `~/.claude/skills/plans/SKILL.md`

### Decisions Made
- **No-emdash rule placement:** Put in the coordinator (not individual personas) so all team members inherit it globally. Toni has a duplicate because content writing is core to that persona's role.
- **Rule wording:** "Restructure the sentence" not "swap the character." Early attempts at find-and-replace produced broken grammar. The rule must instruct Claude to rewrite, not substitute.
- **Parallel session cap:** Maximum 3 sessions. Coordination overhead outweighs speed gains beyond that. Validated in prior session (2026-03-26) with 3 parallel streams completing independently with no merge conflicts.
- **File scope as hard boundary:** Each parallel session prompt must include explicit file/directory scope with no overlap between sessions, which is the key to avoiding merge conflicts.

## [2026-03-26] Added no-emdash content generation rule to Toni persona

**Category:** `feature`
**Tags:** `toni`, `content-style`, `emdash`, `writing-rules`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
Added an explicit "no emdashes" rule to the Toni persona so generated content uses hyphens, commas, colons, or semicolons instead of emdashes. Same rule added to the publish and plans skills.

### Detail
- Rule added to `How You Communicate` section in both `profiles/toni.md` and `commands/toni.md`
- Rule added to `Medium Formatting Conventions` in publish skill (`claude-publish-agent/SKILL.md` and installed `~/.claude/skills/publish/SKILL.md`)
- Rule added to `Style Guidelines` in plans skill (`~/.claude/skills/plans/SKILL.md`)
- Reinstalled claude-team-cli via `install.sh`

### Decisions Made
Rule applies to content generation only, not to the persona definition files themselves. The instruction tells Claude not to produce emdashes in output, rather than retroactively removing them from skill documentation.

## [2026-03-26] Added lint requirement to all engineer personas and coordinator

**Category:** `feature`
**Tags:** `lint`, `static-analysis`, `engineer-personas`, `coordinator`, `code-quality`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
All six engineer personas (Akira, Robin, Sasha, Alex, Morgan, Jordan) and the coordinator now proactively check for linter configuration when encountering a new codebase, and flag it if missing with stack-specific recommendations.

### Detail
- Added a new bullet to `## Enterprise Security Focus` in each engineer persona, framed through their domain lens:
  - **Akira**: security anti-patterns + code quality (bandit/S rules)
  - **Robin**: pre-test quality gate (lint catches bugs before tests run)
  - **Sasha**: code consistency + accessibility lint plugins (eslint-plugin-jsx-a11y)
  - **Alex**: CI/CD pipeline quality gate (lint as blocking step before tests)
  - **Morgan**: security baseline (cheapest static analysis for injection, secrets, unsafe calls)
  - **Jordan**: pipeline reliability + SQLFluff for SQL-heavy projects
- Added `### When starting work on a new project or codebase` subsection to coordinator's Check-In Behavior with full detection signal checklist
- Detection covers: Python (Ruff), JS/TS (ESLint/Biome), Swift (SwiftLint), Go (golangci-lint), Rust (clippy), SQL (SQLFluff), and `.pre-commit-config.yaml`
- Updated both `profiles/` and `commands/` directories (13 files total), reinstalled via `install.sh`

### Decisions Made
- **Bullet in Enterprise Security Focus, not a 4th Required Interactive Behavior** — Lint is a code quality/security concern, not a conversational behavior pattern. Adding it to Enterprise Security Focus preserves the consistent "3 behaviors + handoff" structure across all personas.
- **Domain-specific framing per persona** — Each bullet uses the persona's lens (security, testing, CI/CD, etc.) rather than generic copy-paste, making the recommendation feel natural to each persona's voice.
- **Coordinator gets a checklist, not a bullet** — The coordinator subsection uses a bulleted checklist of detection signals by stack, since it serves as a reference guide rather than a persona behavior.

### Related
- Plan file: `~/.claude/plans/shimmering-swimming-treehouse.md`

---

## [2026-03-21] Added plans and todo companion skills to README, updated posts path to publish/posts/

**Category:** `feature`
**Tags:** `companion-skills`, `plans`, `todo`, `content-kit`, `readme`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
Updated README to document two new companion skills (claude-plans-skill and claude-todo-skill) alongside devlog and roadmap. Updated `.gitignore` to reflect the `posts/` → `publish/posts/` directory move matching the publish-agent convention.

### Detail
- Companion Skills table expanded from 2 to 4 entries: added claude-plans-skill (`/plans`) and claude-todo-skill (`/todo`)
- Install block updated from "Install both" to "Install all four" with curl commands for all four skills
- Usage section updated with `/plans` and `/todo` slash command examples
- `.gitignore` updated: `posts/` → `publish/posts/` to match the publish-agent content kit convention
- Remote origin updated from legacy gitlab-master.nvidia.com to github.com/code-katz/claude-team-cli

### Decisions Made
- **Four companion skills in one table** — Plans and todo are natural additions to the devlog/roadmap pair. All four serve the same purpose: persistent project context that survives session boundaries.
- **publish/posts/ convention adopted** — Aligns with the publish-agent's decision to keep posts inside the content kit directory rather than at project root.

### Related
- claude-plans-skill: https://github.com/code-katz/claude-plans-skill
- claude-todo-skill: https://github.com/code-katz/claude-todo-skill
- publish-agent posts path change: [2026-03-21] entry in claude-publish-agent DEVLOG.md

---

## [2026-03-17] Codekatz brand identity established — 10 cat persona badges, logo, and visual identity system

**Category:** `strategy`
**Tags:** `codekatz`, `branding`, `visual-identity`, `badges`, `personas`, `gtm`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
Created the "Code Katz" brand identity for the claude-team-cli blog series and broader tool suite. Each of the 10 personas now has a unique cartoon cat character rendered as an employee badge. The codekatz.com domain was acquired, and a complete visual identity system was designed — from favicon to GitHub org avatar to Medium hero images.

### Detail
- All 10 persona cat badges created via Gemini and saved to `assets/badges/` — each cat has a distinct personality expressed through line art style (ear shape, eye expression, markings, props)
- Badge format: "Code Katz Staff ID" employee badges with cat illustration, persona name, role title, employee ID, hire date, and paw logo mark
- Art style: rust-orange (#d97757) line art on cream background, consistent across all 10 badges
- Morgan's cat has a monocle and lock shield; Sasha's has a JS badge; each cat is visually distinct at thumbnail scale
- Image prompts document (`posts/image-prompts.md`) fully rewritten for the cat approach — Phase 1 (base character design), Phase 2 (blog hero images per persona), Phase 3 (brand extensions)
- Brand extension roadmap defined: GitHub org avatar (paw icon), README headers per repo, codekatz.com landing page, animated GIFs, sticker pack, "which cat are you?" quiz
- Post file naming convention established and applied: `post-{NN}-{slug}.md` (1-2 word slugs)

### Decisions Made
- **Different cats per persona over one cat in different poses** — Originally planned a single cat mascot. Pivoted to 10 unique cats after seeing the reference style (Sudowoodo minimal cat faces). Different cats create instant visual recognition per post, "collect them all" engagement, and match the product better — these are specialists with distinct personalities, not modes of one tool.
- **Cats over human figures** — Human illustrations created gender/diversity representation challenges. Cats eliminate the issue entirely while adding approachability and fun to a developer tools brand.
- **codekatz.com as the umbrella brand** — The domain unifies the tool suite (team-cli, devlog, roadmap, publish-agent) under one memorable brand. Individual GitHub repos remain under `code-katz` org.
- **Employee badge format** — Badges are more visually interesting and shareable than plain character portraits. They add worldbuilding detail (employee IDs, hire dates) that makes the personas feel like a real team.
- **Paw icon as logo mark** — Extracted from the badge artwork. Simple enough for favicon (32px), distinctive enough for GitHub org avatar. Rust orange on charcoal as primary lockup.

### Related
- Badge assets: `assets/badges/*.png` (10 files)
- Image prompts: `posts/image-prompts.md`
- Style guide: `publish/style-guide.md`
- Domain: codekatz.com
- GitHub org: github.com/code-katz

---

## [2026-03-15] Casey profile overhauled — aligned to Cole Nussbaumer Knaflic's Storytelling with Data framework

**Category:** `feature`
**Tags:** `casey`, `personas`, `storytelling-with-data`, `data-visualization`, `v0.3`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
Rewrote the Casey (Data Analyst & Visualization) persona profile to deeply embed Cole Nussbaumer Knaflic's *Storytelling with Data* methodology — moving Casey from a general data visualization consultant to a specialist in explanatory data communication.

### Detail
- **Exploratory vs. explanatory distinction** added as a core personality belief — Casey now refuses to design audience-facing visualizations until the exploratory analysis is complete and the finding is clear
- **Storytelling with Data** added as a first-class Domain Expertise entry: The Big Idea, narrative arc (setup/tension/resolution/call to action), audience/tone/message framing, 3-minute story
- **Clutter Reduction** and **Pre-Attentive Attributes** promoted to dedicated Domain Expertise entries (previously buried in personality/communication sections)
- **The Big Idea** added as Required Interactive Behavior #1 — hard gate before any visualization work: one sentence with subject + verb + stakes
- **Clutter Audit** added as Required Interactive Behavior #3 — explicit checklist (gridlines, chart borders, diagonal labels, redundant legends, 3D effects, dual-y-axis, spaghetti graphs, rainbow scales)
- **Dashboard Wireframe** behavior updated to include the Big Idea statement at the top of the wireframe layout
- **Chart avoidance list** made explicit in How You Communicate: pie charts, 3D charts, dual-axis without justification, spaghetti graphs, rainbow color scales — each with specific reasoning
- **Signature Question** replaced: now leads with audience and desired action ("Who is the audience, what is the single thing you need them to know, and what do you need them to do with that information?")
- Both `profiles/casey.md` and `commands/casey.md` updated and synced to `~/.claude/`; slash commands reinstalled

### Decisions Made
- **Deepened Casey instead of creating a new persona.** Initial prompt requested a new "Cole Nussbaumer Knaflic" team member. Casey already covered data storytelling, so a new persona would have created overlap and bloat. The right call was to make Casey the specialist she always implied she was.
- **4 Required Interactive Behaviors instead of 2.** Added The Big Idea and Clutter Audit on top of existing So What? Drill and Wireframe. Each addresses a distinct stage: pre-work gate (Big Idea), metric triage (So What?), pre-ship quality check (Clutter Audit), layout planning (Wireframe). No overlap.


---

## [2026-03-10] README overhaul — positioning, structure, and conversion content

**Category:** `milestone`
**Tags:** `readme`, `positioning`, `documentation`, `v0.3`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
Comprehensive README rewrite to improve positioning clarity, fix outdated content, and add conversion-focused content including a team summary table, ICP statement, and before/after exchange.

### Detail
- **Team reordered** in lifecycle order: River → Akira → Sasha → Jordan → Casey → Morgan → Alex → Robin → Toni. Reflects how a product actually gets built — from discovery to launch.
- **Team summary table** added near the top (name, role, "ask them about") — gives first-time readers an immediate orientation before diving into profiles.
- **"Who This Is For"** section added — explicitly names solo developers and small teams as the ICP. Previous README implied the audience but never stated it.
- **"See the Difference"** before/after exchange added inside The Idea section — contrasts generic Claude output with Robin's specialist response to a test strategy prompt. Based on a real interaction.
- **Badges** added at top: MIT license, Bash 3.2+, Works with Claude Code.
- **Section renamed**: "The Team" → "Meet the Team".
- **Outdated content fixed**: Usage section and project structure now reflect all 9 team members; Roadmap updated — v0.3 moved to current with proper description of what landed (4 new members + Required Interactive Behaviors).

### Decisions Made
- Chose Robin (not Akira) for the before/after example because test coverage is the most universally relatable pain point — everyone knows their test coverage is inadequate. Backend architecture requires more context to appreciate.
- "Who This Is For" kept deliberately short — two paragraphs, no bullet list. Naming the audience without over-segmenting.
- Before/after generalized from a real user prompt about dashboard test strategy. Kept realistic rather than contrived to preserve credibility.

---

## [2026-03-08] Added bash test suite — 36 tests covering all CLI commands

**Category:** `milestone`
**Tags:** `testing`, `quality`, `v0.2`

### Summary
Added `tests/run.sh` — a self-contained 36-test bash suite covering all CLI commands. No external dependencies required.

### Detail
- 36 tests across: help, list, show (incl. case-insensitivity + error), use (injection, switching, idempotency), coordinator block survival across persona switches, reset, coordinator on/off (incl. idempotency), status, and error handling
- Uses a temp `$HOME` (`mktemp -d`) and `CLAUDE_TEAM_PROFILES` env override to run in full isolation — never touches the real `~/.claude/CLAUDE.md`
- Self-contained pure bash — no bats or other external test framework required; runs anywhere the CLI runs
- Key bug caught during implementation: CLI's `touch "$CLAUDE_MD"` fails if `$HOME/.claude/` doesn't exist; fixed in test setup with `mkdir -p "$TEST_HOME/.claude"`
- Decided against adding a `claude-team test` subcommand — single-dev personal tool, `bash tests/run.sh` is sufficient and keeps the CLI surface minimal

### Related
- Protects the awk block manipulation logic in `cmd_use`, `cmd_reset`, and `cmd_coordinator` — the highest-risk area of the codebase

---

## [2026-03-08] v0.2 shipped — in-session persona switching via slash commands

**Category:** `milestone`
**Tags:** `feature`, `slash-commands`, `v0.2`, `bash-compat`

### Summary
Shipped v0.2: in-session persona switching without restarting Claude Code. Users can now type `/robin`, `/akira`, `/sasha`, `/toni`, or `/river` in any Claude Code session to switch personas immediately. Also added `claude-team install-commands` subcommand and switched the installer to symlink the CLI.

### Detail
- Added `commands/` directory with 6 slash command files: one per team member + `/team`
- Each command file calls `claude-team use <name>` (persistent state) AND embeds the full persona inline (immediate in-session adoption — no restart required)
- Added `cmd_install_commands()` to `bin/claude-team`: copies commands to `~/.claude/commands/`, lists installed commands with usage
- Updated `install.sh` to install slash commands as part of the standard install flow
- Changed CLI install from `cp` to `ln -sf` (symlink) — repo edits take effect immediately without reinstalling
- Fixed bash 3.2 compat in install.sh: replaced `${var^^}` with `tr '[:lower:]' '[:upper:]'`
- Updated README to reflect v0.2 as current, moved slash commands from roadmap to shipped

### Related
- v0.3+ backlog: session handoff context, local profile overrides, new members (Alex/DevOps, Morgan/Security, Jordan/Data)

---

## [2026-03-07] v0.1 shipped — blog posts, roadmap, and gitignore cleanup

**Category:** `milestone`
**Tags:** `launch`, `content`, `roadmap`, `v0.1`

### Summary
Completed the v0.1 feature set for claude-dev-team: five personas, coordinator layer, bash 3.2-compatible CLI, and installer. Added a PMM-voice blog post series and a product roadmap to the README.

### Detail
- Five team member personas shipped: Robin (QA/Testing), Akira (Backend), Sasha (Frontend), Toni (Product Marketing), River (Product)
- Coordinator layer added as a separate CLAUDE.md block — survives team member switches, suggests team member + operating mode (Plan / Ask before edits / Edit automatically) at task start and on domain shifts
- Fixed bash 3.2 compatibility (macOS ships bash 3.2; removed `${var^}` and `${var,,}` in favor of `awk`/`tr` helpers)
- Fixed wildcard bug in `cmd_list` where empty `$active` matched every team member
- Fixed coordinator appearing in `claude-team list` output
- Wrote five blog posts in Toni's PMM voice (benefit-first, audience-obsessed, outcome-focused) — one per team member, stored in `claude-dev-team-blog-posts.md` outside the repo
- Added roadmap to README covering: v0.1 current state, v0.2 slash command shortcuts (`/robin`, `/sasha-plan`, etc. via `.claude/commands/`), and v0.3+ backlog
- Added `claude-dev-team-blog-posts.md` to `.gitignore` (draft content, not repo)

### Related
- Slash command implementation planned for v0.2 — Claude Code `.claude/commands/` Markdown files invoking `claude-team use <name>`
