# claude-team-cli — Development Log

A living record of architectural decisions, milestones, key insights, and strategic direction.
Auto-maintained via Claude devlog skill. Entries are reverse-chronological.

---

## [2026-07-30] Coordinator knew one handoff route out of three

**Category:** `bugfix`
**Tags:** `coordinator`, `handoff`, `model-tiers`, `subagents`, `sync`, `prompt-drift`

**Risk Level:** `med`
**Breaking Change:** `no`

### Summary

Both coordinator profiles offered the persona switch as though it were the only way to hand off, which is the one route where a persona's configured model tier is never applied. They now name all three routes and say what each costs.

### Detail

**The gap.** A handoff can take three forms. `/name` changes who the session is and keeps the whole conversation. Delegating to the `name` subagent keeps the session as it is and hands one scoped task over. `claude-team launch name` opens a second session. They differ in what the incoming persona can see and which model they run on.

Grepping either coordinator profile for `launch`, `subagent`, or `delegate` returned nothing but Toni's role blurb. The coordinator knew one route and presented it as the only one. That route is the one where the session keeps whatever model it already had, so setting Akira to `claude-fable-5` in `profiles/tiers.conf` and following the coordinator's advice gets Akira on the session's model, silently.

**This was drift, not a missing capability.** `README.md:62` and `:64` already documented delegation and launch to human readers, tier models included. Only the prompt was never told. Both profiles now carry a "three handoff routes" section, a `Format:` instruction that offers the fitting route and states its cost, and a 4-item Switching Reminders list. The Handoff Brief paragraph gained the reason it matters: a courtesy on a switch, where the incoming member can read the conversation, and required on a delegation, where it is the only thing they will see.

**A trap worth recording.** Repo profile edits do not reach the installed coordinator through `claude-team coordinator on` alone. `_coordinator_install` reads `$PROFILES_DIR` (`~/.claude/team`), so it reports "profile refreshed" while re-injecting the old text. `claude-team sync` has to copy the profiles across first. Caught by grepping the installed block after the first refresh reported success. This is a fourth surface with the same class of failure the [2026-07-29] sync entry documented for the three persona copies.

### Decisions Made

- **Rejected: making the persona switch carry a model change.** No mechanism exists, since command and skill `model:` frontmatter lasts one turn and the session model resumes on the next prompt. Even if one existed, a mid-session model change re-reads the full history uncached, so the cost lands precisely where the switch's value is. And `/model <name>` typed directly saves the choice as the user's default for all new sessions, so putting it in handoff advice would rewrite a global setting during a session-scoped action. A new Boundaries line forbids both, matching the existing rule against changing permission modes.
- **The tier belongs to the work, not the persona's identity.** `tiers.conf` names a model per persona as shorthand for that persona's typical stakes, which is right for delegation and launch, where a fresh context is built anyway. If this premise is wrong, nothing shipped becomes incorrect: every claim in the new prose is about observed mechanism behavior.
- **Prod profile diverges on route 3.** It says "separate session in its own worktree" and points at its own worktree section, since prod enforces branch hygiene.
- **No tests added.** Every profile loop in `tests/run.sh` skips `coordinator*`, so no test asserts on coordinator prose. The suite cannot catch a regression here, and building that assertion was out of scope. Worth raising with Robin separately.

### Related

- Commit `b300f78`
- [2026-07-29] `claude-team sync`: one command for the three-copy persona problem (same failure class, fourth surface)
- [2026-07-04] v0.7: established the session-scoped `/name` guidance this extends
- `profiles/tiers.conf`, `scripts/generate-agents.sh:69` (skips `coordinator*`)

---

## [2026-07-29] Two stale promises: a customization layer that should not exist, and a feature that already did

**Category:** `decision`
**Tags:** `roadmap`, `docs`, `handoff`, `codegen`, `messaging`, `dogfooding`

**Risk Level:** `low`
**Breaking Change:** `no`

### Summary

PRs #23 and #24 close the same kind of gap from opposite directions: the documentation described a product that did not match the code. #23 removed a promise that should never be kept. #24 found a shipped feature listed as unbuilt, and fixed the one surface where it failed to arrive. The suite went 163 to 175.

### Detail

**Local profile overrides were retired rather than deferred.** They had been the top unbuilt roadmap item since v2 planning. The reasoning that killed them came from the product owner and is worth preserving verbatim in spirit: an override layer creates a second source of persona truth competing with the repo, and no reliable way to tell whether Akira is behaving like upstream Akira or like a local edit. Team-scoped profiles, the same layer at project scope via `claude-team init` and `.claude-team/`, went for the same reason. The supported paths are the two that already existed, a pull request or a fork, and `CONTRIBUTING.md` now documents both along with persona authoring.

**The installer was overstating what it had activated, and the first diagnosis was wrong.** The claim was that it advertised subagents as ready to delegate to. That message had been deleted by `cbbb7a4` when `install.sh` began delegating to `claude-team sync`. The real defect was silence. Claude Code registers subagents and hooks when a session starts and reads slash commands on demand, so a sync activates one of three surfaces immediately. Nothing said so, three green checkmarks in a row read as three live capabilities, and `install.sh` closed with "Your Claude dev team is ready." The SessionStart hook had the starkest form of it, printing a bare checkmark for something that cannot by definition fire in the session that registers it.

