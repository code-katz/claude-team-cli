---
description: Show the active branch status for this project, and propose a branch name if none is registered
disable-model-invocation: true
---

Run this command and report the output to the user: `claude-team branch status`

Then:
- If an active branch is shown, confirm it to the user and remind them all work this session goes on that branch.
- If no active branch is shown, propose a branch name based on the current conversation context and tell the user to run: `claude-team branch start feat/<proposed-name>`
