---
codex: 1
project: mindattic.com
code: MAC
layer: amendments
status: living
updated: 2026-10-02
---

# mindattic.com — Amendments (append-only; amendment wins over the bible)

> Never rewrite an amendment; supersede it with a new one. Beyond ~25, fold the settled ones into
> the BIBLE and start a new epoch (note the git tag). History stays in git.

## MAC-A1 — Theme toggle retired; site locked to the dark palette (supersedes README "light/dark theme toggle")

**What changed.** The in-page light/dark theme toggle was removed; mindattic.com now renders only
the dark Cyberspace palette. The file's own table of contents records this ("§ 2 Theme tokens — CSS
custom properties (dark palette only)"; "§ 10 Theme toggle — Retired — site is locked to the dark
palette").

**Why.** The Cyberspace house style is dark-first; a light variant added CSS surface area and a
runtime control without a clear payoff. Locking the palette keeps the single file lean.

**Migration.** None in `index.htm` (already dark-locked). `README.md` still describes a "light/dark
theme toggle" and is now **out of date** with respect to this amendment. Per the task constraints
this documentation pass does not modify site content or the README; correcting that line is tracked
as a backlog story ([MAC-US-D1](USER_STORIES.md#MAC-US-D1)). Recorded as [LAW-5](BIBLE.md#MAC-LAW-5).

## MAC-A2 — Deployment centralized in MindAttic.Deploy (supersedes per-project deploy scripts)

**What changed.** The site no longer deploys itself. The per-project `deploy.ps1`/`deploy.bat`/FTP
`settings.json` are retired; deployment runs through the sibling `MindAttic.Deploy` pipeline
(`npm run deploy -- --site mindattic.com`), which pulls `MindAttic.UiUx`, syncs subscribed
components, fetches descriptions, stamps the file, and FTPS-uploads `*.htm`.

**Why.** One repo owning the whole FTP pipeline centralizes credentials
(`MindAttic.Deploy/secrets/ftp.json`) and the per-site profile (`projects.json`), instead of
duplicating deploy logic and secrets per project.

**Migration.** Local `settings.json` (FTP credentials) is gitignored and no longer read. The
`/deploy` slash command points at `MindAttic.Deploy`. Recorded as [LAW-4](BIBLE.md#MAC-LAW-4).

## MAC-A3 — Catalog content moves from server-baked HTML to same-origin `data/*.json` fetched at runtime

**What changed.** The Software, MindAttic Ecosystem, Hardware, Writing, and Visual Arts sections are
no longer regenerated as full `<button>`/`<div class="tabPage">` HTML spliced into `index.htm`.
Each is now a static, empty `<div class="home-sections" data-catalog="...">` placeholder; at page
load, `index.htm`'s own JS (`mountCatalog()`, using the native `fetch()` API — no library) requests
`data/software.json`, `data/ecosystem.json`, `data/hardware.json`, `data/books.json`, and
`data/visual-arts.json` and renders tiles/books client-side via the existing `buildBoardSection()`
helper (previously used only for Portfolio). `fetch-descriptions.ps1` and `add-book.ps1` now write
these JSON files instead of splicing HTML strings into `index.htm`.

**Why.** The GitHub-repo and Amazon-book catalog was capped at whatever was hand-run through the
generators; growing it into a genuinely complete portfolio (all tagged repos, all books under an
author's Amazon imprints) needed a data format that's trivial to regenerate, diff, and bulk-append
to, without regex-splicing HTML. JSON fetched at runtime is that format, and it requires no build
step — `fetch-descriptions.ps1`/`add-book.ps1` remain plain PowerShell, `index.htm` remains the only
authored page.

**Effect on LAW-1 and MAC-US-A1.** This changes the "one request, one file" framing: a page load now
issues `index.htm` plus up to 5 same-origin JSON requests. It does **not** reintroduce a build step,
a framework, or any third-party request — [LAW-6](BIBLE.md#MAC-LAW-6) (privacy/no third-party
requests) stays fully intact, and `data/*.json` is still exclusively machine-generated from GitHub
(LAW-3) or Amazon (LAW-3), never hand-authored — so this does **not** contradict
[RFC 0001](rfc/0001-codex-adoption.md)'s rejection of a hand-maintained `docs/data/*.json` canon;
that RFC's L5 layer and this repo-root `data/` directory are unrelated. [LAW-1](BIBLE.md#MAC-LAW-1)
is amended to "single authored HTML file, no build step, no third-party requests" rather than
literally "one HTTP request."

**Migration.** `fetch()` of `data/*.json` is blocked by CORS under the `file://` protocol, so local
testing requires serving the directory over local HTTP (see the `run` skill / `.claude/launch.json`)
instead of opening `index.htm` directly. Production is unaffected — `MindAttic.Deploy` serves the
site over `https`, where same-origin `fetch()` needs no workaround. `MindAttic.Deploy`'s upload step
must include `data/*.json` alongside `*.htm`, or the live site's catalog sections render empty.

## MAC-A4 — Every public repo gets a tile; `software`/`hardware` topic no longer gates visibility

**What changed.** `fetch-descriptions.ps1` no longer excludes public `mindattic` repos that lack the
`software`/`hardware` topic. Every public repo (except `mindattic.com` itself) now gets a tile. The
`hardware` topic and the `MindAttic.*` name prefix still decide **which section** a repo lands in
(Hardware vs. MindAttic Ecosystem vs. Software), they just no longer decide **whether** it appears
at all. This raised the catalog from 19 tiles (11 Software + 6 Ecosystem + 2 Hardware, gated) to 37
(21 + 14 + 2, ungated) in one run, and all 17 tiles that had an empty/thin GitHub description got a
README-derived (or, where no README existed, file-listing/language-derived) description drafted,
approved, and written back via `gh repo edit --description`.

**Why.** The stated goal is a complete portfolio — "my entire body of work represented" — and a
topic-tag opt-in silently hid 18 of 37 public repos, several with real, working content (a Unity
prototype, a GraphQL gateway example, branding collateral, an authentication library). Visibility
(public vs. private) is still the deliberate human decision that controls inclusion; a repo the user
wants hidden from the portfolio should be made private, not left untagged.

**Migration.** `-ListUntagged` remains but is now purely informational (which repos have no
software/hardware topic — not which ones are hidden, since none are). [LAW-3](BIBLE.md#MAC-LAW-3)
is amended: visibility is the only inclusion gate; topic/name only pick a section.

## MAC-A5 — Presentation-mode theme system: Classic rebuilt; Collage/Terminal to follow

**What changed.** `index.htm` now has a `[data-theme]` attribute on `<html>` (default `"classic"`)
and a picker (`#theme-picker`) in the header, matching the pattern already proven on the sibling
site `ryandebraal.com`. This supersedes [LAW-5](BIBLE.md#MAC-LAW-5)'s blanket "do not reintroduce a
runtime theme switch without an amendment" — this amendment *is* that sign-off, scoped precisely:

- This is a **presentation-mode** switch (which UI paradigm renders the same `data/*.json`
  catalogs), not the retired light/dark **color-palette** toggle. All modes render exclusively in
  the dark Cyberspace palette — [LAW-5](BIBLE.md#MAC-LAW-5)'s dark-palette-lock is untouched.
- Unlike `ryandebraal.com`'s `{#RDC-LAW-4}` ("themes are CSS-variable swaps, not JS style
  mutation"), these modes are **full alternate renderers**, not pure CSS swaps — Classic, Collage,
  and Terminal each mount a completely different DOM/interaction model over the same mapped catalog
  data. That's a deliberate, wider kind of theming than the reference site's, and it's fine
  specifically because it's recorded here rather than drifting in silently.

**Classic rebuilt** (this pass): the old flat wall of small pill buttons per section (`.board-grid`/
`.tabButton`/`.tabPage`, one section per `<h2>`) is retired. Classic is now a categorized
master-detail browser: a top tab bar of 5 topics (Portfolio, Software, Hardware, Writing, Visual
Arts) — MindAttic Ecosystem repos fold into "Software," no longer a separate top-level topic or
dependency diagram — each with a vertical, alphabetically-sorted side list (togglable left/right,
default right, scrollable instead of wrapping) and a detail pane for the selected item. This is a
deliberately ordinary desktop-app pattern (a categorized sidebar + detail pane), not a novel
invention, chosen because the flat button-wall stopped working once every public repo got a tile
(see [MAC-A4](#MAC-A4)) — 37 equal-weight text pills read as a tag cloud, not a portfolio.

**Dropped from Classic:** the MindAttic Ecosystem dependency `<svg>` diagram (no heading to hang it
under anymore) and the Portfolio section's old DOM-scraping (`tabifyPortfolio()` scraped `<a>` tags
out of hand-authored markup; Classic now builds Portfolio's 3 items directly from the existing
`PORTFOLIO_URLS`/`PORTFOLIO_BLURBS`/`PORTFOLIO_IMAGES` JS objects, same data, no scraping).
`diagram/ecosystem.mmd` and `diagram/render.ps1` are untouched on disk in case a future theme wants
the diagram back.

**Roadmap, not yet built:** Collage (a treemap mosaic sized by code volume, colored by recency —
for the many repos with no UI of their own to screenshot) and Terminal (an Apple-II-style CLI for
navigating the same catalog by typed command). The picker already lists both as disabled options so
the roadmap is visible in the UI itself. Each will get its own `[data-theme="..."]`-scoped CSS block
and renderer, reusing the same `mapRepoTile`/`mapBook`/`mapVisualArt`/`generateProjectArt` building
blocks Classic uses — only the rendering layer differs per theme; `fetch-descriptions.ps1`/
`add-book.ps1` remain the sole producers of `data/*.json` regardless of which theme is active.

## MAC-A6 — The page is reduced to wordmark + three buttons; all binary assets move to the MindAttic.UiUx jsDelivr package (supersedes MAC-A3 and MAC-A5; refines LAW-1, LAW-2, LAW-3, LAW-5, LAW-6)

**What changed.** `index.htm` is now a deliberately tiny page (user decision, 2026-10-02): a centered
"MindAttic" wordmark (Attic font) with three equal-width link buttons beneath it — **Résumé**
(`https://ryandebraal.com`), **GitHub** (`https://github.com/mindattic`) and **MindAttic Cares**
(`https://mindatticcares.com`), each `target="_blank"` — a copyright footer fixed to the bottom
edge, and the Cyberspace backdrop. Tapping/clicking anywhere (except on a button) spawns one random
Cyberspace effect via `window.consoleBg._demo`. The page never scrolls and every size on it is a
multiple of one viewport-relative unit (`--u`, 1% of the smaller visible viewport side, capped at
`0.7273rem`), so it keeps the same shape at every size and aspect ratio; the three buttons together
are exactly as wide as the wordmark.

**Removed from `index.htm`:** the Classic catalog browser (the Portfolio / Software / Hardware /
Writing / Visual Arts topic tabs, side list and detail pane), the `PORTFOLIO_*` objects and the
`data/*.json` runtime `fetch()`, the presentation-mode / theme picker (`#theme-picker`,
`[data-theme]`), the Projects grid and shine effect, the site header, and the `PinFooter` and
`WebSnapshot` components. The footer is now a plain fixed element, not `pin-when-short`. The page
wrapper is `<div id="content" role="main">`, **not** a `<main>` element, because Cyberspace treats
every `<main>` as a keepout zone that effects stay out of — a full-screen `<main>` would block the
whole screen; only the `.lockup` (wordmark + buttons) carries `.cyberspace-keepout`.

**Assets are no longer embedded.** Fonts (Outfit, Attic), the logo PNGs, the Cyberspace engine
(`console-bg.js`, `sacred-geometry.js`) and the parallax textures are plain static files served from
jsDelivr out of the `MindAttic.UiUx` repo at a **tag-pinned** URL
(`https://cdn.jsdelivr.net/gh/mindattic/MindAttic.UiUx@V7/<path>`). `<head>` carries a
`preconnect` to `cdn.jsdelivr.net` and `preload` hints for the two fonts the first paint needs; the
two engine scripts are `defer`red; the three textures are preloaded at low priority. The page went
from ~224 KB to ~85 KB. Layout of the package and its rules: `MindAttic.UiUx/docs/ASSETS.md`,
decision recorded there as MAU-A4.

**Supersedes / refines.**

- **[LAW-1](BIBLE.md#MAC-LAW-1) is refined.** The old text ("one authored file, inline CSS/JS,
  base64-inlined fonts … no CDN, no third-party request") is retired. The surviving core is: *`index.htm`
  is the only hand-authored page, with no build step, no bundler and no framework.* Static assets
  may — and should — be external, served from the `MindAttic.UiUx` jsDelivr package. `<link rel=…>`,
  `preconnect`, `preload` and `defer` are allowed.
- **[LAW-6](BIBLE.md#MAC-LAW-6) is refined, not dropped.** Still forbidden: analytics, tracking
  pixels, third-party fonts, and any third-party host *other than* jsDelivr serving the
  `MindAttic.UiUx` repo. The one allowed external host is `cdn.jsdelivr.net` (own content, pinned tag).
- **[LAW-2](BIBLE.md#MAC-LAW-2) and [LAW-3](BIBLE.md#MAC-LAW-3) are dormant.** Nothing the page renders
  is generated from GitHub/Amazon/Mermaid any more. The only generated region left in `index.htm` is
  the `BEGIN/END MINDATTIC.UIUX:CYBERSPACE` block, owned by `MindAttic.UiUx/sync/sync-mindattic-com.ps1`
  (still [LAW-2](BIBLE.md#MAC-LAW-2): never hand-edit it). The GitHub/Amazon generators still run and
  still write `data/*.json`, but no page reads those files.
- **[MAC-A3](#MAC-A3) is superseded.** The page makes no same-origin `data/*.json` requests, so
  `MindAttic.Deploy` no longer needs to upload `data/*.json` and `/run` no longer needs local HTTP to
  avoid a CORS-blocked `fetch()` (it is kept as the convenient way to preview).
- **[MAC-A5](#MAC-A5) is superseded.** The presentation-mode system (Classic / Collage / Terminal),
  the `#theme-picker` and the `[data-theme]` renderers are gone; the Collage and Terminal roadmap is
  cut. The dark Cyberspace palette ([LAW-5](BIBLE.md#MAC-LAW-5)) remains the only palette — LAW-5's
  presentation-mode clause is moot.
- **[MAC-A2](#MAC-A2) still holds, with different hooks.** `MindAttic.Deploy` (`projects.json`,
  site `mindattic.com`) still runs `uiux-pull`, then `sync-mindattic-com.ps1` (which now splices only
  the `CYBERSPACE` block — `mindattic.com` is no longer enrolled for `OutfitFont`, `AtticFont`,
  `PinFooter` or `WebSnapshot` in `MindAttic.UiUx/subscribers.json`), then the *optional*
  `fetch-descriptions.ps1` (harmless: it only rewrites `data/*.json`), then stamps and FTPS-uploads
  `*.htm`.
- **[LAW-5](BIBLE.md#MAC-LAW-5), [LAW-4](BIBLE.md#MAC-LAW-4), [LAW-7](BIBLE.md#MAC-LAW-7)** are
  unchanged. The View Source banner and table of contents are kept (rewritten so they no longer claim
  "one file / no CDN").

**Dormant, kept on disk (nothing deleted).** `data/*.json`, `fetch-descriptions.ps1`,
`add-book.ps1` / `add-book.bat`, `diagram/` (note: `diagram/render.ps1` splices between
`BEGIN/END ECOSYSTEM-DIAGRAM` markers that `index.htm` no longer contains, so it will throw if run),
`previews/` and `.image-base64.txt`. `idiotproof/` is **not** dormant: it is still FTP-uploaded as the
`idiotproof-replays` site in `MindAttic.Deploy/projects.json`. Whether to delete the dormant
machinery is an open decision for the maintainer.

**Why.** The user wanted the front door reduced to the logo and three buttons, loading as fast as
possible, with every MindAttic site sharing one cached, versioned asset backend instead of each page
carrying megabytes of base64.

**Migration.** Bump the `@V<n>` tag in `index.htm` (search `MindAttic.UiUx@V`) to take a newer asset
release; tags are immutable whole numbers. Never point the page at `@main`.
