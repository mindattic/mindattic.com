---
codex: 1
project: mindattic.com
code: MAC
layer: bible
status: living
updated: 2026-10-03
---

# mindattic.com — Project Bible

> Single source of truth for what mindattic.com IS, is NOT, and the rules that keep it coherent.
> README says how to build/run; this says how to think about the system.

## 1. The one sentence {#MAC-§1}

mindattic.com is Ryan DeBraal's front door — one hand-authored `index.htm` (no build step, no
framework) that shows the MindAttic wordmark, the motto "A distributed software development company
specializing in interactive media." and three link buttons (Résumé, GitHub, MindAttic Cares) over the
Cyberspace backdrop, with every font, image and effect asset served from a
tag-pinned jsDelivr package instead of being embedded in the page.

## 2. The product promise {#MAC-§2}

- **One authored page, no build step.** A visitor loads a small `index.htm` (~90 KB). There is no
  bundler, no transpiler and no framework; the only "framework" is the browser. Heavy static assets
  (fonts, logo, effect engine, textures) are *not* in the file — they are plain files on a CDN, pinned
  to an immutable release tag, so they are cached and shared with the other MindAttic sites.
- **No tracking.** No analytics, no tracking pixels, no third-party fonts. The only external host is
  the jsDelivr CDN (cdn.jsdelivr.net) serving the `MindAttic.UiUx` repo. Privacy is the default.
- **Fast and proportional.** `<head>` opens the CDN connection early and preloads the first-paint
  fonts; the ~560 KB effects engine is `defer`red so it never blocks the first paint. Everything on the
  page is a multiple of one viewport-relative unit, so the layout is the same shape on every screen and
  aspect ratio, never scrolls, and the three buttons together are exactly as wide as the wordmark. The
  motto is fitted to the wordmark's width too: a small script solves for its font-size and
  letter-spacing (one line on wide screens, 2–3 balanced lines on narrow ones, each spanning the
  wordmark exactly); without JavaScript it is justified to the same width.
- **Findable and shareable.** `<head>` carries a `meta description`, a canonical URL
  (`https://mindattic.com/`), `theme-color`, and Open Graph / Twitter "summary" card tags whose image is
  the M monogram (`mindattic.com/logos/m-monogram.png`, 320×320) from the same pinned package.
- **View-source as a feature.** The file opens with an ASCII banner and a guided table of contents
  for anyone who reads the markup; the code is meant to be a conversation, not a puzzle.
- **Cyberpunk house style, and it reacts.** The shared Cyberspace look (circuit-board backdrop,
  scanlines, floating console windows) is spliced in from `MindAttic.UiUx`; tapping or left-clicking
  anywhere around the lockup sets off a short spark surge and spawns one random Cyberspace effect that
  starts at the tap point. Locked to a dark palette.

## 3. What it is NOT {#MAC-§3}

