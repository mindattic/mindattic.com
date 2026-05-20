# fetch-descriptions.ps1 - regenerate the Software Development board-grid
# from public mindattic repos.
#
# Source of truth: GitHub. Public visibility decides whether a repo
# appears on the site; description and homepage URL drive its content.
# To feature a repo:    make it public, set a description (and optionally
#                       a homepage URL for the Live Demo button).
# To hide a repo:       make it private.
# To refresh the site:  run /fetch (or /deploy, which calls this first).
#
# What this script does:
#   1. gh repo list mindattic --visibility public --json name,description,homepageUrl
#   2. Filter out the site repo itself (mindattic.com).
#   3. Sort by name, case-insensitive.
#   4. Build a <button> + <div class="board-tile-desc"> block per repo,
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
$json = & gh repo list $Owner --visibility public --limit 100 --json name,description,homepageUrl 2>$null
$listExit = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($listExit -ne 0 -or [string]::IsNullOrWhiteSpace($json)) {
    Write-Error "gh repo list failed (exit $listExit)."
    exit 1
}

$repos = $json | ConvertFrom-Json

# Skip the site repo itself (it shouldn't be a tile on its own homepage).
$selfRepo = "$Owner.com"
$repos = @($repos | Where-Object { $_.name -ne $selfRepo })

# Alphabetize case-insensitively.
$repos = @($repos | Sort-Object @{Expression={$_.name.ToLowerInvariant()}})

Write-Host "Found $($repos.Count) public repo(s) to include (excluding $selfRepo)." -ForegroundColor Cyan

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

# Build a stable HTML element id from a repo name.
function Get-TileId {
    param([string]$Name)
    $n = $Name.ToLowerInvariant() -replace '[^a-z0-9]', ''
    return "sd-$n"
}

# Build the markup for one tile (button + toggleable desc panel).
function New-TileHtml {
    param($Repo, [string]$Owner, [string]$Nl)

    $name = $Repo.name
    $id = Get-TileId $name
    $ghUrl = "https://github.com/$Owner/$name"

    $desc = $Repo.description
    if ([string]::IsNullOrWhiteSpace($desc)) {
        $descHtml = "Repository on GitHub $EM_DASH see source for details."
    } else {
        $descHtml = ConvertTo-HtmlText $desc
    }

    $liveAttr = ''
    $liveBtn = ''
    if (-not [string]::IsNullOrWhiteSpace($Repo.homepageUrl)) {
        $liveUrl = $Repo.homepageUrl
        $liveAttr = " data-live=`"$liveUrl`""
        $liveBtn = "            <a class=`"board-tile-btn`" href=`"$liveUrl`" target=`"_blank`" rel=`"noopener noreferrer`">Demo</a>$Nl"
    }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append("        <button type=`"button`" class=`"board-tile`" data-target=`"$id`">$Nl")
    [void]$sb.Append("          <div class=`"board-tile-name`">$name</div>$Nl")
    [void]$sb.Append("        </button>$Nl")
    [void]$sb.Append("        <div class=`"board-tile-desc`" id=`"$id`" data-repo=`"$Owner/$name`"$liveAttr>$Nl")
    [void]$sb.Append("          <div class=`"board-tile-desc-row`">$Nl")
    [void]$sb.Append("            <div class=`"board-tile-desc-img board-tile-desc-img--placeholder`" aria-hidden=`"true`"></div>$Nl")
    [void]$sb.Append("            <div class=`"board-tile-desc-body`">$Nl")
    [void]$sb.Append("              <p class=`"board-tile-desc-text`">$descHtml</p>$Nl")
    [void]$sb.Append("            </div>$Nl")
    [void]$sb.Append("          </div>$Nl")
    [void]$sb.Append("          <div class=`"board-tile-desc-links`">$Nl")
    if ($liveBtn) { [void]$sb.Append($liveBtn) }
    [void]$sb.Append("            <a class=`"board-tile-btn`" href=`"$ghUrl`" target=`"_blank`" rel=`"noopener noreferrer`">GitHub</a>$Nl")
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
# Build the new <div class="board-grid">...</div>
# ---------------------------------------------------------------------------
$gridSb = [System.Text.StringBuilder]::new()
[void]$gridSb.Append("      <div class=`"board-grid`">$nl")

$first = $true
foreach ($r in $repos) {
    if (-not $first) { [void]$gridSb.Append($nl) }
    $first = $false
    [void]$gridSb.Append((New-TileHtml -Repo $r -Owner $Owner -Nl $nl))
}

[void]$gridSb.Append("      </div>")
$newGrid = $gridSb.ToString()

# ---------------------------------------------------------------------------
# Replace the existing board-grid block in index.htm
# ---------------------------------------------------------------------------
# (?s)             dotall -- so .*? spans newlines
# Match from start `      <div class="board-grid">` up through the first
# `      </div>` that's followed by `    </div>` (the board-section close).
# That sequence uniquely identifies the grid-end among nested </div>s.
$pattern = '(?s)      <div class="board-grid">.*?\r?\n      </div>(?=\r?\n    </div>)'
$rx = [regex]::new($pattern)

if (-not $rx.IsMatch($content)) {
    Write-Error 'Could not locate <div class="board-grid">...</div> block in index.htm.'
    exit 1
}

# Use a MatchEvaluator so '$' characters in descriptions (e.g. "$0.01")
# are not interpreted as regex backreferences in the replacement.
$newContent = $rx.Replace($content, { param($m) $newGrid }, 1)

if ($newContent -eq $content) {
    Write-Host "No changes needed - grid already up to date." -ForegroundColor DarkGray
    exit 0
}

[System.IO.File]::WriteAllText($IndexFile, $newContent, [System.Text.Encoding]::UTF8)

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Regenerated $($repos.Count) tile(s):" -ForegroundColor Green
foreach ($r in $repos) {
    if ([string]::IsNullOrWhiteSpace($r.homepageUrl)) { $mark = ' ' } else { $mark = '*' }
    if ($r.description) { $descLen = $r.description.Length } else { $descLen = 0 }
    Write-Host ("  [$mark] {0,-32} {1,4} chars desc" -f $r.name, $descLen) -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "* = has homepage URL (Live Demo button)" -ForegroundColor DarkGray
exit 0
