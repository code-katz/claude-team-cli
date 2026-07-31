---
description: Switch the coordinator to casual mode, with no branch enforcement
disable-model-invocation: true
---

Run this bash command to enable casual coordinator mode: `claude-team coordinator on`

Casual mode is now active. Branch enforcement is off — commit directly to main as you normally would.

The coordinator will still suggest the right team member for your task and prompt mode selection, but it won't block code changes or require branch registration.

To enable production workflow (branches, worktrees, MR/PR flow): run `/prod-mode` or `claude-team coordinator prod`
