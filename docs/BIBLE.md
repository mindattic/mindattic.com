---
codex: 1
project: mindattic.com
code: MAC
layer: bible
status: living
updated: 2026-06-07
---

# mindattic.com — Project Bible

> Single source of truth for what mindattic.com IS, is NOT, and the rules that keep it coherent.
> README says how to build/run; this says how to think about the system.

## 1. The one sentence {#MAC-§1}

mindattic.com is Ryan DeBraal's personal portfolio — one hand-authored, self-contained
`index.htm` (inline CSS/JS, base64-inlined fonts and images, no build step, no framework, no
external requests) showcasing software, hardware, writing, and visual art.

## 2. The product promise {#MAC-§2}

- **One request, one file.** A visitor loads a single `index.htm`; fonts, logo, book covers, and
  art previews are base64-inlined so first paint costs one HTTP request and nothing phones home.
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
  Amazon product pages          ──fetch──▶  (Software board + Writing synopses)
                                                                     ├─rewrites regions─▶  index.htm
  diagram/ecosystem.mmd (Mermaid) ─render─▶ diagram/render.ps1 ─────┤                     (one self-
  MindAttic.UiUx components       ─sync───▶ sync-mindattic-com.ps1 ─┘                      contained
                                            (fonts, Cyberspace, PinFooter, WebSnapshot)    file)
                                                                                              │
  PostToolUse hook stamps <!-- Last Updated: ... --> on every Edit/Write of index.htm ◀──────┘
                                                                                              │
                                            MindAttic.Deploy (sibling repo) ──FTPS──▶  live site