**Session handoff briefing was listed as aspirational and had shipped with the personas.** All seventeen carried a Handoff Brief section with byte-identical opening and closing stems; both coordinator profiles instructed the coordinator to ask for one at a switch; three earlier DEVLOG entries treat "3 behaviors + handoff" as a structural invariant. The roadmap entry had been written by paraphrasing the already-shipped `robin.md` text.

**The defect was delivery, and it landed on the worst surface available.** `### Handoff Brief` sat inside `## Required Interactive Behaviors`, which `strip_interactive_behaviors` excises from every slash command: 17 of 17 subagents carried it, 0 of 17 slash commands did. `coordinator.md:126` tells the user to run `/<name>` at the exact moment of a handoff, and `:128` then tells the coordinator to ask that persona for a brief. The asker had the instruction. The answerer, on the path the coordinator itself recommends, had never been told what a Handoff Brief is.

**A test asserted the bug as correct.** The commands drift check mirrored the stripper's awk exactly, so the absence was not an oversight that slipped through review; it was pinned in place by CI. This is the third defect in two days where a green suite protected the wrong behavior, after the hook tests that passed while the hook never installed, and the three-copy persona problem that produced no error.

### Decisions Made

- **The heading was promoted rather than the stripper made cleverer.** `### Handoff Brief` became `## Handoff Brief`, and the stripper's end marker moved from `## Signature Question` to it. This codifies what the structure already implied: the section was deliberately unnumbered while its siblings are `### 1.`, `### 2.`, `### 3.`
- **The generator now refuses a profile with no `## Handoff Brief`.** The stripper resets its skip flag on that marker, so a profile lacking it would silently drop every later section from the slash command. The identical latent failure exists with `## Signature Question` and goes unnoticed only because all seventeen happen to have one.
- **Handoffs stay prompt-only.** No file, no command, no stored state. This keeps the feature clear of the shared-state locking the branch index needed, and it was the product owner's explicit call.
- **Parallel session prompts gained a fourth Context field.** They carried Persona, Task, and File scope, so every session re-derived context it was never given. A finished session with dependents now writes a brief that becomes the downstream Context.
- **Dated history is never rewritten.** The roadmap row promoting overrides to top priority stays verbatim; new rows record the retirement and the correction.

### Mistakes Worth Recording

- **A control test passed for the wrong reason.** Proving the traversal tests were meaningful required running them against pre-fix code, but the scratch tree was missing `gtm.md`, so the traversal resolved to nothing and every assertion passed against unfixed code. The suite now asserts the traversal target exists before testing against it. The same mistake nearly recurred on the handoff control.
- **The installer diagnosis was wrong in its specifics** and was corrected in the PR body rather than quietly restated. The message being blamed had been deleted three commits earlier.

### Related

- PR #23, PR #24
- `CONTRIBUTING.md`: the supported customization paths and persona authoring
- ROADMAP: the aspirational list is now empty, two items retired and one found already shipped

---

## [2026-07-29] v2 hardening: four specialists, a real race, and a lint I broke

**Category:** `milestone`
**Tags:** `concurrency`, `locking`, `codegen`, `security`, `versioning`, `dogfooding`, `delegation`

**Risk Level:** `medium`
**Breaking Change:** `no`

### Summary

An adversarial review of the codebase produced five findings. All five are fixed, each by the persona whose lane it sits in, working from the installed profiles rather than the repo copy. The suite went 136 to 163. The headline result: the parallel-sessions feature was silently losing data, and two of the four specialists found defects the review had missed.

### Detail

**Dogfooding was the precondition, not a nicety.** The team was cloned and installed through the documented path before any delegation. That validated the two install fixes shipped earlier the same day: the SessionStart hook registered itself in `~/.claude/settings.json`, and all three persona surfaces landed. It also surfaced a gap: Claude Code registers subagent types at session start, so seventeen freshly installed agents were invisible to the running session. The installer prints "Subagents installed (delegate with...)" as though they are live, while `install-commands` correctly states that slash commands need no restart. The one that needs a restart is the one that does not say so. The first round of delegation ran against profiles read from `~/.claude/team/` instead; the agent types appeared later in the session.

**The race was real and worse than reported.** The review found that `cmd_branch_close` does a read-modify-write with no lock, and reasoned that the `>>` appends in `branch start` and `session start` were safe because POSIX makes an O_APPEND write atomic. Akira verified that reasoning, confirmed no row was ever torn, and then showed it was beside the point: an append landing between a rewriter's read and its rename is **erased** by that rename. Atomicity of an append says nothing about its survival. That is the load-bearing argument for locking the appenders too, and the review had explicitly waved it off. Measured at 40-way concurrency, five runs, every run lost data: 23 to 29 of 40 rows survived, 5 to 8 of 20 status updates applied.

He also found a second failure mode nobody had looked for. `block_install` greps for its start marker, misses it against a concurrent write that has not landed, takes the append path, and writes a duplicate block. Two of five runs produced up to four `CLAUDE-TEAM` blocks in `CLAUDE.md`, after which `get_active` reads a corrupted awk range.

**Verification beat reasoning, twice, in the same change.** Akira's first locking implementation treated "no owner record" as stale. Every live holder passes through that state for microseconds between its `mkdir` and its record write, so contenders broke live locks 73 times per run. It also treated "no lock directory" as stale, so contenders removed directories other contenders had just created. Neither was caught by review; both were caught by a harness built to look for them.

