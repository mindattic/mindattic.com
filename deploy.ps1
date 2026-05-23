# deploy.ps1 — FTP deploy script
# Reads credentials from settings.json in the same directory.
# Uses curl.exe (built-in on Windows 10/11) for reliable FTPS support.

param (
    [string]$SettingsFile = "$PSScriptRoot\settings.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Load settings
# ---------------------------------------------------------------------------
if (-not (Test-Path $SettingsFile)) {
    Write-Error "settings.json not found at: $SettingsFile"
    exit 1
}

$cfg = Get-Content -Raw -Path $SettingsFile | ConvertFrom-Json

$ftpHost    = $cfg.FtpHost
$ftpPort    = $cfg.FtpPort
$ftpUser    = $cfg.FtpUsername
$ftpPass    = $cfg.FtpPassword
$remotePath = $cfg.FtpRemotePath.TrimEnd('/')
$useSsl     = [bool]$cfg.FtpUseSsl
$usePassive = [bool]$cfg.FtpPassive

# ---------------------------------------------------------------------------
# Pull latest MindAttic.UIUX from origin, then sync into index.htm.
# This step is MANDATORY -- MindAttic.UIUX is the canonical source for
# the inlined component bundles (Cyberspace, fonts, PinFooter, WebSnapshot).
# A silent skip here would let stale or broken content ship to production,
# so every failure mode is a hard error before any FTP upload happens.
# ---------------------------------------------------------------------------
$contentRoot = "$PSScriptRoot\..\MindAttic.UIUX"
$syncScript = "$contentRoot\sync\sync-mindattic-com.ps1"

if (-not (Test-Path "$contentRoot\.git")) {
    Write-Error "MindAttic.UIUX is not a git repo at $contentRoot. Clone https://github.com/mindattic/MindAttic.UIUX.git into that folder before re-running deploy."
    exit 1
}

Write-Host "Pulling MindAttic.UIUX..."
$ErrorActionPreference = "Continue"
$pullOut = & git -C $contentRoot pull --no-edit --no-rebase 2>&1
$pullExit = $LASTEXITCODE
$ErrorActionPreference = "Stop"
if ($pullExit -ne 0) {
    Write-Host $pullOut -ForegroundColor Red
    Write-Error "git pull on MindAttic.UIUX failed (exit $pullExit). Resolve the conflict / uncommitted changes and re-run deploy. Refusing to ship potentially stale components."
    exit 1
}

if (-not (Test-Path $syncScript)) {
    Write-Error "MindAttic.UIUX sync script not found at $syncScript. Cannot inline subscribed components without it."
    exit 1
}

Write-Host "Syncing MindAttic.UIUX front-page bundle..."
& powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript -TargetIndex "$PSScriptRoot\index.htm"
if ($LASTEXITCODE -ne 0) { Write-Error "MindAttic.UIUX sync failed."; exit 1 }

# ---------------------------------------------------------------------------
# Pull project tile descriptions from GitHub (best-effort)
# ---------------------------------------------------------------------------
$fetchScript = "$PSScriptRoot\fetch-descriptions.ps1"
if (Test-Path $fetchScript) {
    Write-Host "Fetching GitHub repo descriptions..."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $fetchScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Note: fetch-descriptions.ps1 exited $LASTEXITCODE (continuing)." -ForegroundColor Yellow
    }
} else {
    Write-Host "Note: fetch-descriptions.ps1 not found (skipping)."
}

# ---------------------------------------------------------------------------
# Regenerate per-project landing pages from each repo's README.md.
# Writes <slug>.htm files at mindattic.com root for every landing-page
# subscriber in MindAttic.UIUX/subscribers.json. The upload step
# below picks them up via the *.htm glob -- no per-page wiring needed.
# Failures here ARE a hard stop: shipping index.htm with Open buttons that
# point at /<slug>.htm pages we never built would leave the homepage with
# broken links.
# ---------------------------------------------------------------------------
$buildPagesScript = "$PSScriptRoot\build-project-pages.ps1"
if (Test-Path $buildPagesScript) {
    Write-Host "Building per-project landing pages..."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $buildPagesScript
    if ($LASTEXITCODE -ne 0) {
        Write-Error "build-project-pages.ps1 failed (exit $LASTEXITCODE). Aborting deploy so we don't ship index.htm with broken Open links."
        exit 1
    }
} else {
    Write-Host "Note: build-project-pages.ps1 not found (skipping per-project pages)."
}

# ---------------------------------------------------------------------------
# Stamp index.htm
# ---------------------------------------------------------------------------
$indexFile = "$PSScriptRoot\index.htm"
if (Test-Path $indexFile) {
    $date    = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $stamp   = "<!-- Last Updated: $date -->"
    $content = [System.IO.File]::ReadAllText($indexFile, [System.Text.Encoding]::UTF8)

    if ($content -match "(?s)^<!--\s*Last Updated:.*?-->(\r?\n)") {
        $content = $content -replace "(?s)^<!--\s*Last Updated:.*?-->(\r?\n)", "$stamp`$1"
    } else {
        $content = "$stamp`r`n$content"
    }

    [System.IO.File]::WriteAllText($indexFile, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Stamped: $date"
}

# ---------------------------------------------------------------------------
# Collect local files to deploy
# ---------------------------------------------------------------------------
$rootDir = $PSScriptRoot

$files = @(Get-ChildItem -Path $rootDir -Filter "*.htm" -File)

if ($files.Count -eq 0) {
    Write-Host "No files to deploy."
    exit 0
}

# ---------------------------------------------------------------------------
# Deploy via curl.exe
# ---------------------------------------------------------------------------
$curlArgs = @('--ftp-pasv', '--ftp-create-dirs', '--insecure')
if ($useSsl)     { $curlArgs += '--ssl-reqd' }
if (-not $usePassive) { $curlArgs = $curlArgs | Where-Object { $_ -ne '--ftp-pasv' } }

Write-Host ""
Write-Host "Deploying to $ftpHost$remotePath ..."
Write-Host ("-" * 60)

$success = 0
$failed  = 0

foreach ($file in $files) {
    $relative  = $file.FullName.Substring($rootDir.Length + 1).Replace('\', '/')
    $remoteUrl = "ftp://${ftpHost}:${ftpPort}${remotePath}/${relative}"

    $ErrorActionPreference = "Continue"
    $output = & curl.exe @curlArgs -u "${ftpUser}:${ftpPass}" -T $file.FullName $remoteUrl 2>&1
    $ErrorActionPreference = "Stop"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] $relative  ($($file.Length) bytes)"
        $success++
    } else {
        Write-Host "  [FAIL] $relative  - exit $LASTEXITCODE : $output" -ForegroundColor Red
        $failed++
    }
}

Write-Host ("-" * 60)
Write-Host "Done. $success uploaded, $failed failed."
Write-Host ""

if ($failed -gt 0) { exit 1 } else { exit 0 }
