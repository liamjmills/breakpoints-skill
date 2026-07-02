# snag-list

Passively collects UI/UX **niggles** — small recurring interface preferences and
defects — while you build internal tools, then `/snag` reviews, culls, categorizes,
dedupes, and exports a clean set to hand off.

## The flow
On first run, a one-time welcome (via the `SessionStart` hook) explains this flow, then gets out of the way:
1. A `Stop` hook scans each turn against a UI keyword net (`scripts/snag-capture.js`).
   UI-relevant turns are appended to `~/.claude/snag-list/captures.log` (JSONL).
   Zero LLM cost; never breaks a session (always exits 0).
2. Say `snag: <thing>` to force-capture anything the net would miss.
3. Run `/snag` when you want to review: it judges, extracts the rule, categorizes,
   dedupes, lets you keep/cut, writes `catalogue.md`, and emits an export in
   `~/.claude/snag-list/exports/` to hand off.
4. Hand the export to whoever collates the master set.

## Install
Add the `liam-skills` marketplace, then install `snag-list`.

## Tune
Edit `~/.claude/snag-list/config.json` (`keywords`, `forcePhrases`) — no reinstall needed.
Add project paths to `~/.claude/snag-list/denylist` to exclude them.

## Tests
`bash tests/run-all.sh`
