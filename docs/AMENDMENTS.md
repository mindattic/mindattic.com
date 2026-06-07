---
codex: 1
project: mindattic.com
code: MAC
layer: amendments
status: living
updated: 2026-06-07
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
