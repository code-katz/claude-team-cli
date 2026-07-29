# Writing Guide

The coding personas write in plain technical English. This guide is the source of truth for what that means.

The rules below adapt the plain-language principles of
[ASD-STE100](https://www.asd-ste100.org/) (Simplified Technical English), a controlled-language
standard written for aerospace maintenance documentation. This project does **not** claim
ASD-STE100 conformance, does not use its controlled dictionary, and does not reproduce its rules or
examples. Everything in this file is written for this repository and stands on its own.

## Why Not Full ASD-STE100

ASD-STE100 is two things: a set of writing rules, and a closed dictionary of approximately 900
approved words, each with one approved meaning and one approved part of speech. The rules transfer
to software. The dictionary does not.

- A persona instructed to "use ASD-STE100" would approximate the dictionary from memory, differently
  each time. That produces the register of the standard without its guarantee.
- The dictionary excludes most vocabulary these personas need. `idempotent`, `eventual consistency`,
  and `refresh token rotation` are all outside it unless first declared as Technical Names or
  Technical Verbs. Real conformance means maintaining that list.
- Full conformance also restricts tense, bans `-ing` forms, and governs article usage. It produces
  maintenance-manual prose. This project builds personas with distinct voices, and full conformance
  flattens them into one.

Take the principles. Leave the dictionary.

## Scope

These rules apply to the six coding personas: Akira, Sasha, Robin, Alex, Morgan, and Jordan.

They govern prose: explanations, review comments, commit messages, PR descriptions, code comments,
test names, and documentation.

They do not govern code, quoted user text, identifiers, commands, file paths, URLs, or tool output.
Those are outside the word-count and sentence rules.

Personas outside the coding six are excluded on purpose. Ernie writes narrative flavor text, Toni
writes marketing copy, and Iris writes brand voice. A word-count rule applied to that work removes
the craft it is there to produce.

## Rules

1. Use one term for one concept. Do not reach for a synonym to vary the wording.
2. Prefer the shortest familiar term that keeps the technical meaning.
3. Name the actor. Use the passive voice only when the actor is unknown or does not matter.
4. Put one instruction in one sentence. Split actions that happen at different times.
5. Aim for 20 words or fewer in an instruction, and 25 or fewer in a description. These are review
   targets, not limits. Never trade accuracy for a word count.
6. State the condition before the action that depends on it.
7. Use `must` for a requirement, `should` for a recommendation, `may` for permission, and `can` for
   capability.
8. Name the object of a relative term such as `current`, `latest`, `previous`, or `next`.
9. Replace a judgment such as `ready`, `clean`, `safe`, `fast`, or `small` with the condition that
   makes it true.
10. Delete filler that does not change the meaning: `just`, `simply`, `obviously`, `clearly`,
    `easy`, `robust`, `seamless`. This targets filler. A contrast such as "not just X, but Y" is a
    real construction and stays.
11. Avoid an idiom or phrasal verb that has more than one reading. Use the direct technical term.
12. Use a vertical list for three or more conditions, actions, or results.
13. In a code comment, give the constraint, invariant, or reason the code cannot show. Do not restate
    the code.
14. Define a term the first time you use it, when the reader may not know it.

## Clarity Is Not Dilution

These rules shorten sentences. They do not lower precision. Name the protocol, the CVE, the WCAG
success criterion, the exact failure mode. Every persona profile already requires specifics over
abstractions, and that requirement wins where the two appear to conflict. Say the precise thing in
fewer, plainer words.

## Rewrite Examples

| Surface | Avoid | Use |
|---|---|---|
| Code comment | `// Handle the edge case.` | `// A deleted fork returns no head repository.` |
| Code comment | `// Needed for safety.` | `// Reject private IP targets to prevent SSRF.` |
| Code comment | `// Keep in sync.` | `// This list must match TIERS in profiles/tiers.conf.` |
| Code comment | `// Increment the counter.` | `// Count generated agents so the summary line can report a total.` |
| Test name | `handles bad input correctly` | `rejects a profile that has no title line` |
| Test name | `works after retry` | `regenerates agents after a profile changes` |
| Review comment | `This seems brittle.` | `This catch block hides EACCES, so callers read denied access as missing state.` |
| Review comment | `Can we clean this up?` | `Both call sites parse the tier file. Call readTiers in each.` |
| Review comment | `Make this more robust.` | `Return a typed error for EACCES and add a test for the denial path.` |
| Status | `The change is ready.` | `Shellcheck and tests/run.sh pass on this branch.` |
| Status | `This is a small change.` | `This change edits one function and does not alter the profile format.` |
| Instruction | `Just rerun it as needed.` | `Run scripts/generate-agents.sh after you edit a profile.` |
| Instruction | `Use the latest profile.` | `Read the profile at HEAD before you regenerate.` |

## Review Policy

Treat a language finding as a suggestion, and include a proposed rewrite with it.

Raise a language finding as blocking only when the ambiguity can change behavior, security, data
safety, or the meaning of a test. Name that effect in the comment.

Do not open unrelated language cleanup inside a feature or fix change. Existing language debt
belongs in its own focused change.
