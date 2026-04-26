# add-book.ps1 — Convert an Amazon book page into a base64-embedded book cover
# entry in the Creative section of index.htm.
#
# Usage:
#   powershell -File add-book.ps1 https://www.amazon.com/dp/B0XXXXXXXX
#   add-book.bat https://www.amazon.com/dp/B0XXXXXXXX

param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AmazonUrl,

    [string]$IndexFile = "$PSScriptRoot\index.htm"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $IndexFile)) {
    Write-Error "index.htm not found at: $IndexFile"
    exit 1
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
# 3. Extract ASIN from URL (used as the canonical link)
# ---------------------------------------------------------------------------
if ($AmazonUrl -notmatch '/dp/([A-Z0-9]{10})') {
    Write-Error "Could not extract ASIN from URL"
    exit 1
}
$asin = $matches[1]
$canonicalUrl = "https://www.amazon.com/dp/$asin"

# ---------------------------------------------------------------------------
# 4. Download cover and crop/resize to 200x300 (matching other book covers)
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
# 5. Build the <a class="book"> markup
# ---------------------------------------------------------------------------
$titleEsc = $title -replace '"', '&quot;' -replace '&', '&amp;'
$NL = "`r`n"
$cardHtml = '    <a class="book" href="' + $canonicalUrl + '" target="_blank" rel="noopener noreferrer"><img src="' + $dataUrl + '" alt="' + $titleEsc + '" title="' + $titleEsc + '"></a>'

# ---------------------------------------------------------------------------
# 6. Detect duplicate ASIN (skip insert if already present)
# ---------------------------------------------------------------------------
$content = [System.IO.File]::ReadAllText($IndexFile, [System.Text.Encoding]::UTF8)
if ($content.Contains("/dp/$asin`"")) {
    Write-Host "Book already present (ASIN $asin). Skipping insert."
    exit 0
}

# ---------------------------------------------------------------------------
# 7. Insert at end of the Creative books-grid (before its closing </div>)
# ---------------------------------------------------------------------------
$creativeIdx = $content.IndexOf('<h2>Creative</h2>')
if ($creativeIdx -lt 0) {
    Write-Error "Could not locate <h2>Creative</h2> in index.htm"
    exit 1
}
$gridStart = $content.IndexOf('<div class="books-grid">', $creativeIdx)
if ($gridStart -lt 0) {
    Write-Error "Could not locate Creative books-grid"
    exit 1
}
# Find the matching </div> for this books-grid
$gridClose = $content.IndexOf('  </div>', $gridStart)
if ($gridClose -lt 0) {
    Write-Error "Could not locate closing </div> of books-grid"
    exit 1
}

$before = $content.Substring(0, $gridClose)
$after = $content.Substring($gridClose)
$newContent = $before + $cardHtml + $NL + $after
[System.IO.File]::WriteAllText($IndexFile, $newContent, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "Added: $title (ASIN $asin)"
Write-Host "File size: $((Get-Item $IndexFile).Length) bytes"
