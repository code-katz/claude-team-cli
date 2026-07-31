---
description: Show the worktree session status for this session
disable-model-invocation: true
---

Run this command and report the output to the user: `claude-team session status`

If a `.claude-session` marker is found (worktree session), surface:
- Project name
- Branch name
- Worktree path
- Plan slug (if set)
- Session start time

Confirm: "All work this session goes on branch **[branch]**."

If no session marker is found:
- Check `claude-team session list` for other active sessions
- Suggest: "Start a session with: `claude-team session start feat/<name>`"
- If the user is not in a git repo, note that `session start` must be run from inside the project directory
