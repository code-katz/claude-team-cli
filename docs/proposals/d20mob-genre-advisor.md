# Proposal: A fantasy genre advisor for d20Mob

**Status:** proposed
**Date:** 2026-09-04
**Related:** `profiles/rez.md` (the template), PR #33 (Rez lands as persona eighteen)

## TL;DR

Rez gives NIGHTGRID a genre-authority seat: prior art, homage versus cliché, and whether a name is free to take. d20Mob has no equivalent, and it carries licensing exposure that no one on the roster owns.

This proposal adds **Tracy, Fantasy Genre Advisor**, built section for section on the Rez template, and **deepens Reiner** with d20 RPG systems expertise rather than adding a third persona.

- One new profile: `profiles/tracy.md`
- One additive edit: `profiles/reiner.md`
- The same registration surface the Rez PR touched, and no more

## 1. What Rez actually does for NIGHTGRID

Rez is not a designer, a writer, or an artist. The profile is explicit: *"you do not design game mechanics (Reiner), position products (Toni), produce art (Iris and Kai), or clear trademarks (you flag, Sage owns the process, counsel clears it)."*

Rez is the team's genre memory, and it does four jobs.

### 1.1 Prior-art gate before commitment

The Provenance Check behavior fires automatically on any proposed name, term, visual, or mechanic and returns a table led by a verdict line. NIGHTGRID's own brand record carries two open items of exactly this shape: a trademark and name scan before external use, and the note that the coder-theme names it drew palettes from belong to their communities and companies, so palettes may inspire but names do not ship.

### 1.2 Coinage versus commons versus active IP

Cyberpunk vocabulary has uneven provenance. Some terms are genre commons, some are a specific author's coinage, and some are live commercial IP. Rez is the seat that answers "is that free?" before art and code commit to it.

### 1.3 Anti-pastiche calibration

NIGHTGRID ran twenty-five brand directions, most of them named after existing editor themes, and landed on a house identity with an explicit open item: a deliberate hue-shift pass for originality against its source. The Homage Meter (lift, pastiche, homage, fresh twist, plus the single change that moves it one notch) is the instrument for that pass.

### 1.4 Grounding recommendations in named work

Every answer closes with a `Touchstones:` line of two to four specific works, chosen for relevance rather than fame. This converts "make it more cyberpunk" into a reading list.

### 1.5 The structural pattern

Rez sits in the main roster, not inside the Game Development Team, and works alongside it. That is the same slot Cornelius fills for the WW2 LCG. The pattern is consistent across the repo:

| Project | Domain-authority seat | Verifies |
|---|---|---|
| WW2 LCG | Cornelius | Historical fact |
| NIGHTGRID | Rez | Genre precedent |
| d20Mob | none today | nothing |

## 2. Why d20Mob needs the same seat

Four unowned risks.

### 2.1 SRD versus Product Identity is a shipping trap

The d20Mob Brand Identity Guide makes SRD 5.1 CC-BY attribution mandatory, and the Mechanics Analysis confirms the licensing strategy holds. Neither addresses which *names* the SRD actually contains.

The Phase 1 bestiary is safe: Ghoul, Troll, Kobold, Wraith, and Dire Wolf are all SRD content. But the marquee creatures players ask for by name (Beholder, Mind Flayer, Displacer Beast, Umber Hulk, Yuan-ti, Kuo-toa, Slaad, Githyanki) are Product Identity and were deliberately withheld from every SRD. A bestiary growing toward later phases needs someone holding that line before an illustration is commissioned or a stat block is written.

### 2.2 "Shadowdark-inspired" needs a canon authority

The Mechanics Analysis recommends borrowing Shadowdark's design philosophy wholesale: roll-to-cast, gear slots, advantage as the primary modifier system, four DC tiers. Shadowdark is a commercial product by Kelsey Dionne. Its mechanical ideas are largely free to emulate; its name, text, and trade dress are not. Somebody has to say where that line sits, in writing, before the ruleset hardens.

### 2.3 Fantasy is the most trope-saturated genre in games

Class names, monster names, the tagline, and the six zone types (Wilderness, Tavern, Market, Dungeon, Fortress, Arcane Tower) all sit on fifty years of prior art. Not all of it is commons.

### 2.4 The art direction cites a lineage nobody owns

The Brand Identity Guide specifies old-school D&D style with bold ink line work. That is a named tradition with named practitioners. Iris and Kai execute the look; no one on the roster can name the reference or say when an homage tips into copying a specific plate.

