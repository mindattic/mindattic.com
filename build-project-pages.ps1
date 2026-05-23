# build-project-pages.ps1 -- generate per-repo landing pages at mindattic.com root.
#
# Replaces the per-repo build-html.js + scripts/cli/deploy.ps1 pipeline. For
# each landing-page subscriber in MindAttic.UIUX/subscribers.json:
#
#   1. Resolve the GitHub repo name from the subscriber's target-path parent
#      folder. (Lets subscriber and repo names drift independently if needed.)
#   2. Pull README.md from GitHub via the gh CLI -- single source of truth.
#   3. Render Markdown to HTML through scripts\render-readme.js (Node + marked
#      + highlight.js). Token-classed code blocks survive, same as the legacy
#      per-repo renderer they replace.
#   4. Wrap the rendered README in a hero + readme-article template with the
#      four MindAttic.UIUX marker pairs (OutfitFont, AtticFont,
#      Cyberspace, BackHomeM).
#   5. Write the file to mindattic.com\<slug>.htm where <slug> is the repo
#      name lowercased with non-alphanumerics stripped (e.g. MindAttic.Psst
#      -> mindatticpsst). This matches the tile-id slug pattern in
#      fetch-descriptions.ps1, so the homepage Open buttons land here.
#   6. Splice the four component blocks in via sync-landing-page.ps1 (the same
#      sync that drove the legacy per-repo pages -- we just pass -TargetIndex
#      to redirect output to the central root).
#
# Auto-installs Node deps (marked, highlight.js) on first run if node_modules
# is absent. Each page is regenerated end-to-end every invocation; no
# incremental rebuild logic to drift out of sync.