- **NOT a framework app.** No React/Vue/Svelte, no bundler, no transpiler, no `dist/` folder. (See
  [LAW-1](#MAC-LAW-1).)
- **NOT a portfolio or catalog.** The page is a wordmark, a motto, three buttons and a backdrop. It fetches no
  local data and lists no projects.
- **NOT a multi-page site.** It is one `index.htm`. There are no per-project sub-pages: each project's
  page is its GitHub README (`https://github.com/mindattic/<Repo>`), and the server 301-redirects
  `/<slug>.htm` URLs there (see [§4.4](#MAC-§4.4)).
- **NOT a light/dark toggle site.** The site is locked to the dark Cyberspace palette
  ([LAW-5](#MAC-LAW-5)).
- **NOT the home of its own assets.** Fonts, logos, textures and the effects engine live in the
  `MindAttic.UiUx` repo (`MindAttic.UiUx/fonts/`, `MindAttic.UiUx/mindattic.com/`, `MindAttic.UiUx/Components/Cyberspace/`) and are loaded
  from jsDelivr. Edit them there and take a new tag; do not paste binaries back into `index.htm`.
- **NOT self-deploying.** Deployment is owned by the sibling `MindAttic.Deploy` repo; this repo has no
  deploy script or FTP settings. (See [LAW-4](#MAC-LAW-4).)
- **NOT a CMS or server app.** The server docroot holds static files only, plus a hand-placed
  `.htaccess` ([§4.4](#MAC-§4.4)).

## 4. Architecture canon {#MAC-§4}

```
  MindAttic.UiUx repo (GitHub)  ──tag V10──▶  jsDelivr CDN  ◀──────────────  visitor's browser
    fonts/, mindattic.com/logos/,                  ▲                              ▲
    Components/Cyberspace/ (+ textures)            │ <link>/<script>/@font-face   │ GET /
                                                   │ URLs, pinned to @V10         │ (.htaccess: HTTPS,
  MindAttic.UiUx/sync/sync-mindattic-com.ps1 ──splice (CYBERSPACE block only)──▶  index.htm   www→bare)
  PostToolUse hook stamps <!-- Last Updated: ... --> on every Edit/Write of index.htm ──▶  (authored page)
                                                                                    ▲
                      MindAttic.Deploy (sibling repo) ──FTPS (index.htm only)─────┘  /mindattic.com/
```

### 4.1 Files / components {#MAC-§4.1}

- **`index.htm`** — the entire authored page (~90 KB): the View Source banner, a `<head>` with the
  meta/link-preview tags and `preconnect`/`preload` hints, the font `@font-face` rules, the page CSS, the
  Cyberspace block (sync-owned), and a `<div id="content" role="main">` holding
  `.lockup.cyberspace-keepout` (the `#site-name` wordmark and the `.link-row` of three `.link-btn`
  anchors), a fixed `#site-footer`, the motto fitter and a small tap-to-spawn script. It is a `<div role="main">`, not a
  `<main>`, because Cyberspace treats every `<main>` as a keepout zone and a full-screen one would block
  every effect. Its sections are numbered in the file's own table of contents (§ 1 Fonts … § 12
  Cyberspace).
- **Assets (not in this repo).** Everything binary comes from `MindAttic.UiUx` over jsDelivr at a
  tag-pinned URL — see [§10 Conventions](#MAC-§10) and `MindAttic.UiUx/docs/ASSETS.md`.
- **`idiotproof/`** — static support pages (`privacy-policy.htm`, `terms-of-use.htm`) and the
  `dataset/` export for the IdiotProof project, plus a gitignored, generated `replays/` archive.
  `MindAttic.Deploy` uploads the folder as its `idiotproof-replays` site.
- **`docs/`** — the Codex canon (this file, `AMENDMENTS.md`, `USER_STORIES.md`, the generated
  `BIBLE.digest.md`, and `images/` used by the README).
- **`tools/`** — `codex.ps1` (`doctor` / `digest`) and `build-readme.ps1` (renders `README.md` to
  `README.htm`).
- **`.claude/`** — `commands/` (`/deploy`, `/quicksave`, `/quickload`), `skills/` (`run`, `commit`,
  `discard`, `revert`), `hooks/` (Codex digest injection, quickload-on-do), `settings.json`
  (PostToolUse last-updated stamp + SessionStart and UserPromptSubmit hooks), `settings.local.json`.
  `.prose/commands/` holds the provider-neutral aliases of the same commands.

### 4.2 Domain model (NOUNS) {#MAC-§4.2}

- **Lockup** — the wordmark plus the three buttons, shrink-wrapped to the wordmark's width and
  centered both ways (`.lockup`). It is the only keepout (`.cyberspace-keepout`).
- **Buffer zone** — the lockup's rect grown by the engine's `KEEPOUT_BUFFER` (16px) on every side.
  Taps inside it do nothing; effects spawned at a tap are kept out of it.
- **Spark surge** — the engine's `spawnSparkBurst`: a white-hot flash ring and a shower of
  gravity-bound sparks that cool and burn out within ~0.3–0.7s, drawn on one pooled
  `canvas.cyberspace-surge` (fixed, click-through, z-index 1, below `#content`'s 1000).
- **Unit (`--u`)** — 1% of the smaller visible viewport side (`dvmin`), capped at 0.7273 rem. The
  wordmark is `--wm` = 11 × `--u`; the buttons are sized from `--btn-u` = 0.15 × `--wm`.
- **Link button (`.link-btn`)** — one of the three equal-width anchors (`target="_blank"`,
  `rel="noopener noreferrer"`, `aria-describedby` pointing at a hidden "Opens in a new window." note);
  red outline, red fill and glow on hover/focus.
- **Asset package** — the `MindAttic.UiUx` repo seen as a runtime CDN package, addressed as
  `https://cdn.jsdelivr.net/gh/mindattic/MindAttic.UiUx@V<n>/<path>`.
- **Generated region** — a block owned by a generator, not by hand-editing. On the page that is only
  the `CYBERSPACE` marker block.
- **Theme tokens** — CSS custom properties on `:root`; dark palette only.

### 4.3 Key services / flows (VERBS) {#MAC-§4.3}

- **sync** (`MindAttic.UiUx/sync/sync-mindattic-com.ps1`, run during deploy) — splice the `CYBERSPACE`
  block into `index.htm` (inline CSS and small scripts; the two big scripts and three textures as
  tag-pinned CDN URLs, scripts `defer`red, textures preloaded). Cyberspace is the only UiUx component
  this site subscribes to.
- **stamp** (PostToolUse hook in `.claude/settings.json`) — write the UTC `<!-- Last Updated: ... -->`
  comment on every Edit/Write of `index.htm`.
- **deploy** (`/deploy` → `MindAttic.Deploy`) — the linked 4-in-1 deploy: publish the UiUx tag, pin it in
  all three sites, run this site's hooks (`uiux-pull`, then the sync above), verify the CDN, stamp, then
  FTPS-upload `index.htm` only. Assets need no upload: they are already on the CDN.
- **tap-to-spawn** — in-page script: on a primary-button `pointerdown` that is not on a link and not in
  the keepout buffer zone (`consoleBg.inKeepout(x, y)`: the `.lockup` rect grown by the engine's 16px
  `KEEPOUT_BUFFER`), it fires `consoleBg.spawnSparkBurst(x, y)` at the tap and then calls the spawn
  functions of `window.consoleBg._demo` (an underscore-prefixed "dev handle" of the engine, the only
  public way to fire a single effect on demand) in a shuffled order, each with the tap as its origin
  `{ x, y }` in viewport %, until one returns something other than `false`. If the CDN script failed to
  load it silently does nothing.

### 4.4 Hosting {#MAC-§4.4}

- The site is static files on an FTP-managed web host. FTP root `/` is the ryandebraal.com docroot;
  `/mindattic.com/` is the mindattic.com docroot; `/mindatticcares.com/` holds the MindAttic Cares page.
- `/mindattic.com/` contains `index.htm` (from this repo), `idiotproof/` (the `idiotproof-replays`
  site) and hyperspace/ (the `Hyperspace` repo's `hyperspace` site), all uploaded by
  `MindAttic.Deploy`.
- A hand-placed `.htaccess` in `/mindattic.com/` (not in this repo and not uploaded by the deploy)
  forces HTTPS, redirects www.mindattic.com to the bare domain, and 301-redirects the
  `/<slug>.htm` project URLs to the matching GitHub repo (`https://github.com/mindattic/<Repo>`).
  Change it by hand on the server.

## 5. The Laws {#MAC-§5}

These project-specific laws are in addition to — and never override — the shared MindAttic house
rules, which are **inherited** here, not restated:

> **Inherited:** [`MindAttic.HouseRules.md`](../../MindAttic.HouseRules.md) (shared across all
> MindAttic projects: whole-number versioning, tooling etiquette, etc.). When a house rule and a
> project law conflict, the house rule wins.

- **{#MAC-LAW-1} One authored page, no build step, no framework.** `index.htm` is the only
  hand-authored page, with no bundler, no transpiler and no framework. Heavy static assets are served
  from the tag-pinned `MindAttic.UiUx` jsDelivr package, never embedded; `<link rel=…>`, `preconnect`,
  `preload` and `defer` are allowed. A build pipeline would need an RFC and a bible change first.
- **{#MAC-LAW-2} Generated regions are not hand-edited.** The only generated region in `index.htm` is
  the `BEGIN/END MINDATTIC.UIUX:CYBERSPACE` block, owned by
  `MindAttic.UiUx/sync/sync-mindattic-com.ps1`; edit the source in `MindAttic.UiUx` and re-run the
  sync.
- **{#MAC-LAW-4} Deployment is centralized.** Deploys go through the sibling `MindAttic.Deploy`
  pipeline (`npm run deploy -- --site mindattic.com`). This repo keeps no deploy script and no FTP
  credentials (a stray `settings.json` is gitignored).
- **{#MAC-LAW-5} Dark palette only.** The dark Cyberspace palette is the only palette — no light mode,
  no theme toggle, no theme picker.
- **{#MAC-LAW-6} Privacy by default.** No analytics, tracking pixels, third-party fonts, or third-party
  network requests may be added to `index.htm`. The one allowed external host is the jsDelivr CDN
  (cdn.jsdelivr.net), serving the `MindAttic.UiUx` repo at a pinned tag.
- **{#MAC-LAW-7} View-source stays welcoming.** Preserve the opening banner, the section table of
  contents, and explanatory comments, and keep them accurate. Code here is documentation for the
  curious reader.

## 6. Verified state {#MAC-§6}

Status legend: ✅ done (verified) · 🟡 partial · ⬜ planned · living.

There is **no compiler, unit-test suite, or CI** in this repo — it is a static HTML page. "Verification"
here means: the page's markup/CSS/script is present as described, the shared Playwright suite in
`MindAttic.UiUx/tests` covers the linked sites, and `codex doctor` passes. Evidence below was checked on
disk on 2026-10-03 unless stated otherwise.

- ✅ **The page.** `index.htm` contains `<div id="content" role="main">` →
  `<div class="lockup cyberspace-keepout">` → `<h1 id="site-name">` + `<nav class="link-row">` with three
  `<a class="link-btn" target="_blank" rel="noopener noreferrer" aria-describedby="new-window-note">`
  (Résumé, GitHub, MindAttic Cares), a hidden `#new-window-note`, and a `<footer id="site-footer">`.
  *(Evidence: grep of `index.htm`; file is ~90 KB.)*
- ✅ **Assets served from the tag-pinned jsDelivr package.** Fonts, logo variables, favicon, preview
  image, the two engine scripts and the three textures are referenced as
  `https://cdn.jsdelivr.net/gh/mindattic/MindAttic.UiUx@V10/…` (18 URLs, all `@V10`); `<head>` has
  `preconnect` and font `preload`; engine scripts carry `defer`. *(Evidence: grep of `index.htm`; no
  `base64` font or image data in it.)*
- ✅ **Meta and link-preview tags.** `meta description`, `link rel="canonical"`, `theme-color`, `og:*`
  and `twitter:*` tags are in `<head>`. *(Evidence: grep of `index.htm`.)*
- ✅ **Sizing model.** `.lockup` defines `--u`/`--wm`, `.link-row` defines `--btn-u` and fills
  `.lockup`, and `html`/`body` are `overflow: hidden` (and `user-select: none`, no touch callout,
  transparent tap highlight) with a `position: fixed` footer. *(Evidence: CSS in `index.htm`; button-row
  width and no-scroll were measured in headless Chrome across viewports from 120×600 to 5120×2880 in an
  earlier session — reported, not re-run here.)*
- ✅ **Tap response.** A tap outside the buffer zone starts an effect within 30px of the tap point and
  bursts sparks that animate and then go idle; taps in the zone or on a link spawn nothing; reduced
  motion gets a flash only. *(Evidence: `MindAttic.UiUx/tests/specs/sites/mindattic.spec.mjs`, run with
  `npm run test:local` on 2026-10-03.)*
- ✅ **Last-updated stamp automated.** PostToolUse hook stamps `<!-- Last Updated: ... -->`; the
  current stamp is line 1 of `index.htm`. *(Evidence: hook in `.claude/settings.json`; stamp on line 1.)*
- ✅ **Codex tooling.** `tools/codex.ps1 doctor` passes. *(Evidence: run at the end of this doc pass.)*

## 7. Active frontier {#MAC-§7}

- There are no open RFCs; new design notes go in docs/rfc.
- Backlog and shipped capabilities live in [`docs/USER_STORIES.md`](USER_STORIES.md). Open: an
  HTML-validity / link-check step the doctor can run ([MAC-US-D3](USER_STORIES.md#MAC-US-D3)).
- Each new `MindAttic.UiUx` tag is taken through the linked deploy, which re-pins every asset URL.

## 8. Quality bar {#MAC-§8}

A change to mindattic.com is "done" when:

1. `index.htm` is still the only hand-authored page, with no build step or framework, and no binary
   asset has been embedded into it — heavy assets come from the pinned `MindAttic.UiUx` CDN
   package — [LAW-1](#MAC-LAW-1), [LAW-6](#MAC-LAW-6).
2. It edits the **source of truth**, not a generated region (the `CYBERSPACE` block is edited in
   `MindAttic.UiUx`) — [LAW-2](#MAC-LAW-2).
3. Every asset URL is tag-pinned (`@V<n>`, never `@main`) and the tag actually serves the file.
4. The page loads in a browser with no console errors, the dark Cyberspace styling intact, no
   scrollbar, and the three buttons exactly as wide as the wordmark — [LAW-5](#MAC-LAW-5).
5. The banner, table of contents and comments still describe the file accurately — [LAW-7](#MAC-LAW-7).
6. `pwsh tools/codex.ps1 doctor` passes and the digest is regenerated.
7. The corresponding user story is updated with real status, and any ✅ cites its evidence.
8. Deployment (if performed) went through `MindAttic.Deploy` — [LAW-4](#MAC-LAW-4).

## 9. Glossary {#MAC-§9}

- **Lockup** — the wordmark, the motto and the three link buttons (`.lockup`), centered both ways and
  shrink-wrapped to the wordmark's width. The only Cyberspace keepout.
- **Unit (`--u`)** — 1% of the smaller visible viewport side (`dvmin`), capped at 0.7273 rem; every
  size on the page is a multiple of it.
- **Asset package** — the `MindAttic.UiUx` repo served over jsDelivr at `…@V<n>/<path>`; tags are
  immutable whole numbers.
- **Generated region** — a block owned by a generator and never hand-edited; on the page, only the
  `CYBERSPACE` marker block. See [LAW-2](#MAC-LAW-2).
- **Cyberspace** — the shared MindAttic.UiUx visual bundle (circuit-board backdrop, scanlines, console
  windows). Its CSS and small scripts are spliced inline; its engine and textures load from the CDN.
- **Sync** — splicing the subscribed UiUx component (Cyberspace) into `index.htm` during deploy.
- **Stamp** — the automated `<!-- Last Updated: ... -->` UTC comment.
- **Linked deploy** — `MindAttic.Deploy`'s 4-in-1 flow: deploying any of `MindAttic.UiUx`,
  mindattic.com, ryandebraal.com or mindatticcares.com publishes the package and deploys all three sites.
- **House rules** — the shared [`MindAttic.HouseRules.md`](../../MindAttic.HouseRules.md), inherited
  by [§5](#MAC-§5).

## 10. Conventions {#MAC-§10}

- **Asset URL pattern.** `https://cdn.jsdelivr.net/gh/mindattic/MindAttic.UiUx@V<n>/<path>` — always
  pinned to a tag, never `@main`.
- **UiUx tags** are whole numbers (`V9`, `V10`, …), immutable once published (house rule: no SemVer). The
  page pins `V10`; the linked deploy rewrites every `MindAttic.UiUx@V…` in `index.htm` to the release
  tag (the `CYBERSPACE` block's tag comes from the sync script's `-CyberspaceCdnTag`).
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
- **Docs.** Codex layers as in the README (`MAC-US-<Epic><n>` stories, `{#MAC-LAW-n}` laws, pending
  decisions in `AMENDMENTS.md` only until folded); never hand-edit `docs/BIBLE.digest.md`.
