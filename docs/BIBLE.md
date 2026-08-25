---
codex: 1
project: mindattic.com
code: MAC
layer: bible
status: living
updated: 2026-08-20
---

# mindattic.com — Project Bible

> Single source of truth for what mindattic.com IS, is NOT, and the rules that keep it coherent.
> README says how to build/run; this says how to think about the system.

## 1. The one sentence {#MAC-§1}

mindattic.com is Ryan DeBraal's personal portfolio — one hand-authored, self-contained
`index.htm` (inline CSS/JS, base64-inlined fonts and images, no build step, no framework, no
external requests) showcasing software, hardware, writing, and visual art.

## 2. The product promise {#MAC-§2}

- **One authored file, no build step.** A visitor loads `index.htm`; fonts and logo are
  base64-inlined. The Software/Ecosystem/Hardware/Writing/Visual-Arts catalogs are fetched from
  same-origin `data/*.json` at runtime (see [MAC-A3](AMENDMENTS.md#MAC-A3)) — still no third-party
  request, still no build step, just a handful of same-origin requests instead of literally one.
- **No tracking, no third parties.** No analytics, no tracking pixels, no third-party fonts, no
  CDN, no `npm install` to view source. Privacy is the default.
- **View-source as a feature.** The file opens with an ASCII banner and a guided table of contents
  for anyone who reads the markup; the code is meant to be a conversation, not a puzzle.
- **A living index of the MindAttic ecosystem.** Project tiles (Software/Hardware) are sourced from
  public GitHub repo metadata; the Writing grid is sourced from Amazon; the ecosystem diagram is
  sourced from a Mermaid file. The page is the rendered view of those sources of truth.
- **Cyberpunk house style.** A shared Cyberspace look (circuit-board backdrop, scanline/CRT
  treatment, torn-edge and shine effects) inlined from `MindAttic.UiUx` components, locked to a
  dark palette.

## 3. What it is NOT {#MAC-§3}

- **NOT a framework app.** No React/Vue/Svelte, no bundler, no transpiler, no `dist/` folder. The
  only "framework" is the browser. (See [LAW-1](#MAC-LAW-1).)
- **NOT a multi-page site.** It is one `index.htm`. Per-project landing pages (`<slug>.htm`) ship
  via the external deploy catalog, not from hand-authored sub-pages here.
- **NOT a light/dark toggle site.** The theme toggle was retired; the site is locked to the dark
  Cyberspace palette. (The README's mention of a toggle is historical — superseded; see
  [MAC-A1](AMENDMENTS.md#MAC-A1).)
- **NOT the source of truth for tile/book/diagram content.** The Software board, Writing synopses,
  and ecosystem diagram are *generated* regions; editing them by hand is overwritten on the next
  fetch/deploy/render. (See [LAW-2](#MAC-LAW-2), [LAW-3](#MAC-LAW-3).)
- **NOT self-deploying.** Deployment is owned by the sibling `MindAttic.Deploy` repo; the retired
  per-project `deploy.ps1`/`deploy.bat`/`settings.json` are not used. (See [LAW-4](#MAC-LAW-4).)

## 4. Architecture canon {#MAC-§4}

```
  SOURCES OF TRUTH (external)                      AUTHORING / GENERATION                 ARTIFACT
  ───────────────────────────                      ──────────────────────                ────────
  GitHub org (mindattic) repos  ──fetch──▶  fetch-descriptions.ps1 ─┐
  Amazon product pages          ──fetch──▶  (+ add-book.ps1)       ├─writes──▶  data/*.json ─┐
                                                                     ┘                        │
  diagram/ecosystem.mmd (Mermaid) ─render─▶ diagram/render.ps1 ────────splice─▶  index.htm    │ fetch()
  MindAttic.UiUx components       ─sync───▶ sync-mindattic-com.ps1 ────splice─▶  (one authored │ at
                                            (fonts, Cyberspace, PinFooter, WebSnapshot)  file) │ runtime
                                                                                              │◀┘
  PostToolUse hook stamps <!-- Last Updated: ... --> on every Edit/Write of index.htm ◀──────┘
                                                                                              │
                                MindAttic.Deploy (sibling repo) ──FTPS──▶  live site (index.htm + data/*.json)
```

### 4.1 Files / components {#MAC-§4.1}

- **`index.htm`** — the entire authored page: one HTML document with inlined `<style>` blocks and
  `<script>` IIFEs. No third-party assets. A `[data-theme]` attribute on `<html>` (default
  `"classic"`) selects which presentation mode renders `<div id="classic-root">` in `<main>` (see
  [MAC-A5](AMENDMENTS.md#MAC-A5)); Classic renders a top tab bar of 5 topics (Portfolio, Software,
  Hardware, Writing, Visual Arts — MindAttic Ecosystem repos fold into Software) each with a
  vertical alphabetical side list and a detail pane, all built client-side from `data/*.json` (see
  [MAC-A3](AMENDMENTS.md#MAC-A3)) plus the small `PORTFOLIO_*` JS objects for Portfolio's 3 links.
  Contains a header (wordmark + the theme picker), `<main>`, and a pinned footer.
- **`data/`** — `software.json`, `ecosystem.json`, `hardware.json`, `books.json`, `visual-arts.json`.
  Generated by `fetch-descriptions.ps1`/`add-book.ps1` from GitHub/Amazon; fetched by `index.htm`'s
  own JS at runtime (same-origin, no third-party host). Never hand-edited (see [LAW-2](#MAC-LAW-2)).
- **`fetch-descriptions.ps1`** — regenerates `data/software.json`/`ecosystem.json`/`hardware.json`
  from public `mindattic` GitHub repos and refreshes `data/books.json` synopses from Amazon.
  Idempotent. Also supports `-ListUntagged` (report public repos missing a topic) and
  `-ProposeDescriptions`/`-ApplyDescriptions` (README-derived description write-back via
  `gh repo edit`, human-approved before writing).
- **`add-book.ps1` / `add-book.bat`** — helper to append a book to `data/books.json` from an Amazon
  URL (cover crop/base64-embed + dedup by ASIN).
- **`diagram/`** — `ecosystem.mmd` (Mermaid source) → `render.ps1` → `ecosystem.svg`. Not currently
  spliced into `index.htm` (dropped from the Classic theme per [MAC-A5](AMENDMENTS.md#MAC-A5) since
  there's no "MindAttic Ecosystem" heading to hang it under anymore); kept on disk for a future
  theme that wants it.
- **`previews/`** — base64 art/preview assets (`Mosaic.b64`, `mindatticcares.com.b64`), inlined into
  the matching `data/*.json` entry's `previewImage` field by `fetch-descriptions.ps1`.
- **`.image-base64.txt`** — base64 source for an inlined image.
- **`.claude/`** — `commands/` (`/commit`, `/deploy`, `/fetch`), `skills/` (including `run`, which
  serves the site over local HTTP so `fetch()` of `data/*.json` isn't blocked by `file://` CORS),
  `settings.json` (PostToolUse last-updated stamp + Codex SessionStart hook), `settings.local.json`.

### 4.2 Domain model (NOUNS) {#MAC-§4.2}

- **Topic** — one of the 5 top-level categories in Classic's tab bar: Portfolio, Software, Hardware,
  Writing, Visual Arts. MindAttic Ecosystem repos are members of the Software topic, not their own
  topic (see [MAC-A5](AMENDMENTS.md#MAC-A5)).
- **Item** — one entry in a topic's side list (a repo tile, a book, a Portfolio link, or a
  visual-art piece), normalized to `{id, name, img, body, href/links}` by a mapper function
  (`mapRepoTile`/`mapBook`/`mapVisualArt`/`buildPortfolioItems`) before rendering.
- **Book** — an item sourced from `data/books.json` or `data/visual-arts.json` (title, Amazon/art
  URL, base64 cover, synopsis).
- **Generated region** — a `data/*.json` file (or the ecosystem SVG, or a UiUx component block)
  owned by a generator, not by hand-editing.
- **Theme tokens** — CSS custom properties; dark palette only.

### 4.3 Key services / flows (VERBS) {#MAC-§4.3}

- **fetch** (`/fetch`) — rebuild `data/software.json`/`ecosystem.json`/`hardware.json` from GitHub +
  refresh `data/books.json` synopses from Amazon. Idempotent ("already up to date" when nothing
  changed). `index.htm` itself is not rewritten.
- **render** (`diagram/render.ps1`) — render `ecosystem.mmd` to SVG and splice into `index.htm`.
- **sync** (`MindAttic.UiUx/sync/sync-mindattic-com.ps1`, run during deploy) — splice subscribed
  UiUx components (Outfit/Attic fonts, Cyberspace, PinFooter, WebSnapshot) into `index.htm`.
- **stamp** (PostToolUse hook in `.claude/settings.json`) — write the UTC `<!-- Last Updated: ... -->`
  comment on every Edit/Write of `index.htm`.
- **deploy** (`/deploy` → `MindAttic.Deploy`) — pull UiUx, sync components, fetch descriptions,
  stamp, then FTPS-upload `*.htm` (and `data/*.json`) to the host.
- **runtime hydration** — in-page JS (`tabifyPortfolio`/`mountCatalog`/`wireClicks` and the
  Cyberspace effect IIFEs) fetches `data/*.json`, renders tiles via `buildBoardSection()`, and wires
  tile clicks and visual effects on load.

## 5. The Laws {#MAC-§5}

These project-specific laws are in addition to — and never override — the shared MindAttic house
rules, which are **inherited** here, not restated:

> **Inherited:** [`MindAttic.HouseRules.md`](../../MindAttic.HouseRules.md) (shared across all
> MindAttic projects: whole-number versioning, tooling etiquette, etc.). When a house rule and a
> project law conflict, the house rule wins unless an amendment says otherwise.

- **{#MAC-LAW-1} One authored file, no build step, no third-party requests.** `index.htm` is the only
  hand-authored page: inline CSS/JS, base64-inlined fonts. It fetches `data/*.json` at runtime
  (same-origin, see [MAC-A3](AMENDMENTS.md#MAC-A3)) — no framework, no bundler, no CDN, no
  third-party request. If a build pipeline (compiler/bundler step) ever becomes justified, it must
  be decided in an RFC and recorded as an amendment.
- **{#MAC-LAW-2} Generated regions are not hand-edited.** `data/*.json` (Software/Ecosystem/Hardware/
  Writing/Visual-Arts), the ecosystem `<svg>`, and the UiUx component blocks are owned by their
  generators (`fetch-descriptions.ps1`, `add-book.ps1`, `diagram/render.ps1`,
  `MindAttic.UiUx/sync/sync-mindattic-com.ps1`). Edit the source of truth and re-run the generator;
  manual edits inside these regions are overwritten.
- **{#MAC-LAW-3} GitHub and Amazon are upstream.** Tile content comes from public `mindattic` repo
  metadata (description, homepage, `software`/`hardware` topic); book/synopsis content comes from
  Amazon. Every public repo gets a tile — visibility (public/private) is the only inclusion gate;
  the `software`/`hardware` topic and the `MindAttic.*` name prefix only decide which section
  (Software/Ecosystem/Hardware) a repo lands in. Feature/hide a project by toggling repo visibility,
  not by editing `data/*.json`. A repo's GitHub description may be written back via
  `gh repo edit --description` (from a README-derived draft, shown to a human for approval first) so
  GitHub itself stays the durable source — never hand-edit a description only in `data/*.json`.
- **{#MAC-LAW-4} Deployment is centralized.** Deploys go through the sibling `MindAttic.Deploy`
  pipeline (`npm run deploy -- --site mindattic.com`). The per-project deploy scripts and
  `settings.json` FTP profile are retired and gitignored; do not resurrect them.
- **{#MAC-LAW-5} Dark palette only, across every presentation mode.** The dark Cyberspace palette
  is the only palette, full stop — no light mode, no per-theme color scheme. A runtime
  *presentation-mode* switch (which UI paradigm renders the catalog — Classic's master-detail
  browser, and eventually Collage/Terminal) is authorized by [MAC-A5](AMENDMENTS.md#MAC-A5) and
  does not reopen this law; it is not a color-palette toggle. Any new mode must render exclusively
  in the dark Cyberspace palette, and any further amendment to *this* law specifically (not a new
  mode under MAC-A5) still needs its own amendment.
- **{#MAC-LAW-6} Privacy by default.** No analytics, tracking pixels, third-party fonts, or
  third-party network requests may be added to `index.htm`.
- **{#MAC-LAW-7} View-source stays welcoming.** Preserve the opening banner, the section table of
  contents, and explanatory comments. Code here is documentation for the curious reader.

## 6. Verified state {#MAC-§6}

Status legend: ✅ done (verified) · 🟡 partial · ⬜ planned · 🗑️ cut · living.

There is **no compiler, unit-test suite, or CI** in this repo — it is a static HTML site with
PowerShell generators. "Verification" here means: the file parses/loads as HTML, the generators run
idempotently, and `codex doctor` passes. Recorded evidence:

- ✅ **Single authored page, catalog content fetched at runtime.** `index.htm` holds the authored
  markup + inlined `<style>`/`<script>`; Software/Ecosystem/Hardware/Writing/Visual-Arts are empty
  `data-catalog` placeholders filled from `data/*.json` via `fetch()` at load. `git ls-files` shows
  no external CSS/JS asset dependencies. *(Evidence: `data-catalog="..."` markers in `index.htm`;
  `data/*.json` present on disk; confirmed 2026-08-20 — see [MAC-A3](AMENDMENTS.md#MAC-A3).)*
- ✅ **fetch generator executed end-to-end against live GitHub; every public repo represented.**
  `fetch-descriptions.ps1` run against the real `mindattic` org wrote every public repo (21
  Software + 14 Ecosystem + 2 Hardware = 37) to `data/*.json` — the `software`/`hardware` topic no
  longer gates visibility, only section placement (see [MAC-A4](AMENDMENTS.md#MAC-A4)). All 17
  previously-empty/thin descriptions were drafted from each repo's README (or file listing +
  language stats where no README existed), human-approved, and written back via
  `gh repo edit --description` — every tile now has a real, non-generic description. *(Evidence:
  script run + `gh repo view --json description` confirming all 17 updates landed on GitHub,
  2026-08-20.)*
- ✅ **Writing/Visual-Arts catalogs populated.** `data/books.json` (6 Amazon books) and
  `data/visual-arts.json` (1 Mosaic entry) exist, each entry with a base64 cover + synopsis.
  *(Evidence: files present on disk, 2026-08-20.)*
- ✅ **Ecosystem diagram inlined.** The `<svg>` rendered from `ecosystem.mmd` sits between the
  `BEGIN/END ECOSYSTEM-DIAGRAM` markers, untouched by the `data/*.json` migration. *(Evidence:
  markers + `<figure class="ecosystem-diagram">` in `index.htm`; source `diagram/ecosystem.mmd` +
  `render.ps1` present.)*
- ✅ **Last-updated stamp automated.** PostToolUse hook stamps `<!-- Last Updated: ... -->`; the
  current stamp is line 1 of `index.htm`. *(Evidence: hook in `.claude/settings.json`; stamp on
  line 1.)*
- 🟡 **Book catalog is a partial slice of the author's Amazon catalog.** Only the MindAttic-imprint
  Amazon author page has been searched and is pending import (~26 titles found, not yet added);
  Pulpit Press and Ars Historica imprints are not yet searched. *(Backlog — see
  [MAC-US-C4](USER_STORIES.md#MAC-US-C4).)*
- ✅ **Codex tooling.** `tools/codex.ps1 doctor` passes. *(Evidence: run 2026-08-20 after this
  pass's edits — see the doctor's own output for current check/warning/error counts.)*

## 7. Active frontier {#MAC-§7}

- Design notes live in [`docs/rfc/`](rfc/). Seed: [`0001-codex-adoption`](rfc/0001-codex-adoption.md).
- Backlog and shipped capabilities live in [`docs/USER_STORIES.md`](USER_STORIES.md) (Epics A–D).
- Near-term candidates (see stories): build the **Collage** and **Terminal** presentation modes
  (roadmap recorded in [MAC-A5](AMENDMENTS.md#MAC-A5); the picker already lists both as disabled);
  import the remaining ~26 MindAttic-imprint books plus the Pulpit Press / Ars Historica imprints
  ([MAC-US-C4](USER_STORIES.md#MAC-US-C4)); root-cause an intermittent `ConvertFrom-Json` under-read
  of `data/books.json` observed inside `fetch-descriptions.ps1`'s process (currently mitigated by a
  malformed-read guard that skips the synopsis refresh with a warning rather than risking data loss
  — real fix still open); verify `MindAttic.Deploy`'s upload step includes `data/*.json`; add an
  HTML-validity / link-check step the doctor can run; document the per-project landing-page catalog
  flow.

## 8. Quality bar {#MAC-§8}

A change to mindattic.com is "done" when:

1. It keeps `index.htm` the only hand-authored page (no new third-party requests/assets; same-origin
   `data/*.json` fetches are fine) — [LAW-1](#MAC-LAW-1), [LAW-6](#MAC-LAW-6).
2. It edits the **source of truth**, not a generated region — [LAW-2](#MAC-LAW-2),
   [LAW-3](#MAC-LAW-3). If a generator was involved, it was re-run and reported idempotent.
3. The page still loads in a browser with no console errors and the dark Cyberspace styling intact
   — [LAW-5](#MAC-LAW-5).
4. `pwsh tools/codex.ps1 doctor` passes and the digest is regenerated.
5. The corresponding user story is updated with real status, and any ✅ cites its evidence.
6. Deployment (if performed) went through `MindAttic.Deploy` — [LAW-4](#MAC-LAW-4).

## 9. Glossary {#MAC-§9}

- **Generated region** — a `data/*.json` file (or the ecosystem SVG, or a UiUx component block)
  owned by a generator; never hand-edited. See [LAW-2](#MAC-LAW-2).
- **Topic** — one of Classic's 5 top-level categories (Portfolio, Software, Hardware, Writing,
  Visual Arts), selected via the top tab bar.
- **Item** — one entry in a topic's side list; a normalized `{id, name, img, body, href/links}`
  object regardless of whether it's a repo, book, Portfolio link, or visual-art piece.
- **Book** — a `data/books.json` or `data/visual-arts.json` entry, rendered client-side.
- **Presentation mode / theme** — which UI paradigm renders the catalog data (`Classic`, and
  eventually `Collage`/`Terminal`), selected via `[data-theme]` on `<html>` and the `#theme-picker`.
  See [MAC-A5](AMENDMENTS.md#MAC-A5). Not a color-palette toggle — [LAW-5](#MAC-LAW-5)'s dark
  Cyberspace palette applies to every mode.
- **Cyberspace** — the shared MindAttic.UiUx visual component bundle (circuit-board backdrop,
  scanline/CRT, torn-edge, shine) inlined into the page.
- **Sync** — splicing subscribed UiUx components into `index.htm` during deploy.
- **Fetch** — rebuilding the Software board + Writing synopses from GitHub/Amazon.
- **Stamp** — the automated `<!-- Last Updated: ... -->` UTC comment.
- **Self-contained** — no external network requests; all assets inlined.
- **House rules** — the shared [`MindAttic.HouseRules.md`](../../MindAttic.HouseRules.md), inherited
  by [§5](#MAC-§5).
