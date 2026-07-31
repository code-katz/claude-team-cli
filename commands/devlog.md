---
description: Invoke the devlog skill to record a development log entry for this project
disable-model-invocation: true
---

Invoke the devlog skill for the current project.

Read the DEVLOG.md in the current project's repo root. If no DEVLOG.md exists, offer to create one.

If the user provided context in their message, draft a devlog entry based on that context and show it for approval.

If no context was provided, ask what they'd like to log — a decision made, a milestone reached, an architectural change, or a strategy shift.

Always show the drafted entry for approval before committing. Commit with prefix `devlog:` and push to the project's git remote.
