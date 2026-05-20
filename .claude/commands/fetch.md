Regenerate the Software Development board-grid on the front page from public mindattic repos on GitHub.

Run:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "D:/Projects/MindAttic/mindattic.com/fetch-descriptions.ps1"
```

What it does:

1. Calls `gh repo list mindattic --visibility public --json name,description,homepageUrl`.
2. Filters out `mindattic.com` (the site itself).
3. Sorts repos by name, case-insensitive.
4. Rebuilds the entire `<div class="board-grid">...</div>` block from scratch — one `<button class="board-tile">` + `<div class="board-tile-desc">` panel per repo. Each panel has a placeholder image (left), the GitHub description (right), and a button row with `Demo` (if the repo's homepage URL is set) plus `GitHub`.
5. For each entry in `BOOK_AMAZON_URLS`, fetches the Amazon product page and refreshes the matching `BOOK_SYNOPSES` entry from the `div[name="book_description_expander"]` span text. Trims the trailing "Read more". Amazon is the source of truth for Writing-section synopses; edit on Amazon, rerun this.
6. Writes the result back to `index.htm`.

GitHub is the source of truth:

- **To feature a repo:** make it public (`gh repo edit mindattic/<name> --visibility public --accept-visibility-change-consequences`). Edit its description on the repo page or via `gh repo edit --description "..."`. Optionally set a homepage URL via `gh repo edit --homepage "<url>"` to add a Live Demo button.
- **To hide a repo:** make it private. It disappears on the next `/fetch` (or `/deploy`).
- **To refresh descriptions:** edit them on GitHub, rerun this.

The script is idempotent — if nothing changed on GitHub since the last run, it reports "already up to date" and exits without rewriting the file.

After running, summarize how many tiles were regenerated and call out which have Live Demo buttons. Flag any failures.
