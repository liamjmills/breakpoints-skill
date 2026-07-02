#!/usr/bin/env node
'use strict';
/* Snag List — UI/UX niggle capture.
   Usage: node snag-capture.js capture   (Stop hook; stdin = hook JSON)
          node snag-capture.js nudge      (SessionStart hook)
   Must never break a session: everything is wrapped; always exits 0. */
const fs = require('fs');
const path = require('path');
const os = require('os');

const DIR = process.env.SNAG_DIR || path.join(os.homedir(), '.claude', 'snag-list');
const LOG = path.join(DIR, 'captures.log');
const ARCHIVE = path.join(DIR, 'archive');
const DENYLIST = path.join(DIR, 'denylist');
const CONFIG = path.join(DIR, 'config.json');
const LAST_UUID = path.join(DIR, '.last-capture-uuid');
const LAST_SIG = path.join(DIR, '.last-capture-sig');
const LAST_REVIEW = path.join(DIR, '.last-review');
const WELCOMED = path.join(DIR, '.welcomed');

const THRESHOLD = 15;            // nudge after this many fresh captures
const MAXLEN = 1500;
const ROTATE_BYTES = 5 * 1024 * 1024;
const EDIT_TOOLS = new Set(['Edit', 'Write', 'MultiEdit', 'NotebookEdit']);

const DEFAULT_CONFIG = {
  keywords: [
    "dropdown", "select", "combobox", "listbox", "autocomplete", "typeahead",
    "number field", "spinner", "stepper", "textarea", "form", "validation", "placeholder",
    "toggle", "switch", "checkbox", "radio", "slider",
    "table", "row", "column", "resize", "sort", "filter", "pagination", "sticky", "scroll", "virtualize",
    "modal", "dialog", "drawer", "popover", "tooltip", "toast", "notification", "banner",
    "undo", "redo",
    "zoom", "pan", "canvas", "fit to",
    "hover", "focus", "disabled", "loading", "skeleton", "empty state", "error state",
    "drag", "drop", "reorder", "keyboard shortcut", "accessibility", "contrast", "spacing", "alignment",
    "dropdown menu", "context menu", "date picker", "time picker"
  ],
  forcePhrases: ["snag:", "note this niggle:", "niggle:"]
};

const WELCOME = `👋 snag-list is now watching for UI/UX niggles.

The flow:
1. As you build, it quietly notes any turn about interface bits —
   dropdowns, tables, inputs, undo, zoom, and the like.
   No cost, nothing interrupted.
2. Missed one? Type "snag: <the thing>" to capture it for sure.
3. Run /snag when ready — it sorts what it caught, drops the noise,
   and lets you keep or cut each one.
4. You get a clean list to hand off. Done.

Nothing leaves your machine. Tune or pause it anytime in ~/.claude/snag-list/.`;

function readStdin() { try { return fs.readFileSync(0, 'utf8'); } catch { return ''; } }
function ensureDir() { try { fs.mkdirSync(DIR, { recursive: true }); } catch {} }

function parseTranscript(file) {
  const out = [];
  let text; try { text = fs.readFileSync(file, 'utf8'); } catch { return out; }
  for (const line of text.split('\n')) {
    const t = line.trim(); if (!t) continue;
    try { out.push(JSON.parse(t)); } catch {}
  }
  return out;
}

function textOf(entry) {
  const c = entry && entry.message && entry.message.content;
  if (!Array.isArray(c)) return '';
  return c.filter(b => b && b.type === 'text' && typeof b.text === 'string')
          .map(b => b.text).join('\n').trim();
}

function extractTurn(entries) {
  const conv = entries.filter(e =>
    e && (e.type === 'user' || e.type === 'assistant') &&
    e.isMeta !== true && e.isSidechain !== true);
  let pIdx = -1;
  for (let i = conv.length - 1; i >= 0; i--) {
    if (conv[i].type === 'user' && textOf(conv[i])) { pIdx = i; break; }
  }
  if (pIdx === -1) return null;
  const prompt = textOf(conv[pIdx]);
  const after = conv.slice(pIdx + 1);
  const respParts = []; const edited = []; let dedupId = null;
  for (const e of after) {
    if (e.type !== 'assistant') continue;
    dedupId = e.uuid || dedupId;
    const c = (e.message && e.message.content) || [];
    if (!Array.isArray(c)) continue;
    for (const b of c) {
      if (!b) continue;
      if (b.type === 'text' && typeof b.text === 'string') respParts.push(b.text);
      if (b.type === 'tool_use' && EDIT_TOOLS.has(b.name)) {
        const fp = b.input && (b.input.file_path || b.input.notebook_path);
        if (fp) edited.push(fp);
      }
    }
  }
  if (!dedupId && conv.length) dedupId = conv[conv.length - 1].uuid || null;
  return { prompt, response: respParts.join('\n').trim(), edited, dedupId };
}

function readDenylist() {
  try {
    return fs.readFileSync(DENYLIST, 'utf8').split('\n')
      .map(l => l.trim()).filter(l => l && !l.startsWith('#'));
  } catch { return []; }
}
function isDenied(cwd) {
  if (!cwd) return false;
  for (const p of readDenylist()) {
    const base = p.replace(/\/+$/, '');
    if (cwd === base || cwd.startsWith(base + '/')) return true;
  }
  return false;
}

