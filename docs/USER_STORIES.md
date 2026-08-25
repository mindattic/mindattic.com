---
codex: 1
project: mindattic.com
code: MAC
layer: stories
status: living
updated: 2026-08-20
---

# mindattic.com — User Stories

> ✅ done (shipped & verified) · 🟡 partial · ⬜ planned · 🗑️ cut. Every ✅ cites its evidence.
> This repo has no automated test suite (static HTML + PowerShell generators), so "verified" cites
> on-disk artifacts, idempotent generator behavior, or a passing `codex doctor` instead of a unit
> test name.

## Epic A — The single-file site (visitor experience)

- **MAC-US-A1 ✅** As a visitor, I can load the whole portfolio with no third-party requests, so the
  page paints fast and nothing phones home. *Given* a browser, *when* I open `index.htm`, *then*
  fonts/logo are base64-inlined and the only additional requests are same-origin `data/*.json`
  catalog fetches (no third-party host). *(verified by: no `<link rel="stylesheet">` / third-party
  `<script src>` in `index.htm`; catalog fetches are relative `data/*.json` paths — see
  [MAC-A3](AMENDMENTS.md#MAC-A3), [BIBLE §6](BIBLE.md#MAC-§6).)*
- **MAC-US-A2 ✅** As a curious visitor, I can View Source and find a welcoming banner + table of
  contents, so the code reads as a conversation. *Given* the raw markup, *when* I open it, *then*
  lines 1–63 present the ASCII banner and the §1–§12 TOC. *(verified by: header comment block in
  `index.htm`; [LAW-7](BIBLE.md#MAC-LAW-7).)*
- **MAC-US-A3 ✅** As a visitor, I see a consistent dark cyberpunk look, so the site matches the
  MindAttic house style. *Given* the page loads, *when* it renders, *then* only the dark Cyberspace
  palette applies (no theme toggle). *(verified by: dark-palette-only tokens; toggle retired per
  [MAC-A1](AMENDMENTS.md#MAC-A1) / [LAW-5](BIBLE.md#MAC-LAW-5).)*
- **MAC-US-A4 ✅** As a visitor on a short viewport, I see the footer pinned to the bottom, so the
  page never looks unfinished. *Given* a short page, *when* it renders, *then* the
  `pin-when-short` footer (PinFooter component) pins. *(verified by: `<footer ... class="pin-when-short">`
  + inlined PinFooter component in `index.htm`.)*

## Epic B — Project showcase (Software & Hardware)

- **MAC-US-B1 ✅** As a visitor, I can browse projects by category and see any one's description
  and links, so I can explore the MindAttic ecosystem. *Given* the Classic theme's Software topic
  (which merges `data/software.json` + `data/ecosystem.json` — MindAttic Ecosystem repos are
  members, not a separate topic, per [MAC-A5](AMENDMENTS.md#MAC-A5)) and Hardware topic, *when* I
  click an item in the side list, *then* its description + links render in the detail pane.
  *(verified by: `renderClassic()`/`renderDetail()` in `index.htm`; 21 Software + 14 Ecosystem + 2
  Hardware = every public repo, in `data/software.json`/`ecosystem.json`/`hardware.json`, confirmed
  live against GitHub 2026-08-20.)*
- **MAC-US-B2 ✅** As the maintainer, every public repo shows up on the site automatically, so I
  never hand-edit tiles or have to remember to tag a repo just to make it visible. *Given* a public
  repo, *when* I run `/fetch`, *then* `data/software.json`/`ecosystem.json`/`hardware.json` are
  rebuilt from repo metadata — the `software`/`hardware` topic only picks the section, not
  inclusion (see [MAC-A4](AMENDMENTS.md#MAC-A4)). *(verified by: `fetch-descriptions.ps1` run
  against live `mindattic` org, 2026-08-20 — 21/14/2 = all 37 public non-site repos written;
  [LAW-2](BIBLE.md#MAC-LAW-2), [LAW-3](BIBLE.md#MAC-LAW-3).)*
- **MAC-US-B3 🗑️** As a visitor, I see the MindAttic ecosystem dependency diagram inline, so I
  understand how the projects relate. *(cut 2026-08-20: dropped from the Classic theme per
  [MAC-A5](AMENDMENTS.md#MAC-A5) — there's no "MindAttic Ecosystem" heading to hang it under once
  Ecosystem repos folded into the Software topic. `diagram/ecosystem.mmd` + `render.ps1` remain on
  disk in case a future theme wants it back.)*
- **MAC-US-B4 ✅** As the maintainer, I can get a README-derived description candidate for a
  thin/empty repo, approve it, and have it written back to GitHub, so real descriptions replace the
  generic fallback without me hand-drafting GitHub metadata blind. *Given* a repo with no
  description, *when* I run `-ProposeDescriptions` then approve and run `-ApplyDescriptions`, *then*
  `gh repo edit --description` writes the approved text and the next plain run picks it up.
  *(verified by: 17 repos' descriptions written back and confirmed via `gh repo view --json
  description`, 2026-08-20 — 3 in the first batch (Cursory, mindatticcares.com,
  MindAttic.Helpers), 14 more once the visibility gate was dropped per MAC-A4. Every tile on the
  site now has a real, non-generic description.)*

## Epic C — Writing & Visual Arts

- **MAC-US-C1 ✅** As a visitor, I can see Ryan's books with covers linking to Amazon, so I can read
  his writing. *Given* the Writing section, *when* it renders, *then* 6 books (from
  `data/books.json`) link to Amazon `/dp/` pages with inlined covers. *(verified by: 6 entries with
  `amazonUrl`/`coverImage` in `data/books.json`.)*
- **MAC-US-C2 ✅** As a visitor, I can see featured visual art, so the portfolio shows more than
  code. *Given* the Visual Arts section, *when* it renders, *then* the Mosaic preview links out.
  *(verified by: `data/visual-arts.json` entry with `url: "https://ryandebraal.com/mosaic/"`;
  synopsis no longer wrongly claims "Available on Amazon".)*
- **MAC-US-C3 🟡** As the maintainer, I can refresh book synopses from Amazon, so they stay current
  without manual copy-paste. *Given* `data/books.json`, *when* I run `/fetch`, *then* synopses are
  re-scraped from Amazon and written back. *(partial: `fetch-descriptions.ps1`'s
  `Update-BookSynopses` ran successfully once against the live 6-book catalog, but an intermittent
  `ConvertFrom-Json` under-read of `data/books.json` was observed when this function runs as part of
  the full script — now guarded against (skips the refresh with a warning instead of writing
  corrupt data) but not root-caused. See [BIBLE §7](BIBLE.md#MAC-§7).)*
- **MAC-US-C4 ⬜** As the maintainer, I want every book under my MindAttic / Ars Historica / Pulpit
  Press Amazon imprints imported into `data/books.json`, so the site is a complete record of my
  writing. *Given* the three imprint author-search URLs, *when* each title is added via
  `add-book.ps1`, *then* it appears with cover + synopsis. *(planned: the MindAttic imprint search
  alone found ~26 titles not yet imported — user will supply the ASIN list to backfill; Pulpit
  Press / Ars Historica not yet searched at all.)*

## Epic E — Presentation-mode theme system

- **MAC-US-E1 ✅** As a visitor, I can browse every topic (Portfolio, Software, Hardware, Writing,
  Visual Arts) through one consistent categorized sidebar + detail-pane interface, so 37+ items
  read as a curated portfolio instead of a wall of identical pill buttons. *Given* the Classic
  theme, *when* I pick a topic in the top tab bar, *then* its members list alphabetically in a
  vertical side list (scrollable, never wrapping) and the selected one's description + links show
  in a detail pane. *(verified by: `renderClassic()` in `index.htm`; local render confirmed
  2026-08-20 via `http://localhost:3457/index.htm`; see [MAC-A5](AMENDMENTS.md#MAC-A5).)*
- **MAC-US-E2 ✅** As a visitor, I can move the side list to whichever side I prefer, and that
  choice (plus my last topic/selection) persists across visits. *Given* the side-toggle control,
  *when* I click it, *then* the list moves left/right and the choice is saved. *(verified by:
  `loadClassicState`/`saveClassicState` + `localStorage` key `mindattic-classic-state` in
  `index.htm`.)*
- **MAC-US-E3 ⬜** As a visitor, I can switch to a "Collage" presentation — a treemap mosaic sized
  by code volume and colored by recency — so projects with no UI of their own are still visually
  interesting. *(planned — roadmap entry in the picker, not yet built. See [MAC-A5](AMENDMENTS.md#MAC-A5).)*
- **MAC-US-E4 ⬜** As a visitor, I can switch to a "Terminal" presentation and navigate the same
  catalog by typed command (`ls`/`dir`, `cat`/`type`, `open`, `cd`, `help`, plus flavor/easter-egg
  commands), so old-terminal enthusiasts get a CLI-native way to browse. *(planned — roadmap entry
  in the picker, not yet built. See [MAC-A5](AMENDMENTS.md#MAC-A5).)*

## Epic D — Documentation & maintenance discipline

- **MAC-US-D1 ✅** As the maintainer, I want `README.md` corrected to drop the stale "light/dark
  theme toggle" claim, so the README matches reality. *Given* the dark-locked site, *when* the
  README is edited, *then* it no longer advertises a toggle. *(verified by: `README.md`'s "Add
  exhaustive README" rewrite (2026-08-14) already states the palette is dark-only, theme toggle
  retired, citing [MAC-A1](AMENDMENTS.md#MAC-A1); this story was still marked ⬜ here until this
  pass caught the drift.)*
- **MAC-US-D2 ✅** As the maintainer, I want a Codex doctor that validates the docs and the
  bible↔code cross-references, so documentation can't silently rot. *Given* `tools/codex.ps1`,
  *when* I run `doctor`, *then* front-matter, IDs, cross-refs, cited paths, and digest freshness are
  checked. *(verified by: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex.ps1
  doctor` run 2026-08-20 after this pass's edits.)*
- **MAC-US-D3 ⬜** As the maintainer, I want the doctor to optionally run an HTML-validity / dead
  link check on `index.htm`, so regressions in the single file are caught. *(planned — see
  [RFC 0001](rfc/0001-codex-adoption.md).)*
- **MAC-US-D4 ⬜** As the maintainer, I want the `commit` skill and the `commit` command to agree on
  the co-author footer text, so `/commit` behaves the same regardless of which definition resolves.
  *(planned: reconciled to the same version string this pass, but the two files still duplicate the
  same behavior — consider retiring one in favor of the other.)*

## Priority backlog

1. ~~**MAC-US-D2** — prove `codex doctor` green~~ ✅ done 2026-06-07, re-verified 2026-08-20.
2. ~~**MAC-US-D1** — correct the README theme-toggle line~~ ✅ done (README already fixed
   2026-08-14; story status caught up 2026-08-20).
3. ~~**MAC-US-C3 / MAC-US-B2** — run the `fetch` generator end-to-end~~ ✅ done 2026-08-20 (repo
   tiles + description write-back verified; book-synopsis refresh partially blocked, see C3).
4. **MAC-US-C4** — import the remaining MindAttic titles + the Pulpit Press / Ars Historica
   imprints once the user supplies ASINs.
5. Root-cause the `ConvertFrom-Json` under-read behind **MAC-US-C3**'s partial status.
6. **MAC-US-E3** — build the Collage presentation mode (treemap by code volume, colored by recency).
7. **MAC-US-E4** — build the Terminal presentation mode (CLI navigation of the same catalog).
8. **MAC-US-D3** — add an HTML-validity / link-check step the doctor can invoke.
9. **MAC-US-D4** — reconcile or retire the duplicate `commit` skill/command.

### Audit log

No stories have been re-scoped from an original written spec; this file is the first stories
artifact for the repo, derived from the actual state of `index.htm`, the generator scripts, and the
`.claude/commands`. When a story is later re-scoped, preserve its original ask verbatim here, marked
"(original spec — audit log)".