**The commands generator closed a gap that had already bitten twice.** `commands/` was hand-maintained while being about 95 percent derivable, and the drift test already contained the transformation as a checker. Alex turned the checker into a generator. He also overruled the brief: offered a choice between extending `generate-agents.sh` and adding a sibling script, he extended it, because `claude-team sync` and `install.sh` both invoke that one script and a sibling would never run on either path, reopening the same gap one level down.

**Two findings were correctly downgraded.** Morgan rated the path traversal Low, Informational as a vulnerability, and said so rather than inflating it: the CLI runs as the invoking user, reads with that user's permissions, and appends `.md`, so every reachable file is one the caller can already `cat`. He fixed it anyway on correctness grounds, because `use ../gtm` exited 0, printed a success line with an empty name, and pinned a non-profile into global state. He also checked `sanitize_branch_for_path`, found git's `check-ref-format` already rejects `..`, and left it alone on the grounds that a control reducing no risk is a liability.

**The symlink finding was closed as working-as-intended.** If the clone moves, the CLI and hook break loudly, and loud is correct: the install genuinely is broken and `bash install.sh` repairs it. Silencing it would hide real breakage, and the symlink buys `git pull` updating the CLI with no reinstall.

### Decisions Made

- **A `mkdir` directory lock, not `flock` with a fallback.** `flock` is absent from stock macOS. A two-scheme design does not exclude itself, so any host with mixed invocations silently loses mutual exclusion, and the fallback would run only on the platform CI does not cover it. The accepted cost is owning liveness by hand: traps, a dead-PID rule, and a 120 second ceiling for the reboot case.
- **Temp files are created beside their destination.** Not comment accuracy. A cross-device `mv` degrades to copy plus unlink, and a reader can observe a half-copied index during it, so this is what makes "readers need no lock" true.
- **The greeting is excised from `use` but not from `launch`.** `use` pins a default that every future session reads; `launch` starts one session, which is the moment a greeting is for.
- **Version numbering normalised to v2.0.0 with no fabricated v1 release.** The repository has no git tags, so v1 is presented as the first generation rather than a dated release. The April roadmap row still reads "v0.6 shipping" and stays verbatim: a dated changelog entry is not rewritten to match a later renumber.

### Mistakes Worth Recording

- **I broke CI lint and shipped it.** Commit `00b82aa` introduced three shellcheck findings in `tests/run.sh`, two of them a bare `done` read as a loop terminator. The rest of the suite already quotes `"done"` for exactly that reason, so the new code was the outlier against a convention already visible in the file. Morgan caught it while working in an adjacent file.
- **Morgan's suggested fix for one of those was wrong.** Quoting `${spec%%:*}` would have passed `coordinator on` as a single argument and broken the test. The finding was right and the fix was not, which is the argument for verifying a subagent's patch rather than applying it.
- **A control test passed for the wrong reason.** The first attempt to prove the traversal tests were meaningful ran against a scratch tree that did not contain `gtm.md`, so the traversal resolved to nothing and every assertion passed on unfixed code. The suite now asserts the traversal target exists before testing against it.
- **A `git add` swept a running agent's work into an unrelated commit.** Morgan's `resolve_name` fix landed inside the locking commit. Harmless to the code, wrong for the history. Scoped `git add <paths>` is the rule while agents are live.

### Related

- PRs #19, #20, #21: the same-day work this builds on
- `WRITING.md`: the plain technical English standard all four specialists wrote to
- ROADMAP: local profile overrides, now top priority and still the real gap

---

## [2026-07-29] claude-team sync: one command for the three-copy persona problem

**Category:** `decision`
**Tags:** `cli`, `install`, `sync`, `drift`, `customization`, `bugfix`

**Risk Level:** `low`
**Breaking Change:** `no`

### Summary

Adds `claude-team sync`, which regenerates subagents from profiles and reinstalls all three installed persona copies. `install.sh` now delegates its copying to it, so one code path decides where persona files land. Also fixes a crash shipped in PR #20.

### Detail

**The trap.** A persona is installed as three self-contained files: `~/.claude/team/<name>.md` (read by `show` and `use`), `~/.claude/agents/<name>.md` (the delegation subagent), and `~/.claude/commands/<name>.md` (the `/<name>` slash command). Nothing linked them. Editing the installed profile, which is the obvious move since `claude-team show` reads it, updated exactly one of the three and left the other two stale with no warning and no error. `/akira` and `use akira` would disagree about who Akira is, and the user would sooner blame the model than suspect three divergent files. The README made it worse: "Adding Your Own Team Members" step 3 said to `cp` the profile into `~/.claude/team/`, which produces a persona with no slash command and no subagent.

**Why this was the one worth fixing.** Two other install gaps surfaced in the same sweep. The CLI symlink into the clone breaks loudly if the clone moves, and loud is correct there: the install genuinely is broken and `bash install.sh` fixes it, so silencing it would hide real breakage. `WRITING.md` not being installed is cosmetic. This one fails silently and partially, and it hits persona customization, which is the product's whole point. README line 885 still lists `~/.claude/team/local/` overrides as planned, so there was no supported customization path at all.

**install.sh now delegates.** Its three copy blocks were replaced with one `"$BIN_SRC" sync` call, and the CLI symlink step moved ahead of it so the binary exists when it is invoked. This follows the convention the coordinator path already set: the CLI owns the edit, install.sh calls it, and the suite exercises the same path users do. Without it there would be two copy implementations free to drift, which is the exact bug class this repository keeps hitting.

