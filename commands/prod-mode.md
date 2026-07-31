---
description: Switch the coordinator to production mode, with branch enforcement on
disable-model-invocation: true
---

Run this bash command to enable production coordinator mode: `claude-team coordinator prod`

Production mode is now active. Branch enforcement is on.

Rules in effect:
- All code changes require a registered branch (`claude-team branch start feat/<name>`)
- Plans must include a proposed branch line
- Worktrees are preferred for parallel sessions (`claude-team session start`)
- Ship via rebase + push + MR/PR; the user merges, Claude pushes
- Session wrap-up requires devlog + `claude-team session done`

To return to casual mode: run `/casual-mode` or `claude-team coordinator on`
