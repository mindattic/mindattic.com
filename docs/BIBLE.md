---
codex: 1
project: mindattic.com
code: MAC
layer: bible
status: living
updated: 2026-10-02
---

# mindattic.com — Project Bible

> Single source of truth for what mindattic.com IS, is NOT, and the rules that keep it coherent.
> README says how to build/run; this says how to think about the system.
> **Read [MAC-A6](AMENDMENTS.md#MAC-A6) first** — it radically simplified the site and wins over any
> older wording below; sections that it changed say so.

## 1. The one sentence {#MAC-§1}

mindattic.com is Ryan DeBraal's front door — one hand-authored `index.htm` (no build step, no
framework) that shows the MindAttic wordmark and three link buttons (Résumé, GitHub, MindAttic
Cares) over the Cyberspace backdrop, with every font, image and effect asset served from a
tag-pinned jsDelivr package instead of being embedded in the page.

## 2. The product promise {#MAC-§2}

- **One authored page, no build step.** A visitor loads a small `index.htm` (~85 KB). There is no
  bundler, no transpiler and no framework; the only "framework" is the browser. Heavy static assets
  (fonts, logo, effect engine, textures) are *not* in the file — they are plain files on a CDN, pinned
  to an immutable release tag, so they are cached and shared with the other MindAttic sites
  ([MAC-A6](AMENDMENTS.md#MAC-A6)).
- **No tracking.** No analytics, no tracking pixels, no third-party fonts. The only external host is
  the jsDelivr CDN (cdn.jsdelivr.net) serving the `MindAttic.UiUx` repo. Privacy is the default.
- **Fast and proportional.** `<head>` opens the CDN connection early and preloads the first-paint
  fonts; the 580 KB effects engine is `defer`red so it never blocks the first paint. Everything on the
  page is a multiple of one viewport-relative unit, so the layout is the same shape on every screen and
  aspect ratio, never scrolls, and the three buttons together are exactly as wide as the wordmark.
- **View-source as a feature.** The file opens with an ASCII banner and a guided table of contents
  for anyone who reads the markup; the code is meant to be a conversation, not a puzzle.
- **Cyberpunk house style, and it reacts.** The shared Cyberspace look (circuit-board backdrop,
  scanlines, floating console windows) is spliced in from `MindAttic.UiUx`; tapping or clicking
  anywhere (except on a button) spawns one random Cyberspace effect. Locked to a dark palette.

## 3. What it is NOT {#MAC-§3}

- **NOT a framework app.** No React/Vue/Svelte, no bundler, no transpiler, no `dist/` folder. (See
  [LAW-1](#MAC-LAW-1).)
- **NOT a portfolio browser any more.** The Classic catalog browser (Portfolio / Software / Hardware /
  Writing / Visual Arts), the presentation-mode picker and the `data/*.json` runtime fetch were removed
  ([MAC-A6](AMENDMENTS.md#MAC-A6)). The page is a wordmark, three buttons and a backdrop.
- **NOT a multi-page site.** It is one `index.htm`. There are no per-project sub-pages: the old
  `<slug>.htm` catalog landing pages were retired (MindAttic.Deploy DEP-A6), and each project's page
  is its GitHub README (`https://github.com/mindattic/<Repo>`).
- **NOT a light/dark toggle site.** The site is locked to the dark Cyberspace palette
  ([MAC-A1](AMENDMENTS.md#MAC-A1)).
- **NOT the home of its own assets.** Fonts, logos, textures and the effects engine live in the
  `MindAttic.UiUx` repo (`MindAttic.UiUx/fonts/`, `MindAttic.UiUx/mindattic.com/`, `MindAttic.UiUx/Components/Cyberspace/`) and are loaded
  from jsDelivr. Edit them there and take a new tag; do not paste binaries back into `index.htm`.
- **NOT self-deploying.** Deployment is owned by the sibling `MindAttic.Deploy` repo; the retired
  per-project `deploy.ps1`/`deploy.bat`/`settings.json` are not used. (See [LAW-4](#MAC-LAW-4).)

## 4. Architecture canon {#MAC-§4}

```
  MindAttic.UiUx repo (GitHub)  ──tag V7──▶  jsDelivr CDN  ◀──────────────  visitor's browser
    fonts/, mindattic.com/logos/,                  ▲                              ▲
    Components/Cyberspace/ (+ textures)            │ <link>/<script>/@font-face   │ GET index.htm
                                                   │ URLs, pinned to @V7          │
  MindAttic.UiUx/sync/sync-mindattic-com.ps1 ──splice (CYBERSPACE block only)──▶  index.htm
  PostToolUse hook stamps <!-- Last Updated: ... --> on every Edit/Write of index.htm ──▶  (authored page)
                                                                                    ▲
                      MindAttic.Deploy (sibling repo) ──FTPS (index.htm only)─────┘  live site
```

### 4.1 Files / components {#MAC-§4.1}

- **`index.htm`** — the entire authored page (~85 KB): the View Source banner, a `<head>` with
  `preconnect`/`preload` hints, the font `@font-face` rules, the page CSS, the Cyberspace block
  (sync-owned), and a `<div id="content" role="main">` holding `.lockup.cyberspace-keepout` (the
  `#site-name` wordmark and the `.link-row` of three `.link-btn` anchors), a fixed
  `#site-footer`, and a small tap-to-spawn script. It is a `<div role="main">`, not a `<main>`, so
  Cyberspace's built-in `main` keepout does not block the whole screen
  ([MAC-A6](AMENDMENTS.md#MAC-A6)). Its sections are numbered in the file's own table of contents
  (§ 1 Fonts … § 12 Cyberspace).
- **Assets (not in this repo).** Everything binary comes from `MindAttic.UiUx` over jsDelivr at a
  tag-pinned URL — see [§10 Conventions](#MAC-§10) and `MindAttic.UiUx/docs/ASSETS.md`.
- **`idiotproof/`** — static support pages and data for the IdiotProof sub-project; **not dormant**:
  `MindAttic.Deploy` uploads it as the `idiotproof-replays` site.
- **Dormant machinery (kept on disk, unused by the page — [MAC-A6](AMENDMENTS.md#MAC-A6)):**
  `data/` (`software.json`, `ecosystem.json`, `hardware.json`, `books.json`, `visual-arts.json`),
  `fetch-descriptions.ps1`, `add-book.ps1` / `add-book.bat`, `diagram/` (`render.ps1` would throw: the
  `ECOSYSTEM-DIAGRAM` markers are gone from `index.htm`), `previews/` and `.image-base64.txt`.
  The generators still run when invoked by hand; no page reads their output, and
  `MindAttic.Deploy` no longer calls `fetch-descriptions.ps1` as a pre-deploy hook (DEP-A4).
- **`docs/`** — the Codex canon (this file, `AMENDMENTS.md`, `USER_STORIES.md`, `rfc/`, the generated
  `BIBLE.digest.md`).
- **`tools/`** — `codex.ps1` (`doctor` / `digest`) and `build-readme.ps1`.
- **`.claude/`** — `commands/` (`/deploy`, `/fetch`, `/quicksave`, `/quickload`), `skills/` (`run`,
  `commit`, `discard`, `revert`), `settings.json` (PostToolUse last-updated stamp + Codex SessionStart
  hook), `settings.local.json`.

### 4.2 Domain model (NOUNS) {#MAC-§4.2}

- **Lockup** — the wordmark plus the three buttons, shrink-wrapped to the wordmark's width and
  centered both ways (`.lockup`). It is the only keepout (`.cyberspace-keepout`).
- **Unit (`--u`)** — 1% of the smaller visible viewport side (`dvmin`), capped at 0.7273 rem. The
  wordmark is `--wm` = 11 × `--u`; the buttons are sized from `--btn-u` = 0.15 × `--wm`.
- **Link button (`.link-btn`)** — one of the three equal-width anchors; red outline, red fill and glow
  on hover/focus.
- **Asset package** — the `MindAttic.UiUx` repo seen as a runtime CDN package, addressed as
  `https://cdn.jsdelivr.net/gh/mindattic/MindAttic.UiUx@V<n>/<path>`.
- **Generated region** — a block owned by a generator, not by hand-editing. On the page that is now
  only the `CYBERSPACE` marker block.
- **Theme tokens** — CSS custom properties on `:root`; dark palette only.

### 4.3 Key services / flows (VERBS) {#MAC-§4.3}

- **sync** (`MindAttic.UiUx/sync/sync-mindattic-com.ps1`, run during deploy) — splice the `CYBERSPACE`
  block into `index.htm` (inline CSS and small scripts; the two big scripts and three textures as
  tag-pinned CDN URLs, scripts `defer`red, textures preloaded). It is the only component `mindattic.com`
  is still enrolled in.
- **stamp** (PostToolUse hook in `.claude/settings.json`) — write the UTC `<!-- Last Updated: ... -->`
  comment on every Edit/Write of `index.htm`.
- **deploy** (`/deploy` → `MindAttic.Deploy`) — the linked 4-in-1 deploy: publish the UiUx tag, pin it, run
  the sync, verify the CDN, stamp, then FTPS-upload `index.htm` only. Assets need no upload: they are already on
  the CDN.
- **tap-to-spawn** — in-page script: on `pointerdown` anywhere except a link, call one random spawn
  function from `window.consoleBg._demo` (an underscore-prefixed "dev handle" of the engine — the only
  public way to fire a single effect on demand). If the CDN script failed to load it silently does
  nothing.
- **fetch / render (dormant)** — `fetch-descriptions.ps1` still regenerates `data/*.json` from GitHub
  and Amazon; `diagram/render.ps1` still renders the ecosystem diagram. No page consumes either.

## 5. The Laws {#MAC-§5}

These project-specific laws are in addition to — and never override — the shared MindAttic house
rules, which are **inherited** here, not restated:

> **Inherited:** [`MindAttic.HouseRules.md`](../../MindAttic.HouseRules.md) (shared across all
> MindAttic projects: whole-number versioning, tooling etiquette, etc.). When a house rule and a
> project law conflict, the house rule wins unless an amendment says otherwise.

> **Amended 2026-10-02 by [MAC-A6](AMENDMENTS.md#MAC-A6):** LAW-1 and LAW-6 are refined (external
> static assets from the `MindAttic.UiUx` jsDelivr package are allowed); LAW-2 and LAW-3 are dormant.
> The law IDs are unchanged.

- **{#MAC-LAW-1} One authored page, no build step, no framework.** `index.htm` is the only
  hand-authored page, with no bundler, no transpiler and no framework. *Refined by
  [MAC-A6](AMENDMENTS.md#MAC-A6):* the old "inline CSS/JS, base64-inlined fonts, no CDN, no
  third-party request" wording is retired — heavy static assets are served from the tag-pinned
  `MindAttic.UiUx` jsDelivr package, and `<link rel=…>`, `preconnect`, `preload` and `defer` are
  allowed. If a build pipeline (compiler/bundler step) ever becomes justified, it must be decided in an
  RFC and recorded as an amendment.
- **{#MAC-LAW-2} Generated regions are not hand-edited.** The only generated region left in
  `index.htm` is the `BEGIN/END MINDATTIC.UIUX:CYBERSPACE` block, owned by
  `MindAttic.UiUx/sync/sync-mindattic-com.ps1`; edit the source in `MindAttic.UiUx` and re-run the
  sync. *Dormant by [MAC-A6](AMENDMENTS.md#MAC-A6):* `data/*.json`, the ecosystem `<svg>` and the
  other generators (`fetch-descriptions.ps1`, `add-book.ps1`, `diagram/render.ps1`) no longer feed
  the page, but the rule still applies to their outputs: never hand-edit `data/*.json`.
- **{#MAC-LAW-3} GitHub and Amazon are upstream.** *Dormant by [MAC-A6](AMENDMENTS.md#MAC-A6):* the
  page no longer shows repo tiles or books. The rule still governs the dormant generators: tile content
  comes from public `mindattic` repo metadata and book/synopsis content from Amazon; every public repo
  gets an entry (visibility is the only gate; the `hardware` topic and the `MindAttic.*` name prefix
  only pick the section — [MAC-A4](AMENDMENTS.md#MAC-A4)); a repo's GitHub description may be written
  back via `gh repo edit --description` (README-derived draft, human-approved first) so GitHub itself
  stays the durable source.
- **{#MAC-LAW-4} Deployment is centralized.** Deploys go through the sibling `MindAttic.Deploy`
  pipeline (`npm run deploy -- --site mindattic.com`). The per-project deploy scripts and
  `settings.json` FTP profile are retired and gitignored; do not resurrect them.
- **{#MAC-LAW-5} Dark palette only.** The dark Cyberspace palette is the only palette, full stop — no
  light mode, no per-theme color scheme. (The presentation-mode switch that [MAC-A5](AMENDMENTS.md#MAC-A5)
  allowed was removed by [MAC-A6](AMENDMENTS.md#MAC-A6); there is no theme picker.)
- **{#MAC-LAW-6} Privacy by default.** No analytics, tracking pixels, third-party fonts, or third-party
  network requests may be added to `index.htm`. *Refined by [MAC-A6](AMENDMENTS.md#MAC-A6):* the one
  allowed external host is the jsDelivr CDN (cdn.jsdelivr.net), serving the `MindAttic.UiUx` repo at a pinned tag.
- **{#MAC-LAW-7} View-source stays welcoming.** Preserve the opening banner, the section table of
  contents, and explanatory comments — kept accurate: they must not claim "one file / no CDN". Code
  here is documentation for the curious reader.

## 6. Verified state {#MAC-§6}

Status legend: ✅ done (verified) · 🟡 partial · ⬜ planned · 🗑️ cut · living.

There is **no compiler, unit-test suite, or CI** in this repo — it is a static HTML page with
dormant PowerShell generators. "Verification" here means: the file parses/loads as HTML, the page's
markup/CSS/script is present as described, and `codex doctor` passes. Evidence below was checked on
disk on 2026-10-02 unless stated otherwise.

- ✅ **Reduced page.** `index.htm` contains `<div id="content" role="main">` →
  `<div class="lockup cyberspace-keepout">` → `<h1 id="site-name">` + `<nav class="link-row">` with three
  `<a class="link-btn" target="_blank" rel="noopener noreferrer" aria-describedby="new-window-note">`
  (Résumé, GitHub, MindAttic Cares; the hidden `#new-window-note` tells screen readers they open a new
  window), a `<footer id="site-footer">`, and no `renderClassic`, `PORTFOLIO_*`, `#theme-picker`, `data-catalog`
  or `fetch('data/…')`. *(Evidence: grep of `index.htm`; file is ~85 KB.)*
- ✅ **Assets served from the tag-pinned jsDelivr package.** Fonts, logo variables, the two engine
  scripts and the three textures are referenced as `https://cdn.jsdelivr.net/gh/mindattic/MindAttic.UiUx@V7/…`;
  `<head>` has `preconnect` and font `preload`; engine scripts carry `defer`. *(Evidence: grep of
  `index.htm`; no `base64` font or image data remains in it.)*
- ✅ **Sizing model.** `.lockup` defines `--u`/`--wm`, `.link-row` defines `--btn-u` and fills
  `.lockup`, and `html`/`body` are `overflow: hidden` (and `user-select: none`, no touch callout, transparent
  tap highlight — nothing on the page is selectable) with a `position: fixed` footer. *(Evidence: CSS
  in `index.htm`; the parent session also measured the button row at the wordmark's width, within
  0.02 px, and no scroll, in headless Chrome across viewports from 120×600 to 5120×2880 — recorded
  here as reported, not re-run for this doc pass.)*
- ✅ **Last-updated stamp automated.** PostToolUse hook stamps `<!-- Last Updated: ... -->`; the
  current stamp is line 1 of `index.htm`. *(Evidence: hook in `.claude/settings.json`; stamp on line 1.)*
- ✅ **Codex tooling.** `tools/codex.ps1 doctor` passes. *(Evidence: run at the end of this doc pass.)*
- 🟡 **Dormant generators, last verified earlier.** `fetch-descriptions.ps1` was run end-to-end against
  live GitHub on 2026-08-20 (21 Software + 14 Ecosystem + 2 Hardware = 37 entries written to
  `data/*.json`; 17 descriptions written back with `gh repo edit`) and `data/books.json` /
  `data/visual-arts.json` hold 6 / 1 entries. They were **not** re-run in this pass and no page uses
  their output. *(Evidence: [MAC-A3](AMENDMENTS.md#MAC-A3)/[MAC-A4](AMENDMENTS.md#MAC-A4); files on disk.)*
- 🗑️ **Retired from the page:** Classic catalog browser, presentation modes, ecosystem diagram, Projects
  grid/shine, PinFooter, WebSnapshot ([MAC-A6](AMENDMENTS.md#MAC-A6)).

## 7. Active frontier {#MAC-§7}

- Design notes live in [`docs/rfc/`](rfc/). Seed: [`0001-codex-adoption`](rfc/0001-codex-adoption.md)
  (historical — written when the site was still "one file").
- Backlog and shipped capabilities live in [`docs/USER_STORIES.md`](USER_STORIES.md).
- Open decisions: delete or keep the dormant machinery (`data/`, `fetch-descriptions.ps1`,
  `add-book.*`, `diagram/`, `previews/`); add an HTML-validity / link-check step the doctor can run
  ([MAC-US-D3](USER_STORIES.md#MAC-US-D3)); bump the page to each new `MindAttic.UiUx` tag
  deliberately.

## 8. Quality bar {#MAC-§8}

A change to mindattic.com is "done" when:

1. `index.htm` is still the only hand-authored page, with no build step or framework, and no binary
   asset has been embedded back into it — heavy assets come from the pinned `MindAttic.UiUx` CDN
   package — [LAW-1](#MAC-LAW-1), [LAW-6](#MAC-LAW-6).
2. It edits the **source of truth**, not a generated region (the `CYBERSPACE` block is edited in
   `MindAttic.UiUx`) — [LAW-2](#MAC-LAW-2).
3. Every asset URL is tag-pinned (`@V<n>`, never `@main`) and the tag actually serves the file.
4. The page loads in a browser with no console errors, the dark Cyberspace styling intact, no
   scrollbar, and the three buttons exactly as wide as the wordmark — [LAW-5](#MAC-LAW-5).
5. `pwsh tools/codex.ps1 doctor` passes and the digest is regenerated.
6. The corresponding user story is updated with real status, and any ✅ cites its evidence.
7. Deployment (if performed) went through `MindAttic.Deploy` — [LAW-4](#MAC-LAW-4).

## 9. Glossary {#MAC-§9}

- **Lockup** — the wordmark plus the three link buttons (`.lockup`), centered both ways and
  shrink-wrapped to the wordmark's width. The only Cyberspace keepout.
- **Unit (`--u`)** — 1% of the smaller visible viewport side (`dvmin`), capped at 0.7273 rem; every
  size on the page is a multiple of it.
- **Asset package** — the `MindAttic.UiUx` repo served over jsDelivr at `…@V<n>/<path>`; tags are
  immutable whole numbers.
- **Generated region** — a block owned by a generator and never hand-edited; on the page, only the
  `CYBERSPACE` marker block. See [LAW-2](#MAC-LAW-2).
- **Dormant machinery** — `data/*.json`, `fetch-descriptions.ps1`, `add-book.*`, `diagram/`,
  `previews/`: kept on disk, no longer used by the page ([MAC-A6](AMENDMENTS.md#MAC-A6)).
- **Cyberspace** — the shared MindAttic.UiUx visual bundle (circuit-board backdrop, scanlines, console
  windows). Its CSS and small scripts are spliced inline; its engine and textures load from the CDN.
- **Sync** — splicing the subscribed UiUx component (Cyberspace) into `index.htm` during deploy.
- **Stamp** — the automated `<!-- Last Updated: ... -->` UTC comment.
- **House rules** — the shared [`MindAttic.HouseRules.md`](../../MindAttic.HouseRules.md), inherited
  by [§5](#MAC-§5).

## 10. Conventions {#MAC-§10}

- **Asset URL pattern.** `https://cdn.jsdelivr.net/gh/mindattic/MindAttic.UiUx@V<n>/<path>` — always
  pinned to a tag, never `@main`.
- **UiUx tags** are whole numbers (`V7`, `V8`, …), immutable once published (house rule: no SemVer). The
  page currently pins `V7`; to take a newer release change every `MindAttic.UiUx@V…` in `index.htm`
  (the `CYBERSPACE` block's tag comes from the sync script's `-CyberspaceCdnTag`).
- **Asset layout in `MindAttic.UiUx`.** Global/shared assets sit at the repo root (`fonts/<family>/`:
  `MindAttic.UiUx/fonts/outfit/`, `MindAttic.UiUx/fonts/attic/`); site-specific assets sit directly under the domain folder as
  `<domain>/<category>/` — there is no assets level (`MindAttic.UiUx/mindattic.com/logos/`,
  `MindAttic.UiUx/mindatticcares.com/logos/`, `MindAttic.UiUx/ryandebraal.com/{themes/<name>,icons,images}/`); component-owned
  textures stay at `MindAttic.UiUx/Components/Cyberspace/assets/` (that folder keeps its own name). Category folders are
  named for what the files are, not for the page that uses them.
- **Asset filenames** are lowercase kebab-case, variant last (for example m-monogram-transparent.png,
  outfit-latin-ext.woff2).
- **Page CSS naming.** IDs for the page's singletons (`#content`, `#site-name`, `#site-footer`);
  classes for the reusable pieces (`.lockup`, `.link-row`, `.link-btn`, `.logo`, `.logo-tiny`).
  Custom properties: palette tokens (`--bg`, `--bg2`, `--bg3`, `--border`, `--accent`, `--accent2`,
  `--text`, `--text2`, `--text3`, `--rule`), logo URLs (`--logo`, `--logo-tiny`), and the sizing chain
  `--u` → `--wm` (= 11 × `--u`) → `--btn-u` (= 0.15 × `--wm`). Lengths are `rem`, `dvmin` or multiples of
  those variables — no raw `px` in the page's own layout CSS.
- **Fonts.** The CSS uses the quoted stacks (`'Outfit', system-ui, sans-serif`; `'Attic', serif`) or
  `var(--font-outfit)` / `var(--font-attic)`; a bare `font-family: Outfit;` can fail silently.
- **Docs.** Codex layers as in the README (`MAC-A<n>` amendments, `MAC-US-<Epic><n>` stories, `{#MAC-LAW-n}`
  laws); never hand-edit `docs/BIBLE.digest.md`.
