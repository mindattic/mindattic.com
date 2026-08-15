# mindattic.com

Personal portfolio for Ryan DeBraal — one hand-authored, self-contained `index.htm` showcasing
software, hardware, writing, and visual art, plus a small set of per-project support pages that ride
along in the same deploy.

[mindattic.com](https://mindattic.com)

For how to *think about* this repo (Laws, invariants, verified state), see the Codex canon in
[docs/BIBLE.md](docs/BIBLE.md). This README is the how-to-build/run layer.

---

## What it is

The whole homepage is one file: `index.htm`, with inlined CSS, inlined vanilla JavaScript, and
base64-inlined fonts/images/covers. Open DevTools → Network on a fresh load and you'll see exactly
one request. There is no bundler, no framework, no CDN, no `npm install` needed to view or edit the
site — the only "build step" is a handful of idempotent PowerShell generators that rewrite fenced
regions of the file from external sources of truth (GitHub, Amazon, a Mermaid diagram).

The file opens with an ASCII banner and a `§ 1`–`§ 12` table of contents aimed at anyone who opens
View Source — the code is meant to read as a conversation, not a puzzle (see
[BIBLE §2](docs/BIBLE.md#MAC-§2), [LAW-7](docs/BIBLE.md#MAC-LAW-7)).

### Sections on the page

| Section | Content | Source of truth | Generator |
|---|---|---|---|
| Portfolio | Tabbed project showcase (Software + Hardware tiles) | — | — |
| Software | Board-grid of public `mindattic` GitHub repos tagged topic `software` (excluding the `MindAttic.*` prefix) | GitHub repo description/homepage/topics | `fetch-descriptions.ps1` |
| MindAttic Ecosystem | Board-grid of `MindAttic.*`-prefixed repos tagged `software`, plus an inlined dependency diagram above the grid | GitHub (grid) + `diagram/ecosystem.mmd` (diagram) | `fetch-descriptions.ps1` (grid) + `diagram/render.ps1` (diagram) |
| Hardware | Board-grid of repos tagged topic `hardware` | GitHub repo description/homepage/topics | `fetch-descriptions.ps1` |
| Writing | Amazon book covers (base64-inlined) with synopses | Amazon product pages | `add-book.ps1` (add cover) + `fetch-descriptions.ps1` (refresh synopsis text) |
| Visual Arts | Art preview grid (hand-maintained links + `previews/*.b64` sidecars) | hand-authored | — |

Repos with neither the `software` nor `hardware` GitHub topic simply don't appear on the homepage —
tagging is the opt-in mechanism, not a manual editing step (see "Content updates" below).

## Stack

`HTML5` · `CSS3` (custom properties, dark "Cyberspace" palette only — the theme toggle was retired,
see [MAC-A1](docs/AMENDMENTS.md#MAC-A1)) · `Vanilla JavaScript` (IIFE-scoped) · `Canvas 2D` · `SVG`

No React. No Vite. No npm. No CDN. No analytics, tracking pixels, or third-party network requests
of any kind ([LAW-6](docs/BIBLE.md#MAC-LAW-6)).

## Repository layout

```
mindattic.com/
├── index.htm                  # The entire homepage — one self-contained HTML file
├── fetch-descriptions.ps1     # Regenerates Software/Ecosystem/Hardware board-grids from GitHub
│                               #   repo metadata, and refreshes Writing synopses from Amazon
├── add-book.ps1 / .bat        # Fetch an Amazon book page, crop/resize the cover, insert a
│                               #   base64 <a class="book"> card into the Writing grid
├── diagram/
│   ├── ecosystem.mmd          # Mermaid source for the "MindAttic Ecosystem" dependency diagram
│   ├── mermaid-config.json    # Themes the render to the site's Cyberspace palette
│   ├── render.ps1             # ecosystem.mmd -> ecosystem.svg -> spliced into index.htm
│   └── ecosystem.svg          # Rendered/checked-in output (hand-maintainable fallback)
├── previews/                  # Per-repo preview-image sidecars: <RepoName>.b64 (full data: URL),
│                               #   inlined into that repo's tile by fetch-descriptions.ps1
├── idiotproof/                # Support pages for the IdiotProof sub-project (see below)
│   ├── privacy-policy.htm     # Standalone privacy policy, deployed to /idiotproof/
│   ├── terms-of-use.htm       # Standalone terms of use, deployed to /idiotproof/
│   ├── dataset/                # ML feature-store exports (trades.csv, bars.csv, manifest.json)
│   └── replays/                # Generated trade-replay HTML archive — gitignored, deploy-only
├── .image-base64.txt          # Base64 source text for one inlined image asset
├── docs/                      # Codex canon: BIBLE, AMENDMENTS, USER_STORIES, rfc/ (see below)
├── tools/
│   ├── codex.ps1               # `doctor` (validate docs/) and `digest` (regenerate BIBLE.digest.md)
│   └── build-readme.ps1        # Thin wrapper -> shared engine in ../codex-standard/build-readme.ps1
├── .claude/                    # Slash commands (/commit, /deploy, /fetch, /checkpoint), skills,
│                               #   hooks (last-updated stamp, Codex digest injection)
└── README.md                   # <- you are here
```

> `deploy.ps1` / `deploy.bat` / a per-repo FTP `settings.json` are **retired**. Deployment lives in
> the sibling **MindAttic.Deploy** repo (see [Deploy](#deploy) below).

## Local development

```powershell
# Open it directly — no dev server, nothing to compile.
start index.htm
```

Everything on the page is either hand-authored markup or a generated region rewritten in place by
one of the scripts below. Never hand-edit inside a generated region (board-grids, the ecosystem
`<svg>`, UiUx component blocks) — the next generator run overwrites it
([LAW-2](docs/BIBLE.md#MAC-LAW-2)).

## Content updates

### Refresh Software/Ecosystem/Hardware tiles and Writing synopses

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Projects\MindAttic\mindattic.com\fetch-descriptions.ps1"
```

What it does:

1. `gh repo list mindattic --visibility public --json name,description,homepageUrl,repositoryTopics`.
2. Drops the site's own repo (`mindattic.com`) from the results.
3. Partitions the rest by GitHub topic: `software` repos named `MindAttic.*` go to the **MindAttic
   Ecosystem** grid, other `software` repos go to **Software**, `hardware`-tagged repos go to
   **Hardware**. Anything with neither topic is skipped (reported, not shown on the page).
4. Rebuilds each `<div class="board-grid">` from scratch — one tile (button + `tabPage` detail
   panel) per repo, with the GitHub description, a per-repo preview image if a `previews/<repo>.b64`
   sidecar exists, an **Open** button (resolved against `MindAttic.Deploy/projects.json` first, then
   GitHub's `homepageUrl`), and a **GitHub** link.
5. For each entry in `index.htm`'s `BOOK_AMAZON_URLS` map, fetches the Amazon product page and
   refreshes the matching `BOOK_SYNOPSES` entry from the description-expander text (trims the
   trailing "Read more").
6. Writes the result back to `index.htm` only if something actually changed — otherwise it reports
   "already up to date" and exits cleanly.

To feature a repo: make it public, give it a description (and optionally a `homepage` URL for the
Open button), and tag it:

```powershell
gh repo edit mindattic/<name> --add-topic software   # or: hardware
```

To hide a repo: remove the topic, or make the repo private. Requires the `gh` CLI, authenticated
(`gh auth login`); the script no-ops gracefully (exit 0) if `gh` is missing or unauthenticated.

### Add a book to the Writing grid

"Book" here means a `<a class="book">` card: an Amazon product link wrapping a cropped, base64-
inlined 200×300 cover image.

```powershell
powershell -File add-book.ps1 https://www.amazon.com/dp/B0XXXXXXXX
# or: add-book.bat https://www.amazon.com/dp/B0XXXXXXXX
```

`add-book.ps1` fetches the Amazon page, pulls the product title and hi-res cover URL, extracts the
ASIN from the URL for the canonical link, downloads and center-crops the cover to 200×300 (matching
the existing covers), base64-encodes it as a `data:image/jpeg` URL, and inserts a new card at the
end of the Writing `books-grid` in `index.htm` — skipping the insert if that ASIN is already present.

### Regenerate the MindAttic Ecosystem diagram

```powershell
powershell -File diagram\render.ps1            # render ecosystem.mmd -> svg, then inline it
powershell -File diagram\render.ps1 -NoRender  # skip rendering; just re-inline the existing svg
```

Edits go in `diagram/ecosystem.mmd` (Mermaid source), never in the inlined `<svg>` directly. The
render uses `npx @mermaid-js/mermaid-cli`, themed by `diagram/mermaid-config.json` to match the
site's Cyberspace palette, and splices the result into `index.htm` between the
`<!-- BEGIN/END ECOSYSTEM-DIAGRAM -->` markers. On networks that MITM TLS (corporate proxy / custom
root CA), the `npx` download can fail — in that case keep `ecosystem.svg` hand-maintained in sync
with `ecosystem.mmd` and run with `-NoRender` to just re-splice it.

### Refresh UiUx components (fonts, Cyberspace, PinFooter, WebSnapshot)

Not run standalone from this repo — it happens as step 2 of a deploy (see below), via
`MindAttic.UiUx/sync/sync-mindattic-com.ps1`.

## The `idiotproof/` folder

[IdiotProof](https://github.com/mindattic/IdiotProof) is one of the `MindAttic.*`-ecosystem software
projects listed on the homepage (`sd-idiotproof` tile, tagged `software`), a tool that connects to a
brokerage account (Alpaca) to author and evaluate trading strategies and, optionally, place orders.
Its homepage tile's **Open** button points at `https://mindattic.com/idiotproof.htm` — a per-project
landing page rendered by the `MindAttic.Deploy` catalog pipeline from that project's own repo, not
hand-authored here.

What *does* live in this repo, under `idiotproof/`, is the small set of static support pages that
ship to `/idiotproof/` on the same domain:

| Path | What it is | Tracked in git? |
|---|---|---|
| `idiotproof/privacy-policy.htm` | Standalone privacy policy page | Yes |
| `idiotproof/terms-of-use.htm` | Standalone terms-of-use page | Yes |
| `idiotproof/dataset/manifest.json`, `trades.csv`, `bars.csv` | Exported ML feature-store data (one row per round-trip trade / one row per minute bar) — generated externally by IdiotProof's own SQL export, checked in here as a static download | Yes |
| `idiotproof/replays/**` | A generated archive of trade-strategy replays (an `index.htm` per ticker plus one per individual replay run), grouped by trading day | **No** — gitignored (`idiotproof/replays/`); it exists on disk and is uploaded by a deploy, but is not part of this repo's history |

These are plain static files with their own inline `<style>`/`<script>` — same "no build step, no
external request" discipline as the main site, just not part of `index.htm` itself.

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
2. Runs `MindAttic.UiUx/sync/sync-mindattic-com.ps1` to splice the latest subscribed UiUx components
   (Outfit/Attic fonts, Cyberspace, PinFooter, WebSnapshot) into `index.htm`.
3. Runs `fetch-descriptions.ps1` (best-effort — pulls GitHub repo tiles and Amazon synopses).
4. Stamps `index.htm`'s `<!-- Last Updated: ... -->` comment with the current UTC time.
5. FTPS-uploads every `*.htm` in this folder to `/mindattic.com/`.

This site's deploy profile lives in `MindAttic.Deploy/projects.json` under `sites[]`; per-project
landing pages (`mindattic.com/<slug>.htm`, e.g. `idiotproof.htm`) ship via the catalog half of the
same pipeline (`npm run deploy -- --only <slug>`), not via this command. FTP credentials are
centralized in `MindAttic.Deploy/secrets/ftp.json` (gitignored there) — this repo no longer reads
its own `settings.json` for that purpose.

A `PostToolUse` hook in `.claude/settings.json` also stamps `<!-- Last Updated: ... -->` locally on
every `Edit`/`Write` of `index.htm`, independent of a deploy.

## Codex — canonical documentation

This repo follows the MindAttic Codex documentation standard (project code **MAC**). A fact lives in
exactly one layer; this README links to it rather than restating it:

| Layer | File | What it holds |
|---|---|---|
| L0 | [docs/BIBLE.md](docs/BIBLE.md) | What the site IS / is NOT, architecture, the Laws (`{#MAC-LAW-n}`), verified state, glossary |
| L1 | [docs/AMENDMENTS.md](docs/AMENDMENTS.md) | Append-only change log (`MAC-A<n>`); an amendment wins over the bible |
| L2 | [docs/USER_STORIES.md](docs/USER_STORIES.md) | Stories `MAC-US-<Epic><n>`; every ✅ cites its evidence |
| rfc | [docs/rfc/](docs/rfc/) | Design notes (e.g. `0001-codex-adoption.md`) that graduate into the layers above |
| generated | [docs/BIBLE.digest.md](docs/BIBLE.digest.md) | Produced by `tools/codex.ps1 digest`; never hand-edited |

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\codex.ps1 doctor   # validate docs/
powershell -NoProfile -ExecutionPolicy Bypass -File tools\codex.ps1 digest   # regenerate the digest
```

There is no compiler, unit-test suite, or CI in this repo — it's a static HTML site with PowerShell
generators. "Verified" here means: the file parses/loads as HTML, the generators run idempotently,
and `codex doctor` passes clean.
