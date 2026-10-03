---
codex: 1
project: mindattic.com
code: MAC
layer: stories
status: living
updated: 2026-10-03
---

# mindattic.com — User Stories

> ✅ done (shipped & verified) · 🟡 partial · ⬜ planned. Every ✅ cites its evidence.
> This repo has no automated test suite of its own (a static HTML page), so "verified" cites on-disk
> artifacts (what is present in `index.htm`), measurements reported from a headless-browser session,
> or a passing `codex doctor` instead of a unit test name. The shared Playwright suite in
> `MindAttic.UiUx/tests` covers the linked sites.

## Epic A — The front-door page (visitor experience)

- **MAC-US-A2 ✅** As a curious visitor, I can View Source and find a welcoming banner + table of
  contents, so the code reads as a conversation. *Given* the raw markup, *when* I open it, *then*
  lines 2–66 present the ASCII banner and the §1–§12 TOC. *(verified by: banner comment block ending at
  line 66 of `index.htm`; [LAW-7](BIBLE.md#MAC-LAW-7).)*
- **MAC-US-A3 ✅** As a visitor, I see a consistent dark cyberpunk look, so the site matches the
  MindAttic house style. *Given* the page loads, *when* it renders, *then* only the dark Cyberspace
  palette applies (no theme toggle, no theme picker). *(verified by: dark-palette-only `:root` tokens and
  the Cyberspace block in `index.htm`; [LAW-5](BIBLE.md#MAC-LAW-5).)*
- **MAC-US-A4 ✅** As a visitor, I see a copyright line at the bottom of the screen at all times, so the
  page always looks finished. *Given* any viewport, *when* it renders, *then* `#site-footer` is
  `position: fixed` to the bottom edge and the page does not scroll. *(verified by: `#site-footer`
  rule and `html`/`body` `overflow: hidden` in `index.htm`.)*
- **MAC-US-A5 ✅** As a visitor, I get a fast first paint, so the front door feels instant. *Given* a
  browser, *when* I open `index.htm`, *then* the page itself is small (~90 KB), the CDN connection is
  opened early, the first-paint fonts are preloaded, the heavy effects engine is `defer`red and fonts,
  logo, engine and textures come from the tag-pinned `MindAttic.UiUx` jsDelivr package rather than being
  embedded. *(verified by: `<link rel="preconnect">` / font `<link rel="preload">` in `<head>`, `defer` on
  the engine scripts, `…/MindAttic.UiUx@V10/…` URLs and no base64 font/image data in `index.htm`; file
  size 89,615 bytes on 2026-10-03. No load-time benchmark has been run.)*
- **MAC-US-A6 ✅** As a visitor on any device, I see the wordmark and three buttons (Résumé, GitHub,
  MindAttic Cares) centered on the screen, the buttons together exactly as wide as the wordmark, at every
  size and aspect ratio. *Given* any viewport, *when* it renders, *then* `.lockup` is centered both ways,
  `.link-row` fills it, and all sizes derive from `--u`. *(verified by: `.lockup`/`.link-row`/`.link-btn`
  rules and the three `<a class="link-btn" target="_blank">` anchors in `index.htm`; the button row was
  measured within 0.02 px of the wordmark's width, with no scroll, in headless Chrome at viewports from
  120×600 to 5120×2880 in an earlier session — reported, not re-run here.)*
- **MAC-US-A7 ✅** As a visitor, I can tap or left-click anywhere (except on a button) and a random
  Cyberspace effect appears, so the page feels alive. *Given* the engine has loaded, *when* I press on the
  page, *then* one effect is spawned, positioned at the tap for the effects that accept a position.
  *(verified by: the `pointerdown` handler calling `window.consoleBg._demo.*` in `index.htm`, every called
  function present in `console-bg.js` at tag `V10`; simulated taps added elements in headless Chrome in an
  earlier session — reported, not re-run here.)*
- **MAC-US-A8 ✅** As someone sharing or searching for the site, I see a proper title, description and
  M-monogram preview card, so links to mindattic.com look intentional. *Given* a crawler or chat app,
  *when* it reads `<head>`, *then* it finds `meta description`, a canonical `https://mindattic.com/`,
  `theme-color`, and Open Graph / Twitter "summary" tags whose image is
  `MindAttic.UiUx@V10/mindattic.com/logos/m-monogram.png`. *(verified by: grep of `index.htm` `<head>`.)*

## Epic D — Documentation & maintenance discipline

- **MAC-US-D1 ✅** As the maintainer, I want `README.md` to match reality, so nobody is told the site
  has a theme toggle, a catalog or generators it does not have. *Given* the current page, *when* the
  README is read, *then* it describes the wordmark + buttons page, the CDN asset package, hosting and the
  linked deploy. *(verified by: `README.md` rewritten 2026-10-03 alongside this bible.)*
- **MAC-US-D2 ✅** As the maintainer, I want a Codex doctor that validates the docs and the
  bible↔code cross-references, so documentation can't silently rot. *Given* `tools/codex.ps1`,
  *when* I run `doctor`, *then* front-matter, IDs, cross-refs, cited paths, and digest freshness are
  checked. *(verified by: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex.ps1
  doctor` run 2026-10-03.)*
- **MAC-US-D3 ⬜** As the maintainer, I want the doctor to optionally run an HTML-validity / dead
  link check on `index.htm` (including that every `MindAttic.UiUx@V<n>` URL resolves), so regressions are
  caught. Make it opt-in so it never needs the network by default.
- **MAC-US-D4 ✅** As the maintainer, I want a single `/commit` definition, so `/commit` behaves the same
  every time. *(verified by: `.claude/commands/` holds only `deploy.md`, `quickload.md` and
  `quicksave.md`; the one `/commit` definition is `.claude/skills/commit/SKILL.md`.)*

## Priority backlog

1. **MAC-US-D3** — add an opt-in HTML-validity / link-check step the doctor can invoke.
