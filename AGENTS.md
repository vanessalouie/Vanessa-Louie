# AI conventions

## About this repository
My public portfolio for finance related models,  owned by Vanessa Louie.
Canonical file: AGENTS.md. CLAUDE.md points here.

## About me
- Work background in HR operations: leave of absence cases, I-9 review, position tracking, payroll validation, SharePoint and Excel tools.
-Reply in English only.

## Where things are
- capabilities/<capability>/  a capability, with its spec
- docs/briefs/          written BEFORE work: scope + hypothesis
- docs/decisions/       written AFTER work: recommendations
- analysis/             findings and figures
- data/                 sourced inputs, with provenance

## Naming
- If you are not certain which folder a file belongs in, ask me before you write it. Do not choose for me.
- Never invent a path or filename. I will give you the exact one.
- Use the exact filename the stage brief gives: lowercase, hyphens, no spaces. Dated documents are YYYY-MM-DD-slug-type.md.
- Slugs name the engagement, never the week, the course, or the assignment number.

## How I work
- Explain concepts fully in an easy and understandable manner for beginners and walk through a worked example. Do not just hand me conclusions.
- Plain language first, then the technical term in parentheses.
- Critique my reasoning directly. I would rather be corrected than agreed with.
- When you are uncertain, say so and say what would resolve it.

## What you may and may not draft
- You MAY explain, critique, debug, quiz me, and draft mechanical files (folders, stubs, .gitignore, formatting, typo checks).
- You MAY NOT write my briefs, analyses, memos, reflections, or my README bio. You may review them.
- Never overwrite README.md or RESUME.md unless I ask for a specific edit.
- Every statistic or figure you give me is a draft until I verify it against a source.

## Scope
Do the work I asked for. If you notice something worth doing that I did not ask for, tell me instead of doing it. Show me every file before it is committed.

## Documentation
When work changes, update the document that describes it in the same commit.

## Commits
Descriptive messages: what changed and why. Never "update" or "stuff".

## Prompt log
At the end of every session that changed a file, append one entry to prompt-log.md: the date, what I asked, what you produced, what was wrong, and how it was caught. Never backfill earlier sessions and never edit a past entry.

## Never paste into a model, never commit
- No personal data about anyone
- Credentials, API keys, tokens
- Licensed or copyrighted material (textbook chapters, publisher slides, paid datasets)

If I paste something that fits this list, stop and tell me instead of continuing. Use fake or anonymized samples when a task needs this kind of data.

## Mistakes to avoid (append to this list)
Record errors here as they happen, so the same one does not repeat.
- (empty: add the first one when it happens)