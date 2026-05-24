Deploy mindattic.com via **MindAttic.Deploy** (sibling repo at `D:\Projects\MindAttic\MindAttic.Deploy`). One repo owns the whole FTP pipeline; the per-project `deploy.ps1` / `deploy.bat` / `settings.json` in this folder are retired.

Run this command and report the result:

```
powershell -NoProfile -ExecutionPolicy Bypass -Command "cd D:\Projects\MindAttic\MindAttic.Deploy; npm run deploy -- --site mindattic.com"
```

This site's profile lives in `MindAttic.Deploy/projects.json` under `sites[]`. It runs:

1. `git pull` on the sibling `MindAttic.UiUx` repo (hard-fail if dirty or missing).
2. `MindAttic.UiUx/sync/sync-mindattic-com.ps1` to splice the latest subscribed components (Outfit/Attic fonts, Cyberspace, PinFooter, WebSnapshot) into `index.htm`.
3. `fetch-descriptions.ps1` (best-effort: pulls GitHub repo descriptions / Amazon book synopses for the project tiles).
4. Stamps `index.htm` with the current UTC `<!-- Last Updated: ... -->`.
5. FTPS-uploads every `*.htm` in this folder to `/mindattic.com/`.

After running, summarize how many files uploaded and flag any failures.

Notes:
- FTP credentials are centralized in `MindAttic.Deploy/secrets/ftp.json` (gitignored). The per-site `settings.json` is no longer read.
- Per-project landing pages (`mindattic.com/<slug>.htm`) ship via the catalog half of the same pipeline (`npm run deploy -- --only <slug>`), not via this command.
