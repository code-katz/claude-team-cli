# claude-team-cli — Go-to-Market Content Plan

> Blog series strategy, Post 0 draft, and LinkedIn publishing playbook.
> Maintained by Toni (Product Marketing).

---

## 1. Audience & Positioning

### Ideal Customer Profile (ICP)

**Primary:** Solo developers and small-team leads (2-5 people) who already use Claude Code — or are actively evaluating it — and follow AI/developer tooling content on LinkedIn.

**Secondary:** Technical decision-makers at mid-stage startups exploring how to get more leverage from AI-assisted development without hiring specialists.

These people don't need to be sold on Claude. They need to be sold on **the difference between generic Claude and Claude with a team.**

### Core Positioning

claude-team-cli is not a prompt library. It's not a collection of system prompts you paste into a chat window.

It's a named, opinionated specialist who shows up with domain expertise, asks the questions a senior practitioner would ask, and pushes back when something's off. A roster of them. Most cover the full product development lifecycle from discovery to launch. Four of them are a tabletop-game studio, and they exist to answer the one objection this category always draws.

**The objection, and the answer.** "If it just injects a persona, why not wire up the two or three specialists I care about myself, in an afternoon?" You could. The mechanism was never the moat. Copying a profile is easy; curating specialists who hold a lane and hand off to each other cleanly is the work, and that is what a session actually runs on. The proof is the game studio: Reiner (design), Cornelius (history), Ernie (narrative), and Piper (playtesting) form an interlocking four-person team in a domain the tool was never built for, assembled from the same profile structure as the software specialists. Anyone can paste three prompts; a coherent studio that holds its lanes and hands off by name is a different claim, and it is the one worth paying attention to.

**One-line positioning:** *Your AI development team. Named specialists, one CLI, zero meetings.*

### Differentiation Hook

Every piece of content in this series uses the same proof structure: **before/after dialogue.** Show the same prompt answered by generic Claude, then by the relevant persona. The contrast does the selling.

Generic Claude gives you a checklist. A team member reframes the problem.

### Key Messages

1. **You're not getting Claude's best work.** Without a persona, Claude defaults to generic, safe, surface-level responses. With a specialist active, it thinks the way that domain actually thinks.
2. **It's not a gimmick — it's a workflow.** The coordinator suggests who should lead each task. Slash commands let you switch mid-session. The devlog and roadmap skills persist context across sessions.
3. **Ten minutes to install. Immediate difference.** `git clone`, `bash install.sh`, done. No API keys, no configuration, no dependencies beyond Bash and Claude Code.
4. **The team is the moat, not the mechanism.** Injecting a persona is easy to copy; a curated set of specialists who hold their lanes and hand off cleanly is not. The four-person tabletop-game studio (Reiner, Cornelius, Ernie, Piper) is the proof: the same structure produces a working team even in a domain the tool was never built for.

---

## 2. Content Series Plan

### All Content

The blog series follows a single product (ACME Personal Jet Packs) through its entire development lifecycle. Each post features a different team member handling their domain. Standalone thought pieces and LinkedIn-only posts round out the content calendar.

| # | Title | Type | Status |
|---|---|---|---|
| 0 | Meet My Claude Dev Team | Blog (Medium) | **Published** |
| 1 | "What problem does a jet pack actually solve?" (River) | Blog (Medium) | **Published** |
| 2 | "Your telemetry API has a consistency problem" (Akira) | Blog (Medium) | **Published** |
| 3 | "A pilot at 200 feet can't squint at a tooltip" (Sasha) | Blog (Medium) | Written |
| 4 | "What happens when the upstream sensor schema changes?" (Jordan) | Blog (Medium) | Written |
| 5 | "What decision does this dashboard actually drive?" (Casey) | Blog (Medium) | Written |
| 6 | "What's the worst thing an attacker could do mid-flight?" (Morgan) | Blog (Medium) | Written |
| 7 | "If this OTA server dies, do pilots fall out of the sky?" (Alex) | Blog (Medium) | Written |
| 8 | "The riskiest failures aren't code bugs..." (Robin) | Blog (Medium) | Written |
| 9 | "Who specifically buys a jet pack..." (Toni) | Blog (Medium) | Written |
| 10 | "Who owns this, when is it due, and what's blocking it?" (Quinn) | Blog (Medium) | Written |
| 11 | "The tools that make the team remember" (Devlog + Roadmap) | Blog (Medium) | Written |
| 12 | "AI Writes Code Fast. Lint Keeps It Honest." | Blog (Medium) | **Published** |
| E | "I pointed a dev-team tool at a WW2 board game" (game studio / extensibility) | Blog + LinkedIn | Planned |
| L1 | Post 0 LinkedIn teaser (Robin before/after) | LinkedIn | Written (Section 6) |
| L2 | Slash commands overview | LinkedIn | Written (Section 7) |

