---
description: Invoke the roadmap skill to update the product roadmap for this project
disable-model-invocation: true
---

Invoke the roadmap skill for the current project.

Read the ROADMAP.md in the current project's repo root. If no ROADMAP.md exists, offer to create one using the roadmap skill template.

If the user provided context in their message (e.g. "we shipped X", "add Y to the roadmap", "defer Z"), proceed immediately with the appropriate update: modify the Current Roadmap section and draft a Revision History entry.

If no context was provided, summarize the current roadmap state (active Tier 1 items, any open questions) and ask what they'd like to update.

Always show changes for approval before committing. Commit with prefix `roadmap:` and push to the project's git remote.
