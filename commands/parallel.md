---
description: Generate a parallel session plan with worktree isolation, one persona per session, and conductor tracking when available
---

Generate a parallel session plan for the current work.

You are acting as a session planner. Analyze the current conversation context, any active plan, and the user's stated goals to identify independent work streams that can run in parallel Claude Code sessions.

The session you are in now becomes the coordination session. Its checkout stays on the default branch at all times. Every parallel session runs in its own git worktree, so no session ever switches branches.

---

## What to do

1. **Identify the work.** Review the conversation for tasks, plans, or goals. If nothing is clear, ask: "What are you trying to get done? I'll look for ways to split it into parallel sessions."

2. **Find independent streams.** Break the work into 2-3 streams where:
   - Each stream touches different files/directories (no overlap)
   - Each stream can be completed without waiting on the others
   - Each stream maps naturally to a team member's domain

3. **Check for dependencies.** If streams share files or one produces output the other needs, either restructure the split or note the merge order.

4. **Check whether the conductor companion is installed.** `claude-conductor` lives in its own repo. This project never installs it and puts no `claude-conductor` binary on PATH. Check for it before you decide what the plan contains:
   - Look for `conductor` among the skills or commands already available to you this session.
   - If that does not settle it, check the filesystem directly: `test -f ~/.claude/skills/conductor/SKILL.md` (the path the README installs it to).

   State the result once, before you present the plan. Say: "Conductor is installed, so this plan includes tracking commands," or: "No conductor companion found, so this plan skips cross-session tracking. Install claude-conductor first if you want session registration, activity updates, and the live dashboard." This check governs every `claude-conductor` reference in steps 5 through 8. Check again each time; never carry the answer over from an earlier session.

5. **Choose a branch name per session.** Use the convention `session/<number>-<persona>-<task-slug>`, for example `session/1-akira-implement-battle-api`. Do this before step 6, because the worktree branch must match it exactly.

   If conductor is installed, register each session instead of hand-picking the name. Run one `add` command per session:

```bash
claude-conductor add --persona [Name] --task "[task description]" --files "[file list]" [--depends "[#N if applicable]"] [--branch "custom-branch-name"]
```

   This creates the SESSIONS.md entries and the plan checklist. It derives the same branch-name convention unless `--branch` overrides it. Do this before step 7.

   If conductor is absent, use the name you chose above. There is no registration step.

6. **Create one worktree per session.** From this coordination session, run one command per session, using the exact branch name chosen in step 5:

```bash
claude-team session start session/1-[persona]-[task-slug]
claude-team session start session/2-[persona]-[task-slug]
```

Each command creates an isolated git worktree with the session's branch checked out and prints the worktree path. Record each path; it goes into the session prompt. Never instruct a session to run `git checkout` or `git switch`. The worktree IS the branch isolation.

7. **Present the plan.** Output numbered session prompts in this format. The user opens a new Claude Code session inside each worktree directory. Each prompt must start with the verification command, before any other work.

   The template below is complete on its own: fill in the brackets and output it exactly as written when conductor is absent. If step 4 found conductor installed, make these three additions as you fill it in (`[N]` is each session's number):
   - Right after `claude-team session status`, add a line: `claude-conductor u [N] coding --activity "starting work"`.
   - In the "when you are completely done" list, insert a step right after the rebase step and before the Handoff Brief step: `Mark session done: claude-conductor d [N]`. Renumber the steps that follow it.
   - On each `git merge session/[N]-...` line in the merge commands block, add a trailing comment: `      # then: claude-conductor m [N]`.

   Make none of these additions when conductor is absent. Do not mention `claude-conductor` anywhere in the output in that case.

```
## Parallel Session Plan

### Session 1: [domain label]
**Persona:** /[name]
**Worktree:** [path printed by session start] — open Claude Code in this directory
**Task:** [specific, scoped instruction]
**Files:** [explicit file/directory list]
**Context:** [decisions this session must respect, and open questions it owns. This session starts with none of the coordination conversation, so anything omitted here is something it will guess at or re-derive.]

**IMPORTANT: Before doing anything else, run the following:**
```bash
claude-team session status
```
If `session status` does not show branch `session/1-[persona]-[task-slug]`, STOP and tell the user to reopen this session in the worktree path above.

When you are completely done:
1. Commit all changes: `git add [files] && git commit -m "[persona]: [brief summary]"`
2. Sync with the default branch: `git fetch origin && git rebase origin/[default-branch]` (no remote? rebase onto the local default branch instead)
3. Write a Handoff Brief for the coordination session: decisions made, open risks or unresolved questions, and a direct question by name for whoever picks this up. If another session depends on yours, its Context field comes from this brief.
4. Do NOT merge and do NOT switch branches. The coordination session merges in dependency order.

### Session 2: [domain label]
[same structure]

### Session 3: [domain label] (if applicable)
[same structure]

**Merge order:** [order with reasoning, or "No merge order required; all sessions are independent."]

**Merge commands for the coordination session** (this checkout is already on the default branch; no checkout needed):
```bash
git merge session/1-[persona]-[slug]
git merge session/2-[persona]-[slug]
# Add session/3 if applicable, respecting the merge order above.

# Cleanup after all sessions are merged:
claude-team session list                  # shows each worktree path
git worktree remove [worktree-path]       # one per session
git branch -d session/1-[persona]-[slug] session/2-[persona]-[slug]
```

**Coordination session:** Keep this session open for questions, reviewing work, and merging branches.
```

8. **If conductor is installed, suggest the dashboard.** Tell the user: "Run `claude-conductor dash --open` to open the live dashboard in your browser." Skip this step when conductor is absent.

## Rules

- Maximum 3 parallel sessions
- File scopes must not overlap between sessions
- Every session gets its own worktree via `claude-team session start`; never put `git checkout`, `git switch`, or `git merge` in a session prompt
- If conductor is installed, the branch registered with `claude-conductor add` must exactly match the branch passed to `claude-team session start`
- Every prompt must include persona, task, file scope, and worktree path; add conductor tracking instructions only when step 4 found conductor installed
- Completion instructions must include committing all work and rebasing onto the default branch before marking done
- Merging happens only in the coordination session, in dependency order
- If the work cannot be meaningfully parallelized, say so: "This task is too intertwined to split. Better to run it as a single session."
- Do not generate vague or open-ended prompts; each task should be specific enough that the session can complete it without asking clarifying questions
- If conductor is installed, register sessions with `claude-conductor add` before presenting the prompts
- If conductor is installed and SESSIONS.md does not exist, run `claude-conductor init` first
- Never print a `claude-conductor` command anywhere in the plan when step 4 found the companion absent
- Session re-entry: the worktree persists until removed, so reopening the worktree directory resumes the session's branch automatically
