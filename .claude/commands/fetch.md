Regenerate data/software.json, data/ecosystem.json, and data/hardware.json from
public mindattic repos on GitHub, and refresh data/books.json synopses from
Amazon. index.htm never changes — it holds a static, empty
`<div class="home-sections" data-catalog="...">` placeholder per section, and
fetches these JSON files at runtime (mountCatalog() in index.htm's own JS).

Run:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "D:/Projects/MindAttic/mindattic.com/fetch-descriptions.ps1"
```

What it does:

1. Calls `gh repo list mindattic --visibility public --json name,description,homepageUrl,repositoryTopics`.
2. Filters out `mindattic.com` (the site itself).
3. Partitions by GitHub topic: `software` topic + name not matching
   `MindAttic.*` -> `data/software.json`; `software` topic + `MindAttic.*`
   name -> `data/ecosystem.json`; `hardware` topic -> `data/hardware.json`.
   Repos with neither topic are skipped (reported, not written).
4. Rebuilds each JSON file from scratch: one object per repo (`id`, `name`,
   `description`, `githubUrl`, `openUrl`, `openInternal`, `previewImage`,
   `dataRepo`, `topics`). `openUrl` resolves against
   `../MindAttic.Deploy/projects.json` first (slug landing page or explicit
   `openUrl`), falling back to the repo's GitHub homepage URL.
   `previewImage` comes from `previews/<repo-name>.b64` if present.
5. Refreshes `data/books.json`: for every entry with an `amazonUrl`, fetches
   the Amazon product page and re-extracts its synopsis from
   `div[name="book_description_expander"]`, trimming the trailing "Read
   more". Amazon is the source of truth for synopses; edit on Amazon, rerun
   this. Covers/titles/ASINs are untouched here — those come from
   `add-book.ps1`.

GitHub is the source of truth for repo tiles:

- **To feature a repo:** make it public and tag it
  `gh repo edit mindattic/<name> --add-topic software` (or `hardware`). Set
  its description on the repo page or via
  `gh repo edit --description "..."`. Optionally set a homepage URL via
  `gh repo edit --homepage "<url>"` to add an Open button.
- **To hide a repo:** remove the topic, or make it private. It disappears on
  the next `/fetch` (or `/deploy`).
- **To refresh a description:** edit it on GitHub, rerun this.

Other flags on the same script:

- `-ListUntagged` — report public repos missing both the `software` and
  `hardware` topic, without writing anything (tagging stays a manual
  decision).
- `-ProposeDescriptions` — for every tagged repo with an empty/thin
  description, print a README-derived hint. Review, draft real candidates,
  then apply with `-ApplyDescriptions "Repo=New description", ...` (calls
  `gh repo edit --description`, so show the candidates to the user for
  approval before running this).

The script is idempotent — if nothing changed on GitHub/Amazon since the last
run, the JSON files come out byte-identical.

After running, summarize how many tiles were regenerated per file and call
out which have an Open button. Flag any failures.
