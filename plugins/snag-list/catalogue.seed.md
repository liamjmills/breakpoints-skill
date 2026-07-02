# UI/UX niggle catalogue

Behaviour-level rules for internal tools. Current stack: HTML (React/Astro examples added later).

## Form controls
- **Dropdowns:** never a native `<select>`; build a styled dropdown that matches the app.
  _HTML example:_ a `role="listbox"` element with styled options; hide the native control.
  <!-- TODO: React/Astro example -->
- **Number inputs:** no spinner up/down arrows; allow free text entry.
  _HTML example:_ `<input type="text" inputmode="decimal">` (not `type="number"`), validate on blur.
  <!-- TODO: React/Astro example -->

## Input & editing
- **Undo:** provide undo (and redo where sensible) for destructive/edit actions.

## Canvas & zoom
- **Zoom:** provide zoom for dense or visual content.

## Tables & data
- **Row sizing:** rows should smart-resize (fit content sensibly, resizable where useful), not fixed/clipped.