## 3. Proposal: Tracy, Fantasy Genre Advisor

**Name.** Tracy, after Tracy Hickman, following the Game Development Team convention of a genre luminary's first name used as an original character: Reiner (Knizia), Cornelius (Ryan), Ernie (Pyle). Gender neutral, and consistent with River, Sage, Quinn, and Morgan.

**Role name.** "Fantasy Genre Advisor" is a job title, not a topic, matching every other Role column entry and the correction the Rez port already made once.

**Model tier.** `claude-opus-4-8`, matching Rez, Cornelius, and Ernie: judgment-heavy consulting at moderate volume.

**Roster placement.** Main roster, immediately after Rez, inside `## Meet the Team`. Not in the Game Development Team, for the same reason Rez is not.

### 3.1 Structure

Mirrors `profiles/rez.md` heading for heading and count for count: three personality paragraphs, seven domain bullets, five How You Operate questions, five standards bullets, six communication bullets, three interactive behaviors. The only heading that differs is `## Provenance and Licensing Standards`, widened from Rez's `## Provenance Standards` because licensing is the sharp edge in this genre rather than a footnote.

### 3.2 The three behaviors

1. **Provenance Check.** Prior Art table before any other commentary, led by a verdict line. The Status column is retuned to d20Mob's real exposure: SRD content, Product Identity, OGL third-party, genre commons, author coinage.
2. **The Homage Meter.** Same four notches as Rez, deliberately. Two genre advisors that grade on one scale are comparable.
3. **Cite the Canon.** Every answer closes with a `Touchstones:` line.

### 3.3 Signature question

> "Someone has run this before: what did they call it, and is the name ours to take?"

### 3.4 Lane boundaries

Mechanics to Reiner. Positioning and store copy to Toni. Art execution to Iris and Kai. Table validation to Piper. Legal process to Sage, because a Tracy flag is a research lead and never a legal opinion.

## 4. Deepen Reiner instead of adding a rules designer

A d20 rules specialist would have overlapped Reiner heavily. The repo has a precedent for the alternative: Casey was deepened rather than duplicated when a proposed new persona covered ground she already held.

`profiles/reiner.md` takes additive edits only:

- The first domain bullet widens from "card and board games" to "card, board, and roleplaying games"
- Two RPG-systems bullets: class identity and progression curves, encounter and monster math, loot and rarity tables; and the OSR simplification tradition as a way to cut rules overhead without cutting decisions
- The lane paragraph gains the Tracy boundary: Tracy owns what the genre has already done with a mechanic or a name, Reiner owns whether the mechanic earns its place

The `# Reiner — Tabletop Game Designer` title is unchanged. Three parsers split on that em dash, and a title change would ripple through six files for no functional gain.

## 5. Files touched

Mirrors the Rez PR surface exactly.

| File | Change |
|---|---|
| `profiles/tracy.md` | New. Source of truth |
| `profiles/tiers.conf` | `tracy claude-opus-4-8`, inside the Opus block after `rez` |
| `profiles/coordinator.md` | Four blocks: roster bullet, greeting table, routing example, shift trigger |
| `profiles/coordinator-prod.md` | Same four blocks |
| `profiles/reiner.md` | Additive deepening |
| `agents/tracy.md`, `commands/tracy.md`, `agents/reiner.md`, `commands/reiner.md` | Generated. Never hand-edited |
| `TEAM.md` | Tracy section after Rez and before the Game Development Team H2 |
| `README.md` | Pitch sentence, roster row, studio-adjacency note |
| `gtm.md` | Two drafted-post snapshot figures, per the pre-flight note in that file |

No change needed, verified: `.claude-plugin/plugin.json` carries no count, `install.sh` globs `profiles/*.md`, `bin/claude-team` hardcodes no persona names, and `tests/run.sh` computes counts rather than asserting literals. `ROADMAP.md` is left alone because its count records what v2.0 shipped.

## 6. Open question, deliberately out of scope

Nobody on the roster writes fantasy prose. The d20Mob Engagement Analysis shows DM Dialogue as a real content surface, alongside lore fragments and a Lore XP track. Ernie is WW2-specific and Toni writes marketing rather than in-world copy.

That is an Ernie-analogue seat, not a Rez-analogue seat. It is not part of this proposal, and it is recorded here so the omission is a decision rather than an oversight.
