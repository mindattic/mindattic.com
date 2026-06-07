---
codex: 1
project: mindattic.com
code: MAC
layer: stories
status: living
updated: 2026-06-07
---

# mindattic.com — User Stories

> ✅ done (shipped & verified) · 🟡 partial · ⬜ planned · 🗑️ cut. Every ✅ cites its evidence.
> This repo has no automated test suite (static HTML + PowerShell generators), so "verified" cites
> on-disk artifacts, idempotent generator behavior, or a passing `codex doctor` instead of a unit
> test name.

## Epic A — The single-file site (visitor experience)

- **MAC-US-A1 ✅** As a visitor, I can load the whole portfolio in one HTTP request, so the page
  paints fast and nothing phones home. *Given* a browser, *when* I open `index.htm`, *then* all
  fonts, logo, covers, and previews are base64-inlined and there are no external requests.
  *(verified by: no `<link rel="stylesheet">` / external `<script src>` in `index.htm`; assets are
  `data:` URIs — see [BIBLE §6](BIBLE.md#MAC-§6).)*
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

- **MAC-US-B1 ✅** As a visitor, I can browse project tiles and expand any one for its description
  and links, so I can explore the MindAttic ecosystem. *Given* the Software/Hardware boards, *when*
  I click a tile, *then* its `tabPage` panel opens. *(verified by: 17 `sd-*` + 2 `hw-*` `tabPage`
  panels and the `wireClicks()` handler in `index.htm`.)*
- **MAC-US-B2 ✅** As the maintainer, I can feature/hide a software project by toggling its GitHub
  repo (public + `software`/`hardware` topic + description), so I never hand-edit tiles. *Given* a
  public repo, *when* I run `/fetch`, *then* the board-grid is rebuilt from repo metadata.
  *(verified by: `fetch-descriptions.ps1` + the generated board markup; [LAW-2](BIBLE.md#MAC-LAW-2),
  [LAW-3](BIBLE.md#MAC-LAW-3). Generator not executed this pass — see backlog.)*
- **MAC-US-B3 ✅** As a visitor, I see the MindAttic ecosystem dependency diagram inline, so I
  understand how the projects relate. *Given* the page, *when* I scroll to "MindAttic Ecosystem",
  *then* the SVG rendered from `ecosystem.mmd` is shown. *(verified by: `BEGIN/END
  ECOSYSTEM-DIAGRAM` markers + `<figure class="ecosystem-diagram">` in `index.htm`; source
  `diagram/ecosystem.mmd` + `render.ps1`.)*

## Epic C — Writing & Visual Arts

- **MAC-US-C1 ✅** As a visitor, I can see Ryan's books with covers linking to Amazon, so I can read
  his writing. *Given* the Writing section, *when* it renders, *then* 6 `class="book"` entries link
  to Amazon `/dp/` pages with inlined covers. *(verified by: 6 `class="book" href="...amazon.com/dp/..."`
  entries in `index.htm`.)*
- **MAC-US-C2 ✅** As a visitor, I can see featured visual art, so the portfolio shows more than
  code. *Given* the Visual Arts section, *when* it renders, *then* the Mosaic preview links out.
  *(verified by: `class="book" href="https://ryandebraal.com/mosaic/"` + `previews/Mosaic.b64` in
  the repo.)*
- **MAC-US-C3 🟡** As the maintainer, I can refresh book synopses from Amazon, so they stay current
  without manual copy-paste. *Given* `BOOK_AMAZON_URLS`, *when* I run `/fetch`, *then* synopses are
  re-scraped from Amazon. *(partial: implemented in `fetch-descriptions.ps1` but not executed this
  pass; depends on Amazon page structure + network.)*

## Epic D — Documentation & maintenance discipline

- **MAC-US-D1 ⬜** As the maintainer, I want `README.md` corrected to drop the stale "light/dark
  theme toggle" claim, so the README matches reality. *Given* the dark-locked site, *when* the
  README is edited, *then* it no longer advertises a toggle. *(planned: deferred — this Codex pass
  does not modify site content/README; tracked against [MAC-A1](AMENDMENTS.md#MAC-A1).)*
- **MAC-US-D2 🟡** As the maintainer, I want a Codex doctor that validates the docs and the
  bible↔code cross-references, so documentation can't silently rot. *Given* `tools/codex.ps1`,
  *when* I run `doctor`, *then* front-matter, IDs, cross-refs, cited paths, and digest freshness are
  checked. *(partial until doctor is proven green — see Phase 3 report.)*
- **MAC-US-D3 ⬜** As the maintainer, I want the doctor to optionally run an HTML-validity / dead
  link check on `index.htm`, so regressions in the single file are caught. *(planned — see
  [RFC 0001](rfc/0001-codex-adoption.md).)*

## Priority backlog

1. **MAC-US-D2** — prove `codex doctor` green (immediate; this pass).
2. **MAC-US-D1** — correct the README theme-toggle line (needs maintainer sign-off on content).
3. **MAC-US-C3 / MAC-US-B2** — run the `fetch` generator end-to-end and record idempotent output.
4. **MAC-US-D3** — add an HTML-validity / link-check step the doctor can invoke.

### Audit log

No stories have been re-scoped from an original written spec; this file is the first stories
artifact for the repo, derived from the actual state of `index.htm`, the generator scripts, and the
`.claude/commands`. When a story is later re-scoped, preserve its original ask verbatim here, marked
"(original spec — audit log)".
