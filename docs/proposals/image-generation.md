# Proposal: Quality image generation for the design lane

**Status:** Proposals 1, 2, and 5 implemented. Proposal 3 dropped. Proposal 4 folded into Proposal 6, which remains open.
**Date:** 2026-07-28
**Owner:** Code Katz
**Problem:** Kai cannot produce quality images. We need a persona that can design a logo, an icon set, and brand-aligned graphics from a written brief and a style guide.

> **Implementation note.** Proposal 1 shipped as persona behavior only; the `claude-team doctor` CLI command described below was explicitly declined, so backend honesty is enforced by the "Declare the Backend" behavior rather than by a diagnostic command. Proposal 5 shipped as **Iris — Brand & Illustration** (persona #17), with Kai handing off all asset generation and keeping screens, layout, and design systems. The `profiles/kai.md` line-number citations in the sections below refer to the pre-change file and are left as written for the historical record.

## Decisions after implementation

**Proposal 3 is dropped.** Two of its justifications did not survive checking. It claims `claude-team brand init` would mirror `branch start` and `session start`; those write exclusively to `~/.claude/`, and the CLI has never written a committable file into a user's working tree (its only project writes, `.git/hooks/pre-commit` and `.git/info/exclude`, are untracked by design). It also claims to unblock the repo's "missing" `publish/style-guide.md`; that file was deliberately deleted in `04ace9e` ("consolidated to code-katz/style-guide.md"), so re-adding a per-repo brand file re-introduces what was removed on purpose. Separately, half of Proposal 3 already shipped inside Iris's Brand Brief and Asset Provenance Record behaviors, and "persona names an artifact the repo does not define" is the established convention here (Kai and Sasha have pointed at `DesignSystem.swift` with no schema since they were written). Accepted tradeoff: Iris keeps improvising a manifest shape per project. If that becomes a problem, define schemas for all four artifacts at once rather than only Iris's.

**Proposal 4 is folded into Proposal 6.** They were decomposed as separate items and should not have been: the companion skill is the delivery vehicle for backend wiring. A vendor matrix inside this repo would be documentation the project does not control, drifting on someone else's release schedule, and it would break the convention that every companion capability (devlog, roadmap, plans, todo, publish, conductor) lives in its own repo while "Works Well With" stays one line and a link. Backend mechanics also serve more than Iris: Reiner and Ernie will want card art, Toni marketing graphics, Kai mockup assets. Persona content keeps the taste ("vector marks need vector-native output"); the skill takes the mechanics ("the endpoint is X, the npm package is deprecated").

### Prior art for the skill

Researched 2026-07-28. **Licenses were not verifiable in that session** (api.github.com returned 403 through the proxy); verify each before copying anything.

- **`neonwatty/logo-designer-skill`** is the closest analogue: interview, explore (3-5 SVG concepts side by side), refine, export (PNG at 16/32/48/192/512/1024/2048). It generates SVG directly with **no image backend at all**. This is the most important finding, and it revises the framing above: the vector-mark problem does not need a vendor. Claude writing SVG, rendered at multiple sizes and run through the Visual QA Loop, is a complete logo pipeline at zero cost. The backend table below already said "Claude alone, wiring effort: None" and then under-weighted it. External backends are for raster illustration, a much narrower need than "Iris cannot make images."
- **`designrique/ai-graphic-design-skill`** is a knowledge source rather than a pipeline (much of its workflow assumes a human driving Midjourney, Illustrator, and Photoshop). Worth borrowing: its backend decision table, which independently reaches Recraft for vector logos; its IP indemnification risk matrix; and its raster-to-vector pipeline (upscale, vectorize, bezier cleanup).
- **`jezweb/claude-skills`** (design-assets/ai-image-generator) contributes API mechanics and one hard-won lesson: call image APIs from Python with urllib rather than curl, because shell escaping breaks on apostrophes.
- **Anthropic's `theme-factory`** gives the structural pattern: a thin `SKILL.md` that orchestrates plus one data file per theme in a sibling directory. Mapped onto an image skill, that means one file per backend, which isolates vendor drift to a single file instead of accepting it as a standing risk.

---

## TL;DR

The gap is not Kai's design judgment. It is that **no Claude model generates raster images**, so Kai can only emit what Claude can type: HTML, CSS, and SVG. Kai's profile already claims Hugging Face and Figma image tooling, but nothing in this repo installs, verifies, or teaches those tools, so the persona promises a capability the install does not deliver.

Four things need fixing, and only one of them is a vendor decision:

1. **Honesty**: stop claiming image tools the installer does not provide. Detect what is actually connected.
2. **Iteration**: Claude can *see* images even though it cannot draw them. A generate, inspect, critique, regenerate loop is available today and costs nothing.
3. **Memory**: brand alignment needs a checked-in brand spec, not a per-session mood board that evaporates.
4. **Backend**: pick a generator (or a documented set of them).

**Does this require Canva?** No, and Canva is probably the wrong first choice for logos and icons specifically. Canva is strong when the deliverable is an editable, on-brand layout. Its brand kit and brand template autofill (the exact feature that would enforce "aligned with brand") is gated behind **Canva Enterprise** on the MCP surface, per Canva's own MCP docs. For logo and icon work the better fit is a vector-native generator, because a logo needs to be an SVG, not a PNG of an SVG.

---

## 1. What "quality images" actually means here

"Generate images" collapses three different problems with three different right answers. Treating them as one problem is why the output disappoints.

| Class | Examples in this project | What good looks like | Right tool family |
|---|---|---|---|
| **A. Vector brand marks** | Code Katz paw logo, favicon at 32px, GitHub org avatar, UI icon sets | True SVG paths, legible at 16px, few nodes, editable in Figma, trademark-able | Vector-native generation, or hand-authored SVG. Diffusion raster models are the wrong instrument. |
| **B. Illustrative raster** | The 10 cat persona badges, Medium hero images, textures, game art | Consistent character and style across a set, correct spelling in any embedded text, 2K or better | Diffusion image models (Nano Banana, Recraft, Ideogram, FLUX, Firefly) |
| **C. Composed layouts** | Badge cards, README headers, social cards, one-pagers, decks | Type hierarchy, grid, real fonts, exact colors, editable afterwards | HTML/CSS or SVG that Claude writes directly, Figma, or Canva. Not a prompt-to-image problem. |

This repo already needs all three. The DEVLOG entry for 2026-03-17 records the cat badges being produced through Gemini by hand, outside any persona workflow, and `publish/style-guide.md` is referenced there but does not exist in this repository. That is the workflow we are trying to bring inside the team.

**Key consequence:** a single "connect Canva and we're done" answer cannot cover A, B, and C. The proposal below separates them.

---

## 2. Why Kai produces weak images today

Four root causes, each with evidence in the repo.

### 2.1 No native raster generation

Claude models generate text. Kai's ceiling for a "logo" is hand-authored SVG. That is genuinely fine for geometric marks (a paw, a bracket, a monogram) and genuinely poor for anything illustrative. Nothing in the persona acknowledges this boundary, so Kai attempts illustrative work with a text tool and the result is what you have seen.

### 2.2 The persona claims tools the installer never installs

- `profiles/kai.md:13` — "You know the available image generation tools (Hugging Face MCP spaces, Figma MCP)"
- `profiles/kai.md:23` — "prompt engineering for FLUX.1-Krea-dev, Qwen-Image, and FLUX.1-Kontext-Dev models via Hugging Face MCP (`dynamic_space`)"
- `profiles/kai.md:24` — Figma MCP tool names

`install.sh` copies profiles, agents, and commands. It never checks for, configures, or mentions an MCP server. A user who installs claude-team-cli and runs `/kai` gets a persona confidently describing tools that are not connected. Kai then improvises, which is exactly the failure mode being reported.

### 2.3 No visual feedback loop

This is the single largest quality lever and it needs no vendor at all. Claude is multimodal on **input**: reading a PNG or SVG file shows Claude the actual picture. Kai currently has no instruction to look at what came back. A designer who cannot see their own output cannot iterate, and prompt-and-pray produces prompt-and-pray quality.

### 2.4 No persistent brand spec

Kai's "Mood Board Prompt" (`profiles/kai.md:53-64`) is a per-session table. It is not written anywhere, so session two starts cold, and the icon set does not match the logo that was generated last week. "Aligned with brand / style guide" requires the style guide to be a file the persona reads, not a conversation it half-remembers.

---

## 3. The backend landscape (July 2026)

Verified against vendor docs and current comparisons. Vendor pricing and plan gates move quickly, so confirm before committing.

| Backend | Best at | True SVG? | Brand control | Access | Wiring effort |
|---|---|---|---|---|---|
| **Claude alone (SVG/HTML)** | Class A geometric marks, all of Class C | Yes, hand-authored | Total, it reads your tokens | Already installed | None |
| **Recraft** | Class A logos and icon sets, Class B vector illustration | **Yes, native vector paths** | Style references from your own assets, brand palette | API key, MCP server available | Low |
| **Gemini "Nano Banana 2" / Gemini 3 Pro Image** | Class B general workhorse, 4K, reliable text rendering | No | Prompt plus reference images | API key, cheap, scriptable | Low |
| **Ideogram** | Class B wordmarks and any embedded typography | No | Prompt plus style codes | API key | Low |
| **Adobe Firefly** | Class B where legal exposure matters | No | Brand kits on enterprise tiers | Adobe plan | Medium |
| **Canva MCP** | Class C editable on-brand layouts, resizing, export | No | Brand kits and template autofill, **Enterprise plan only** | OAuth to `mcp.canva.com/mcp`, supported in Claude Code | Low, OAuth only |
| **Claude Design (Anthropic Labs)** | Class C decks, one-pagers, prototypes, exports into Canva | No | Canva Design Engine under the hood | Free on Pro/Max/Team/Enterprise | N/A, separate product surface, not an MCP into the CLI |
| **Hugging Face MCP (FLUX)** | Class B budget option, what Kai claims today | No | Prompt only | HF account, PRO for volume | Low |
| **Figma MCP** | Class C, turning a mark into a design system, mockups | Yes, it is a vector editor | Reads your real design system | Already connected in some environments | None if present |

### Reading the matrix

- **For logos and icons (the stated need), Recraft is the standout** because it emits real vector geometry rather than a rasterized approximation. A logo that arrives as editable SVG paths can go straight into Figma, scale to a favicon, and be handed to Sasha. A 1024px PNG of a logo cannot.
- **For illustrative graphics, Gemini's current image models are the best default workhorse**: strong text rendering, 4K output, trivially scriptable, low cost.
- **Canva earns its place at Class C**, and only really shines on Enterprise where brand kits are exposed through MCP. On lower tiers you get create, search, and export, which is useful but is not brand enforcement.
- **Firefly is the answer to a question Kai already asks.** The persona's Enterprise Security Focus section demands documented provenance and commercial-use licensing. Firefly is the only major model that contractually indemnifies enterprise customers against IP claims. That matters for a logo, which is the one asset a company files a trademark on.

---

## 4. Proposals

Six proposals, roughly in order of value per unit of effort. They are additive, not exclusive. Effort is sized in files touched: **S** = 1 file, **M** = 2 to 5 files plus tests, **L** = 10 or more files plus README, tests, and docs.

---

### Proposal 1: Truth in advertising, plus a capability preflight

**Effort: S to M · Dependencies: none · Risk: none**

Stop the persona from claiming tools that are not connected.

- Rewrite `profiles/kai.md` lines 13 and 23 to state the boundary plainly: Claude generates no raster images natively; Kai's capability depends on which image backend is connected.
- Add a required behavior: **before promising an image, name the backend you will use.** If none is connected, say so, and offer the hand-authored SVG path or an explicit "connect one of X, Y, Z" instruction.
- Optionally add `claude-team doctor` to the CLI: report which image MCPs are reachable (Canva, Recraft, Hugging Face, Figma) and print the exact connect command for the ones that are not.

**What it fixes:** the confident-but-wrong failure mode. **What it does not fix:** image quality itself. This is the honesty floor, not the solution.

---

### Proposal 2: The Visual QA loop

**Effort: S · Dependencies: none · Risk: none · Highest value per unit of effort**

Add a non-negotiable behavior to the design persona: **after generating any visual asset, open it and critique it.**

```
1. Generate the asset.
2. Read the file back (Claude sees images).
3. Score it against the brief on named criteria:
   - Does it read at the smallest target size (16px favicon, 24px icon)?
   - Are the palette hexes actually the palette hexes?
   - Is embedded text spelled correctly and kerned?
   - Does it match the rest of the set?
4. Name the single worst failure. Revise the prompt to address it specifically.
5. Repeat up to N times (default 3). Report what changed each pass.
```

This is how a human designer works and it is available right now with zero new vendors. It also makes every backend in Proposal 4 better, so it should land before the vendor decision, not after.

Second half of the same idea: render Class C deliverables as HTML at exact target size, screenshot them, and look at the screenshot. Chromium and Playwright are already standard in Claude Code environments.

**What it fixes:** most of the perceived quality gap. **What it does not fix:** Class A vector output, which still needs a vector-capable backend or hand-authored SVG.

---

### Proposal 3: Brand Spec and Asset Manifest as checked-in artifacts

**Effort: M · Dependencies: none · Risk: low**

Make brand alignment a file, not a memory.

- **`BRAND.md`** at the project root (or `.claude-team/brand.md`): palette hexes with semantic names, type scale and font licenses, logo usage rules, illustration style statement, negative constraints ("never gradients", "never drop shadows", "line weight 2px at 24px"), and a reference asset list.
- Every image prompt Kai or the Illustrator writes is **composed from `BRAND.md`**, never freehand. That is what turns "make a logo" into a reproducible brief.
- **`assets/MANIFEST.md`**: one row per generated asset recording model, exact prompt, date, license, and commercial-use status. Kai's own security section already demands this provenance. There is currently nowhere to put it.
- Optional CLI surface: `claude-team brand init` scaffolds `BRAND.md` from an interview, mirroring how `branch start` and `session start` already work.

This is also the piece that makes an icon set consistent across weeks and the piece that makes the "aligned with brand / style guide" requirement in the original ask actually achievable.

---

### Proposal 4: Wire a real generation backend

**Effort: M · Dependencies: one vendor account · Risk: medium (vendor lock, cost, licensing)**

The vendor decision. The recommendation is **not to marry one backend**, but to define a thin contract in the persona ("an image backend takes a composed prompt plus size plus format and returns a file on disk") and document two or three supported ones, letting the user pick at install time.

Ranked by fit for the stated need:

**4a. Recraft (recommended primary, for Class A)**
Vector-native SVG for logos and icons, brand style controls trained on your own assets, REST API and an MCP server. This is the only backend that answers "design a logo" with an artifact a designer can actually use.
*Cost:* paid API. *Risk:* another vendor account; style-reference quality varies.

**4b. Gemini image models (recommended primary, for Class B)**
The general raster workhorse. Strong text rendering, 4K, cheap, and scriptable with a plain API key and no MCP required. Note that this is what actually produced the Code Katz cat badges, so it is already the de facto house tool. Note also that Imagen is deprecated with a shutdown date of 2026-08-17, so any wiring should target the current Nano Banana model IDs, not Imagen.
*Cost:* low per image. *Risk:* rapid model ID churn.

**4c. Canva MCP (recommended only for Class C, or if the org already lives in Canva)**
OAuth to a hosted remote server, supported in Claude Code, gives create, modify, search, and export. The brand kit and brand template autofill that would enforce brand alignment is **Enterprise-gated**. Best justification: the deliverable needs to be handed to a non-engineer who will keep editing it.
*Cost:* Canva plan, Enterprise for the brand features. *Risk:* paying Enterprise for one MCP feature.

**4d. Adobe Firefly (recommended when a mark is going to be trademarked or a client demands indemnity)**
The IP-indemnified option. Narrow but decisive use case.

**4e. Ideogram (optional add-on)**
Worth documenting for wordmarks and anything with embedded typography.

**4f. Hugging Face MCP with FLUX (keep as the free tier)**
This is what the profile claims today. Keep it as the zero-cost default so the persona is honest for users who connect nothing, but stop presenting it as the primary path. Weakest text rendering of the set, and volume needs a PRO account.

**4g. Figma MCP (already present in some environments)**
Not a generator in the diffusion sense, but the right home for Class C and for turning an approved mark into a design system. Worth an explicit "if Figma MCP is connected, prefer it for X" routing rule.

---

### Proposal 5: Split the lane, add "Illustrator" as persona #17

**Effort: L · Dependencies: Proposals 2 through 4 land first · Risk: medium (roster bloat)**

Kai is already carrying two jobs that share a vocabulary but not a skill set:

| Kai (UX Design) | Illustrator (Brand & Visual Assets) |
|---|---|
| Screens, flows, information architecture | Logos, wordmarks, icon sets |
| Device-frame mockups, design system tokens | Illustration, hero images, marketing graphics |
| Hands off to Sasha for implementation | Hands off to Kai (design system) and Toni (marketing use) |
| Judged on usability and hierarchy | Judged on craft, consistency across a set, and licensing |
| Model tier: Opus 4.8 | Model tier: Opus 4.8 |

The Illustrator would own: the brand spec, prompt craft per backend, the Visual QA loop, the asset manifest, licensing and provenance, and set consistency (the thing that makes 10 cat badges look like 10 cats from the same studio).

**Cost of adding a persona,** based on the existing 16-persona structure:
`profiles/illustrator.md`, regenerate `agents/`, `commands/illustrator.md`, `profiles/tiers.conf`, both coordinator profiles (roster line plus routing rule), README (roster table, full section, project structure, roadmap), `install.sh` quick-start, `.claude-plugin/plugin.json` description ("Sixteen named specialist personas"), `bin/claude-team` command listing, and `tests/run.sh:476` which asserts the exact subagent count (16 at the time, 17 since Iris shipped).

**Alternative worth considering:** do not split. Keep one design persona and deepen its image skills through Proposals 2 through 4. The split is worth it only if you find yourself wanting UX critique and brand asset production in the same session without them stepping on each other. My read: **do Proposals 1 through 4 first and see whether the split still feels necessary.** Personas are cheap to add and expensive to remove, and the roster is already at 16.

---

### Proposal 6: Ship the pipeline as a companion skill

**Effort: L · Dependencies: Proposals 2 through 4 · Risk: low, it is a separate repo**

claude-team-cli's actual product boundary is *personas*, not tooling. The devlog, roadmap, plans, todo, publish, and conductor skills all live in their own repos and are listed under "Works Well With".

An image pipeline fits that pattern better than it fits a profile:

> **`claude-illustrate-skill`** — `/illustrate`
> Owns: brief intake, brand spec composition, backend selection and fallback, the Visual QA loop, output naming and placement, and manifest logging.

The persona then stays a persona (taste, standards, when to push back) and calls the skill for the mechanics. That keeps 500 lines of backend-specific prompt engineering out of a file whose whole job is describing a personality. It also means the skill benefits Kai, Toni, and the game personas equally, since Reiner and Ernie will want card art eventually.

---

## 5. Recommended path

| Phase | Do this | Why |
|---|---|---|
| **1. Now** | Proposal 2 (Visual QA loop) + Proposal 1 (honesty and preflight) | Zero dependencies, zero cost, largest immediate quality delta. Fixes the confident-but-wrong behavior in the same pass. |
| **2. Next** | Proposal 3 (`BRAND.md` + manifest) | Makes "aligned with brand" mechanically true rather than aspirational. Also unblocks the repo's own missing `publish/style-guide.md`. |
| **3. Then** | Proposal 4, starting with 4b Gemini (already the house tool) and 4a Recraft (the only real answer for logos and icons) | Vector output is the specific thing missing for the stated need. Document 4f as the free fallback. |
| **4. Evaluate** | Proposal 5 (Illustrator persona) | Only if the combined lane feels overloaded after phases 1 through 3. |
| **5. Later** | Proposal 6 (companion skill) | The right long-term home once the pipeline has stabilized. |

**Canva verdict:** not required, and not the first move. Add it when the deliverable is a layout a non-engineer needs to keep editing, and only justify Enterprise if brand kit enforcement through MCP is worth the tier on its own.

---

## 6. Open questions

1. **Budget:** is a paid image API acceptable, or does this need to work with free tiers only? Recraft and Gemini both cost money per image. This changes the phase 3 recommendation more than anything else.
2. **Existing accounts:** is there already a Canva, Adobe, or Figma subscription in play? An existing Canva Enterprise seat would move Canva up the list considerably.
3. **Trademark intent:** will the Code Katz paw mark, or any client logo, be filed as a trademark? If yes, Firefly's indemnification and a documented provenance trail stop being nice-to-haves.
4. **Split or deepen:** do you want two design personas, or one that is better at images? Proposal 5 versus Proposals 2 through 4 alone.
5. **Scope of the repo:** should the image pipeline live in claude-team-cli, or in a new companion skill repo like the other six?

---

## Sources

- [Canva Model Context Protocol (MCP) documentation](https://www.canva.dev/docs/mcp/)
- [Canva Connector for Claude](https://claude.com/connectors/canva)
- [Create on-brand Canva designs directly inside Claude](https://www.canva.com/newsroom/news/claude-ai-connector/)
- [Introducing Claude Design by Anthropic Labs](https://www.anthropic.com/news/claude-design-anthropic-labs)
- [Introducing Canva in Claude Design](https://www.canva.com/newsroom/news/canva-claude-design/)
- [Recraft API](https://www.recraft.ai/api)
- [What Is Recraft V4 Vector? Native SVG logos and icons](https://www.mindstudio.ai/blog/what-is-recraft-v4-vector-generate-svg-logos-icons-ai)
- [Nano Banana image generation, Gemini API](https://ai.google.dev/gemini-api/docs/image-generation)
- [Imagen deprecation notice, Gemini API](https://ai.google.dev/gemini-api/docs/imagen)
- [Hugging Face MCP Server](https://huggingface.co/docs/hub/spaces-mcp-servers)
- [Best AI Logo Generators 2026, Recraft vs Ideogram vs Looka](https://rangy.ai/blog/best-ai-logo-generator-2026/)
- [Best AI Image Models 2026, ranked by job](https://www.teamday.ai/blog/best-ai-image-models-2026)