**A crash from PR #20 was found and fixed.** `cmd_install_hook` called `yellow` in its python3-missing branch, but `bin/claude-team` never defined that helper; only `install.sh` had it. Under `set -euo pipefail` an undefined function exits 127, so `claude-team install-hook` would have crashed instead of printing the manual JSON on any machine without python3. Neither the suite nor shellcheck caught it, because every CI runner has python3 and that branch never executed. Verified fixed by running the command against a restricted PATH.

### Decisions Made

- **`sync` regenerates before copying.** `agents/` is derived from `profiles/`, so copying first would install subagents lagging the profile edit that prompted the sync.
- **`sync` does not generate slash commands.** `commands/` is hand-maintained by design, being the profile with Required Interactive Behaviors excised and a switch preamble wrapped around it. `sync` copies them; the drift test catches divergence. Documented rather than automated.
- **The symlink stays.** It buys `git pull` updating the CLI with no reinstall, and its failure mode is loud and self-announcing.

### Related

- PR #20: introduced the `yellow` crash fixed here
- `README.md` "Editing an existing persona": the three-copy table
- README Roadmap line 885: `~/.claude/team/local/` overrides, still unbuilt

---

## [2026-07-29] Plain technical English: ASD-STE100 principles for the coding six, without the dictionary

**Category:** `decision`
**Tags:** `personas`, `writing`, `asd-ste100`, `plain-language`, `house-style`, `scope`

**Risk Level:** `low`
**Breaking Change:** `no`

### Summary

The six coding personas now carry a fourteen-rule plain technical English standard adapted from ASD-STE100. The standard is cited as a source of principles, not as a conformance target, and the controlled dictionary is deliberately left out. `WRITING.md` is the new source of truth.

### Detail

**The starting question was whether to instruct personas to "use ASD-STE100."** The answer is no, for a reason worth recording so nobody later "fixes" this by adding the dictionary. ASD-STE100 is two things: roughly 65 writing rules, and a closed dictionary of about 900 approved words, each with one approved meaning and one approved part of speech. The rules transfer to software. The dictionary does not. A persona told to "use ASD-STE100" approximates that dictionary from memory, differently every time, producing the register of the standard with none of its guarantee. The dictionary also excludes most vocabulary these personas need (`idempotent`, `eventual consistency`, `refresh token rotation` are all out unless first declared as Technical Names or Technical Verbs), and full conformance restricts tense, bans `-ing` forms, and governs article usage. That produces maintenance-manual prose and would flatten seventeen deliberately distinct persona voices into one.

**Prior art settled it.** NVIDIA NemoClaw's `WRITING.md` hit the same problem and resolved it the same way: "NemoClaw uses the plain-language principles in ASD-STE100 Issue 9 for software engineering. NemoClaw does not claim full ASD-STE100 compliance," plus an explicit instruction not to copy the dictionary or its examples into the repository. Two details were worth adopting directly: word counts are review targets rather than mechanical limits, and quoted text, code, identifiers, commands, and URLs sit outside the sentence rules entirely. Our rules and examples are written for this repository rather than copied.

**Scope was the contested decision.** The first recommendation was all seventeen personas with the rules scoped by surface, on the reasoning that everyone writes commit messages and PR descriptions, and a surface carve-out neutralises the objection from the creative personas. That was wrong, and got overruled. The carve-out is itself a conditional the model must apply correctly every time, nothing in this repository enforces it, and no test would catch Ernie's flavor text going flat. Scoping by persona deletes the conditional: the rules are in a prompt or they are not. The cost is also asymmetric, since extending from six to more later is a cheap edit while silently flattening a deliberately built voice is not.

**Two self-contradictions were fixed in the same change,** both inside the blast radius: `robin.md` instructed the persona to "present trade-offs clearly" and `morgan.md` to redirect "after clearly stating" constraints, while rule 10 of the new block deletes `clearly` as filler. Rule 10 was also written to target filler specifically, because a first pass flagged five legitimate uses of "not just X, but Y" across the profiles, which is a real contrast construction rather than padding.

**Three surfaces, one source.** `profiles/` is the source of truth, `agents/` is generated by `scripts/generate-agents.sh`, and `commands/` is hand-maintained as the profile with Required Interactive Behaviors excised. The suite caught the commands drift immediately; the block was then extracted verbatim from each profile rather than retyped, so the two copies cannot diverge. 128/128 passing.

### Decisions Made

- **Principles cited, dictionary omitted, no conformance claimed.** Full ASD-STE100 conformance requires maintaining a Technical Names and Technical Verbs whitelist covering every domain term across six personas. The cost is real and the benefit over the fourteen rules is small.
- **Six coding personas only.** Ernie writes narrative flavor text, Toni writes marketing copy, and Iris writes brand voice. A word-count rule applied to that work removes the craft it exists to produce.
- **"Clarity is not dilution" closes every block,** tailored per persona, because the rules could otherwise be read as licence to drop specifics. Every profile already demands the protocol, the CVE, or the WCAG criterion over abstractions, and that demand wins where the two appear to conflict.
- **Language findings are suggestions by default.** They block only when the ambiguity can change behavior, security, data safety, or the meaning of a test, and the comment must name that effect.

### Related

