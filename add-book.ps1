# add-book.ps1 — Convert an Amazon book page into a base64-embedded book
# cover entry appended to data/books.json.
#
# Usage:
#   powershell -File add-book.ps1 https://www.amazon.com/dp/B0XXXXXXXX
#   add-book.bat https://www.amazon.com/dp/B0XXXXXXXX
#
# Synopsis is left empty; run fetch-descriptions.ps1 afterward to fill it in
# from the book's Amazon page (Update-BookSynopses).

param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AmazonUrl,

    [string]$DataDir = "$PSScriptRoot\data"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$booksPath = Join-Path $DataDir "books.json"
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir | Out-Null
}

# ---------------------------------------------------------------------------
# 1. Fetch Amazon page (browser UA required to avoid 503 / blocked)
# ---------------------------------------------------------------------------
Write-Host "Fetching: $AmazonUrl"
$headers = @{
    'User-Agent'      = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
    'Accept-Language' = 'en-US,en;q=0.9'
}
$resp = Invoke-WebRequest -Uri $AmazonUrl -Headers $headers -UseBasicParsing
$html = $resp.Content

# ---------------------------------------------------------------------------
# 2. Extract title and hi-res cover URL
# ---------------------------------------------------------------------------
if ($html -notmatch 'id="productTitle"[^>]*>([^<]+)<') {
    Write-Error "Could not extract product title"
    exit 1
}
$title = $matches[1].Trim()
Write-Host "Title: $title"

if ($html -notmatch '"hiRes":"([^"]+)"') {
    Write-Error "Could not extract cover image URL"
    exit 1
}
$hiResUrl = $matches[1]
# Prefer the smaller _SL300_ variant; fall back to original if pattern absent
$coverUrl = $hiResUrl -replace '_SL\d+_', '_SL300_'
Write-Host "Cover URL: $coverUrl"

# ---------------------------------------------------------------------------
# 3. Extract ASIN from URL (used as the canonical link + dedup key)
# ---------------------------------------------------------------------------
if ($AmazonUrl -notmatch '/dp/([A-Z0-9]{10})') {
    Write-Error "Could not extract ASIN from URL"
    exit 1
}
$asin = $matches[1]
$canonicalUrl = "https://www.amazon.com/dp/$asin"

# ---------------------------------------------------------------------------
# 4. Dedup check (before downloading/cropping the cover)
# ---------------------------------------------------------------------------
$books = @()
if (Test-Path $booksPath) {
    $books = @(Get-Content -Raw -Path $booksPath -Encoding UTF8 | ConvertFrom-Json)
    # Defensive: a malformed read (partial write races, bad JSON) must never
    # propagate into an append+overwrite that clobbers existing entries.
    $malformed = @($books | Where-Object { -not ($_.PSObject.Properties.Name -contains 'title') -or [string]::IsNullOrWhiteSpace($_.title) })
    if ($books.Count -gt 0 -and $malformed.Count -gt 0) {
        Write-Error "Refusing to append: $booksPath parsed into $($books.Count) entrie(s) but $($malformed.Count) are malformed (missing title). Not writing."
        exit 1
    }
}
if ($books | Where-Object { $_.asin -eq $asin }) {
    Write-Host "Book already present (ASIN $asin). Skipping insert."
    exit 0
}

# ---------------------------------------------------------------------------
# 5. Download cover and crop/resize to 200x300 (matching other book covers)
# ---------------------------------------------------------------------------
$tmpFile = [System.IO.Path]::GetTempFileName() + ".jpg"
Invoke-WebRequest -Uri $coverUrl -OutFile $tmpFile -UseBasicParsing

Add-Type -AssemblyName System.Drawing
$srcImg = [System.Drawing.Image]::FromFile($tmpFile)
$srcW = $srcImg.Width; $srcH = $srcImg.Height
Write-Host "Source: $srcW x $srcH"

$targetW = 200; $targetH = 300
$targetRatio = $targetW / $targetH
$srcRatio = $srcW / $srcH

if ($srcRatio -gt $targetRatio) {
    # too wide — crop sides
    $cropW = [int][Math]::Round($srcH * $targetRatio)
    $cropX = [int](($srcW - $cropW) / 2)
    $cropY = 0; $cropH = $srcH
} else {
    # too tall — crop top/bottom
    $cropH = [int][Math]::Round($srcW / $targetRatio)
    $cropX = 0; $cropY = [int](($srcH - $cropH) / 2); $cropW = $srcW
}

$cropRect = New-Object System.Drawing.Rectangle $cropX, $cropY, $cropW, $cropH
$cropped = ([System.Drawing.Bitmap]$srcImg).Clone($cropRect, $srcImg.PixelFormat)
$srcImg.Dispose()

$bmp = New-Object System.Drawing.Bitmap $targetW, $targetH
$gr = [System.Drawing.Graphics]::FromImage($bmp)
$gr.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gr.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gr.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gr.DrawImage($cropped, 0, 0, $targetW, $targetH)
$gr.Dispose(); $cropped.Dispose()

$jpegEncoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 82L
$bmp.Save($tmpFile, $jpegEncoder, $encParams)
$bmp.Dispose()

$jpgBytes = [System.IO.File]::ReadAllBytes($tmpFile)
$dataUrl = 'data:image/jpeg;base64,' + [Convert]::ToBase64String($jpgBytes)
Remove-Item $tmpFile -Force
Write-Host "Cover: $targetW x $targetH, $($jpgBytes.Length) bytes"

# ---------------------------------------------------------------------------
# 6. Append to data/books.json
# ---------------------------------------------------------------------------
$newBook = [pscustomobject]@{
    id         = "bk-" + $asin.ToLowerInvariant()
    title      = $title
    asin       = $asin
    amazonUrl  = $canonicalUrl
    coverImage = $dataUrl
    synopsis   = ''
    imprint    = $null
}
$books = @($books) + $newBook
$json = ConvertTo-Json -InputObject $books -Depth 6
[System.IO.File]::WriteAllText($booksPath, $json + "`n", [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "Added: $title (ASIN $asin)"
Write-Host "data/books.json now has $($books.Count) entr$(if ($books.Count -eq 1) { 'y' } else { 'ies' })."
Write-Host "Run fetch-descriptions.ps1 to fill in its synopsis from Amazon."
