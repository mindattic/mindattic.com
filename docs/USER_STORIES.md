---
codex: 1
project: mindattic.com
code: MAC
layer: stories
status: living
updated: 2026-10-02
---

# mindattic.com — User Stories

> ✅ done (shipped & verified) · 🟡 partial · ⬜ planned · 🗑️ cut. Every ✅ cites its evidence.
> This repo has no automated test suite (a static HTML page + dormant PowerShell generators), so
> "verified" cites on-disk artifacts (what is present in `index.htm`), measurements reported from a
> headless-browser session, or a passing `codex doctor` instead of a unit test name.
>
> On 2026-10-02 [MAC-A6](AMENDMENTS.md#MAC-A6) reduced the page to a wordmark + three buttons and moved
> all binary assets to the `MindAttic.UiUx` jsDelivr package. Stories about the removed portfolio
> browser are marked 🗑️ and keep their original text as an audit trail.

## Epic A — The front-door page (visitor experience)

- **MAC-US-A1 🗑️** *(superseded by [MAC-A6](AMENDMENTS.md#MAC-A6); original spec — audit log)* As a visitor,
  I can load the whole portfolio with no third-party requests, so the page paints fast and nothing phones
  home. *Given* a browser, *when* I open `index.htm`, *then* fonts/logo are base64-inlined and the only
  additional requests are same-origin `data/*.json` catalog fetches (no third-party host). Replaced by
  [MAC-US-A5](#MAC-US-A5) (fast first paint from pinned CDN assets) — the privacy half survives in
  [LAW-6](BIBLE.md#MAC-LAW-6).
- **MAC-US-A2 ✅** As a curious visitor, I can View Source and find a welcoming banner + table of
  contents, so the code reads as a conversation. *Given* the raw markup, *when* I open it, *then*
  lines 1–67 present the ASCII banner and the §1–§12 TOC (rewritten so it no longer claims "one file /
  no CDN"). *(verified by: banner comment block ending at line 67 of `index.htm`;
  [LAW-7](BIBLE.md#MAC-LAW-7).)*
- **MAC-US-A3 ✅** As a visitor, I see a consistent dark cyberpunk look, so the site matches the
  MindAttic house style. *Given* the page loads, *when* it renders, *then* only the dark Cyberspace
  palette applies (no theme toggle, no theme picker). *(verified by: dark-palette-only `:root` tokens and
  the Cyberspace block in `index.htm`; toggle retired per [MAC-A1](AMENDMENTS.md#MAC-A1), picker
  removed per [MAC-A6](AMENDMENTS.md#MAC-A6); [LAW-5](BIBLE.md#MAC-LAW-5).)*
- **MAC-US-A4 ✅** As a visitor, I see a copyright line at the bottom of the screen at all times, so the
  page always looks finished. *Given* any viewport, *when* it renders, *then* `#site-footer` is
  `position: fixed` to the bottom edge and the page does not scroll. *(verified by: `#site-footer`
  rule and `html`/`body` `overflow: hidden` in `index.htm`. This replaces the old `pin-when-short`
  PinFooter behavior.)*
- **MAC-US-A5 ✅** As a visitor, I get a fast first paint, so the front door feels instant. *Given* a
  browser, *when* I open `index.htm`, *then* the page itself is small (~85 KB), the CDN connection is
  opened early, the first-paint fonts are preloaded, the heavy effects engine is `defer`red and fonts,
  logo, engine and textures come from the tag-pinned `MindAttic.UiUx` jsDelivr package rather than being
  embedded. *(verified by: `<link rel="preconnect">` / font `<link rel="preload">` in `<head>`, `defer` on the
  two engine scripts, `…/MindAttic.UiUx@V7/…` URLs and no base64 font/image data in `index.htm`; file
  size 85,313 bytes on 2026-10-02. No load-time benchmark was run for this doc pass.)*
- **MAC-US-A6 ✅** As a visitor on any device, I see the wordmark and three buttons (Résumé, GitHub,
  MindAttic Cares) centered on the screen, the buttons together exactly as wide as the wordmark, at every
  size and aspect ratio. *Given* any viewport, *when* it renders, *then* `.lockup` is centered both ways,
  `.link-row` fills it, and all sizes derive from `--u`. *(verified by: `.lockup`/`.link-row`/`.link-btn`
  rules and the three `<a class="link-btn" target="_blank">` anchors in `index.htm`; the parent session
  also measured the button row within 0.02 px of the wordmark's width, with no scroll, in headless Chrome at
  viewports from 120×600 to 5120×2880 — reported, not re-run for this doc pass.)*
- **MAC-US-A7 ✅** As a visitor, I can tap or click anywhere (except on a button) and a random Cyberspace
  effect appears, so the page feels alive. *Given* the engine has loaded, *when* I press on the page,
  *then* one effect is spawned, positioned at the tap for the effects that accept a position. *(verified by:
  the `pointerdown` handler calling `window.consoleBg._demo.*` in `index.htm`; the parent session
  reported 9 of 12 and 18 of 20 simulated taps adding elements in headless Chrome — reported, not re-run
  here.)*

## Epic B — Project showcase (Software & Hardware) — removed from the page

- **MAC-US-B1 🗑️** *(cut by [MAC-A6](AMENDMENTS.md#MAC-A6); original spec — audit log)* As a visitor, I
  can browse projects by category and see any one's description and links, so I can explore the MindAttic
  ecosystem. *Given* the Classic theme's Software topic (`data/software.json` + `data/ecosystem.json`) and
  Hardware topic, *when* I click an item in the side list, *then* its description + links render in the
  detail pane.
- **MAC-US-B2 🗑️** *(cut from the page by [MAC-A6](AMENDMENTS.md#MAC-A6); the generator is dormant, not
  deleted)* As the maintainer, every public repo shows up on the site automatically. The behavior still
  exists in `fetch-descriptions.ps1` (it rebuilds `data/software.json`/`ecosystem.json`/`hardware.json`;
  see [MAC-A4](AMENDMENTS.md#MAC-A4)), but no page displays those files.
- **MAC-US-B3 🗑️** As a visitor, I see the MindAttic ecosystem dependency diagram inline, so I
  understand how the projects relate. *(cut 2026-08-20 per [MAC-A5](AMENDMENTS.md#MAC-A5); `diagram/` stays
  on disk, and `diagram/render.ps1` would now throw because the `ECOSYSTEM-DIAGRAM` markers are gone.)*
- **MAC-US-B4 ✅** As the maintainer, I can get a README-derived description candidate for a
  thin/empty repo, approve it, and have it written back to GitHub, so real descriptions replace the
  generic fallback without me hand-drafting GitHub metadata blind. *Given* a repo with no
  description, *when* I run `-ProposeDescriptions` then approve and run `-ApplyDescriptions`, *then*
  `gh repo edit --description` writes the approved text. *(verified by: 17 repos' descriptions written
  back and confirmed via `gh repo view --json description`, 2026-08-20. This writes to GitHub, not to the
  page, so it is unaffected by [MAC-A6](AMENDMENTS.md#MAC-A6); it was not re-run in this pass.)*

## Epic C — Writing & Visual Arts — removed from the page

- **MAC-US-C1 🗑️** *(cut by [MAC-A6](AMENDMENTS.md#MAC-A6); original spec — audit log)* As a visitor, I can
  see Ryan's books with covers linking to Amazon, so I can read his writing. *Given* the Writing section,
  *when* it renders, *then* 6 books (from `data/books.json`) link to Amazon `/dp/` pages with inlined
  covers. (`data/books.json` still holds the 6 entries.)
- **MAC-US-C2 🗑️** *(cut by [MAC-A6](AMENDMENTS.md#MAC-A6); original spec — audit log)* As a visitor, I can
  see featured visual art, so the portfolio shows more than code. *Given* the Visual Arts section, *when*
  it renders, *then* the Mosaic preview links out. (`data/visual-arts.json` still holds the entry.)
- **MAC-US-C3 🗑️** *(cut by [MAC-A6](AMENDMENTS.md#MAC-A6); original spec — audit log)* As the maintainer,
  I can refresh book synopses from Amazon, so they stay current without manual copy-paste. (Was 🟡: the
  `Update-BookSynopses` step ran once, with an unresolved intermittent `ConvertFrom-Json` under-read.
  No page displays synopses now; the code remains in `fetch-descriptions.ps1`.)
- **MAC-US-C4 🗑️** *(cut by [MAC-A6](AMENDMENTS.md#MAC-A6); original spec — audit log)* As the maintainer, I
  want every book under my MindAttic / Ars Historica / Pulpit Press Amazon imprints imported into
  `data/books.json`. (Was ⬜; there is no Writing section to show them in. `add-book.ps1` remains.)

## Epic E — Presentation-mode theme system — removed

- **MAC-US-E1 🗑️** *(cut by [MAC-A6](AMENDMENTS.md#MAC-A6); original spec — audit log)* As a visitor, I can
  browse every topic through one consistent categorized sidebar + detail-pane interface (the Classic theme).
- **MAC-US-E2 🗑️** *(cut by [MAC-A6](AMENDMENTS.md#MAC-A6); original spec — audit log)* As a visitor, I can
  move the side list to whichever side I prefer, and the choice persists (`localStorage`
  `mindattic-classic-state`).
- **MAC-US-E3 🗑️** *(cut by [MAC-A6](AMENDMENTS.md#MAC-A6); original spec — audit log)* As a visitor, I can
  switch to a "Collage" presentation (treemap mosaic sized by code volume).
- **MAC-US-E4 🗑️** *(cut by [MAC-A6](AMENDMENTS.md#MAC-A6); original spec — audit log)* As a visitor, I can
  switch to a "Terminal" presentation and navigate the catalog by typed command.

## Epic D — Documentation & maintenance discipline

- **MAC-US-D1 ✅** As the maintainer, I want `README.md` to match reality, so nobody is told the site
  has a theme toggle, a catalog browser or an "all in one file" design. *Given* the current page,
  *when* the README is read, *then* it describes the wordmark + buttons page, the CDN asset package and the
  dormant generators. *(verified by: `README.md` rewritten 2026-10-02 per
  [MAC-A6](AMENDMENTS.md#MAC-A6); the earlier toggle fix is [MAC-A1](AMENDMENTS.md#MAC-A1).)*
- **MAC-US-D2 ✅** As the maintainer, I want a Codex doctor that validates the docs and the
  bible↔code cross-references, so documentation can't silently rot. *Given* `tools/codex.ps1`,
  *when* I run `doctor`, *then* front-matter, IDs, cross-refs, cited paths, and digest freshness are
  checked. *(verified by: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex.ps1
  doctor` run 2026-10-02 after the [MAC-A6](AMENDMENTS.md#MAC-A6) doc pass.)*
- **MAC-US-D3 ⬜** As the maintainer, I want the doctor to optionally run an HTML-validity / dead
  link check on `index.htm` (including that every `MindAttic.UiUx@V<n>` URL resolves), so regressions are
  caught. *(planned — see [RFC 0001](rfc/0001-codex-adoption.md).)*
- **MAC-US-D4 ✅** As the maintainer, I want a single `/commit` definition, so `/commit` behaves the same
  every time. *(verified by: `.claude/commands/` no longer contains `commit.md` (only `deploy.md`,
  `fetch.md`, `quickload.md`, `quicksave.md`); the one remaining definition is
  `.claude/skills/commit/SKILL.md`, whose stale "keep in sync with `commands/commit.md`" note was removed
  2026-10-02. The shadowed command was dropped in commit `aceacac`.)*
- **MAC-US-D5 ⬜** As the maintainer, I want a decision on the dormant machinery (`data/`,
  `fetch-descriptions.ps1`, `add-book.*`, `diagram/`, `previews/`) — delete it, or keep it — and, if it is
  deleted, `MindAttic.Deploy`'s optional `fetch-descriptions.ps1` pre-deploy hook removed too. *(planned —
  see [MAC-A6](AMENDMENTS.md#MAC-A6).)*

## Priority backlog

1. **MAC-US-D5** — decide the fate of the dormant machinery.
2. **MAC-US-D3** — add an HTML-validity / link-check step the doctor can invoke.
3. Done: ~~MAC-US-D2~~ (doctor green, re-run 2026-10-02), ~~MAC-US-D1~~, ~~MAC-US-D4~~.
4. Cut with [MAC-A6](AMENDMENTS.md#MAC-A6): Epic B (except B4), Epic C, Epic E.

### Audit log

Stories cut or superseded by [MAC-A6](AMENDMENTS.md#MAC-A6) keep their original ask, marked
"(original spec — audit log)", so the history of what the site used to promise stays readable. When a
story is later re-scoped, preserve its original ask verbatim here the same way.