param(
    [string]$Owner       = "mindattic",
    [string]$ContentRoot,
    [string]$OutputRoot  = $PSScriptRoot,
    [string]$RestrictTo  = ""   # optional: build a single subscriber by name
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# gh and node return UTF-8; pin both console streams so multi-byte chars in
# READMEs (em-dashes, smart quotes, emoji) round-trip cleanly through the pipe.
$OutputEncoding              = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding    = [System.Text.UTF8Encoding]::new($false)

if (-not $ContentRoot) { $ContentRoot = Join-Path $PSScriptRoot "..\MindAttic.UIUX" }
$utf8 = [System.Text.UTF8Encoding]::new($false)

# ---------------------------------------------------------------------------
# Pre-checks: gh, node, npm deps
# ---------------------------------------------------------------------------
function Test-ExeAvailable {
    param([string]$Name)
    try {
        & $Name --version 1>$null 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

if (-not (Test-ExeAvailable 'gh'))   { throw "gh CLI not available. Install GitHub CLI and run 'gh auth login'." }
if (-not (Test-ExeAvailable 'node')) { throw "node not available. Install Node.js (LTS)." }

& gh auth status 1>$null 2>$null
if ($LASTEXITCODE -ne 0) { throw "gh CLI not authenticated. Run: gh auth login" }

if (-not (Test-Path (Join-Path $PSScriptRoot 'node_modules'))) {
    Write-Host "Installing Node deps (marked, highlight.js)..." -ForegroundColor Cyan
    $prevDir = Get-Location
    try {
        Set-Location $PSScriptRoot
        & npm install --silent
        if ($LASTEXITCODE -ne 0) { throw "npm install failed (exit $LASTEXITCODE)." }
    } finally {
        Set-Location $prevDir
    }
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function ConvertTo-HtmlAttr {
    # Escape just enough that a value can sit inside double-quoted HTML
    # attributes (description -> <meta content="...">, tagline -> <p>...).
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    $t = $Text -replace '&', '&amp;'
    $t = $t -replace '<', '&lt;'
    $t = $t -replace '>', '&gt;'
    $t = $t -replace '"', '&quot;'
    return $t
}

function Get-Slug {
    param([string]$RepoName)
    return ($RepoName.ToLowerInvariant() -replace '[^a-z0-9]', '')
}

# ---------------------------------------------------------------------------
# Landing-page subscribers from subscribers.json
# ---------------------------------------------------------------------------
$cfg = Get-Content -Raw -Path (Join-Path $ContentRoot 'subscribers.json') -Encoding UTF8 | ConvertFrom-Json

$landingSubs = New-Object System.Collections.Generic.List[object]
foreach ($prop in $cfg.subscribers.PSObject.Properties) {
    if ($prop.Value.kind -ne 'landing-page') { continue }
    if ($RestrictTo -and $prop.Name -ne $RestrictTo) { continue }

    $tgt = $prop.Value.target
    $repoName = Split-Path -Leaf (Split-Path -Parent $tgt)
    $landingSubs.Add([pscustomobject]@{
        Subscriber = $prop.Name
        RepoName   = $repoName
        Slug       = Get-Slug -RepoName $repoName
    })
}

if ($landingSubs.Count -eq 0) {
    if ($RestrictTo) { throw "No landing-page subscriber matched -RestrictTo '$RestrictTo'." }
    Write-Host "No landing-page subscribers in subscribers.json. Nothing to build." -ForegroundColor Yellow
    exit 0
}

Write-Host ("Generating {0} landing page(s) at {1}..." -f $landingSubs.Count, $OutputRoot) -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Bulk-fetch repo descriptions and homepage URLs in one gh call.
# ---------------------------------------------------------------------------
$ErrorActionPreference = "Continue"
$reposJson = & gh repo list $Owner --visibility public --limit 200 --json name,description,homepageUrl 2>$null
$listExit  = $LASTEXITCODE
$ErrorActionPreference = "Stop"
if ($listExit -ne 0 -or [string]::IsNullOrWhiteSpace($reposJson)) {
    throw "gh repo list failed (exit $listExit)."
}
$repoIndex = @{}
foreach ($r in ($reposJson | ConvertFrom-Json)) { $repoIndex[$r.name] = $r }

# ---------------------------------------------------------------------------
# Landing page template. Single-quoted here-string so $-signs and backticks
# inside the rendered README don't get expanded; placeholders are substituted
# after construction.
# ---------------------------------------------------------------------------
$template = @'
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__PROJECT_NAME__ | MindAttic</title>
<meta name="description" content="__TAGLINE_ATTR__">

<!-- BEGIN MINDATTIC.UIUX:OUTFITFONT -->
<!-- END MINDATTIC.UIUX:OUTFITFONT -->

<!-- BEGIN MINDATTIC.UIUX:ATTICFONT -->
<!-- END MINDATTIC.UIUX:ATTICFONT -->

<style id="mindattic-landing-css">
:root {
    --bg:           #07090b;
    --fg:           #d6dde2;
    --muted:        #8a949c;
    --accent:       #ff8c00;
    --accent-fg:    #07090b;
    --border:       rgba(214, 221, 226, 0.18);
    --card-bg:      rgba(10, 14, 18, 0.78);
    --content-bg:   rgba(10, 14, 18, 0.86);
    --code-bg:      rgba(255, 255, 255, 0.04);
    --code-border:  rgba(255, 255, 255, 0.10);
    --link:         #ffb347;
    --link-hover:   #ffd089;
    --table-stripe: rgba(255, 255, 255, 0.03);
    --table-border: rgba(214, 221, 226, 0.14);
    --max-width:    920px;
}
* { box-sizing: border-box; }
html, body {
    margin: 0;
    padding: 0;
    background: var(--bg);
    color: var(--fg);
    font-family: 'Outfit', system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
    -webkit-font-smoothing: antialiased;
    text-rendering: optimizeLegibility;
    line-height: 1.55;
}
.page { position: relative; z-index: 1; }
.hero { max-width: var(--max-width); margin: 0 auto; padding: 88px 24px 32px; text-align: center; }
.project-name { margin: 0 0 14px; font-size: clamp(2.6rem, 7vw, 4.4rem); line-height: 1; letter-spacing: 0.01em; color: var(--fg); }
.tagline { margin: 0 auto 32px; max-width: 720px; font-size: clamp(1rem, 1.55vw, 1.18rem); color: var(--muted); font-weight: 400; }
.btn-row { display: flex; gap: 14px; flex-wrap: wrap; justify-content: center; }
.btn { display: inline-flex; align-items: center; justify-content: center; gap: 8px; min-width: 160px; padding: 13px 24px; border-radius: 6px; font-family: inherit; font-size: 1rem; font-weight: 500; letter-spacing: 0.02em; text-decoration: none; transition: transform 120ms ease, box-shadow 120ms ease, background 120ms ease, color 120ms ease; cursor: pointer; border: 1px solid var(--border); }
.btn:hover, .btn:focus-visible { transform: translateY(-1px); }
.btn-primary { background: var(--accent); color: var(--accent-fg); border-color: var(--accent); }
.btn-primary:hover { box-shadow: 0 8px 22px rgba(255, 140, 0, 0.32); }
.btn-secondary { background: transparent; color: var(--fg); }
.btn-secondary:hover { background: rgba(255, 255, 255, 0.06); }
.btn svg { width: 18px; height: 18px; }
.readme { max-width: var(--max-width); margin: 24px auto 96px; padding: 36px 44px 48px; background: var(--content-bg); border: 1px solid var(--border); border-radius: 10px; backdrop-filter: blur(6px); box-shadow: 0 18px 60px rgba(0, 0, 0, 0.45); }
.readme h1, .readme h2, .readme h3, .readme h4, .readme h5, .readme h6 { color: var(--fg); line-height: 1.25; margin: 1.8em 0 0.6em; }
.readme h1 { font-size: 2.0rem; margin-top: 0; }
.readme h2 { font-size: 1.55rem; border-bottom: 1px solid var(--border); padding-bottom: 0.3em; }
.readme h3 { font-size: 1.25rem; }
.readme h4 { font-size: 1.08rem; color: var(--muted); }
.readme p, .readme li { font-size: 1rem; }
.readme a { color: var(--link); text-decoration: none; border-bottom: 1px solid transparent; transition: color 120ms, border-color 120ms; }
.readme a:hover { color: var(--link-hover); border-bottom-color: var(--link-hover); }
.readme code { font-family: 'Fira Code', Consolas, 'SF Mono', Menlo, monospace; font-size: 0.92em; background: var(--code-bg); border: 1px solid var(--code-border); border-radius: 4px; padding: 0.12em 0.4em; }
.readme pre { background: var(--code-bg); border: 1px solid var(--code-border); border-radius: 6px; padding: 14px 16px; overflow-x: auto; line-height: 1.5; }
.readme pre code { background: transparent; border: 0; padding: 0; font-size: 0.9em; }
.readme blockquote { margin: 1em 0; padding: 0.4em 1em; border-left: 3px solid var(--accent); background: rgba(255, 140, 0, 0.06); color: var(--muted); }
.readme table { border-collapse: collapse; width: 100%; margin: 1em 0; font-size: 0.95em; }
.readme th, .readme td { border: 1px solid var(--table-border); padding: 8px 12px; text-align: left; }
.readme th { background: rgba(255, 255, 255, 0.04); font-weight: 600; }
.readme tr:nth-child(even) td { background: var(--table-stripe); }
.readme img { max-width: 100%; height: auto; border-radius: 6px; }
.readme hr { border: none; border-top: 1px solid var(--border); margin: 2em 0; }
.readme ul, .readme ol { padding-left: 1.6em; }
.readme li + li { margin-top: 0.25em; }
.readme .heading-anchor { color: var(--muted); font-weight: 400; text-decoration: none; opacity: 0; transition: opacity 120ms; margin-left: 0.4em; border-bottom: none; }
.readme h2:hover .heading-anchor, .readme h3:hover .heading-anchor, .readme h4:hover .heading-anchor { opacity: 1; }
@media (max-width: 640px) {
    .hero { padding-top: 64px; }
    .readme { margin: 16px 14px 64px; padding: 22px 18px 30px; }
    .btn { min-width: 132px; padding: 11px 18px; font-size: 0.95rem; }
}
</style>

<!-- BEGIN MINDATTIC.UIUX:BACKHOMEM -->
<!-- END MINDATTIC.UIUX:BACKHOMEM -->
</head>
<body>

<!-- BEGIN MINDATTIC.UIUX:CYBERSPACE -->
<!-- END MINDATTIC.UIUX:CYBERSPACE -->

<a class="back-home-m" href="https://mindattic.com" aria-label="Back to mindattic.com" title="Back to mindattic.com"></a>

<div class="page">
    <header class="hero">
        <h1 class="project-name" id="__SLUG__">__PROJECT_NAME__</h1>
        <p class="tagline">__TAGLINE_HTML__</p>
        <div class="btn-row">
__OPEN_BUTTON__            <a class="btn btn-secondary" href="https://github.com/__OWNER__/__PROJECT_NAME__" target="_blank" rel="noopener noreferrer">
                <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 .5C5.65.5.5 5.65.5 12c0 5.08 3.29 9.39 7.86 10.91.58.11.79-.25.79-.56v-2c-3.2.7-3.88-1.36-3.88-1.36-.52-1.34-1.28-1.7-1.28-1.7-1.05-.71.08-.7.08-.7 1.16.08 1.77 1.19 1.77 1.19 1.03 1.77 2.71 1.26 3.37.97.1-.75.4-1.26.73-1.55-2.55-.29-5.24-1.28-5.24-5.7 0-1.26.45-2.29 1.19-3.1-.12-.29-.52-1.46.11-3.04 0 0 .97-.31 3.18 1.18a11 11 0 0 1 5.79 0c2.21-1.49 3.18-1.18 3.18-1.18.63 1.58.23 2.75.11 3.04.74.81 1.19 1.84 1.19 3.1 0 4.43-2.69 5.41-5.25 5.69.41.36.78 1.07.78 2.16v3.2c0 .31.21.68.8.56C20.21 21.39 23.5 17.08 23.5 12 23.5 5.65 18.35.5 12 .5z"/></svg>
                GitHub
            </a>
        </div>
    </header>

    <article class="readme">
<!-- BEGIN README-CONTENT -->
__README_CONTENT__
<!-- END README-CONTENT -->
    </article>
</div>

</body>
</html>
'@

$openButtonTemplate = @'
            <a class="btn btn-primary" href="__OPEN_URL__" target="_blank" rel="noopener noreferrer">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
                Open
            </a>
'@

# ---------------------------------------------------------------------------
# Build loop
# ---------------------------------------------------------------------------
$syncScript = Join-Path $ContentRoot 'sync\sync-landing-page.ps1'
if (-not (Test-Path $syncScript)) { throw "sync-landing-page.ps1 not found at $syncScript" }

$renderScript = Join-Path $PSScriptRoot 'scripts\render-readme.js'
if (-not (Test-Path $renderScript)) { throw "render-readme.js not found at $renderScript" }

$built  = 0
$failed = New-Object System.Collections.Generic.List[string]

foreach ($s in $landingSubs) {
    Write-Host ""
    Write-Host ("--- {0} -> {1}.htm ---" -f $s.RepoName, $s.Slug) -ForegroundColor Cyan

    if (-not $repoIndex.ContainsKey($s.RepoName)) {
        Write-Host ("  Repo '{0}' not in public gh listing. Skipping." -f $s.RepoName) -ForegroundColor Yellow
        $failed.Add($s.RepoName + " (not public on GitHub)")
        continue
    }
    $repo = $repoIndex[$s.RepoName]

    # 1. Pull README content (base64) via gh api
    $ErrorActionPreference = "Continue"
    $rmJson = & gh api "repos/$Owner/$($s.RepoName)/readme" 2>$null
    $rmExit = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    if ($rmExit -ne 0 -or [string]::IsNullOrWhiteSpace($rmJson)) {
        Write-Host ("  README fetch failed (gh exit {0}). Skipping." -f $rmExit) -ForegroundColor Yellow
        $failed.Add($s.RepoName + " (no README on GitHub)")
        continue
    }
    $rmObj = $rmJson | ConvertFrom-Json
    $b64   = ($rmObj.content -replace '\s', '')
    $md    = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))

    # 2. Render Markdown to HTML via Node. Write the MD to a temp file rather
    #    than piping into a child process -- PowerShell 5.1's piping mangles
    #    UTF-8 in non-trivial inputs, so the file-on-disk + Get-Content -Raw
    #    + ... | node form is the only reliably-clean handoff.
    $tmpMd = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($tmpMd, $md, $utf8)
        $ErrorActionPreference = "Continue"
        $renderedHtml = Get-Content -Raw -Encoding UTF8 $tmpMd | & node $renderScript 2>&1
        $nodeExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($nodeExit -ne 0) {
            throw "render-readme.js failed (exit $nodeExit): $renderedHtml"
        }
    } finally {
        Remove-Item -Path $tmpMd -Force -ErrorAction SilentlyContinue
    }

    # 3. Build the Open button. Suppressed when homepageUrl points at
    #    mindattic.com itself -- those URLs were the legacy per-repo landing
    #    pages (e.g. https://mindattic.com/tutor/), now replaced by THIS file.
    #    Keep the button only for genuine external live demos (e.g. a deployed
    #    Blazor app on azurewebsites.net). To re-enable the button for a repo,
    #    update its homepageUrl on GitHub to the real external URL.
    $openButtonHtml = ''
    if (-not [string]::IsNullOrWhiteSpace($repo.homepageUrl) -and
        $repo.homepageUrl -notmatch '^https?://(www\.)?mindattic\.com(/|$)') {
        $openButtonHtml = $openButtonTemplate.Replace('__OPEN_URL__', $repo.homepageUrl)
    }

    # 4. Substitute placeholders.
    $taglineAttr = ConvertTo-HtmlAttr $repo.description
    $taglineHtml = ConvertTo-HtmlAttr $repo.description  # same escaping rules suffice for inside <p>

    $page = $template
    $page = $page.Replace('__PROJECT_NAME__', $s.RepoName)
    $page = $page.Replace('__SLUG__',         $s.Slug)
    $page = $page.Replace('__TAGLINE_ATTR__', $taglineAttr)
    $page = $page.Replace('__TAGLINE_HTML__', $taglineHtml)
    $page = $page.Replace('__OWNER__',        $Owner)
    $page = $page.Replace('__OPEN_BUTTON__',  $openButtonHtml)
    $page = $page.Replace('__README_CONTENT__', $renderedHtml.TrimEnd())

    # 5. Write the file (overwrites previous run end-to-end -- no incremental
    #    splice for the README body, sync-landing-page.ps1 fills the four
    #    component blocks below).
    $outPath = Join-Path $OutputRoot ("{0}.htm" -f $s.Slug)
    [System.IO.File]::WriteAllText($outPath, $page, $utf8)

    # 6. Splice MindAttic.UIUX blocks (OutfitFont, AtticFont, Cyberspace,
    #    BackHomeM) using the existing sync. -TargetIndex redirects output to
    #    the central root path instead of the subscriber's recorded target.
    $ErrorActionPreference = "Continue"
    $syncOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript -Subscriber $s.Subscriber -TargetIndex $outPath 2>&1
    $syncExit = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    if ($syncExit -ne 0) {
        Write-Host ("  Component sync failed (exit {0}):" -f $syncExit) -ForegroundColor Red
        $syncOut | ForEach-Object { Write-Host ("    {0}" -f $_) -ForegroundColor Red }
        $failed.Add($s.RepoName + " (component sync failed)")
        continue
    }

    $sizeKb = [math]::Round((Get-Item $outPath).Length / 1024, 1)
    Write-Host ("  [OK] {0}.htm ({1} KB)" -f $s.Slug, $sizeKb) -ForegroundColor Green
    $built++
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host ("Built {0} landing page(s)." -f $built) -ForegroundColor Green
if ($failed.Count -gt 0) {
    Write-Host ("Failed: {0}" -f $failed.Count) -ForegroundColor Yellow
    foreach ($f in $failed) { Write-Host ("  - {0}" -f $f) -ForegroundColor Yellow }
    exit 1
}
exit 0
