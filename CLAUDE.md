# mindattic.com Project Rules

## Conversation
- A bare "do" / "do it" / "yes" from the user means "continue", "keep going", "proceed". Resume the current task without asking for clarification.

## Codex (canonical documentation)
This repo follows the MindAttic Codex standard. The source of truth lives in `docs/`:
- `docs/BIBLE.md` (L0) — what mindattic.com IS, is NOT, and its Laws. Project CODE: **MAC**.
- `docs/AMENDMENTS.md` (L1) — append-only change log; an amendment wins over the bible.
- `docs/USER_STORIES.md` (L2) — test/evidence-cited stories + backlog.
- `docs/rfc/` — design notes that graduate into the bible + stories.
- `docs/BIBLE.digest.md` — GENERATED; never hand-edit (regenerate with `codex.ps1 digest`).

How to work here:
- A fact lives in exactly one layer; cross-reference by `{#MAC-...}` anchor, never restate it.
- Shared rules are inherited from `../MindAttic.HouseRules.md` via BIBLE §5 — don't restate them.
- Before finishing a change: `pwsh tools/codex.ps1 digest` then `pwsh tools/codex.ps1 doctor`
  (or `powershell -File tools/codex.ps1 ...`). Doctor must pass.
- This is a single-file static site (`index.htm`) with no build/test step. Respect the Laws:
  generated regions (Software board, Writing synopses, ecosystem SVG, UiUx blocks) are not
  hand-edited — edit the upstream source and re-run the generator.