#### Standalone Thought Pieces (Post 12+)

Post 12 breaks from the ACME series format. It's a standalone thought piece targeting the general dev community **and Engineering VPs** — framing lint as an organizational risk management tool when AI multiplies code velocity. The piece leads with the problem (AI outpaces review capacity), builds the case (what linters actually catch, the math on defect accumulation), and closes with claude-team-cli as "how I solved this" — not a product pitch.

**Audience expansion:** This post intentionally targets Engineering VPs and technical leadership by framing lint as a scaling and risk problem, not a developer convenience. The "velocity trap" and "math that should worry engineering leaders" sections are written for someone managing a team whose PR volume just tripled.

**Publishing:** Medium + LinkedIn. Same golden rule (no link in LinkedIn body). LinkedIn teaser leads with the tension: AI writes fast, review doesn't scale.

#### The Extensibility Angle (separate thread)

The four-person tabletop-game studio (Reiner, Cornelius, Ernie, Piper) does not belong in the ACME jet-pack series: it is not part of that product's lifecycle, and forcing it in would blur the narrative. It earns its own standalone piece, aimed squarely at the "why not just build this myself" skeptic. Working title: *"I pointed a dev-team tool at a WW2 board game. It built a studio."* The argument is that the same profile structure produced a coherent, lane-disciplined team in a domain the tool was never designed for, which is the strongest answer we have to "why not wire up three personas yourself." Same before/after proof structure; the "after" is the studio holding its lanes and handing off by name. One post, not a series.

### Post Structure — Persona Spotlights (Posts 1-10)

Each persona post follows the same template:

1. **Intro** (2-3 sentences) — Who this persona is and what domain they cover. No lengthy explanation.
2. **The scenario** (1 sentence) — What we're asking them to do with ACME Jet Packs.
3. **The conversation** (5-8 exchanges) — A realistic Claude Code dialogue showing the persona in action. This is the core of the post. The persona must do at least one thing generic Claude would not:
   - Ask a reframing question before answering
   - Push back on an unstated assumption
   - Flag a security, compliance, or safety concern
   - Structure the problem before proposing a solution
4. **The "so what"** (2-3 sentences) — What just happened and why it matters. Name the specific behavior that differentiates the persona from generic Claude.
5. **Footer** — GitHub link, install command, next post teaser.

---

## 3. ACME Personal Jet Packs — Demo Scenario

### The Company

**ACME Aerospace** — a startup building the first consumer-grade personal jet pack. Series A funded, 12-person engineering team, shipping v1 in Q4.

### The Product

**ACME Jet Pack v1** — a vertical flight device for personal transportation. 15-minute flight time, 500-foot ceiling, GPS-guided return-to-base, over-the-air firmware updates, companion mobile app with real-time telemetry.

### Implied Tech Stack

| Layer | Technology |
|---|---|
| Backend API | Python / FastAPI |
| Frontend (pilot dashboard) | React / TypeScript |
| Data warehouse | Snowflake |
| ML / anomaly detection | Python / scikit-learn |
| Infrastructure | Kubernetes on AWS |
| CI/CD | GitHub Actions + ArgoCD |
| Monitoring | Prometheus + Grafana |

### Key Tensions (Why This Scenario Works)

Each persona naturally engages with different tensions in the same product:

- **Safety-critical system** — Morgan, Robin, and Akira all react differently to the fact that software failures can cause physical harm
- **Consumer launch with regulatory unknowns** — River, Toni, and Quinn each see this from a different angle (requirements, positioning, delivery risk)
- **Real-time telemetry at scale** — Jordan, Casey, and Alex each own a different part of the data flow
- **Accessibility for a safety UI** — Sasha flags that a pilot at altitude needs UI that works under stress, in sunlight, with gloves

The scenario is absurd enough to be memorable and complex enough to be real.

---

## 4. Publishing Strategy

### Medium

**Purpose:** Canonical long-form source. SEO-friendly. Shareable. Persistent.

