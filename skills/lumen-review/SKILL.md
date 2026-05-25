---
name: lumen-review
description: Hand off completed code changes to a human reviewer in the lumen terminal diff viewer, then ingest their exported annotations and revise the code to address each one. Use this skill whenever the user wants to review changes in lumen, mentions "lumen", says "let me review this first", asks you to "address my annotations" / "apply my review comments" / "I left notes in lumen", or any time you finish a batch of code changes in a repo that uses lumen for review. Trigger this for any lumen-based review-and-revise loop even if the user does not name the skill explicitly.
---

# lumen-review

This skill runs a review-and-revise loop where a human reviews your changes in `lumen` (a terminal diff viewer), leaves annotations, exports them to a file, and you address each annotation. lumen has no API for an agent to drive it, so the integration is a plain file handoff: the human annotates and exports, you read the export. This is robust in sandboxed environments because nothing needs network or loopback access — it is just a file.

## When to run this

Run the loop when you have finished a coherent batch of changes and the user wants to review before continuing, or when the user signals they have review feedback waiting (annotations exported, notes left in lumen). Do not declare a task "done" and stop if review is expected — hand off to review instead.

## The loop

3. When the human says they have reviewed, ingest their exported annotations (see "Reading the annotations").
4. Address every annotation. Make the edits, then report back per annotation what you changed.

## Reading the annotations

lumen exports plain text to `annotations.txt`. Read the file directly — the format is self-explanatory. Each annotation is a block separated by a line of `---`:

```
**<file path>** line <N> (<SIDE>)
<comment, one or more lines>
---
**<file path>** lines <START>-<END> (<SIDE>)
<comment, one or more lines>
```

Two things are worth interpreting rather than taking literally. `(RIGHT)` is the new, post-change side of the diff; `(LEFT)` is the old side — so a RIGHT line number points into the current file, a LEFT one into code being removed or replaced. And do not trust the line numbers once you start editing: they refer to the diff the human just reviewed, and positions shift the moment you change anything, so open the referenced file near that line and locate the exact code by what the comment is about. Treat each export as a snapshot of one round — always work from a freshly exported file, never stale numbers from a previous pass.

If the human pastes the annotations into the conversation instead of exporting, just read them there; the format is identical.

## Addressing annotations

Work through every annotation. For each: locate the referenced code, make the change the comment asks for, and note what you did. If a comment is ambiguous or you disagree (e.g. it would introduce a regression), do not silently skip it — make your best edit and flag the tension for the human in your summary, or ask before proceeding if the stakes are high.

After the round, report back in this shape so the human can verify against their notes:

```
Addressed N annotations:
- <file>:<location> — "<short paraphrase of comment>" → <what you changed>
- ...
Could not address / needs your input:
- <file>:<location> — "<comment>" → <why>
```

## Notes

- jj: `lumen diff` works natively in a jj workspace and shows the working-copy change. The human does not need to commit before reviewing, and you do not need to manage git refs.
- Do not run `lumen` to "check" the diff yourself — you cannot read its TUI output. If you want to inspect the diff programmatically, use `jj diff` / `git diff` instead; lumen is for the human.
- Keep each review round scoped to one coherent batch of changes so the human's annotations stay easy to map back.

## Example

**Round 1 — handoff:**
> I've implemented the rate limiter in `limiter.rs` and wired it into `server.rs`. Review the changes and tell me when you're done.

**Round 1 — after the human exports and says "done":**
> Addressed 3 annotations:
> - `limiter.rs:41` — "use a monotonic clock here" → switched from `SystemTime::now()` to `Instant::now()`
> - `limiter.rs:58` — "this lock is held too long" → narrowed the critical section to just the counter update
> - `server.rs:112` — "missing test for the burst case" → added `test_burst_allows_up_to_capacity`
