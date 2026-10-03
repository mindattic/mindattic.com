# mindattic.com

Ryan DeBraal's front door: one hand-authored HTML page with the MindAttic wordmark, three links and a tap-to-play Cyberspace backdrop, with no build step, no framework and no tracking.

[![HTML5](https://img.shields.io/badge/HTML5-hand--authored-e34f26)](index.htm) [![CSS3](https://img.shields.io/badge/CSS3-custom%20properties-1572b6)](index.htm) [![JavaScript](https://img.shields.io/badge/JavaScript-vanilla-f7df1e)](index.htm) [![Assets](https://img.shields.io/badge/assets-MindAttic.UiUx%20V10-6c5ce7)](https://github.com/mindattic/MindAttic.UiUx) [![Status](https://img.shields.io/badge/status-live-2ea043)](https://mindattic.com)

![The mindattic.com home page: the MindAttic wordmark above three red-outlined buttons (Résumé, GitHub, MindAttic Cares) on the dark Cyberspace backdrop, with two faint console windows drifting behind them](docs/images/home-cyberspace.png)

Try it: [mindattic.com](https://mindattic.com)

## Why

- One click from the MindAttic name to the résumé, the GitHub organisation or the charity, with nothing in the way.
- The page is the same shape on every screen. Every length is a multiple of one viewport unit, so a phone and an ultrawide monitor see the same composition.
- View Source is meant to be read. The file opens with an ASCII banner and a numbered table of contents, so it reads like a conversation, not a puzzle.
- Nothing to install and nothing to build. The file you edit is the file the browser runs.
- No analytics, no tracking pixels and no third-party fonts. The only outside host is a tag-pinned CDN copy of MindAttic's own asset package.

## Features

| Piece | What it is |
|---|---|
| `#site-name` | The "MindAttic" wordmark, set in the Attic display font |
| `.link-row` and `.link-btn` | Three equal-width buttons: Résumé (`https://ryandebraal.com`), GitHub (`https://github.com/mindattic`) and MindAttic Cares (`https://mindatticcares.com`). Each opens in a new window, which screen readers announce through `aria-describedby` |
| `.lockup` | The wordmark and buttons, centred both ways. The three buttons together are exactly as wide as the wordmark |
| `#site-footer` | Copyright line fixed to the bottom edge. The page never scrolls |
| No selection | Text can't be highlighted (`user-select: none`), long-press shows no iOS copy bubble and taps don't flash a highlight box. Links and keyboard focus still work |
| Cyberspace block | The backdrop (circuit-board parallax, scanlines, console windows), spliced in by the UiUx sync |
| Tap script | Tap or left-click anywhere off the buttons to spawn one random Cyberspace effect. Right and middle clicks are ignored |
| Link preview | Meta description, canonical URL, `theme-color` and Open Graph / Twitter card tags, so shared links show the M monogram and a one-line summary |

Everything on the page is a multiple of one viewport-relative unit (`--u`, 1% of the smaller visible viewport side), so it keeps the same shape on every screen and aspect ratio.

![After a few taps: a ring of drifting glyphs top left, a blue glyph cluster beside the wordmark and a schematic console window bottom right](docs/images/tap-effects.png)

The file opens with an ASCII banner and a numbered table of contents, from § 1 to § 12, aimed at anyone who opens View Source (see [BIBLE §2](docs/BIBLE.md#MAC-§2) and [LAW-7](docs/BIBLE.md#MAC-LAW-7)).

## Quick start

You need Python 3 (or any static file server) and a network connection, because fonts, logo, effects engine and textures load from jsDelivr.

```powershell
git clone https://github.com/mindattic/mindattic.com
cd mindattic.com
python -m http.server 3457
start http://localhost:3457/index.htm
```

You should see the wordmark and three buttons over the dark Cyberspace backdrop. Tap the background to spawn an effect. The `/run` Claude Code skill does the same thing.

The page fetches no local data, so opening `index.htm` directly works too.

## Stack

`HTML5`, `CSS3` (custom properties, `dvmin`-based sizing, dark "Cyberspace" palette only, see [LAW-5](docs/BIBLE.md#MAC-LAW-5)), one small vanilla JavaScript snippet, and the shared Cyberspace bundle from `MindAttic.UiUx`.

No React. No Vite. No npm. No analytics, tracking pixels or third-party fonts. The only external host is `cdn.jsdelivr.net`, serving the `MindAttic.UiUx` repo ([LAW-6](docs/BIBLE.md#MAC-LAW-6)).

## Where the assets live

The assets are not in this repo and not in the HTML. Fonts (Outfit, Attic), the logo PNGs, the Cyberspace effects engine and its parallax textures are plain static files in the sibling MindAttic.UiUx repo, served over jsDelivr at a tag-pinned URL:

```text
https://cdn.jsdelivr.net/gh/mindattic/MindAttic.UiUx@V10/<path>
```

`<head>` opens the connection early (`preconnect`) and preloads the first-paint fonts. The two big engine scripts are `defer`red so they never block the first paint.

UiUx tags are immutable whole numbers (`V9`, `V10`, and so on). The page pins `V10`. The linked deploy rewrites every `MindAttic.UiUx@V…` in `index.htm` to the release tag; the Cyberspace block's tag is set by the sync script's `-CyberspaceCdnTag`, which defaults to the latest `V*` tag in the UiUx checkout. Never point the page at `@main`.

Layout of the package (full rules in `MindAttic.UiUx/docs/ASSETS.md`):

- Shared fonts at the repo root: `fonts/outfit/`, `fonts/attic/`.
- Site-specific files directly under the domain folder as `<domain>/<category>/` (this site: `mindattic.com/logos/`).
- Cyberspace textures at `Components/Cyberspace/assets/`.
- Filenames are lowercase kebab-case.

## Project layout

```text
mindattic.com/
├── index.htm                  # The entire homepage: wordmark, three buttons, backdrop
├── idiotproof/                # Support pages for the IdiotProof project (see below), deployed
│   ├── privacy-policy.htm     # Standalone privacy policy, deployed to /idiotproof/
│   ├── terms-of-use.htm       # Standalone terms of use, deployed to /idiotproof/
│   ├── dataset/               # ML feature-store exports (trades.csv, bars.csv, manifest.json)
│   └── replays/               # Generated trade-replay HTML archive: gitignored, deploy-only
├── docs/                      # Codex canon: BIBLE, AMENDMENTS, USER_STORIES, images/
├── tools/
│   ├── codex.ps1              # doctor (validate docs/) and digest (regenerate BIBLE.digest.md)
│   └── build-readme.ps1       # Thin wrapper -> shared engine in ../codex-standard/build-readme.ps1
├── .claude/                   # Slash commands (/deploy, /quicksave, /quickload), skills
│                              #   (/run, /commit, /discard, /revert), hooks (digest injection,
│                              #   quickload-on-do)
├── .prose/                    # Provider-neutral aliases of the same commands
└── README.md                  # This file
```

This repo has no deploy script and no FTP settings. Deployment lives in the sibling MindAttic.Deploy repo (see [Deployment](#deployment)).

## Editing the page

The only region you must not hand-edit is the `BEGIN/END MINDATTIC.UIUX:CYBERSPACE` block: the next UiUx sync overwrites it ([LAW-2](docs/BIBLE.md#MAC-LAW-2)).

### Change a link or the wordmark

Edit the three `<a class="link-btn">` anchors (or the `<h1 id="site-name">`) near the end of `index.htm`. Keep `target="_blank" rel="noopener noreferrer"` on the links. The layout adapts on its own: the buttons are equal width and span exactly the wordmark's width.

### Take a new asset release

1. Add or change the file in `MindAttic.UiUx`, tag the next whole-number release and push the tag.
2. Change every `MindAttic.UiUx@V…` in `index.htm` to the new tag (or run the UiUx sync with `-CyberspaceCdnTag V<n>` for the Cyberspace block, and update the font and logo URLs by hand).
3. Confirm the new URLs resolve (`curl -I` them) before deploying.

The linked deploy does all three steps for you (see [Deployment](#deployment)).

### Cyberspace, the only synced component

It is not run on its own from this repo. It happens as step 3 of a deploy, through `MindAttic.UiUx/sync/sync-mindattic-com.ps1`, which rewrites only the `CYBERSPACE` marker block. Cyberspace is the only UiUx component this site subscribes to: the fonts and logo load straight from the CDN.

## The idiotproof folder

[IdiotProof](https://github.com/mindattic/IdiotProof) is one of the `MindAttic.*` ecosystem software projects: a tool that connects to a brokerage account (Alpaca) to author and evaluate trading strategies and, optionally, place orders. Its project page is its GitHub README.

What does live in this repo, under `idiotproof/`, is the small set of static support pages that ship to `/idiotproof/` on the same domain:

| Path | What it is | Tracked in git |
|---|---|---|
| `idiotproof/privacy-policy.htm` | Standalone privacy policy page | Yes |
| `idiotproof/terms-of-use.htm` | Standalone terms-of-use page | Yes |
| `idiotproof/dataset/manifest.json`, `trades.csv`, `bars.csv` | Exported ML feature-store data (one row per round-trip trade, one row per minute bar), generated by IdiotProof's own SQL export and checked in | Yes |
| `idiotproof/replays/**` | A generated archive of trade-strategy replays (an `index.htm` per ticker plus one per replay run), grouped by trading day | No: gitignored, it exists only to be uploaded |

These are plain static files with their own inline `<style>` and `<script>`. They are uploaded by the `idiotproof-replays` site entry in `MindAttic.Deploy/projects.json` (`uploadDir`), separately from `index.htm`.

## Deployment

Use the `/deploy` Claude Code slash command, or run:

```powershell
cd D:\Projects\MindAttic\MindAttic.Deploy
npm run deploy -- --site mindattic.com
```

The pipeline is owned entirely by the sibling MindAttic.Deploy repo ([LAW-4](docs/BIBLE.md#MAC-LAW-4)).

It is a linked 4-in-1 deploy: deploying this site also publishes `MindAttic.UiUx` and deploys `ryandebraal.com` and `mindatticcares.com` (see `MindAttic.Deploy/README.md`, "Linked deploy"):

1. Preflight: `MindAttic.UiUx` must be clean, on `main`, not behind origin, with a current manifest.
2. Publishes the next `MindAttic.UiUx` tag (`V<n>`) if its `HEAD` is ahead of the latest tag.
3. Pins that tag in each site's `index.htm` and runs `sync-mindattic-com.ps1` to splice the Cyberspace block.
4. Verifies every asset the sites use is live on jsDelivr, byte-exact, before anything is uploaded.
5. Stamps the `Last Updated` comment at the top of `index.htm` and FTPS-uploads it to `/mindattic.com/`.

Only `index.htm` is uploaded. The fonts, logo, engine and textures are already on the CDN (they ship when the `MindAttic.UiUx` tag is pushed).

This site's deploy profile lives in `MindAttic.Deploy/projects.json` under `sites[]`. FTP credentials are centralised in MindAttic.Deploy (gitignored there).

A `PostToolUse` hook in `.claude/settings.json` also stamps the `Last Updated` comment locally on every `Edit` or `Write` of `index.htm`, independent of a deploy.

## Hosting

The server holds static files only. Its `/mindattic.com/` folder is the docroot: `index.htm` from this repo, `idiotproof/` and `hyperspace/` (both uploaded by MindAttic.Deploy), and a hand-placed `.htaccess` that is not in this repo. That `.htaccess` forces HTTPS, redirects `www.mindattic.com` to `mindattic.com`, and 301-redirects project URLs of the form `/<slug>.htm` to the matching GitHub repo, so each project's page is its GitHub README. Details: [BIBLE §4.4](docs/BIBLE.md#MAC-§4.4).

## Conventions

- Asset URLs: `https://cdn.jsdelivr.net/gh/mindattic/MindAttic.UiUx@V<n>/<path>`, tag-pinned, whole-number tags, never `@main`.
- Asset layout in `MindAttic.UiUx`: shared fonts at the root (`fonts/<family>/`), per-site files at `<domain>/<category>/` (no `assets/` level), kebab-case filenames, variant last (`m-monogram-transparent.png`).
- Page CSS: IDs for singletons (`#content`, `#site-name`, `#site-footer`); classes for reusable pieces (`.lockup`, `.link-row`, `.link-btn`); sizing chain `--u` to `--wm` to `--btn-u`; lengths in `rem` or `dvmin`, or multiples of those variables.

The full list is [BIBLE §10](docs/BIBLE.md#MAC-§10).

## Testing

There is no compiler, unit-test suite or CI in this repo: it is a static HTML page. "Verified" here means the file loads as HTML, the page's markup is present as documented, and `codex doctor` passes clean. The shared Playwright suite in `MindAttic.UiUx/tests` covers the linked sites.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\codex.ps1 doctor   # validate docs/
powershell -NoProfile -ExecutionPolicy Bypass -File tools\codex.ps1 digest   # regenerate the digest
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-readme.ps1   # regenerate README.htm
```

## Documentation

This repo follows the MindAttic Codex documentation standard (project code MAC). A fact lives in exactly one layer:

| Layer | File | What it holds |
|---|---|---|
| L0 | [docs/BIBLE.md](docs/BIBLE.md) | What the site is and is not, architecture, hosting, the Laws (`MAC-LAW-n`), verified state, glossary, conventions |
| L1 | [docs/AMENDMENTS.md](docs/AMENDMENTS.md) | Decisions not yet folded into the bible (normally empty) |
| L2 | [docs/USER_STORIES.md](docs/USER_STORIES.md) | Stories `MAC-US-<Epic><n>`; every done story cites its evidence |
| rfc | `docs/rfc/` | Open design notes, when there are any |
| generated | [docs/BIBLE.digest.md](docs/BIBLE.digest.md) | Produced by `tools/codex.ps1 digest`; never hand-edited |

Agent instructions: [AGENTS.md](AGENTS.md) is this project's agent entrypoint. `CLAUDE.md` is a provider forwarder to the workspace-wide MindAttic agent standard.

## License

This repo has no LICENSE file. All rights reserved.

---

Part of [MindAttic](https://mindattic.com) — see more projects at [github.com/mindattic](https://github.com/mindattic). Related: [ryandebraal.com](https://github.com/mindattic/ryandebraal.com), [mindatticcares.com](https://github.com/mindattic/mindatticcares.com), [MindAttic.UiUx](https://github.com/mindattic/MindAttic.UiUx), [MindAttic.Deploy](https://github.com/mindattic/MindAttic.Deploy).