- Publish all 13 posts under your Medium account
- **Tags (every post):** `Claude`, `Claude Code`, `AI Development`, `Developer Tools`, `AI Agents`
- Each post ends with a consistent footer:
  - GitHub repo link: `github.com/code-katz/claude-team-cli`
  - Install command: `git clone ... && bash install.sh`
  - "Next in the series: [Persona Name] — [teaser line]"
- **Post 0** gets a Table of Contents section — backfill links as each persona post is published
- Publish Post 0 first. Wait 2-3 days for engagement before starting the persona posts.

### LinkedIn

**Purpose:** Distribution engine. Engagement driver. Traffic to Medium.

#### The Golden Rule

**Never put the Medium link in the LinkedIn post body.** LinkedIn's algorithm suppresses posts with external links. The link goes in your first comment, posted immediately after the post itself.

#### LinkedIn Post Template (every post)

```
1. HOOK (1-2 sentences)
   - Name the persona and the scenario
   - Make it specific and visual
   - Example: "I asked Claude to design a test strategy
     for a jet pack flight controller. Here's what happened
     when Robin was on the job."

2. DIALOGUE SNIPPET (3-4 exchanges)
   - Paste as formatted text (not an image)
   - Keep it tight — this is a teaser, not the full conversation
   - The persona must say something surprising or reframing

3. "SO WHAT" LINE (1 sentence)
   - Name the behavior that generic Claude wouldn't exhibit
   - Example: "That's not a checklist. That's a senior QA
     engineer reframing the problem before touching a test file."

4. ENGAGEMENT QUESTION
   - Example: "Which specialist would you put on your
     next project?"
   - Example: "What domain do you wish you had a senior
     consultant for?"

5. FIRST COMMENT (posted immediately after)
   - "Full conversation and install instructions: [Medium link]"
   - Pin this comment if LinkedIn allows it
```

#### Posting Cadence

| Week | Tuesday | Thursday |
|---|---|---|
| 1 | Post 0 (intro) | — (let it breathe) |
| 2 | Post 1 (River) | Post 2 (Akira) |
| 3 | Post 3 (Sasha) | Post 4 (Jordan) |
| 4 | Post 5 (Casey) | Post 6 (Morgan) |
| 5 | Post 7 (Alex) | Post 8 (Robin) |
| 6 | Post 9 (Toni) | Post 10 (Quinn) |
| 7 | Post 11 (Devlog + Roadmap) | — (series recap) |
| 8 | Post 12 (Lint thought piece) | — |

**Publish on LinkedIn between 7-9am in your local timezone.** Dev audiences are most active early morning (commute scrolling) and engagement in the first hour determines reach.

#### Engagement Tactics

- **Post 0:** Tag @Anthropic, use #ClaudeCode #AIDevelopment #DeveloperTools
- **Every post:** When people comment, reply with a dialogue snippet from a *different* persona — this seeds the next post naturally
- **Cross-link:** When Post 3 (Sasha) goes live, go back to Post 2 (Akira) and comment: "Akira built the API. Now Sasha's building the dashboard — and she's not happy about the tooltip placement: [link]"
- **End-of-series recap:** After Post 11, publish a wrap-up LinkedIn post summarizing the full lifecycle with links to all 13 Medium posts in a comment

---

> **Sections 5 to 7 are drafted post copy.** Roster figures in them are point-in-time snapshots, not maintained numbers. Re-check any count against `claude-team list` immediately before publishing.

## 5. Post 0 — "Meet My Claude Dev Team"

*Target: Medium publication. ~1400 words.*

---

### Meet My Claude Dev Team

**Named specialists. One CLI. Zero meetings.**

---

Claude is sharp. It's fast, it's capable, and it will give you a reasonable answer to almost anything you throw at it.

But reasonable isn't the same as good.

Ask Claude to design a test strategy and you'll get a checklist — unit tests, integration tests, CI pipeline. It's correct. It's also exactly what you'd get from a Stack Overflow search. Ask it to review your API design and you'll get a polite summary of what you already built. Ask it to plan a feature and you'll get a tidy list of steps that doesn't push back on a single assumption.

The problem isn't capability. It's that Claude shows up the same way every time — helpful, general, agreeable. No opinions. No hard questions. No domain instincts.

