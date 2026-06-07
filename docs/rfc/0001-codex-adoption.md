---
codex: 1
project: mindattic.com
code: MAC
layer: rfc
status: planned
updated: 2026-06-07
---

# RFC 0001 — Adopt the Codex documentation standard (and a doctor for the single file)

## Problem

mindattic.com is one hand-authored `index.htm` plus a few PowerShell generators and slash commands.
The "rules" of the site (one file, no build step, generated regions, centralized deploy, dark-only
palette) lived only as inline comments and in the maintainer's head — and the README had already
drifted (it still advertises a retired light/dark toggle). There was no single source of truth and
no automated guard against documentation rot or broken cross-references.

## Options compared

1. **Do nothing** — keep relying on inline comments. Cheap, but drift continues (the README proves
   it) and there is no machine check.
2. **Hand-maintained docs, no tooling** — add `docs/` but no doctor. Better, but nothing prevents
   stale IDs, dead cross-refs, or a stale digest.
3. **Full Codex standard (chosen)** — `docs/BIBLE.md` (L0) + `AMENDMENTS.md` (L1) +
   `USER_STORIES.md` (L2) + `rfc/` + a `tools/codex.ps1 doctor/digest` CLI + a SessionStart hook
   that injects the digest. Adds a small PowerShell tool but no build step and no runtime
   dependency on the site.

## Decision

Adopt the full Codex standard (Option 3), scoped to a `website` domain: lean bible, **no L5 data
layer** (the project's catalogs — tiles, books, ecosystem — are *generated regions* sourced from
GitHub/Amazon/Mermaid, not a hand-maintained JSON canon, so duplicating them as `docs/data/*.json`
would violate single-home-per-fact). `doctor` validates front-matter, unique IDs, resolving
cross-refs, cited-path existence, ✅-story evidence tokens, and digest freshness.

## What NOT to do

- Do **not** add `docs/data/*.json` for tiles/books — they are generated from upstream sources;
  encoding them as L5 canon would create a second home for the same facts ([LAW-2](../BIBLE.md#MAC-LAW-2)).
- Do **not** let the doctor require a build/test step — there is none ([LAW-1](../BIBLE.md#MAC-LAW-1)).
- Do **not** modify `index.htm` content or the README as part of adopting Codex.

## Phased plan (with risk)

1. **Now:** create `docs/` (BIBLE/AMENDMENTS/USER_STORIES/this RFC), `tools/codex.ps1`, and the
   SessionStart digest hook; wire a Codex section into `CLAUDE.md`. *Risk: low — docs/tooling only.*
2. **Next:** run the `fetch`/`render`/`deploy` generators end-to-end and upgrade
   MAC-US-B2/C3 from 🟡 to ✅ with recorded idempotent output. *Risk: external (network/`gh`/`npx`).*
3. **Later:** extend `doctor` with an optional HTML-validity / dead-link check over `index.htm`
   (MAC-US-D3). *Risk: false positives on intentional inline data URIs — make it opt-in.*

## Graduates into

- BIBLE: [§4 Architecture](../BIBLE.md#MAC-§4), [§5 Laws](../BIBLE.md#MAC-§5),
  [§8 Quality bar](../BIBLE.md#MAC-§8).
- Stories: [MAC-US-D2](../USER_STORIES.md#MAC-US-D2), [MAC-US-D3](../USER_STORIES.md#MAC-US-D3).