```

### 4.1 Files / components {#MAC-§4.1}

- **`index.htm`** — the entire site: one HTML document with inlined `<style>` blocks and `<script>`
  IIFEs. No external assets. Authored regions are hand-written; generated regions are fenced (see
  4.3). Contains a header (wordmark), `<main>` with sections (Portfolio, Software, MindAttic
  Ecosystem, Hardware, Writing, Visual Arts), and a pinned footer.
- **`fetch-descriptions.ps1`** — regenerates the Software `board-grid` from public `mindattic`
  GitHub repos and refreshes Writing synopses from Amazon. Idempotent.
- **`add-book.ps1` / `add-book.bat`** — helper to add a book to the Writing grid.
- **`diagram/`** — `ecosystem.mmd` (Mermaid source) → `render.ps1` → `ecosystem.svg`, spliced into
  `index.htm` between `<!-- BEGIN/END ECOSYSTEM-DIAGRAM -->` markers; `mermaid-config.json` themes
  it to the Cyberspace palette.
- **`previews/`** — base64 art/preview assets (`Mosaic.b64`, `mindatticcares.com.b64`).
- **`.image-base64.txt`** — base64 source for an inlined image.
- **`.claude/`** — `commands/` (`/commit`, `/deploy`, `/fetch`), `skills/`, `settings.json`
  (PostToolUse last-updated stamp + Codex SessionStart hook), `settings.local.json`.

### 4.2 Domain model (NOUNS) {#MAC-§4.2}

- **Section** — a top-level `<h2>` block in `<main>`: Portfolio, Software, MindAttic Ecosystem,
  Hardware, Writing, Visual Arts.
- **Tile / tabButton** — a clickable project card (`class="tabButton"` with `data-target`) that
  reveals a **tabPage** panel (`id="sd-*"` for software, `id="hw-*"` for hardware).
- **Book** — a Writing/Visual-Arts grid entry (`class="book"`, an Amazon `/dp/` link or art link,
  base64 cover).
- **Ecosystem diagram** — the inlined `<svg>` rendered from `ecosystem.mmd`.
- **Generated region** — a fenced span of markup (board-grid, ecosystem SVG, UiUx component blocks)
  owned by a generator, not by hand-editing.
- **Theme tokens** — CSS custom properties; dark palette only.

### 4.3 Key services / flows (VERBS) {#MAC-§4.3}

- **fetch** (`/fetch`) — rebuild the Software board-grid from GitHub + refresh Writing synopses from
  Amazon; rewrite `index.htm`. Idempotent ("already up to date" when nothing changed).
- **render** (`diagram/render.ps1`) — render `ecosystem.mmd` to SVG and splice into `index.htm`.
- **sync** (`MindAttic.UiUx/sync/sync-mindattic-com.ps1`, run during deploy) — splice subscribed
  UiUx components (Outfit/Attic fonts, Cyberspace, PinFooter, WebSnapshot) into `index.htm`.
- **stamp** (PostToolUse hook in `.claude/settings.json`) — write the UTC `<!-- Last Updated: ... -->`
  comment on every Edit/Write of `index.htm`.
- **deploy** (`/deploy` → `MindAttic.Deploy`) — pull UiUx, sync components, fetch descriptions,
  stamp, then FTPS-upload `*.htm` to the host.
- **runtime hydration** — in-page JS (`tabifyPortfolio`/`tabifyCreative`/`wireClicks`/
  `hydratePlaceholderImages` and the Cyberspace effect IIFEs) wires tile clicks and visual effects
  on load.

## 5. The Laws {#MAC-§5}

These project-specific laws are in addition to — and never override — the shared MindAttic house
rules, which are **inherited** here, not restated:

> **Inherited:** [`MindAttic.HouseRules.md`](../../MindAttic.HouseRules.md) (shared across all
> MindAttic projects: whole-number versioning, tooling etiquette, etc.). When a house rule and a
> project law conflict, the house rule wins unless an amendment says otherwise.

- **{#MAC-LAW-1} One file, no build step.** The site is a single self-contained `index.htm`: inline
  CSS/JS, base64-inlined fonts/images, no framework, no bundler, no CDN, no external requests. If a
  build pipeline ever becomes justified, it must be decided in an RFC and recorded as an amendment.
- **{#MAC-LAW-2} Generated regions are not hand-edited.** The Software board-grid, the Writing
  synopses, the ecosystem `<svg>`, and the UiUx component blocks are owned by their generators
  (`fetch-descriptions.ps1`, `diagram/render.ps1`, `MindAttic.UiUx/sync/sync-mindattic-com.ps1`).
  Edit the source of
  truth and re-run the generator; manual edits inside these regions are overwritten.
- **{#MAC-LAW-3} GitHub and Amazon are upstream.** Tile content comes from public `mindattic` repo
  metadata (description, homepage, `software`/`hardware` topic); Writing synopses come from Amazon
  product pages. Feature/hide a project by toggling repo visibility + topic, not by editing markup.
- **{#MAC-LAW-4} Deployment is centralized.** Deploys go through the sibling `MindAttic.Deploy`
  pipeline (`npm run deploy -- --site mindattic.com`). The per-project deploy scripts and
  `settings.json` FTP profile are retired and gitignored; do not resurrect them.
- **{#MAC-LAW-5} Dark palette only.** The theme toggle is retired and the site is locked to the
  dark Cyberspace palette (see [MAC-A1](AMENDMENTS.md#MAC-A1)). Do not reintroduce a runtime theme
  switch without an amendment.
- **{#MAC-LAW-6} Privacy by default.** No analytics, tracking pixels, third-party fonts, or
  third-party network requests may be added to `index.htm`.
- **{#MAC-LAW-7} View-source stays welcoming.** Preserve the opening banner, the section table of
  contents, and explanatory comments. Code here is documentation for the curious reader.

## 6. Verified state {#MAC-§6}

Status legend: ✅ done (verified) · 🟡 partial · ⬜ planned · 🗑️ cut · living.

There is **no compiler, unit-test suite, or CI** in this repo — it is a static HTML site with
PowerShell generators. "Verification" here means: the file parses/loads as HTML, the generators run
idempotently, and `codex doctor` passes. Recorded evidence:

- ✅ **Single-file site exists and is self-contained.** `index.htm` is present (~3,591 lines), with
  inlined `<style>`/`<script>` and base64 assets; `git ls-files` shows no external CSS/JS asset
  dependencies. *(Evidence: file present on disk; no `<link rel="stylesheet">`/external `<script src>`.)*
- ✅ **Software tiles render from generated markup.** 19 `tabPage` panels (17 `sd-*` software,
  2 `hw-*` hardware) exist in the board. *(Evidence: `id="sd-*"`/`id="hw-*"` anchors in `index.htm`.)*
- ✅ **Writing/Visual-Arts grids populated.** 7 `class="book"` entries (6 Amazon `/dp/` books + 1
  Mosaic art link). *(Evidence: `class="book" href=...` matches in `index.htm`.)*
- ✅ **Ecosystem diagram inlined.** The `<svg>` rendered from `ecosystem.mmd` sits between the
  `BEGIN/END ECOSYSTEM-DIAGRAM` markers. *(Evidence: markers + `<figure class="ecosystem-diagram">`
  in `index.htm`; source `diagram/ecosystem.mmd` + `render.ps1` present.)*
- ✅ **Last-updated stamp automated.** PostToolUse hook stamps `<!-- Last Updated: ... -->`; the
  current stamp is line 1 of `index.htm`. *(Evidence: hook in `.claude/settings.json`; stamp on
  line 1.)*
- 🟡 **fetch / render / deploy generators.** Scripts exist and document idempotent behavior, but
  their runs depend on network/`gh`/`npx`/sibling repos and were **not executed** during this
  documentation pass. *(Unproven here; downgraded from any "done" claim.)*
- 🟡 **Codex tooling.** `tools/codex.ps1 doctor` result is recorded in the Phase 3 report; treat as
  proven only once doctor passes.

## 7. Active frontier {#MAC-§7}

- Design notes live in [`docs/rfc/`](rfc/). Seed: [`0001-codex-adoption`](rfc/0001-codex-adoption.md).
- Backlog and shipped capabilities live in [`docs/USER_STORIES.md`](USER_STORIES.md) (Epics A–D).
- Near-term candidates (see stories): add an HTML-validity / link-check step the doctor can run;
  document the per-project landing-page catalog flow; decide whether the README's stale "theme
  toggle" line should be corrected (tracked by [MAC-A1](AMENDMENTS.md#MAC-A1)).

## 8. Quality bar {#MAC-§8}

A change to mindattic.com is "done" when:

1. It keeps the site a single self-contained `index.htm` (no new external requests/assets) —
   [LAW-1](#MAC-LAW-1), [LAW-6](#MAC-LAW-6).
2. It edits the **source of truth**, not a generated region — [LAW-2](#MAC-LAW-2),
   [LAW-3](#MAC-LAW-3). If a generator was involved, it was re-run and reported idempotent.
3. The page still loads in a browser with no console errors and the dark Cyberspace styling intact
   — [LAW-5](#MAC-LAW-5).
4. `pwsh tools/codex.ps1 doctor` passes and the digest is regenerated.
5. The corresponding user story is updated with real status, and any ✅ cites its evidence.
6. Deployment (if performed) went through `MindAttic.Deploy` — [LAW-4](#MAC-LAW-4).

## 9. Glossary {#MAC-§9}

- **Generated region** — markup owned by a generator and fenced by markers/structure; never
  hand-edited (board-grid, ecosystem SVG, UiUx component blocks). See [LAW-2](#MAC-LAW-2).
- **Tile / tabButton** — a clickable project card; reveals its **tabPage** panel.
- **tabPage** — the detail panel for a tile (`id="sd-*"` software, `id="hw-*"` hardware).
- **Book** — a Writing/Visual-Arts grid entry (`class="book"`).
- **Cyberspace** — the shared MindAttic.UiUx visual component bundle (circuit-board backdrop,
  scanline/CRT, torn-edge, shine) inlined into the page.
- **Sync** — splicing subscribed UiUx components into `index.htm` during deploy.
- **Fetch** — rebuilding the Software board + Writing synopses from GitHub/Amazon.
- **Stamp** — the automated `<!-- Last Updated: ... -->` UTC comment.
- **Self-contained** — no external network requests; all assets inlined.
- **House rules** — the shared [`MindAttic.HouseRules.md`](../../MindAttic.HouseRules.md), inherited
  by [§5](#MAC-§5).