What I actually needed was a *specialist.* Someone who would reframe the problem before answering it. Someone who would flag the security concern I hadn't thought about. Someone who would say "wait — who is this actually for?" before letting me build the wrong thing.

So I built a team of them.

---

#### What claude-team-cli actually does

It gives you named specialist personas for Claude Code. Each one is a formal expert consultant with deep domain knowledge, a distinct way of thinking, and real opinions about how work should be done.

You pick who's on the task. Claude shows up as that person.

Need to define requirements? Call River. Design an API? Akira. Build a component that needs to be accessible and secure? Sasha. Data pipelines? Jordan. Dashboards and KPIs? Casey. Security review? Morgan. Deployment infrastructure? Alex. Test strategy? Robin. Launch positioning? Toni. Sprint planning? Quinn. Company formation and finances? Sage. A mockup before code? Kai. A logo or icon set? Iris. And when the work isn't software at all, there's a four-person studio for tabletop games: Reiner, Cornelius, Ernie, and Piper.

You can switch mid-session with a slash command. The coordinator — an optional behavior layer — suggests who should lead each task and flags when the work drifts into a different domain.

---

#### The team

| Name | Role | They'll ask you... |
|---|---|---|
| **River** | Product Manager | *"What specific user problem does this solve — and how will we know we've solved it?"* |
| **Akira** | Backend Engineering | *"What are the consistency requirements here — and who should never have access to this data?"* |
| **Sasha** | Frontend Engineering | *"How does this behave for a keyboard-only user — and could this expose sensitive data to an attacker?"* |
| **Jordan** | Data & ML | *"How are we monitoring data quality here — and what happens when the upstream schema inevitably changes?"* |
| **Casey** | Data Analyst | *"What is the single most important business decision this dashboard is meant to drive — and who is making it?"* |
| **Morgan** | Security Engineering | *"What is the absolute worst thing an attacker could do if they compromised this specific service account?"* |
| **Alex** | DevOps & Platform | *"If this server dies right now, how exactly does it rebuild itself without human intervention?"* |
| **Robin** | QA & Testing | *"What's the failure mode we haven't considered yet — and could an attacker exploit it?"* |
| **Toni** | Product Marketing | *"Who specifically benefits from this — and what would make them choose us over doing nothing?"* |
| **Quinn** | Project Manager | *"Who owns this, when is it due, and what's blocking it?"* |

And when the project isn't software at all, the same structure holds. Here's the four-person studio for tabletop games:

| Name | Role | They'll ask you... |
|---|---|---|
| **Reiner** | Tabletop Game Designer | *"What decision is the player actually making here, and is it interesting?"* |
| **Cornelius** | Military Historian | *"Is this what actually happened, and why did it matter to the outcome?"* |
| **Ernie** | WW2 Narrative Author | *"Is this true, and does it make the reader feel why it mattered?"* |
| **Piper** | Tabletop Playtester | *"How do I break this, and is it still fun when I can't?"* |

They were built from the same profile structure as the specialists above, and they hold their lanes the same way: Reiner designs, Cornelius checks the history, Ernie writes the words, Piper tries to break it. That is the real claim. Not "you can inject a persona" (you always could), but "the same structure produces a working team even in a domain the tool was never built for."

These aren't decorative. Each persona comes with enterprise-grade security instincts — every team member flags secrets in code, PII in logs, and missing access controls as a matter of course.

---

#### See the difference

Here's the same prompt, two responses.

> *"I want to design a test coverage strategy for this application — including pre-commit tests, post-data-load validation, and a framework that can scale as the app grows."*

**Without a team member active:**

> **Claude:** Great idea! Here's a general test coverage strategy:
> - Unit tests for individual functions and components
> - Integration tests to verify modules work together
> - End-to-end tests for critical user flows
> - Use a pre-commit hook to run unit tests before each commit
> - Set up a CI/CD pipeline to run the full suite on every push
> - Consider a testing framework like Jest, Pytest, or whatever fits your stack

**With Robin active:**

> **Robin:** Before I sketch the strategy, I need to understand the failure modes. What's the worst thing that could silently go wrong in this application — bad data reaching a user, a broken calculation, a stale cache? That determines where the test boundary actually sits.
>
> A few things I'm flagging immediately: pre-commit hooks catch code defects, but for a data-dependent application, the riskiest failures happen after data loads — not before commits. Those need a separate test layer entirely, with assertions against the data itself, not just the code.
>
> Can you walk me through the data flow? I want to see where transformations happen before I recommend where to put the seams.

