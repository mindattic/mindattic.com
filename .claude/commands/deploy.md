Deploy mindattic.com via **MindAttic.Deploy** (sibling repo at `D:\Projects\MindAttic\MindAttic.Deploy`). One repo owns the whole FTP pipeline; the per-project `deploy.ps1` / `deploy.bat` / `settings.json` in this folder are retired.

**mindattic.com is permanently linked to MindAttic.UiUx, ryandebraal.com and mindatticcares.com.** Deploying any one of them deploys all four, so this command publishes the package and deploys the three sites together.

Run this command and report the result:

```
powershell -NoProfile -ExecutionPolicy Bypass -Command "cd D:\Projects\MindAttic\MindAttic.Deploy; npm run deploy -- --site mindattic.com"
```

Flags (append after `--site mindattic.com`): `--dry-run` previews everything (nothing is tagged, pushed, written or uploaded); `--with-tests` also runs the MindAttic.UiUx test suite as a gate; `--no-link` is the **escape hatch** that deploys mindattic.com alone (it prints a loud warning because the other pages may then pin a different asset tag).

The linked flow (`MindAttic.Deploy/src/linked.js`):

1. **Preflight** — `MindAttic.UiUx` must be on `main` with a clean working tree (the deploy never auto-commits), not behind origin, with `assets-manifest.json` current.
2. **Publish** — tag the package `V<n+1>` if `HEAD` is ahead of the latest tag, then push `main` + the tag.
3. **Pin** — `MindAttic.UiUx@V<n>` is rewritten to the release tag in each site's `index.htm` (this site: `index.htm`).
4. **Prepare** — this site's hooks run: `sync-mindattic-com.ps1 -CyberspaceCdnTag <tag>` splices **only the CYBERSPACE block** (the fonts, logo and effects engine are loaded from jsDelivr, not spliced); the dormant `fetch-descriptions.ps1` is no longer a deploy hook (DEP-A4).
5. **CDN gate** — every asset the pages use must be live on jsDelivr at that tag, byte-exact, or the run aborts **before any FTP upload**.
6. **FTP** — ryandebraal.com (`/`), mindatticcares.com (`/mindatticcares.com/`), then this site (`index.htm` only -> `/mindattic.com/`), each stamped with a `<!-- Last Updated: ... -->` comment.

After running, summarize the release tag, the pins that changed, the CDN gate result and the per-site upload table, and flag any failure. The deploy does not commit or push the site repos — mention any uncommitted changes `git status` shows.

Notes:
- FTP credentials are centralized in `MindAttic.Deploy/secrets/ftp.json` (gitignored). The per-site `settings.json` is no longer read.
- The per-project landing pages (`mindattic.com/<slug>.htm`) and MindAttic.Deploy's catalog mode (`--only <slug>`) are retired (DEP-A6, 2026-10-03). Each repo's GitHub README (`https://github.com/mindattic/<Repo>`) is its project page.
- Rules and rationale: `MindAttic.Deploy/docs/AMENDMENTS.md` (DEP-A3).
