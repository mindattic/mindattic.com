# fetch-descriptions.ps1 - regenerate the Software AND Hardware board-grids
# on index.htm from public mindattic repos, partitioned by GitHub topic.
#
# Source of truth: GitHub repo topics + descriptions.
#   - Topic 'software' -> goes in <h2>Software</h2> grid (tile ids prefixed sd-)
#   - Topic 'hardware' -> goes in <h2>Hardware</h2> grid (tile ids prefixed hw-)
#   - Public repos with neither topic are NOT shown on the homepage.
#
# To feature a repo:    make it public, set a description (and optionally
#                       a homepage URL for the "Open" button), and add the
#                       'software' or 'hardware' topic:
#                         gh repo edit mindattic/<name> --add-topic software
# To hide a repo:       remove the topic, or make it private.
# To refresh the site:  run /fetch (or /deploy, which calls this first).
#
# What this script does:
#   1. gh repo list mindattic --visibility public --json name,description,homepageUrl
#   2. Filter out the site repo itself (mindattic.com).
#   3. Sort by name, case-insensitive.
#   4. Build a <button> + <div class="tabPage"> block per repo,
#      using the current tile structure (image placeholder left,
#      description right, button row below).
#   5. Replace the entire <div class="board-grid">...</div> block in
#      index.htm in one pass. New public repos appear; newly-private
#      repos disappear; descriptions and live-demo URLs are refreshed.
#   6. For each entry in BOOK_AMAZON_URLS, fetch the Amazon product page
#      and refresh the matching BOOK_SYNOPSES entry from the
#      div[name="book_description_expander"] span text. Amazon is the
#      source of truth for Writing-section synopses.
#
# Tile element ids are derived deterministically from repo names:
# lowercase + strip non-alphanumeric, prefixed with "sd-". So
# MindAttic.Legion -> sd-mindatticlegion. Stable as long as the repo
# name is stable.
#
# Exit code 0 on success or graceful no-op (gh missing / not authed).
# Non-zero only on unexpected errors.
#
# Source is kept ASCII-only so Windows PowerShell 5.1 (which reads
# .ps1 files as Windows-1252 unless a UTF-8 BOM is present) parses
# it correctly. Unicode glyphs are built via [char] casts at runtime.

param (
    [string]$IndexFile = "$PSScriptRoot\index.htm",
    [string]$Owner = "mindattic"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# gh emits UTF-8. Without these, PS 5.1 captures its stdout as
# Windows-1252 and any em-dash etc. gets mangled before we ever
# write it back to disk.
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$EM_DASH = [char]0x2014

# ---------------------------------------------------------------------------
# Pre-checks
# ---------------------------------------------------------------------------
if (-not (Test-Path $IndexFile)) {
    Write-Error "index.htm not found at: $IndexFile"
    exit 1
}

$ghAvailable = $true
try {
    & gh --version 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) { $ghAvailable = $false }
} catch {
    $ghAvailable = $false
}

if (-not $ghAvailable) {
    Write-Host "gh CLI not available - skipping regenerate." -ForegroundColor Yellow
    exit 0
}

