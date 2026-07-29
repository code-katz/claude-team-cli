# Contributing

Thanks for helping. This project is a set of persona profiles plus a Bash CLI, so contributing is mostly writing Markdown carefully and running two commands before you push.

## How to customize a persona

Two supported paths, and no third:

**Open a pull request** when the change makes the persona better for everyone. Sharper domain expertise, a communication rule that improves every answer, a fixed factual error.

**Fork the repo** when the change is specific to how you or your team work. Your fork is yours. Pull from upstream when you want the improvements.

There is deliberately no per-user override layer. It was on the roadmap and was retired. An override directory means two competing definitions of a persona and no reliable way to tell which one produced a given answer. One source of truth is worth more than the convenience of a local tweak.

Never hand-edit anything under `~/.claude/`. Those are installed copies, and the next `claude-team sync` overwrites them.

## The one rule that matters

`profiles/<name>.md` is the only source of truth for a persona.

Two files are generated from it and must never be edited by hand:

| Generated file | Serves | Contains |
|---|---|---|
| `agents/<name>.md` | delegation, "have robin review this diff" | the profile minus `## Greeting` |
| `commands/<name>.md` | the `/<name>` slash command | the profile minus `## Greeting` and minus `## Required Interactive Behaviors`, with the greeting line as a trailer |

`scripts/generate-agents.sh` writes both. `claude-team sync` runs the generator and then installs all three copies. The test suite fails if either generated file drifts from its profile, so a profile edit without a regeneration will not pass CI.

## Adding or changing a persona

1. Edit `profiles/<name>.md`, or copy an existing profile as a starting point.
2. Keep the title in the form `# Name — Role`. Both the CLI and the generator split it at the first em dash, so the role may contain one but the separator must be there.
3. **Write a `## Greeting` section.** One line, the sentence the persona says when someone runs `/<name>`. The generator aborts without it rather than shipping a slash command that ends in a bare separator. This is the most common thing to forget.
4. Optionally add a model tier in `profiles/tiers.conf`. Without one the persona still works and uses the default.
5. Regenerate and test:

```bash
bash scripts/generate-agents.sh
bash tests/run.sh
```

6. Commit the regenerated `agents/` and `commands/` files alongside the profile. They are committed artifacts, not build output.

Coordinator profiles (`profiles/coordinator.md`, `profiles/coordinator-prod.md`) are exempt. The generator skips them, and they need no `## Greeting`.

## Before you push

Both of these run in CI, so running them locally saves a round trip:

```bash
bash tests/run.sh
shellcheck bin/claude-team bin/team-session-start install.sh scripts/generate-agents.sh tests/run.sh
```

The suite must be fully green. Shellcheck must be silent; it reads `.shellcheckrc` from the repo root, which documents the three disables and why each exists.

The suite runs on Linux and macOS. macOS ships Bash 3.2 and every entry point enforces a Bash 4+ floor, so use current Bash locally if you are on a Mac.

## House style

**No emdashes in prose.** Restructure with commas, colons, semicolons, parentheses, or separate sentences. Emdashes are fine as delimiters in structured lists, such as the `# Name — Role` title or a glossary entry.

**The six coding personas follow [WRITING.md](WRITING.md).** Akira, Sasha, Robin, Alex, Morgan, and Jordan carry a plain technical English standard adapted from the plain-language principles of ASD-STE100. If you are editing one of those profiles, read that file first. The other eleven personas are deliberately exempt, because a word-count rule would strip the craft out of narrative and marketing work.

## Changing the CLI

`bin/claude-team` is a single Bash file with `set -euo pipefail`. A few conventions worth knowing before you edit it:

- **Writes to shared files take the lock.** `~/.claude/branches/INDEX.md` and `~/.claude/CLAUDE.md` are shared across every session on the machine. Both appends and rewrites must serialize: an append that lands between a rewriter's read and its rename is erased by that rename.
- **Temp files are created beside their destination**, never in `TMPDIR`. A cross-device rename degrades to copy plus unlink, during which a reader can observe a half-written file.
- **`awk > tmp && mv` hides failures.** `set -e` exempts a failing command in an `&&` list, so check the result explicitly.
- **Quote `"done"`** when passing it as an argument, or shellcheck reads it as a loop terminator.
- **A test that cannot fail is not a test.** Before trusting a new one, break the thing it guards and watch it go red.

## Reporting a problem

Open an issue with the command you ran, what you expected, what happened, and your OS and Bash version (`bash --version`).
