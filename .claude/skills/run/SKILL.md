---
name: run
description: Serve the mindattic.com portfolio site locally and open it in the default browser. No arguments needed.
---

index.htm no longer fetches any local data, so serving over HTTP is not strictly required any more
(it used to be, because `file://` blocks `fetch()` of data/*.json under CORS). It loads its fonts, logo,
effects engine and textures from jsDelivr, so you must be online. Serving over local HTTP is still the
supported preview path (matches the `mindattic.com` entry in `.claude/launch.json`):

When invoked:

1. Run (from the repo root): `python -m http.server 3457`
2. Run: `start http://localhost:3457/index.htm`
3. Inform the user the page has been opened in their browser, served from
   `http://localhost:3457/`
