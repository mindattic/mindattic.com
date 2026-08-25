# fetch-descriptions.ps1 - regenerate data/software.json, data/ecosystem.json
# and data/hardware.json from EVERY public mindattic repo on GitHub (no
# visibility gate -- being public is the only opt-in), partitioned by GitHub
# topic / repo-name prefix into the right section. Also refreshes
# data/books.json synopses from Amazon.
#
# Source of truth: GitHub repo topics + descriptions.
#   - Topic 'hardware'         -> data/hardware.json
#   - Name matches 'MindAttic.*' (and not 'hardware') -> data/ecosystem.json
#   - Everything else public   -> data/software.json
#   The 'software'/'hardware' topics no longer gate visibility -- they (and
#   the MindAttic.* name prefix) only decide which section a repo lands in.
#
# index.htm holds a static, empty placeholder per section
# (<div class="home-sections" data-catalog="software"></div>, etc.) and is
# never touched by this script. At runtime index.htm's own JS fetches
# data/<catalog>.json and renders the tiles client-side (mountCatalog() /
# buildBoardSection()) -- see index.htm section 12 (SCRIPTS).
#
# The <h2>MindAttic Ecosystem</h2> heading carries a hand-authored flow
# diagram (an inline SVG between <!-- BEGIN/END ECOSYSTEM-DIAGRAM --> markers)
# directly in index.htm, untouched by this script. Edit diagram/ecosystem.mmd
# + run diagram/render.ps1 to change it -- never hand-edit the inlined SVG.
#
# To hide a repo:       make it private. It disappears on the next
#                       /fetch (or /deploy).
# To move a repo between Software/Hardware: add/remove the 'hardware' topic
#                       (gh repo edit mindattic/<name> --add-topic hardware).
# To refresh the site:  run /fetch (or /deploy, which calls this first).
#
# Descriptions: a repo with an empty/whitespace-only GitHub description gets
# a generic fallback client-side ("Repository on GitHub -- see source for
# details.") -- this script does NOT write descriptions back to GitHub on
# its own. -ListUntagged reports public repos missing both the
# 'software'/'hardware' topic (informational -- they still show, just with
# no explicit section signal beyond their name). -ProposeDescriptions
# reports a README-derived candidate description per thin repo, for you to
# review before applying with -ApplyDescriptions (which calls
# `gh repo edit --description`) -- see docs/BIBLE.md LAW-3.
#
# What a plain (no-flag) run does:
#   1. gh repo list mindattic --visibility public --json name,description,homepageUrl,repositoryTopics
#   2. Filter out the site repo itself (mindattic.com).
#   3. Sort by name, case-insensitive.
#   4. Build a tile object per repo (id, name, description, githubUrl,
#      openUrl, openInternal, previewImage, dataRepo, topics).
#   5. Write data/software.json, data/ecosystem.json, data/hardware.json.
#      Every public repo appears; newly-private repos disappear;
#      descriptions and live-demo URLs are refreshed.
#   6. Refresh data/books.json synopses from Amazon (matched by ASIN).
#
# Tile ids are derived deterministically from repo names: lowercase + strip
# non-alphanumeric, prefixed with "sd-" (software/ecosystem) or "hw-"
# (hardware). So MindAttic.Legion -> sd-mindatticlegion. Stable as long as
# the repo name is stable.
#
# Exit code 0 on success or graceful no-op (gh missing / not authed).
# Non-zero only on unexpected errors.
#
# Source is kept ASCII-only so Windows PowerShell 5.1 (which reads
# .ps1 files as Windows-1252 unless a UTF-8 BOM is present) parses
# it correctly. Unicode glyphs are built via [char] casts at runtime.

param (
    [string]$IndexFile = "$PSScriptRoot\index.htm",
    [string]$DataDir = "$PSScriptRoot\data",
    [string]$Owner = "mindattic",
    [switch]$ListUntagged,
    [switch]$ProposeDescriptions,
    [string[]]$ApplyDescriptions
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# gh emits UTF-8. Without these, PS 5.1 captures its stdout as
# Windows-1252 and any em-dash etc. gets mangled before we ever
# write it back to disk.
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$EM_DASH = [char]0x2014

if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir | Out-Null
}

