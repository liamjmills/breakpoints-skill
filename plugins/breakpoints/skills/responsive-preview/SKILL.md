---
name: responsive-preview
description: Use when the user wants to preview, view, launch, or check their website or web app — responsive testing across device sizes OR just "see it". Triggers include "launch it", "launch so i can see", "load server so i can see", "launch locally", "launch in browser", "show this on mobile and desktop", "open the responsive viewer", "preview breakpoints", checking how a local dev site looks at different widths. Keeps ONE viewer per project (reuses the running one instead of opening duplicate windows).
---

# Responsive Preview (Breakpoints)

## Overview

Opens a single-file tool (`viewer.html`) that embeds the user's **running dev server** in several iframes — each set to a true device width (phone / tablet / desktop) — so their site's media queries fire honestly and they see all breakpoints side-by-side. The site live-reloads as they edit (the viewer just frames it; the dev server's own reload still works).

`launch.sh` starts a small Node **reverse proxy**: it serves the bundled `viewer.html` AND proxies the user's dev server through the **same origin**. Same-origin matters because scroll-sync and Save PNG read the iframe's content, which the browser blocks across origins — proxying keeps those features working for any dev server (Vite, Next, static, etc.).

**Requires Node.js** (the proxy). If Node is missing, fall back: serve the project statically and open `viewer.html?url=<same-origin-path>` so at least the preview works.

## When to Use

- "Preview my site responsively" / "show this on mobile + desktop" / "check breakpoints"
- The user has a dev server running (Vite, Next, live-server, `python -m http.server`, etc.)

**When NOT to use:** there is no running local server (offer to start theirs first), or the user wants a static screenshot only (a single headless screenshot is simpler).

## Steps

1. **Get the dev URL.** Find the user's running dev server (e.g. `http://localhost:3000`, `http://localhost:5173`, `http://127.0.0.1:8000`). Ask if unknown. It must be `http://` or `https://`. If nothing is running, help them start their dev server first.

2. **Launch.** Run the bundled `preview.sh` (it sits next to this SKILL.md), passing the dev URL. Use the absolute path to `preview.sh` in this skill's directory, and run it from the user's project directory so it keys the viewer to that project:

   ```bash
   bash <skill-dir>/preview.sh http://localhost:3000
   ```

   `preview.sh` is a single-instance wrapper around `launch.sh`: it keeps **one viewer per project**. If a viewer for this project is already running, it reuses it (just reopens the tab) instead of spawning another — so repeated "launch it" requests don't pile up windows. If the project's dev URL changed (port floated), it replaces the stale viewer. On a fresh launch it picks a free port, starts the proxy, serves `viewer.html`, opens the browser, and prints the viewer URL + server PID (for stopping later).

3. **Report** the printed viewer URL to the user and how to stop the server (`kill <PID>`).

## Quick Reference

| Need | Do |
|------|-----|
| Start / reopen the viewer | `bash <skill-dir>/preview.sh <dev-url>` (one per project — reuses if already running) |
| Stop it | `kill <PID>` (printed on launch) |
| Different site | re-run `preview.sh` with the new URL (replaces this project's viewer) |
| Bypass dedup (raw launch) | `bash <skill-dir>/launch.sh <dev-url>` |

## Common Mistakes

- **Passing a file path instead of a URL.** The viewer needs an `http(s)` URL — the user's dev server, not `./index.html`. If they only have static files, point them at a static server (`python3 -m http.server`) first, then pass that URL.
- **The site refuses to embed.** If the framed site shows blank, its server is sending `X-Frame-Options: DENY` or a restrictive `Content-Security-Policy: frame-ancestors`. Most local dev servers allow framing; production sites often don't. This is the site's setting, not the viewer's.
- **Node missing.** The proxy launcher needs Node.js. If it's not installed, the preview still works without sync/Save-PNG by serving statically and opening `viewer.html?url=<dev-url>` manually.
- **HMR not auto-reloading through the proxy.** Some dev servers hardcode their HMR socket to the original port; if live-reload stops working through the proxy, the manual Reload button still refreshes all frames.