Generic Claude gives you a checklist. Robin reframes the problem, identifies the real risk, and asks a question you probably hadn't considered.

That's the difference between a general-purpose assistant and a specialist consultant.

---

#### Install in two minutes

```bash
git clone https://github.com/code-katz/claude-team-cli.git
cd claude-team-cli
bash install.sh
```

Then activate a team member:

```bash
claude-team use robin     # or akira, sasha, river, etc.
```

Start a new Claude Code session. Robin is on the job.

Switch mid-session without restarting:

```
/akira    /sasha    /river    /jordan    /casey
/morgan   /alex     /robin    /toni      /quinn
```

Works on macOS and Linux. Requires Bash 4+ and Claude Code. macOS ships Bash 3.2, so run `brew install bash` first.

**Bonus:** Two companion skills — [claude-devlog-skill](https://github.com/code-katz/claude-devlog-skill) and [claude-roadmap-skill](https://github.com/code-katz/claude-roadmap-skill) — give the team persistent memory. The devlog captures architectural decisions across sessions. The roadmap tracks priorities and records every reprioritization. Install both with two commands and your team doesn't just think differently — it *remembers* differently. More on these in a later post.

---

#### Coming next

This is the first post in a series of thirteen. Over the next seven weeks, each team member gets their own spotlight — a full conversation showing them in action on a single project: **ACME Personal Jet Packs.**

You'll see River run product discovery. Akira design the telemetry API. Sasha build a pilot dashboard that works at 200 feet in direct sunlight. Morgan threat-model a remotely controlled aircraft. Robin write a test strategy for edge cases that could drop someone out of the sky. And at the end, the companion tools that give the whole team persistent memory across sessions.

Same product, ten different specialists, and the tools that make sure none of it gets lost between sessions.

**Next up: River — "What problem does a personal jet pack actually solve?"**

---

*[GitHub: code-katz/claude-team-cli](https://github.com/code-katz/claude-team-cli) | Works with [Claude Code](https://claude.ai/code)*

---

## 6. LinkedIn Teaser — Post 0

### Post Body (paste directly into LinkedIn)

```
I built an 18-person AI dev team inside Claude Code.

Not prompt templates. A CLI that gives Claude named
specialist personas — senior consultants with domain
expertise and real opinions.

Here's what changes:

Me: I need a test coverage strategy for this app.

Claude: Great idea! Here's a general strategy:
  - Unit tests, integration tests, e2e tests
  - Pre-commit hooks and CI/CD pipeline

[activates Robin — QA & Testing]

Robin: Before I sketch the strategy, I need to
  understand the failure modes. What's the worst
  thing that could silently go wrong? That
  determines where the test boundary actually sits.

  Walk me through the data flow.

That's not a checklist. That's a senior QA engineer
reframing the problem before touching a test file.

Robin is one of twenty. Two-minute install. Open source.

What domain do you wish you had a specialist for?

#ClaudeCode #AIDevelopment #DeveloperTools @Anthropic
```

### First Comment (post immediately after)

```
Full write-up with the complete team roster and install
instructions: [Medium link]

GitHub: github.com/code-katz/claude-team-cli
```

---

## 7. LinkedIn Post — Slash Commands Overview

### Post Body (paste directly into LinkedIn)

```
Your AI dev team has slash commands now.

If you're using Claude Code, these five commands turn
a solo session into a coordinated workflow:

/parallel — split work into 2-3 parallel sessions
            with persona, task, and file scope
/devlog   — log decisions, milestones, and insights
            to DEVLOG.md
/roadmap  — update or read the project roadmap
/plans    — archive finalized implementation plans
/todo     — manage per-project task checklists

Each one is a standalone Claude Code skill. Install one,
install all five, or just grab the team CLI that ties
them together.

All open source. All work with Claude Code today.

What would you automate first?

#ClaudeCode #AIDevelopment #DeveloperTools
```

### First Comment (post immediately after)

```
Repos:

Team CLI (20 specialist personas):
github.com/code-katz/claude-team-cli

Companion skills:
github.com/code-katz/claude-devlog-skill
github.com/code-katz/claude-roadmap-skill
github.com/code-katz/claude-plans-skill
github.com/code-katz/claude-todo-skill
github.com/code-katz/claude-publish-agent
```

---

*Document maintained by Toni. Last updated: 2026-07-29.*