# ---------------------------------------------------------------------------
# Pre-checks
# ---------------------------------------------------------------------------
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
# -ApplyDescriptions: write approved descriptions back to GitHub, then fall
# through to a normal run so the freshly-written text flows into the JSON.
# ---------------------------------------------------------------------------
if ($ApplyDescriptions -and $ApplyDescriptions.Count -gt 0) {
    Write-Host "Applying approved descriptions..." -ForegroundColor Cyan
    foreach ($entry in $ApplyDescriptions) {
        $idx = $entry.IndexOf('=')
        if ($idx -lt 1) {
            Write-Host ("  SKIP (expected repo=description): {0}" -f $entry) -ForegroundColor Yellow
            continue
        }
        $repoName = $entry.Substring(0, $idx)
        $desc = $entry.Substring($idx + 1)
        Write-Host ("  gh repo edit {0}/{1} --description ..." -f $Owner, $repoName) -ForegroundColor DarkGray
        & gh repo edit "$Owner/$repoName" --description $desc
        if ($LASTEXITCODE -ne 0) {
            Write-Error ("Failed to update description for {0}" -f $repoName)
        }
    }
    Write-Host "Descriptions applied. Continuing with a normal regenerate..." -ForegroundColor Green
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


# Every public repo gets a tile -- there is no visibility gate. Topic /
# name only decide which JSON file (section) a repo lands in:
#   - 'hardware' topic          -> data/hardware.json
#   - name matches 'MindAttic.*' (and not 'hardware')
#                                -> data/ecosystem.json
#   - everything else           -> data/software.json
# Both software/ecosystem use the sd- id prefix (ids are derived from the
# repo name, so they stay unique across the two files).
$hardwareRepos = @($allRepos | Where-Object { Test-HasTopic -Repo $_ -Topic 'hardware' } |
    Sort-Object @{Expression={$_.name.ToLowerInvariant()}})
$nonHardwareRepos = @($allRepos | Where-Object { -not (Test-HasTopic -Repo $_ -Topic 'hardware') })
$ecosystemRepos = @($nonHardwareRepos | Where-Object { $_.name -match '^MindAttic\.' } |
    Sort-Object @{Expression={$_.name.ToLowerInvariant()}})
$softwareRepos  = @($nonHardwareRepos | Where-Object { $_.name -notmatch '^MindAttic\.' } |
    Sort-Object @{Expression={$_.name.ToLowerInvariant()}})

# Informational only (kept for -ListUntagged): repos with neither topic
# still appear (in Software or Ecosystem by name), this just flags which
# ones have no explicit software/hardware signal on GitHub.
$untagged = @($allRepos | Where-Object {
    -not (Test-HasTopic -Repo $_ -Topic 'software') -and
    -not (Test-HasTopic -Repo $_ -Topic 'hardware')
})

Write-Host ("Software: {0} repo(s) | MindAttic Ecosystem: {1} repo(s) | Hardware: {2} repo(s) | Untopic'd (still shown): {3}" -f `
    $softwareRepos.Count, $ecosystemRepos.Count, $hardwareRepos.Count, $untagged.Count) -ForegroundColor Cyan

if ($ListUntagged) {
    Write-Host ""
    Write-Host "Public repos missing both the 'software' and 'hardware' topic:" -ForegroundColor Cyan
    if ($untagged.Count -eq 0) {
        Write-Host "  (none)" -ForegroundColor DarkGray
    } else {
        foreach ($u in $untagged) {
            $descLen = if ($u.description) { $u.description.Length } else { 0 }
            Write-Host ("  {0,-32} {1,4} chars desc" -f $u.name, $descLen) -ForegroundColor DarkGray
        }
    }
    exit 0
}

# ---------------------------------------------------------------------------
# -ProposeDescriptions: for every tagged repo with an empty/whitespace
# description, pull its README and print a candidate. Prints only -- never
# writes. Review candidates, then re-run with -ApplyDescriptions
# "repo=text",... once approved.
# ---------------------------------------------------------------------------
if ($ProposeDescriptions) {
    $thin = @($softwareRepos + $ecosystemRepos + $hardwareRepos | Where-Object {
        [string]::IsNullOrWhiteSpace($_.description)
    })
    Write-Host ""
    Write-Host ("Thin/missing descriptions: {0} repo(s)" -f $thin.Count) -ForegroundColor Cyan
    foreach ($r in $thin) {
        Write-Host ""
        Write-Host ("=== {0} ===" -f $r.name) -ForegroundColor Yellow
        $ErrorActionPreference = "Continue"
        $readme = & gh api "repos/$Owner/$($r.name)/readme" --jq ".content" 2>$null
        $ErrorActionPreference = "Stop"
        if ([string]::IsNullOrWhiteSpace($readme)) {
            Write-Host "  (no README found -- no candidate)" -ForegroundColor DarkGray
            continue
        }
        try {
            $bytes = [Convert]::FromBase64String(($readme -replace '\s', ''))
            $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        } catch {
            Write-Host "  (README content not decodable -- draft manually)" -ForegroundColor DarkGray
            continue
        }
        # Print the first non-empty, non-heading, non-badge line as a hint --
        # a human (or the assistant running this) drafts the real candidate
        # by reading the README; this is a starting point, not an oracle.
        $firstLine = ($text -split "`n" | Where-Object {
            $_.Trim() -and $_.Trim() -notmatch '^#' -and $_.Trim() -notmatch '^\[!\[' -and $_.Trim() -notmatch '^!\['
        } | Select-Object -First 1)
        if ($firstLine) {
            Write-Host ("  README hint: {0}" -f $firstLine.Trim())
        } else {
            Write-Host "  (README has no plain-text lead paragraph -- draft manually)" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
    Write-Host "Review candidates above, then re-run:" -ForegroundColor Cyan
    Write-Host '  ./fetch-descriptions.ps1 -ApplyDescriptions "Repo=New description text", ...' -ForegroundColor DarkGray
    exit 0
}

