---
description: Generate a parallel session plan with worktree isolation, one persona per session, and conductor tracking
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

4. **Register sessions with conductor.** After presenting the plan, register each session using `claude-conductor add`:

```bash
claude-conductor add --persona [Name] --task "[task description]" --files "[file list]" [--depends "[#N if applicable]"] [--branch "custom-branch-name"]
```

Run one `add` command per session. This creates the SESSIONS.md entries and plan checklist automatically. A branch name is auto-generated from the session number, persona, and task slug (e.g., `session/1-akira-implement-battle-api`). Use `--branch` to override.

5. **Create one worktree per session.** From this coordination session, run one command per session, using the exact branch name registered in step 4:

```bash
claude-team session start session/1-[persona]-[task-slug]
claude-team session start session/2-[persona]-[task-slug]
```

Each command creates an isolated git worktree with the session's branch checked out and prints the worktree path. Record each path; it goes into the session prompt. Never instruct a session to run `git checkout` or `git switch`. The worktree IS the branch isolation.

6. **Present the plan.** Output numbered session prompts in this format. The user opens a new Claude Code session inside each worktree directory. Each prompt must start with the verification and tracking commands, before any other work.

```
## Parallel Session Plan

### Session 1: [domain label]
**Persona:** /[name]
**Worktree:** [path printed by session start] — open Claude Code in this directory
**Task:** [specific, scoped instruction]
**Files:** [explicit file/directory list]
**Context:** [decisions this session must respect, and open questions it owns. This session starts with none of the coordination conversation, so anything omitted here is something it will guess at or re-derive.]

**IMPORTANT: Before doing anything else, run these commands:**
```bash
claude-team session status
claude-conductor u 1 coding --activity "starting work"
```
If `session status` does not show branch `session/1-[persona]-[task-slug]`, STOP and tell the user to reopen this session in the worktree path above.

When you are completely done:
1. Commit all changes: `git add [files] && git commit -m "[persona]: [brief summary]"`
2. Sync with the default branch: `git fetch origin && git rebase origin/[default-branch]` (no remote? rebase onto the local default branch instead)
3. Mark session done: `claude-conductor d 1`
4. Write a Handoff Brief for the coordination session: decisions made, open risks or unresolved questions, and a direct question by name for whoever picks this up. If another session depends on yours, its Context field comes from this brief.
5. Do NOT merge and do NOT switch branches. The coordination session merges in dependency order.

### Session 2: [domain label]
[same structure]

### Session 3: [domain label] (if applicable)
[same structure]

**Merge order:** [order with reasoning, or "No merge order required; all sessions are independent."]

**Merge commands for the coordination session** (this checkout is already on the default branch; no checkout needed):
```bash
git merge session/1-[persona]-[slug]      # then: claude-conductor m 1
git merge session/2-[persona]-[slug]      # then: claude-conductor m 2
# Add session/3 if applicable, respecting the merge order above.

# Cleanup after all sessions are merged:
claude-team session list                  # shows each worktree path
git worktree remove [worktree-path]       # one per session
git branch -d session/1-[persona]-[slug] session/2-[persona]-[slug]
```

**Coordination session:** Keep this session open for questions, reviewing work, and merging branches.
```

7. **Suggest opening the dashboard.** After registering sessions, tell the user:
   "Run `claude-conductor dash --open` to open the live dashboard in your browser."

## Rules

- Maximum 3 parallel sessions
- File scopes must not overlap between sessions
- Every session gets its own worktree via `claude-team session start`; never put `git checkout`, `git switch`, or `git merge` in a session prompt
- The branch registered with `claude-conductor add` must exactly match the branch passed to `claude-team session start`
- Every prompt must include persona, task, file scope, worktree path, and conductor tracking instructions
- Completion instructions must include committing all work and rebasing onto the default branch before marking done
- Merging happens only in the coordination session, in dependency order
- If the work cannot be meaningfully parallelized, say so: "This task is too intertwined to split. Better to run it as a single session."
- Do not generate vague or open-ended prompts; each task should be specific enough that the session can complete it without asking clarifying questions
- Always register sessions with `claude-conductor add` before presenting the prompts
- If SESSIONS.md does not exist, run `claude-conductor init` first
- Session re-entry: the worktree persists until removed, so reopening the worktree directory resumes the session's branch automatically
