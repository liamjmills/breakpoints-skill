# Breakpoints — responsive preview skill for Claude Code

Preview your **running dev site** at multiple device widths side-by-side, live-reloading as you edit — without leaving Claude Code.

![phone · tablet · desktop, framed side by side]

## Install

In Claude Code, paste:

```
/plugin marketplace add liammills/breakpoints-skill
/plugin install breakpoints@liam-skills
```

(Replace `liammills` with your GitHub user/org once this repo is pushed.)

## Use

1. Start your dev server (Vite, Next, live-server, `python3 -m http.server`, …).
2. Tell Claude: **"preview my site responsively"** (or run `/breakpoints:responsive-preview`).
3. Give it your dev URL (e.g. `http://localhost:3000`). The viewer opens in your browser with phone / tablet / desktop frames.

## What you get

- True-width iframes so the site's media queries fire honestly
- Drag-to-resize each frame, device presets, landscape
- Focus a single frame, sync-scroll, zoom/fit, background swap
- Per-frame Save PNG (same-origin sites)
- Layout presets (Phones, Mobile + Desktop, Full Range, …)

## How it works

The plugin bundles a single `viewer.html`. The skill serves it on a free local port and opens it pointed at your dev server via a `?url=` param. No build step, no dependencies beyond a local Python (for the static server) and a browser.

## Limitations

- The framed site must allow embedding (no `X-Frame-Options: DENY` / restrictive CSP `frame-ancestors`). Local dev servers usually do.
- Save PNG and scroll-sync are same-origin features; across the viewer↔site origin boundary they no-op. Everything else works.

## License

MIT