# ---------------------------------------------------------------------------
# Landing-page manifest (from MindAttic.Deploy/projects.json) is the single
# source of truth for the "Open" URL of each card. MindAttic.Deploy renders
# every projects[] entry to /mindattic.com/<slug>.htm at the site root, so a
# repo listed there gets that deterministic /<slug>.htm URL -- UNLESS the entry
# carries an `openUrl` (an external app like Prose / Cursory on Azure),
# in which case the card links straight to that app. Repos NOT in projects.json
# (or untracked here) fall back to GitHub's homepageUrl.
# ---------------------------------------------------------------------------
$script:landingRepos = @{}
$projectsPath = Join-Path $PSScriptRoot "..\MindAttic.Deploy\projects.json"
if (Test-Path $projectsPath) {
    $projCfg = Get-Content -Raw -Path $projectsPath -Encoding UTF8 | ConvertFrom-Json
    foreach ($p in $projCfg.projects) {
        if (-not $p.repo -or -not $p.slug) { continue }
        $openUrl = if ($p.PSObject.Properties.Name -contains 'openUrl') { $p.openUrl } else { $null }
        $script:landingRepos[$p.repo] = [pscustomobject]@{ Slug = $p.slug; OpenUrl = $openUrl }
    }
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a stable HTML element id from a repo name. Prefix distinguishes
# sections: sd- for Software/Ecosystem, hw- for Hardware.
function Get-TileId {
    param([string]$Name, [string]$Prefix = 'sd')
    $n = $Name.ToLowerInvariant() -replace '[^a-z0-9]', ''
    return "$Prefix-$n"
}

# Per-repo preview images. Tiles default to a generated SVG client-side, but
# a repo can supply a real preview by dropping a sidecar at
# previews\<repo-name>.b64 whose contents are a full data: URL (e.g.
# "data:image/jpeg;base64,..."). Filenames match the GitHub repo name exactly
# (case-sensitive on the lookup key), so "Mosaic" -> previews\Mosaic.b64 and
# "mindatticcares.com" -> previews\mindatticcares.com.b64. These sidecars are
# build-time inputs only; their base64 is inlined into the JSON here, so the
# deployed site stays free of extra image requests.
$script:PreviewDir = Join-Path $PSScriptRoot "previews"

function Get-PreviewDataUrl {
    param([string]$RepoName)
    if (-not (Test-Path $script:PreviewDir)) { return $null }
    $f = Join-Path $script:PreviewDir ($RepoName + ".b64")
    if (-not (Test-Path $f)) { return $null }
    $data = (Get-Content -Raw -Path $f -Encoding UTF8).Trim()
    if ([string]::IsNullOrWhiteSpace($data)) { return $null }
    return $data
}

# Build the catalog object for one repo tile.
function New-TileObject {
    param($Repo, [string]$Owner, [string]$Prefix = 'sd')

    $name = $Repo.name
    $id = Get-TileId -Name $name -Prefix $Prefix
    $ghUrl = "https://github.com/$Owner/$name"

    $desc = if ([string]::IsNullOrWhiteSpace($Repo.description)) { '' } else { $Repo.description }

    # Projects in MindAttic.Deploy/projects.json get their canonical URL: the
    # entry's external `openUrl` if present, else the deterministic
    # /<slug>.htm at the mindattic.com root. Repos outside the manifest fall
    # back to GitHub's homepageUrl. Repos with neither get no Open button.
    # Internal landing pages (mindattic.com/<slug>.htm) each carry a BackHomeM
    # button, so their Open link navigates in the SAME window; external apps
    # (openUrl) and third-party homepages open in a new tab.
    $openUrl = $null
    $openInternal = $false
    if ($script:landingRepos.ContainsKey($name)) {
        $entry = $script:landingRepos[$name]
        if (-not [string]::IsNullOrWhiteSpace($entry.OpenUrl)) {
            $openUrl = $entry.OpenUrl
        } else {
            $openUrl = "https://mindattic.com/$($entry.Slug).htm"
            $openInternal = $true
        }
    } elseif (-not [string]::IsNullOrWhiteSpace($Repo.homepageUrl)) {
        $openUrl = $Repo.homepageUrl
    }

    $topics = @()
    if ($Repo.repositoryTopics) {
        $topics = @($Repo.repositoryTopics | ForEach-Object { $_.name })
    }

    return [pscustomobject]@{
        id            = $id
        name          = $name
        description   = $desc
        githubUrl     = $ghUrl
        openUrl       = $openUrl
        openInternal  = $openInternal
        previewImage  = (Get-PreviewDataUrl -RepoName $name)
        dataRepo      = "$Owner/$name"
        topics        = $topics
    }
}

function Write-CatalogJson {
    param([string]$Path, [object[]]$Items)
    $json = ConvertTo-Json -InputObject @($Items) -Depth 6
    [System.IO.File]::WriteAllText($Path, $json + "`n", [System.Text.UTF8Encoding]::new($false))
}

# ---------------------------------------------------------------------------
# Amazon book synopsis scraper
# ---------------------------------------------------------------------------
# For each entry in data/books.json, fetch its Amazon product page and
# extract the synopsis from div[name="book_description_expander"] > div > p
# > span. Trim the trailing "Read more" Amazon appends, normalize whitespace,
# then write the result back into that entry's synopsis field.

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
    $synopsis = ($synopsis -replace '\s+', ' ').Trim()

    return $synopsis
}

