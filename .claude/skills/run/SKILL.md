---
name: run
description: Serve the mindattic.com page locally and open it in the default browser. No arguments needed.
---

index.htm fetches no local data, so opening it directly also works. It loads its fonts, logo, effects
engine and textures from jsDelivr, so you must be online. Serving over local HTTP is the supported
preview path (matches the `mindattic.com` entry in `.claude/launch.json`):

When invoked:

1. Run (from the repo root): `python -m http.server 3457`
2. Run: `start http://localhost:3457/index.htm`
3. Inform the user the page has been opened in their browser, served from
   `http://localhost:3457/`
