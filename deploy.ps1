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

$files = @(Get-Item -Path "$rootDir\index.htm")

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
