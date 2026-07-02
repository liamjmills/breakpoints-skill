---
description: Review captured UI/UX niggles — cull, categorize, dedupe, and export a clean set for handoff.
---

# /snag — review & cull UI niggles

You are processing the passively-captured UI/UX niggle log into a clean catalogue.

## Inputs
- Log: `~/.claude/snag-list/captures.log` (JSONL; one capture per line with fields
  `ts, project, cwd, prompt, excerpt, edited, matched, forced`).
- Existing catalogue: `~/.claude/snag-list/catalogue.md` (create it from the plugin's
  `${CLAUDE_PLUGIN_ROOT}/catalogue.seed.md` if it does not exist).

## Steps
1. **Read** the log. If it is empty or missing, tell the user there is nothing to review and stop.
2. **Judge** each capture: is it genuinely a UI/UX niggle, preference, or rule for building
   tools? Discard noise (general coding, unrelated chat, false keyword hits). Keep the signal.
3. **Extract** each survivor as a normalized, imperative rule (e.g.
   "Number inputs — no spinner arrows; allow free text entry"). Note its `project` and `ts` as provenance.
4. **Categorize** into exactly these buckets: Form controls · Tables & data · Navigation & layout ·
   Feedback & state · Canvas & zoom · Input & editing · Misc.
5. **Dedupe** against each other AND against rules already in `catalogue.md`. Merge near-identical
   rules; keep the clearest phrasing; increment a frequency note.
6. **Triage:** show the candidate rules grouped by category. Ask the user to keep/cut each
   (use AskUserQuestion in batches, or present a numbered list and take their cuts). Only survivors proceed.
7. **Write** survivors into `~/.claude/snag-list/catalogue.md`, merged under their category headings
   (append-and-reconcile — never blow away existing kept rules). If a category from Step 4 has no heading yet in `catalogue.md`, create the heading (the full taxonomy is the 7 buckets listed in Step 4).
8. **Render** a readable view: write `~/.claude/snag-list/catalogue.review.md` (a copy of the
   catalogue) so Liam's doc-style hook renders + opens it. (If that hook is absent, just note the path.)
9. **Export** the handoff: write `~/.claude/snag-list/exports/ui-niggles-<YYYY-MM-DD>-<who>.md`
   (categorized rules + provenance) and a `.json` mirror. Derive `<who>` from `git config user.name`
   (fallback: `$USER`).
10. **Reset the baseline:** write the current total record count to `~/.claude/snag-list/.last-review`
    so the SessionStart nudge counts only captures after this review.
11. Summarize: how many captured → kept → new-this-run, and the export path to hand to Liam.

## Rules
- Never invent niggles that aren't supported by a capture.
- Keep rules behaviour-level and stack-agnostic; put any code specifics under an `_example_` note.
- Do not delete `captures.log` — the baseline file handles "new since last review".