function redact(text) {
  if (!text) return text;
  return text
    .replace(/\b(bearer\s+)[A-Za-z0-9._~+\/=-]{8,}/gi, '$1[REDACTED]')
    .replace(/((?:password|passwd|secret|token|api[-_]?key|apikey|access[-_]?key|auth|authorization|bearer)\s*["']?\s*[:=]\s*["']?)[^\s"',;}]+/gi, '$1[REDACTED]')
    .replace(/AKIA[0-9A-Z]{16}/g, '[REDACTED-AWS-KEY]')
    .replace(/sk_(?:live|test)_[A-Za-z0-9]+/g, '[REDACTED-STRIPE-KEY]')
    .replace(/gh[pousr]_[A-Za-z0-9]{20,}/g, '[REDACTED-GH-TOKEN]')
    .replace(/-----BEGIN [A-Z ]*PRIVATE KEY-----/g, '[REDACTED PRIVATE KEY BLOCK]');
}

function rotateIfLarge() {
  try {
    if (fs.existsSync(LOG) && fs.statSync(LOG).size > ROTATE_BYTES) {
      fs.mkdirSync(ARCHIVE, { recursive: true });
      const ts = nowStamp().replace(/[: ]/g, '-');
      fs.renameSync(LOG, path.join(ARCHIVE, `captures-${ts}.log`));
    }
  } catch {}
}

function truncate(text, n) {
  if (!text) return '';
  return text.length > n ? text.slice(0, n) + ' …[truncated]' : text;
}

function nowStamp() {
  const d = new Date(); const p = x => String(x).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth()+1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

function loadConfig() {
  let cfg = { keywords: DEFAULT_CONFIG.keywords.slice(), forcePhrases: DEFAULT_CONFIG.forcePhrases.slice() };
  try {
    if (fs.existsSync(CONFIG)) {
      const j = JSON.parse(fs.readFileSync(CONFIG, 'utf8'));
      if (Array.isArray(j.keywords) && j.keywords.length) cfg.keywords = j.keywords;
      if (Array.isArray(j.forcePhrases) && j.forcePhrases.length) cfg.forcePhrases = j.forcePhrases;
    } else {
      ensureDir();
      fs.writeFileSync(CONFIG, JSON.stringify(DEFAULT_CONFIG, null, 2));
    }
  } catch {}
  return cfg;
}

function escapeRe(s) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

function matchedKeywords(text, cfg) {
  if (!text) return [];
  const hay = text.toLowerCase();
  const hits = [];
  for (const kw of cfg.keywords) {
    const k = kw.toLowerCase();
    // keyword bounded by a non-letter (or string edge) on both sides — handles multi-word terms
    const re = new RegExp('(^|[^a-z])' + escapeRe(k) + '([^a-z]|$)');
    if (re.test(hay)) hits.push(kw);
  }
  return hits;
}

function isForced(prompt, cfg) {
  if (!prompt) return false;
  const p = prompt.toLowerCase();
  return cfg.forcePhrases.some(fp => p.includes(fp.toLowerCase()));
}

function runCapture() {
  const payload = readStdin();
  let data = {}; try { data = JSON.parse(payload); } catch {}
  const tp = data.transcript_path;
  if (!tp || typeof tp !== 'string' || !fs.existsSync(tp)) return;
  const cwd = data.cwd || '';
  if (isDenied(cwd)) return;
  const entries = parseTranscript(tp);
  const turn = extractTurn(entries);
  if (!turn || !turn.prompt) return;

  const cfg = loadConfig();
  const forced = isForced(turn.prompt, cfg);
  const hits = matchedKeywords(turn.prompt + '\n' + turn.response, cfg);
  if (!forced && hits.length === 0) return;   // the wide net: UI turns only

  let last = ''; try { last = fs.readFileSync(LAST_UUID, 'utf8').trim(); } catch {}
  if (turn.dedupId && turn.dedupId === last) return;
  const promptOut = truncate(redact(turn.prompt), MAXLEN);
  const respOut = truncate(redact(turn.response), MAXLEN);
  let sig = null; try { sig = JSON.parse(fs.readFileSync(LAST_SIG, 'utf8')); } catch {}
  if (sig && sig.cwd === cwd && sig.prompt === promptOut &&
      (respOut === sig.response || respOut.startsWith(sig.response))) return;

  ensureDir();
  rotateIfLarge();
  const rec = {
    ts: nowStamp(),
    project: cwd ? path.basename(cwd) : '',
    cwd,
    prompt: promptOut,
    excerpt: respOut,
    edited: turn.edited,
    matched: hits,
    forced
  };
  try { fs.appendFileSync(LOG, JSON.stringify(rec) + '\n'); } catch {}
  if (turn.dedupId) { try { fs.writeFileSync(LAST_UUID, turn.dedupId); } catch {} }
  try { fs.writeFileSync(LAST_SIG, JSON.stringify({ cwd, prompt: promptOut, response: respOut })); } catch {}
}

function countRecords() {
  try { return fs.readFileSync(LOG, 'utf8').split('\n').filter(l => l.trim()).length; }
  catch { return 0; }
}

function runNudge() {
  const total = countRecords();
  let baseline = 0;
  try { baseline = parseInt(fs.readFileSync(LAST_REVIEW, 'utf8').trim(), 10) || 0; } catch {}
  const fresh = total - baseline;
  if (fresh >= THRESHOLD) {
    process.stdout.write(
      `Snag List: ${fresh} new UI captures since last review. Run /snag to review, cull, and export.\n`);
  }
}

function runSession() {
  // First session after install: greet once, then stop. Later sessions nudge.
  let welcomed = false;
  try { welcomed = fs.existsSync(WELCOMED); } catch {}
  if (!welcomed) {
    process.stdout.write(WELCOME + '\n');
    ensureDir();
    try { fs.writeFileSync(WELCOMED, nowStamp()); } catch {}
    return;
  }
  runNudge();
}

function main() {
  const mode = process.argv[2] || 'capture';
  try {
    if (mode === 'nudge') runNudge();
    else if (mode === 'session') runSession();
    else runCapture();
  } catch {}
  process.exit(0);
}
main();