- `WRITING.md`: the rules, the rationale, and thirteen rewrite examples
- [NVIDIA/NemoClaw `WRITING.md`](https://github.com/NVIDIA/NemoClaw/blob/main/WRITING.md) (Apache-2.0): the prior art
- [ASD-STE100](https://www.asd-ste100.org/): the source standard
- [2026-07-28] "As much as needed, as little as possible": the shared-block precedent this follows

---

## [2026-07-28] claude-illustrate-skill shipped: Iris gets a pipeline, logos get made without a vendor

**Category:** `milestone`
**Tags:** `skills`, `iris`, `image-generation`, `svg`, `companion-tools`, `dogfooding`

**Risk Level:** `low`
**Breaking Change:** `no`

### Summary

Proposal 6 shipped as [claude-illustrate-skill](https://github.com/code-katz/claude-illustrate-skill), the seventh companion tool, carrying the backend mechanics that were deliberately kept out of claude-team-cli. Its central finding: logos and icons need no image backend at all. Iris now references it, and the README lists it.

### Detail

**Why a skill and not the persona repo:** a vendor MCP matrix inside claude-team-cli would be documentation the project does not control, drifting on someone else's release schedule, and it would break the convention that every companion capability lives in its own repo while "Works Well With" stays one line and a link. Backend mechanics also serve Reiner, Ernie, Toni, and Kai, not only Iris.

**The load-bearing design decision:** vector marks are authored directly as SVG, rendered across the size ladder, inspected, and refined. No account, no API key, no vendor, no cost. This is the default track, not a fallback, and it answers most of what people mean by "design a logo." A generation backend is only needed for raster illustration, which is a far narrower gap than the original problem statement assumed.

**Structure:** follows Anthropic's `theme-factory` pattern, a thin orchestrating `SKILL.md` plus one data file per backend, so vendor detail stays isolated in a single file. Four backends documented with verified endpoints: Recraft (the only true-SVG generator; its npm package is deprecated in favour of the remote server), Hugging Face (free tier, weakest text rendering), Canva (brand kits are Enterprise-only, the most likely wrong inference about it), and Figma (a vector editor, not a generator). `reference/manifest.md` defines the provenance format that dropped Proposal 3 never got, and `reference/ip-and-licensing.md` covers copyright, trademark, and indemnification.

**Dogfooding caught three real bugs.** The render pipeline was tested rather than assumed, and every failure produced plausible-looking wrong output rather than an error: screenshotting a bare `.svg` with `--window-size` crops instead of scaling, so a "16px render" is the top-left corner of a 512px image; `<img src="...">` inside a `file://` contact sheet races the screenshot and fails silently, producing a blank sheet that reads as a design failure; and `--virtual-time-budget` is required or capture fires before layout settles. A fourth finding shaped the technique: individual small PNGs are unreadable when viewed alone, so the contact sheet is the primary inspection artifact rather than a nicety. Chromium is also frequently absent from `PATH` while present under the Playwright directory.

**Wiring (claude-team-cli):** seventh "Works Well With" row, a `git clone` install line (the skill is multi-file, so the single-file curl convention the other six use would silently install only `SKILL.md`), and one line in Iris pointing at it with instructions to work without it if absent.

### Decisions Made

- **Clone rather than curl for this one skill:** the other six are single-file and install with `curl -o .../SKILL.md`. This one has `backends/` and `reference/` siblings that `SKILL.md` reads on demand, so curl would install a skill missing most of its content. Documented as an explicit divergence rather than silently breaking the convention.
- **Original content, prior art credited:** all three third-party sources are MIT and could have been copied with attribution. Writing from scratch and crediting the ideas was cleaner and avoided inheriting workflows built around GUI tools that cannot be driven from Claude Code.
- **The skill degrades rather than requiring itself:** Iris is told to say when it is relying on the skill and to work without it if absent, so the persona never claims a capability the install has not provided. That is the same rule the Kai fix established.

### Related

- [claude-illustrate-skill](https://github.com/code-katz/claude-illustrate-skill) (MIT)
- [2026-07-28] Design lane split entry: created Iris and folded Proposal 4 into Proposal 6, which this closes
- `docs/proposals/image-generation.md`: the original six-proposal option space

---

## [2026-07-28] Design lane split: honest image backends, a visual QA loop, and Iris as persona #17

**Category:** `milestone`
**Tags:** `personas`, `iris`, `kai`, `image-generation`, `mcp`, `capability-claims`, `drift-guards`, `tests`

**Risk Level:** `low`
**Breaking Change:** `behavioral` (Kai no longer generates assets; brand asset work routes to Iris)

### Summary

Kai's profile claimed image-generation tooling the product never installs, which is the root cause behind "Kai cannot create quality images." PR #16 landed a written proposal covering the whole option space, then implemented three of its six proposals: honest backend declaration, a visual QA loop, and a lane split that adds Iris (Brand & Illustration) as persona #17. The suite grew from 123 to 128 tests, including two new guards for a class of silent drift CI could not previously catch.

### Detail

**The finding:** `profiles/kai.md` asserted Hugging Face MCP `dynamic_space` with FLUX.1-Krea-dev, Qwen-Image, and FLUX.1-Kontext-Dev, plus four Figma MCP tools. `install.sh` copies profiles, agents, and commands and never installs, configures, or checks an MCP server. Compounding it, no Claude model generates raster images natively, so Kai's real ceiling was markup it writes itself. The persona confidently described tools that were not present and then improvised. The session that produced this work demonstrated the bug live: the Hugging Face MCP server required authentication and was unavailable.

**Proposal doc first (20eb948):** `docs/proposals/image-generation.md` separates three asset classes that were being collapsed into one ask (vector brand marks, illustrative raster, composed layouts), surveys the July 2026 backend landscape (Recraft, Gemini image models, Ideogram, Firefly, Canva MCP, Claude Design, Hugging Face FLUX, Figma MCP), and lays out six proposals with sequencing. Notable finding: Canva's brand kit and brand template autofill, the feature that would actually enforce brand alignment, is gated behind Canva Enterprise on the MCP surface.

**Proposal 1, honest capability boundary (68e3a96):** the Personality paragraph now states the boundary directly, Domain Expertise bullets are backend agnostic, and a new "Declare the Backend" behavior requires naming the backend before promising an image, or saying none is connected and offering the hand-authored SVG path. Shipped as persona behavior only; a `claude-team doctor` CLI command was considered and declined.

**Proposal 2, visual QA loop (68e3a96):** a behavior requiring the artifact be opened and inspected before it is shown to the user, scored against named criteria (legibility at smallest use size, palette hexes matching the brief, spelling and kerning, set consistency), with the single worst failure named and one thing revised per pass, three passes maximum. Claude is multimodal on input, so this needed no vendor and no cost.

**Proposal 5, Iris as persona #17 (5c3c30d):** `profiles/iris.md` owns logo systems, wordmarks, icon sets, illustration, marketing graphics, and asset licensing and provenance, on tier `claude-opus-4-8`. Four behaviors: Declare the Backend, Brand Brief, Visual QA Loop, Asset Provenance Record. Kai keeps screens, flows, wireframes, device-frame mockups, and design systems, drops to four behaviors, and now specifies the assets a screen needs rather than generating them.

**Test hardening (5c3c30d):** CI ran shellcheck plus the suite on two platforms but never ran `scripts/generate-agents.sh` and never compared `agents/` against `profiles/`. The existing check counted files only, so a profile edited without regenerating passed green while the delegation subagent served stale text. The same hole existed for `commands/`, which is hand-maintained with nothing validating it. Both are now checked per persona by verifying every non-blank profile line appears verbatim in the derived file. The guards were verified by deliberately editing a profile without regenerating (both failed as intended) and then restoring (both passed).

**Roster plumbing:** `profiles/tiers.conf`, both coordinator profiles (four separate enumeration blocks each: roster bullets, fixed-width team table, routing suggestions, context-shift triggers), README (tagline, agent count, roster table, a new persona section, both project-structure trees), `.claude-plugin/plugin.json`, `install.sh`, and two listings in `bin/claude-team`.

**Proposals 3 and 4 closed out (3f7558d):** auditing Proposal 3 (a checked-in `BRAND.md`, `assets/MANIFEST.md`, and a `claude-team brand init` command) found two justifications that do not survive checking, so it was dropped rather than deferred. Proposal 4 was folded into Proposal 6: the companion skill is the delivery vehicle for backend wiring, not a separate item. Iris now routes by asset class, treating hand-authored SVG as the primary path for vector marks rather than a fallback. No vendor names remain anywhere in persona content. The audit also caught two stale README spots where Kai was still credited with image generation across five named vendors, contradicting his own profile.

**Wrap-up:** 128/128 tests passing, shellcheck clean across all five CI-linted files, and 17/17/17 across `profiles/`, `commands/`, and `agents/`. Proposal 6 (companion skill, now carrying Proposal 4's backend wiring) is the only one still open. Until it lands, Iris will hand-author SVG for logos and icons, which covers the original ask, and will correctly decline raster illustration rather than invent a backend.

### Decisions Made

- **Persona behavior over a CLI doctor command:** a `claude-team doctor` subcommand was proposed to report which image MCPs are reachable, and rejected. The false capability claims in the profile were the actual bug, and a diagnostic command does not stop a persona from making them. The runtime check also works better from inside the session, where the agent can see its own tool list.
- **Iris, not "Illustrator":** every persona in the roster is a human first name paired with a role. Naming #17 after its function would have broken the convention that makes `/kai` and `/robin` feel like colleagues rather than modes.
- **Kai hands off all asset generation:** the alternative of letting Kai keep "light" image work was rejected as a fuzzy boundary. Kai designs the surface, Iris produces what goes on it, mirroring the existing Kai to Sasha handoff.
- **The QA loop was split, not deleted:** proposals 1 and 2 added content to Kai that proposal 5 would relocate. Rather than accept the rework, the loop was authored from the start to cover both generated assets and rendered mockups, so the split gave Kai the render-and-screenshot half and Iris the generated-asset half. Both personas landed at four behaviors, inside the house range of three to four.
- **Backend agnostic over picking a vendor:** the profiles name a contract ("whichever backend is connected") rather than committing to Recraft, Gemini, or Canva. The vendor choice is proposal 4 and belongs to whoever is paying for it.
- **Drift guards compare content, not counts:** the existing agent check counted files, which is why it never caught staleness. The new guards compare lines, and were proven to fail before being accepted.
- **Proposal 3 dropped, not deferred:** its `claude-team brand init` rested on the claim that it mirrors `branch start` and `session start`, but those write only to `~/.claude/` and this CLI has never written a committable file into a user's working tree. It also claimed to unblock the "missing" `publish/style-guide.md`, which was in fact deliberately deleted in `04ace9e` and consolidated to an org-level location. Half of it had already shipped inside Iris, and naming an artifact the repo does not define is the established convention (Kai and Sasha have pointed at `DesignSystem.swift` with no schema for as long as they have existed).
- **Proposal 4 folded into Proposal 6:** a vendor MCP matrix inside this repo would be documentation the project does not control, and it breaks the convention that every companion capability lives in its own repo while "Works Well With" stays one line and a link. Backend mechanics also serve Reiner, Ernie, Toni, and Kai, not only Iris.
- **SVG first for vector marks:** prior-art research found that `neonwatty/logo-designer-skill` generates SVG concepts with no image backend at all. The vector-mark problem therefore needs no vendor, which narrows the backend question to raster illustration and makes the original problem statement ("Kai cannot create quality images") largely answerable without one.
- **No "Works Well With" row until the skill exists:** linking a repo that has not been built would be the same class of bug this entry is about.

### Related

- PR #16 (proposal doc, proposals 1, 2, and 5 implemented; 3 dropped; 4 folded into 6)
- `docs/proposals/image-generation.md` (the full option space, with the post-implementation decision record and prior-art research for the skill)
- [2026-03-17] Codekatz brand identity entry: the 10 cat persona badges were produced through Gemini by hand, outside any persona workflow. Iris is the attempt to bring that work in house.
- [2026-07-27] CI entry: the three-job workflow whose agent-sync blind spot the new drift guards close

---

## [2026-07-28] "As much as needed, as little as possible" first principle for the six coding personas

**Category:** `feature`
**Tags:** `personas`, `first-principle`, `simplicity`, `over-engineering`, `required-interactive-behaviors`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary

The six coding personas (Akira, Sasha, Robin, Alex, Morgan, Jordan) now open with a shared first principle: as much as needed, as little as possible. Their Required Interactive Behaviors also changed from unconditional to stakes-scaled, so a one-line fix no longer triggers a full Tradeoff Scorecard, STRIDE model, or Test Matrix.

### Detail

Prompted by an observed failure mode: persona-led coding work was consistently over-complicated relative to the task. Two distinct causes were identified and both were addressed, because fixing only the first would have left the ceremony overhead intact.

**Cause 1, no bias toward the minimum solution.** Added a `## First Principle: As Much as Needed, As Little as Possible` section to each of the six profiles, positioned first (immediately after the intro, before `## Personality`) so it frames the persona's own instincts rather than qualifying them after the fact. All six share an identical opening sentence ("Complexity must be earned. Start from the minimum that fully solves the stated problem, and add more only when a requirement that exists today demands it.") followed by four bullets in that persona's own domain language:

- **Akira**: simplest architecture meeting stated scale and consistency requirements; name the threshold that justifies the next tier and stop there; every service, queue, and cache is a new failure mode and attack surface; simplicity as a security property.
- **Sasha**: fewest states and props, no speculative flexibility; prefer the platform before a package (semantic HTML, native form controls, modern CSS); simplicity as a UX property, since less JavaScript means fewer ways to break keyboard and screen reader flows.
- **Robin**: smallest suite that gives real confidence; test depth follows risk (exhaustive at security, money, and data-integrity boundaries, lean where failure is cheap and reversible); write each test at the lowest layer that catches the failure; coverage of what can hurt you, not a coverage percentage.
- **Alex**: simplest infrastructure that is reproducible (a container and a managed service before an orchestration platform); name the trigger that justifies the next tier; fewer things that can page someone at 3am.
- **Morgan**: controls matched to the actual threat model and data classification rather than a maximal checklist; severity drives response (Critical blocks, Low gets a backlog note); removal as the strongest mitigation; a control that adds complexity without reducing risk breeds workarounds, and workarounds are where breaches live.
- **Jordan**: a scheduled query beats a platform; no ML where SQL will do; prove value before adding infrastructure; every pipeline hop is a place for silent failure to hide.

**Cause 2, unconditional ceremony.** Each persona's `## Required Interactive Behaviors` section gained a one-line preamble scaling the behaviors to the stakes of the change. Akira, Sasha, Robin, and Alex use a skip variant ("mandatory for [new architecture / new components / new surfaces / deployed infrastructure]. For [routine, low-risk] changes, skip them rather than perform ceremony that adds no insight."). Morgan and Jordan use a delta variant instead, since a security- or data-touching change inside an existing system still warrants assessing what changed: "a small change inside an already-modeled system gets a delta assessment of what changed, not a fresh model."

All new prose is emdash-free per the house style established in the [2026-07-27] entry below. Profiles are the single source of truth, so `scripts/generate-agents.sh` was re-run: all 16 agents regenerate deterministically and exactly the 6 coding agents changed, which confirms the delta is limited to this edit. Also added a two-line summary of the shared principle to the README under `## Meet the Team`.

Scope was deliberately limited to the six coding personas. Casey and Kai were considered and excluded: both produce code (SQL and dashboards, HTML/CSS mockups) but both already carry strong minimalism doctrine (Casey's Clutter Audit and data-ink ratio, Kai's constraint-first briefs). The four Game Development Team personas were out of scope, as none of them writes code. Toni, River, Quinn, and Sage were never in scope, since the observed problem was specific to coding work.

Interaction check: Sasha's Design System Gate ([2026-03-29] entry below) is unaffected. The stakes preamble exempts "copy tweaks and token-level changes," which are not the SwiftUI UI construction the gate governs. The gate still halts on a missing design system.

### Decisions Made

- **New top-level section over a bullet in Enterprise Security Focus:** the [2026-03-26] lint entry established that shared cross-persona guidance goes in Enterprise Security Focus to preserve the "3 behaviors + handoff" structure. That precedent was deliberately not followed here. Simplicity is not a security concern, and burying a governing principle in a mid-file bullet list would not give it the framing weight needed to counteract over-engineering. The "3 behaviors + handoff" structure is still preserved, since no 4th behavior was added, so the two decisions coexist.
- **Positioned before `## Personality`:** placement is the mechanism. The principle has to be read before the persona's own instincts (Akira's tradeoff analysis, Morgan's adversarial default) rather than as a caveat after them.
- **Shared opening sentence, domain-specific bullets:** same pattern as the [2026-03-26] lint rollout. The identical first sentence makes the principle recognizable as a team-wide rule, and the per-persona bullets keep it in each voice so it does not read as boilerplate.
- **Both causes addressed, not just the code output:** the ritual overhead was a significant share of the observed over-complication, so scoping the fix to proposed solutions only would have left half the problem in place.
- **Delta assessment over skip for Morgan and Jordan:** rejected the uniform "skip it" wording for these two. Silently skipping a threat model or lineage check on a security-relevant or data-touching change is exactly the failure mode those behaviors exist to prevent. Scaling down to a delta preserves the check while removing the ceremony.
- **Six personas, not eight or ten:** Casey and Kai were evaluated and excluded rather than included for symmetry. Adding a minimalism principle to personas that already enforce minimalism is itself a violation of the principle.

### Related

- [2026-03-26] Added lint requirement to all engineer personas and coordinator: same six-persona rollout pattern, and the source of the structural precedent this entry departs from
- [2026-07-27] Game Development Team entry: established the no-emdash house style this entry's prose follows
- [2026-03-29] Added Design System collaboration loop between Kai and Sasha: Sasha's Design System Gate, confirmed unaffected

---

## [2026-07-27] CI lands: three-job workflow, review hardening, Bash 4+ floor

**Category:** `milestone`
**Tags:** `ci`, `github-actions`, `hardening`, `bash-4`, `atomic-writes`, `tests`
**Risk Level:** `low`
**Breaking Change:** `behavioral` (Bash 3.2 is refused at every entry point)

### Summary

The repo now has continuous integration. PR #14 introduced a three-job GitHub Actions workflow (shellcheck, tests on Linux, tests on macOS) alongside code-review hardening of the CLI and a Bash 4+ requirement across every entry point; PR #15 fixed the one failure CI itself surfaced (the test suite depended on ambient git identity). main is green across all three jobs and the suite stands at 123 tests.

### Detail

**CI workflow (PR #14):** `.github/workflows/ci.yml` runs three jobs: `shellcheck` (ubuntu-latest, honoring the repo `.shellcheckrc`), `tests (linux)` (ubuntu-latest), and `tests (macos)` (macos-latest, which first installs a current bash via Homebrew because stock macOS ships 3.2, below the new floor).

**Code-review hardening (PR #14, ecb6e8f):** bin/claude-team file handling was hardened per code review: writes are now atomic (temp file then mv) and branch-index lookups match literal names rather than treating them as patterns. `.shellcheckrc` was trimmed to three documented disables (SC2016, SC2005, SC2001).

**Bash 4+ floor (PR #14, 58f79c1):** bin/claude-team, install.sh, and tests/run.sh all guard on BASH_VERSINFO and exit with a clear message (plus a `brew install bash` pointer) on anything older than Bash 4, formalizing that stock-macOS Bash 3.2 is unsupported.

**CI identity fix (PR #15, bbf0993):** the session tests seed throwaway repos with real commits, which fails on machines with no git identity configured (GitHub runners, fresh installs): the seeded repo ends up with no commits, worktree creation has nothing to branch from, and 13 session assertions fail. The suite now exports its own GIT_AUTHOR_*/GIT_COMMITTER_* identity instead of depending on ambient config. Two assertions that false-passed on the runner were also tightened to match leftover index rows anywhere in the file.

**Wrap-up:** all three jobs are green on main at merge commit 98c2b60. The feature branch claude/add-team-personas-9jyqiz is fully retired (GitHub auto-deleted the remote ref on merge; the local branch was removed with a merged-only check and the stale tracking ref pruned). install.sh was re-run so ~/.claude now carries all sixteen profiles, agents, and slash commands; the CLI itself needed nothing because ~/.local/bin/claude-team symlinks into the repo. Tests: 123/123 locally (103 at the previous entry).

### Decisions Made

- **Test macOS with Homebrew bash, not against 3.2:** the CLI and suite require Bash 4+, so the macOS job installs a current bash rather than pinning the stock shell. CI validates the supported configuration, not the explicitly dropped one.
- **The test suite owns its git identity:** exporting GIT_AUTHOR/GIT_COMMITTER inside the suite beats configuring identity on runners, because the suite then works on any fresh machine with zero setup, the same contract install.sh implies.
- **Merge commits retained:** PR #15 merged with the merge-commit method, matching the history of PRs #11 through #14.

### Related

- PR #14 (CI workflow, CLI hardening, Bash 4+ floor), PR #15 (test-suite git identity)
- [2026-07-27] Game Development Team entry: the persona work (PRs #12 and #13) that rode this branch before the CI work
- [2026-07-04] v0.7 entry: the launcher and worktree machinery the hardened file handling protects

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