function Update-BookSynopses {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Host "  data/books.json not found - skipping synopsis refresh." -ForegroundColor DarkGray
        return
    }
    $books = @(Get-Content -Raw -Path $Path -Encoding UTF8 | ConvertFrom-Json)
    if ($books.Count -eq 0) {
        Write-Host "  data/books.json is empty - skipping synopsis refresh." -ForegroundColor DarkGray
        return
    }
    # Defensive: a malformed read (partial write races, bad JSON) must never
    # propagate into a write that clobbers the file with fewer/garbage
    # entries. Every real entry has a title; abort loudly instead of risking
    # data loss if that's not true.
    $malformed = @($books | Where-Object { -not ($_.PSObject.Properties.Name -contains 'title') -or [string]::IsNullOrWhiteSpace($_.title) })
    if ($malformed.Count -gt 0) {
        # Non-fatal: this must not abort the whole script (repo-tile JSON
        # generation below is independent of book synopses).
        Write-Warning "  Refusing to refresh synopses: $Path parsed into $($books.Count) entrie(s) but $($malformed.Count) are malformed (missing title). Not writing."
        return
    }

    Write-Host ""
    Write-Host "Refreshing Amazon book synopses..." -ForegroundColor Cyan

    $changed = $false
    foreach ($b in $books) {
        if (-not $b.amazonUrl) { continue }
        $syn = Get-AmazonSynopsis -Url $b.amazonUrl
        if ($syn) {
            if ($b.synopsis -ne $syn) { $changed = $true }
            $b.synopsis = $syn
            Write-Host ("  [OK]   {0,-42} {1,4} chars" -f $b.title, $syn.Length) -ForegroundColor DarkGray
        } else {
            Write-Host ("  [MISS] {0}" -f $b.title) -ForegroundColor Yellow
        }
        # Be polite to Amazon and avoid the rate-limit/blocked-stub response
        # that hits the second-or-third request when bursting too fast.
        Start-Sleep -Milliseconds 1500
    }

    if (-not $changed) {
        Write-Host "  Synopses already up to date." -ForegroundColor DarkGray
        return
    }

    Write-CatalogJson -Path $Path -Items $books
    Write-Host ("Updated synopses in {0}." -f $Path) -ForegroundColor Green
}

