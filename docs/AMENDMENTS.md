---
codex: 1
project: mindattic.com
code: MAC
layer: amendments
status: living
updated: 2026-08-20
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