try {
    & gh auth status 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "gh CLI not authenticated - skipping regenerate." -ForegroundColor Yellow
        Write-Host "Run: gh auth login" -ForegroundColor Yellow
        exit 0
    }
} catch {
    Write-Host "gh CLI auth check failed - skipping regenerate." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------------------------
# Fetch public repos from GitHub
# ---------------------------------------------------------------------------
Write-Host "Fetching public $Owner repos..." -ForegroundColor Cyan

$ErrorActionPreference = "Continue"
$json = & gh repo list $Owner --visibility public --limit 100 --json name,description,homepageUrl,repositoryTopics 2>$null
$listExit = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($listExit -ne 0 -or [string]::IsNullOrWhiteSpace($json)) {
    Write-Error "gh repo list failed (exit $listExit)."
    exit 1
}

$allRepos = $json | ConvertFrom-Json

# Skip the site repo itself (it shouldn't be a tile on its own homepage).
$selfRepo = "$Owner.com"
$allRepos = @($allRepos | Where-Object { $_.name -ne $selfRepo })

# Partition by repo topic. Repos with neither 'software' nor 'hardware' do
# not appear on the homepage at all - tagging is the opt-in.
function Test-HasTopic {
    param($Repo, [string]$Topic)
    if (-not $Repo.repositoryTopics) { return $false }
    foreach ($t in $Repo.repositoryTopics) {
        if ($t.name -and $t.name.ToLowerInvariant() -eq $Topic) { return $true }
    }
    return $false
}

$softwareRepos = @($allRepos | Where-Object { Test-HasTopic -Repo $_ -Topic 'software' } |
    Sort-Object @{Expression={$_.name.ToLowerInvariant()}})
$hardwareRepos = @($allRepos | Where-Object { Test-HasTopic -Repo $_ -Topic 'hardware' } |
    Sort-Object @{Expression={$_.name.ToLowerInvariant()}})

$untagged = @($allRepos | Where-Object {
    -not (Test-HasTopic -Repo $_ -Topic 'software') -and
    -not (Test-HasTopic -Repo $_ -Topic 'hardware')
})

Write-Host ("Software: {0} repo(s) | Hardware: {1} repo(s) | Untagged (not shown): {2}" -f `
    $softwareRepos.Count, $hardwareRepos.Count, $untagged.Count) -ForegroundColor Cyan
if ($untagged.Count -gt 0) {
    foreach ($u in $untagged) { Write-Host ("  (skip) {0}" -f $u.name) -ForegroundColor DarkGray }
}

# ---------------------------------------------------------------------------
# Landing-page subscribers (from MindAttic.UiUx/subscribers.json) get a
# deterministic /<slug>.htm URL on mindattic.com root. Repos outside that set
# fall back to GitHub's homepageUrl (external live demos like StreetSamurai).
# Repo names are derived from each subscriber's target-path parent folder so a
# subscriber whose logical name diverges from its repo (rare, but possible)
# still resolves correctly.
# ---------------------------------------------------------------------------
$script:landingRepos = @{}
$subscribersPath = Join-Path $PSScriptRoot "..\MindAttic.UiUx\subscribers.json"
if (Test-Path $subscribersPath) {
    $subCfg = Get-Content -Raw -Path $subscribersPath -Encoding UTF8 | ConvertFrom-Json
    foreach ($prop in $subCfg.subscribers.PSObject.Properties) {
        if ($prop.Value.kind -eq 'landing-page') {
            $repoName = Split-Path -Leaf (Split-Path -Parent $prop.Value.target)
            $script:landingRepos[$repoName] = $true
        }
    }
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# HTML-escape: <, >, & to entities. Other characters (em-dashes, quotes,
# Unicode) pass through as literal UTF-8.
function ConvertTo-HtmlText {
    param([string]$Text)
    $t = $Text -replace '&', '&amp;'
    $t = $t -replace '<', '&lt;'
    $t = $t -replace '>', '&gt;'
    return $t
}

# Build a stable HTML element id from a repo name. Prefix distinguishes
# sections: sd- for Software, hw- for Hardware.
function Get-TileId {
    param([string]$Name, [string]$Prefix = 'sd')
    $n = $Name.ToLowerInvariant() -replace '[^a-z0-9]', ''
    return "$Prefix-$n"
}

# Build the markup for one tile (button + toggleable desc panel).
function New-TileHtml {
    param($Repo, [string]$Owner, [string]$Nl, [string]$Prefix = 'sd')

    $name = $Repo.name
    $id = Get-TileId -Name $name -Prefix $Prefix
    $ghUrl = "https://github.com/$Owner/$name"

    $desc = $Repo.description
    if ([string]::IsNullOrWhiteSpace($desc)) {
        $descHtml = "Repository on GitHub $EM_DASH see source for details."
    } else {
        $descHtml = ConvertTo-HtmlText $desc
    }

    # Landing-page subscribers get a deterministic /<slug>.htm URL on
    # mindattic.com root; others fall back to GitHub's homepageUrl. Repos
    # with neither get no Open button.
    $liveUrl = $null
    if ($script:landingRepos.ContainsKey($name)) {
        $liveUrl = "https://mindattic.com/" + ($name.ToLowerInvariant() -replace '[^a-z0-9]', '') + ".htm"
    } elseif (-not [string]::IsNullOrWhiteSpace($Repo.homepageUrl)) {
        $liveUrl = $Repo.homepageUrl
    }

    $liveAttr = ''
    $liveBtn = ''
    if ($liveUrl) {
        $liveAttr = " data-live=`"$liveUrl`""
        $liveBtn = "            <a class=`"tabButton-btn`" href=`"$liveUrl`" target=`"_blank`" rel=`"noopener noreferrer`">Open</a>$Nl"
    }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append("        <button type=`"button`" class=`"tabButton`" data-target=`"$id`">$Nl")
    [void]$sb.Append("          <div class=`"tabButton-name`">$name</div>$Nl")
    [void]$sb.Append("        </button>$Nl")
    [void]$sb.Append("        <div class=`"tabPage`" id=`"$id`" data-repo=`"$Owner/$name`"$liveAttr>$Nl")
    [void]$sb.Append("          <div class=`"tabPage-row`">$Nl")
    [void]$sb.Append("            <div class=`"tabPage-img tabPage-img--placeholder`" aria-hidden=`"true`"></div>$Nl")
    [void]$sb.Append("            <div class=`"tabPage-body`">$Nl")
    [void]$sb.Append("              <p class=`"tabPage-text`">$descHtml</p>$Nl")
    [void]$sb.Append("            </div>$Nl")
    [void]$sb.Append("          </div>$Nl")
    [void]$sb.Append("          <div class=`"tabPage-links`">$Nl")
    if ($liveBtn) { [void]$sb.Append($liveBtn) }
    [void]$sb.Append("            <a class=`"tabButton-btn`" href=`"$ghUrl`" target=`"_blank`" rel=`"noopener noreferrer`">GitHub</a>$Nl")
    [void]$sb.Append("          </div>$Nl")
    [void]$sb.Append("        </div>$Nl")
    return $sb.ToString()
}

# ---------------------------------------------------------------------------
# Amazon book synopsis scraper
# ---------------------------------------------------------------------------
# For each entry in the BOOK_AMAZON_URLS map inside index.htm, fetch the
# Amazon product page and extract the synopsis from
#   div[name="book_description_expander"] > div > p > span
# Trim the trailing "Read more" Amazon appends, normalize whitespace, then
# write the result back into the corresponding BOOK_SYNOPSES entry. Other
# BOOK_SYNOPSES entries (e.g. visual-arts pieces) are left untouched.

function Get-AmazonSynopsis {
    param([string]$Url)

    $ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    $headers = @{
        'Accept-Language' = 'en-US,en;q=0.9'
        'Accept'          = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    }

    $ErrorActionPreference = "Continue"
    $response = $null
    try {
        $response = Invoke-WebRequest -Uri $Url -UserAgent $ua -Headers $headers `
            -MaximumRedirection 5 -TimeoutSec 30 -UseBasicParsing -ErrorAction Stop
    } catch {
        $ErrorActionPreference = "Stop"
        return ''
    }
    $ErrorActionPreference = "Stop"

    $html = $response.Content
    if ($html -notmatch '(?s)<div[^>]*name="book_description_expander"[^>]*>(.*?)</div>\s*</div>') {
        return ''
    }
    $block = $matches[1]

    $spans = [regex]::Matches($block, '(?s)<span[^>]*>(.*?)</span>')
    $parts = @()
    foreach ($sm in $spans) {
        $t = $sm.Groups[1].Value -replace '<[^>]+>', ' '
        $t = $t -replace '&nbsp;',  ' '
        $t = $t -replace '&#39;',   ([string][char]0x2019)
        $t = $t -replace '&rsquo;', ([string][char]0x2019)
        $t = $t -replace '&lsquo;', ([string][char]0x2018)
        $t = $t -replace '&ldquo;', ([string][char]0x201C)
        $t = $t -replace '&rdquo;', ([string][char]0x201D)
        $t = $t -replace '&mdash;', ([string]$EM_DASH)
        $t = $t -replace '&ndash;', ([string][char]0x2013)
        $t = $t -replace '&hellip;',([string][char]0x2026)
        $t = $t -replace '&quot;',  '"'
        $t = $t -replace '&amp;',   '&'
        $t = ($t -replace '\s+', ' ').Trim()
        if ($t) { $parts += $t }
    }
    $synopsis = ($parts -join ' ').Trim()

    # Amazon truncates the visible blurb with " Read more"; drop it.
    $synopsis = $synopsis -replace '\s*Read more\s*$', ''
    # <i>-tag artifacts leave a space before some commas/periods.
    $synopsis = $synopsis -replace ' +([,.;:!?])', '$1'
    # JS strings in BOOK_SYNOPSES are single-quoted; promote any straight
    # apostrophes to curly so they don't terminate the string literal.
    $synopsis = $synopsis -replace "'", ([string][char]0x2019)
    $synopsis = ($synopsis -replace '\s+', ' ').Trim()

    return $synopsis
}

function Update-BookSynopses {
    param([string]$IndexPath)

    $content = [System.IO.File]::ReadAllText($IndexPath, [System.Text.Encoding]::UTF8)

    if ($content -notmatch '(?s)var BOOK_AMAZON_URLS = \{(.+?)\};') {
        Write-Host "  BOOK_AMAZON_URLS not found - skipping synopsis refresh." -ForegroundColor DarkGray
        return
    }
    $entries = [regex]::Matches($matches[1], "(?s)'([^']+)':\s*'([^']+)'")
    if ($entries.Count -eq 0) {
        Write-Host "  BOOK_AMAZON_URLS is empty - skipping synopsis refresh." -ForegroundColor DarkGray
        return
    }

    Write-Host ""
    Write-Host "Refreshing Amazon book synopses..." -ForegroundColor Cyan

    $synopses = @{}
    foreach ($m in $entries) {
        $title = $m.Groups[1].Value
        $url   = $m.Groups[2].Value
        $syn   = Get-AmazonSynopsis -Url $url
        if ($syn) {
            $synopses[$title] = $syn
            Write-Host ("  [OK]   {0,-42} {1,4} chars" -f $title, $syn.Length) -ForegroundColor DarkGray
        } else {
            Write-Host ("  [MISS] {0}" -f $title) -ForegroundColor Yellow
        }
        # Be polite to Amazon and avoid the rate-limit/blocked-stub response
        # that hits the second-or-third request when bursting too fast.
        Start-Sleep -Milliseconds 1500
    }

    if ($synopses.Count -eq 0) {
        Write-Host "  No synopses scraped." -ForegroundColor Yellow
        return
    }

    # Patch each existing entry in BOOK_SYNOPSES. Other entries are preserved.
    $newContent = $content
    foreach ($title in $synopses.Keys) {
        $escTitle = [regex]::Escape($title)
        $entryRx  = [regex]::new("(?s)('$escTitle':\s*)'[^']*'")
        $newValue = "'" + $synopses[$title] + "'"
        $newContent = $entryRx.Replace($newContent, { param($x) $x.Groups[1].Value + $newValue }, 1)
    }

    if ($newContent -eq $content) {
        Write-Host "  Synopses already up to date." -ForegroundColor DarkGray
        return
    }

    [System.IO.File]::WriteAllText($IndexPath, $newContent, [System.Text.Encoding]::UTF8)
    Write-Host ("Updated {0} synopses in index.htm." -f $synopses.Count) -ForegroundColor Green
}

Update-BookSynopses -IndexPath $IndexFile

# ---------------------------------------------------------------------------
# Read index.htm and detect line endings
# ---------------------------------------------------------------------------
$content = [System.IO.File]::ReadAllText($IndexFile, [System.Text.Encoding]::UTF8)

# Match the file's existing line endings so we don't mix CRLF and LF.
if ($content.IndexOf("`r`n") -ge 0) {
    $nl = "`r`n"
} else {
    $nl = "`n"
}

# ---------------------------------------------------------------------------
# Build a `<div class="board-grid">...</div>` block from a repo list.
# ---------------------------------------------------------------------------
function New-GridHtml {
    param([object[]]$Repos, [string]$Owner, [string]$Nl, [string]$Prefix)
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append("      <div class=`"board-grid`">$Nl")
    $first = $true
    foreach ($r in $Repos) {
        if (-not $first) { [void]$sb.Append($Nl) }
        $first = $false
        [void]$sb.Append((New-TileHtml -Repo $r -Owner $Owner -Nl $Nl -Prefix $Prefix))
    }
    [void]$sb.Append("      </div>")
    return $sb.ToString()
}

# Replace the first `<div class="board-grid">...</div>` that appears AFTER
# the given <h2>...</h2> anchor. This lets us target Software vs. Hardware
# independently. Returns the new content (or original if no change/match).
function Update-SectionGrid {
    param([string]$Content, [string]$Heading, [string]$NewGrid)

    $escH = [regex]::Escape("<h2>$Heading</h2>")
    # (?s) dotall; capture the prefix (h2 + everything up to the grid open)
    # so we can reattach it verbatim in the replacement.
    $pattern = "(?s)($escH.*?)      <div class=`"board-grid`">.*?\r?\n      </div>(?=\r?\n    </div>)"
    $rx = [regex]::new($pattern)
    if (-not $rx.IsMatch($Content)) {
        Write-Host ("  WARNING: could not locate <h2>{0}</h2> + board-grid block." -f $Heading) -ForegroundColor Yellow
        return $Content
    }
    # MatchEvaluator so '$' in descriptions isn't treated as a backreference.
    return $rx.Replace($Content, { param($m) $m.Groups[1].Value + $NewGrid }, 1)
}

$softwareGrid = New-GridHtml -Repos $softwareRepos -Owner $Owner -Nl $nl -Prefix 'sd'
$hardwareGrid = New-GridHtml -Repos $hardwareRepos -Owner $Owner -Nl $nl -Prefix 'hw'

$newContent = $content
$newContent = Update-SectionGrid -Content $newContent -Heading 'Software' -NewGrid $softwareGrid
$newContent = Update-SectionGrid -Content $newContent -Heading 'Hardware' -NewGrid $hardwareGrid

if ($newContent -eq $content) {
    Write-Host "No changes needed - grids already up to date." -ForegroundColor DarkGray
    exit 0
}

[System.IO.File]::WriteAllText($IndexFile, $newContent, [System.Text.Encoding]::UTF8)

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
function Write-RepoReport {
    param([string]$Title, [object[]]$Repos)
    Write-Host ""
    Write-Host ("Regenerated {0} tile(s) [{1}]:" -f $Repos.Count, $Title) -ForegroundColor Green
    foreach ($r in $Repos) {
        if ([string]::IsNullOrWhiteSpace($r.homepageUrl)) { $mark = ' ' } else { $mark = '*' }
        if ($r.description) { $descLen = $r.description.Length } else { $descLen = 0 }
        Write-Host ("  [$mark] {0,-32} {1,4} chars desc" -f $r.name, $descLen) -ForegroundColor DarkGray
    }
}
Write-RepoReport -Title 'Software' -Repos $softwareRepos
Write-RepoReport -Title 'Hardware' -Repos $hardwareRepos
Write-Host ""
Write-Host "* = has homepage URL (Open button)" -ForegroundColor DarkGray
exit 0