Update-BookSynopses -Path (Join-Path $DataDir "books.json")

# ---------------------------------------------------------------------------
# Write catalog JSON files
# ---------------------------------------------------------------------------
$softwareItems  = @($softwareRepos  | ForEach-Object { New-TileObject -Repo $_ -Owner $Owner -Prefix 'sd' })
$ecosystemItems = @($ecosystemRepos | ForEach-Object { New-TileObject -Repo $_ -Owner $Owner -Prefix 'sd' })
$hardwareItems  = @($hardwareRepos  | ForEach-Object { New-TileObject -Repo $_ -Owner $Owner -Prefix 'hw' })

Write-CatalogJson -Path (Join-Path $DataDir "software.json")  -Items $softwareItems
Write-CatalogJson -Path (Join-Path $DataDir "ecosystem.json") -Items $ecosystemItems
Write-CatalogJson -Path (Join-Path $DataDir "hardware.json")  -Items $hardwareItems

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
function Write-RepoReport {
    param([string]$Title, [object[]]$Items)
    Write-Host ""
    Write-Host ("Wrote {0} tile(s) [{1}]:" -f $Items.Count, $Title) -ForegroundColor Green
    foreach ($it in $Items) {
        $mark = if ($it.openUrl) { '*' } else { ' ' }
        Write-Host ("  [$mark] {0,-32} {1,4} chars desc" -f $it.name, $it.description.Length) -ForegroundColor DarkGray
    }
}
Write-RepoReport -Title 'Software' -Items $softwareItems
Write-RepoReport -Title 'MindAttic Ecosystem' -Items $ecosystemItems
Write-RepoReport -Title 'Hardware' -Items $hardwareItems
Write-Host ""
Write-Host "* = has Open button (projects.json landing page or homepage URL)" -ForegroundColor DarkGray
exit 0
