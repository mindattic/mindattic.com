# mindattic.com

Ryan DeBraal's front door — one hand-authored `index.htm` that shows the **MindAttic** wordmark and
three link buttons (Résumé, GitHub, MindAttic Cares) over the Cyberspace backdrop, plus a small set
of per-project support pages that ride along in the same deploy.

[mindattic.com](https://mindattic.com)

For how to *think about* this repo (Laws, invariants, verified state), see the Codex canon in
[docs/BIBLE.md](docs/BIBLE.md). This README is the how-to-build/run layer. The page was radically
simplified on 2026-10-02 — read [MAC-A6](docs/AMENDMENTS.md#MAC-A6) for what changed and why.

---

## What it is

A single hand-authored page, `index.htm` (~85 KB), with no bundler, no framework and no `npm install`
needed to view or edit it. It contains:

| Piece | What it is |
|---|---|
| `#site-name` | The "MindAttic" wordmark, set in the Attic display font |
| `.link-row` / `.link-btn` | Three equal-width buttons — **Résumé** → `https://ryandebraal.com`, **GitHub** → `https://github.com/mindattic`, **MindAttic Cares** → `https://mindatticcares.com` — each opening in a new window |
| `.lockup` | The wordmark + buttons, centered both ways; the buttons together are exactly as wide as the wordmark |
| `#site-footer` | Copyright line fixed to the bottom edge; the page never scrolls |
| Cyberspace block | The backdrop (circuit-board parallax, scanlines, console windows), spliced in by the UiUx sync |
| Tap script | Tap or click anywhere (not on a button) to spawn one random Cyberspace effect |

Everything on the page is a multiple of one viewport-relative unit (`--u`, 1% of the smaller visible
viewport side), so it keeps the same shape on every screen and aspect ratio.

The file opens with an ASCII banner and a `§ 1`–`§ 12` table of contents aimed at anyone who opens
View Source — the code is meant to read as a conversation, not a puzzle (see
[BIBLE §2](docs/BIBLE.md#MAC-§2), [LAW-7](docs/BIBLE.md#MAC-LAW-7)).

## Where the assets live

**Not in this repo and not in the HTML.** Fonts (Outfit, Attic), the logo PNGs, the Cyberspace effects
engine and its parallax textures are plain static files in the sibling **MindAttic.UiUx** repo, served
over jsDelivr at a tag-pinned URL:

```
https://cdn.jsdelivr.net/gh/mindattic/MindAttic.UiUx@V7/<path>
```

`<head>` opens the connection early (`preconnect`) and preloads the first-paint fonts; the two big
engine scripts are `defer`red so they never block the first paint. UiUx tags are immutable whole numbers
(`V7`, `V8`, …); to take a newer asset release, change every `MindAttic.UiUx@V…` in `index.htm` (the
Cyberspace block's tag is set by the sync script's `-CyberspaceCdnTag`, default `V7`). Never point the
page at `@main`.

Layout of the package (full rules in `MindAttic.UiUx/docs/ASSETS.md`): shared fonts at the repo root
(`fonts/outfit/`, `fonts/attic/`); site-specific files directly under the domain folder as
`<domain>/<category>/` (this site: `mindattic.com/logos/`); Cyberspace textures at
`Components/Cyberspace/assets/`. Filenames are lowercase kebab-case.

## Stack

`HTML5` · `CSS3` (custom properties, `dvmin`-based sizing, dark "Cyberspace" palette only — the theme
toggle was retired, see [MAC-A1](docs/AMENDMENTS.md#MAC-A1)) · one small `Vanilla JavaScript` snippet ·
the shared Cyberspace bundle from `MindAttic.UiUx`.

No React. No Vite. No npm. No analytics, tracking pixels or third-party fonts. The only external host
is `cdn.jsdelivr.net`, serving the `MindAttic.UiUx` repo ([LAW-6](docs/BIBLE.md#MAC-LAW-6), refined by
[MAC-A6](docs/AMENDMENTS.md#MAC-A6)).

## Repository layout

```
mindattic.com/
├── index.htm                  # The entire homepage — wordmark, three buttons, backdrop
├── idiotproof/                # Support pages for the IdiotProof sub-project (see below) — still deployed
│   ├── privacy-policy.htm     # Standalone privacy policy, deployed to /idiotproof/
│   ├── terms-of-use.htm       # Standalone terms of use, deployed to /idiotproof/
│   ├── dataset/               # ML feature-store exports (trades.csv, bars.csv, manifest.json)
│   └── replays/               # Generated trade-replay HTML archive — gitignored, deploy-only
├── docs/                      # Codex canon: BIBLE, AMENDMENTS, USER_STORIES, rfc/ (see below)
├── tools/
│   ├── codex.ps1              # `doctor` (validate docs/) and `digest` (regenerate BIBLE.digest.md)
│   └── build-readme.ps1       # Thin wrapper -> shared engine in ../codex-standard/build-readme.ps1
├── .claude/                   # Slash commands (/deploy, /fetch, /quicksave, /quickload), skills
│                              #   (/run, /commit, /discard, /revert), hooks (last-updated stamp,
│                              #   Codex digest injection)
│
│   DORMANT — kept on disk, no longer used by the page (MAC-A6):
├── data/                      # software/ecosystem/hardware/books/visual-arts .json (generated)
├── fetch-descriptions.ps1     # Regenerates data/*.json from GitHub repo metadata + Amazon synopses
├── add-book.ps1 / .bat        # Appends an Amazon book (cover as base64) to data/books.json
├── diagram/                   # ecosystem.mmd (Mermaid) -> render.ps1 -> ecosystem.svg
├── previews/                  # <RepoName>.b64 preview images used by fetch-descriptions.ps1
├── .image-base64.txt          # Base64 source text for an old inlined image
└── README.md                  # <- you are here
```

> `deploy.ps1` / `deploy.bat` / a per-repo FTP `settings.json` are **retired**. Deployment lives in
> the sibling **MindAttic.Deploy** repo (see [Deploy](#deploy) below).

## Local development

```powershell
# /run (or by hand) serves the repo at http://localhost:3457/ and opens the page
python -m http.server 3457
start http://localhost:3457/index.htm
```

The page no longer fetches any local data, so serving over HTTP is no longer *required* (it used to
be, to avoid a CORS-blocked `fetch()` of `data/*.json`). It loads its fonts, logo, effects engine and
textures from jsDelivr, so you need to be online to see it as deployed.

The only region you must not hand-edit is the `BEGIN/END MINDATTIC.UIUX:CYBERSPACE` block — the next
UiUx sync overwrites it ([LAW-2](docs/BIBLE.md#MAC-LAW-2)).

## Content updates

### Change a link or the wordmark

Edit the three `<a class="link-btn">` anchors (or the `<h1 id="site-name">`) near the end of
`index.htm`. Keep `target="_blank" rel="noopener noreferrer"` on the links. The page layout adapts on its
own: the buttons are equal width and span exactly the wordmark's width.

### Take a new asset release

1. Add or change the file in `MindAttic.UiUx`, tag the next whole-number release, push the tag.
2. Change every `MindAttic.UiUx@V…` in `index.htm` to the new tag (or run the UiUx sync with
   `-CyberspaceCdnTag V<n>` for the Cyberspace block, and update the font/logo URLs by hand).
3. Confirm the new URLs resolve (`curl -I` them) before deploying.

### Dormant generators (not used by the page)

These still run, but their output (`data/*.json`, the ecosystem SVG) is not shown anywhere any more:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Projects\MindAttic\mindattic.com\fetch-descriptions.ps1"
powershell -File add-book.ps1 https://www.amazon.com/dp/B0XXXXXXXX
powershell -File diagram\render.ps1      # WILL THROW: the ECOSYSTEM-DIAGRAM markers are no longer in index.htm
```

- `fetch-descriptions.ps1` rebuilds `data/software.json` / `ecosystem.json` / `hardware.json` from every
  public `mindattic` GitHub repo (visibility is the only gate; the `hardware` topic and the `MindAttic.*`
  prefix only pick the section — [MAC-A4](docs/AMENDMENTS.md#MAC-A4)) and refreshes `data/books.json`
  synopses from Amazon. It also has `-ListUntagged` and `-ProposeDescriptions` / `-ApplyDescriptions`
  (README-derived description write-back via `gh repo edit`, human-approved first). Requires the `gh`
  CLI; it no-ops gracefully if `gh` is missing. It never writes `index.htm`.
- `add-book.ps1` appends an Amazon book (cropped cover as a base64 data URL, deduplicated by ASIN) to
  `data/books.json`.
- Whether to delete this machinery is an open decision ([MAC-US-D5](docs/USER_STORIES.md#MAC-US-D5)).

### Cyberspace (the only synced component)

Not run standalone from this repo — it happens as step 2 of a deploy (see below), via
`MindAttic.UiUx/sync/sync-mindattic-com.ps1`, which rewrites only the `CYBERSPACE` marker block. This
site is no longer enrolled for the `OutfitFont`, `AtticFont`, `PinFooter` or `WebSnapshot` components
(the fonts load straight from the CDN).

## The `idiotproof/` folder

[IdiotProof](https://github.com/mindattic/IdiotProof) is one of the `MindAttic.*`-ecosystem software
projects, a tool that connects to a brokerage account (Alpaca) to author and evaluate trading strategies
and, optionally, place orders. Its per-project landing page, `https://mindattic.com/idiotproof.htm`, is
rendered by the `MindAttic.Deploy` catalog pipeline from that project's own repo, not hand-authored here.

What *does* live in this repo, under `idiotproof/`, is the small set of static support pages that
ship to `/idiotproof/` on the same domain:

| Path | What it is | Tracked in git? |
|---|---|---|
| `idiotproof/privacy-policy.htm` | Standalone privacy policy page | Yes |
| `idiotproof/terms-of-use.htm` | Standalone terms-of-use page | Yes |
| `idiotproof/dataset/manifest.json`, `trades.csv`, `bars.csv` | Exported ML feature-store data (one row per round-trip trade / one row per minute bar) — generated externally by IdiotProof's own SQL export, checked in | Yes |
| `idiotproof/replays/**` | A generated archive of trade-strategy replays (an `index.htm` per ticker plus one per individual replay run), grouped by trading day | **No** — gitignored (`idiotproof/replays/`); it exists only to be uploaded |

These are plain static files with their own inline `<style>`/`<script>`. They are uploaded by the
`idiotproof-replays` site entry in `MindAttic.Deploy/projects.json` (`uploadDir`), separately from
`index.htm`.

## Deploy

Use the `/deploy` Claude Code slash command, or run directly:

```powershell
cd D:\Projects\MindAttic\MindAttic.Deploy
npm run deploy -- --site mindattic.com
```

The pipeline (owned entirely by the sibling **MindAttic.Deploy** repo — this repo's own
`deploy.ps1`/`deploy.bat`/FTP `settings.json` are retired, see
[MAC-A2](docs/AMENDMENTS.md#MAC-A2)):

1. `git pull` on the sibling `MindAttic.UiUx` repo (hard-fails if it's dirty or missing).
2. Runs `MindAttic.UiUx/sync/sync-mindattic-com.ps1` to splice the Cyberspace block into `index.htm`.
3. Runs `fetch-descriptions.ps1` (optional, best-effort; it only rewrites the dormant `data/*.json`).
4. Stamps `index.htm`'s `<!-- Last Updated: ... -->` comment with the current UTC time.
5. FTPS-uploads every `*.htm` in this folder to `/mindattic.com/`.

Only `*.htm` is uploaded: the fonts, logo, engine and textures are already on the CDN (they ship when
the `MindAttic.UiUx` tag is pushed), and `data/*.json` is no longer needed on the server
([MAC-A6](docs/AMENDMENTS.md#MAC-A6) supersedes [MAC-A3](docs/AMENDMENTS.md#MAC-A3)).

This site's deploy profile lives in `MindAttic.Deploy/projects.json` under `sites[]`; per-project
landing pages (`mindattic.com/<slug>.htm`, e.g. `idiotproof.htm`) ship via the catalog half of the
same pipeline (`npm run deploy -- --only <slug>`), not via this command. FTP credentials are
centralized in `MindAttic.Deploy/secrets/ftp.json` (gitignored there) — this repo no longer reads
its own `settings.json` for that purpose.

A `PostToolUse` hook in `.claude/settings.json` also stamps `<!-- Last Updated: ... -->` locally on
every `Edit`/`Write` of `index.htm`, independent of a deploy.

## Conventions

- **Asset URLs:** `https://cdn.jsdelivr.net/gh/mindattic/MindAttic.UiUx@V<n>/<path>` — tag-pinned, whole
  number tags, never `@main`.
- **Asset layout in `MindAttic.UiUx`:** shared fonts at the root (`fonts/<family>/`), per-site files at
  `<domain>/<category>/` (no `assets/` level), kebab-case filenames, variant last
  (`m-monogram-transparent.png`).
- **Page CSS:** IDs for singletons (`#content`, `#site-name`, `#site-footer`); classes for reusable pieces
  (`.lockup`, `.link-row`, `.link-btn`); sizing chain `--u` → `--wm` → `--btn-u`; lengths in `rem`/`dvmin`
  or multiples of those variables.

The full list is [BIBLE §10](docs/BIBLE.md#MAC-§10).

## Codex — canonical documentation

This repo follows the MindAttic Codex documentation standard (project code **MAC**). A fact lives in
exactly one layer; this README links to it rather than restating it:

| Layer | File | What it holds |
|---|---|---|
| L0 | [docs/BIBLE.md](docs/BIBLE.md) | What the site IS / is NOT, architecture, the Laws (`{#MAC-LAW-n}`), verified state, glossary, conventions |
| L1 | [docs/AMENDMENTS.md](docs/AMENDMENTS.md) | Append-only change log (`MAC-A<n>`); an amendment wins over the bible |
| L2 | [docs/USER_STORIES.md](docs/USER_STORIES.md) | Stories `MAC-US-<Epic><n>`; every ✅ cites its evidence |
| rfc | [docs/rfc/](docs/rfc/) | Design notes (e.g. `0001-codex-adoption.md`) that graduate into the layers above |
| generated | [docs/BIBLE.digest.md](docs/BIBLE.digest.md) | Produced by `tools/codex.ps1 digest`; never hand-edited |

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\codex.ps1 doctor   # validate docs/
powershell -NoProfile -ExecutionPolicy Bypass -File tools\codex.ps1 digest   # regenerate the digest
```

There is no compiler, unit-test suite, or CI in this repo — it's a static HTML page with dormant
PowerShell generators. "Verified" here means: the file parses/loads as HTML, the page's markup is
present as documented, and `codex doctor` passes clean.
