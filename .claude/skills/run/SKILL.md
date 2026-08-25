---
name: run
description: Serve the mindattic.com portfolio site locally and open it in the default browser. No arguments needed.
---

index.htm fetches data/*.json at runtime via the browser Fetch API, which
`file://` blocks under CORS — opening the file directly shows an empty page.
Serve it over local HTTP instead (matches the `mindattic.com` entry in
`.claude/launch.json`):

When invoked:

1. Run (from the repo root): `python -m http.server 3457`
2. Run: `start http://localhost:3457/index.htm`
3. Inform the user the page has been opened in their browser, served from
   `http://localhost:3457/`
