# render.ps1 - regenerate the MindAttic Ecosystem flow diagram and inline it.
#
# DORMANT / WILL THROW (docs/AMENDMENTS.md MAC-A6, 2026-10-02): this script
# splices the rendered SVG into ../index.htm between <!-- BEGIN/END
# ECOSYSTEM-DIAGRAM --> markers, and index.htm no longer contains them (the
# page is now a wordmark plus three buttons), so running it fails with
# "BEGIN ECOSYSTEM-DIAGRAM marker not found". It is kept on disk in case a
# future page wants the diagram back; rendering ecosystem.svg itself still works.
#
# Source of truth is ecosystem.mmd (Mermaid). This script renders it to
# ecosystem.svg via @mermaid-js/mermaid-cli (themed by mermaid-config.json to
# the site's Cyberspace palette), then splices that SVG into the page. (It
# used to say this kept the page "a single self-contained file"; the page no
# longer makes that promise -- assets come from the MindAttic.UiUx CDN package.)
#
# The splice region used to sit BETWEEN <h2>MindAttic Ecosystem</h2> and its
# board-grid, preserved by fetch-descriptions.ps1 and ignored by the UiUx sync
# (plain HTML comments, not MINDATTIC.UIUX markers).
#
# NOTE: on networks that MITM TLS (corporate proxy / custom root CA), the
# `npx @mermaid-js/mermaid-cli` download can fail with
# UNABLE_TO_VERIFY_LEAF_SIGNATURE. In that case ecosystem.svg is hand-maintained
# to match ecosystem.mmd (same nodes/edges/palette) and this script's render
# step is skipped -- it still re-splices the existing ecosystem.svg into the page.
#
# Usage:  powershell -File render.ps1            (render + inline)
#         powershell -File render.ps1 -NoRender  (inline existing ecosystem.svg)

param([switch]$NoRender)

$ErrorActionPreference = 'Stop'
$here    = $PSScriptRoot
$mmd     = Join-Path $here 'ecosystem.mmd'
$cfg     = Join-Path $here 'mermaid-config.json'
$svgPath = Join-Path $here 'ecosystem.svg'
$index   = Join-Path $here '..\index.htm'
$utf8    = [System.Text.UTF8Encoding]::new($false)

if (-not $NoRender) {
    try {
        & npx -y "@mermaid-js/mermaid-cli@latest" -i $mmd -c $cfg -b transparent -o $svgPath
        if ($LASTEXITCODE -ne 0) { throw "mermaid-cli exited $LASTEXITCODE" }
        Write-Host "Rendered $svgPath from ecosystem.mmd." -ForegroundColor Green
    } catch {
        Write-Host "Render skipped ($($_.Exception.Message)). Using existing ecosystem.svg." -ForegroundColor Yellow
    }
}

if (-not (Test-Path $svgPath)) { throw "ecosystem.svg not found: $svgPath" }

$svg   = ([System.IO.File]::ReadAllText($svgPath, $utf8)).Trim()
$figure = '  <figure class="ecosystem-diagram">' + "`r`n" + $svg + "`r`n" + '  </figure>'

$begin = '<!-- BEGIN ECOSYSTEM-DIAGRAM (generated from diagram/ecosystem.mmd; run diagram/render.ps1) -->'
$end   = '<!-- END ECOSYSTEM-DIAGRAM -->'

$html = [System.IO.File]::ReadAllText($index, $utf8)
$startIdx = $html.IndexOf($begin)
if ($startIdx -lt 0) { throw "BEGIN ECOSYSTEM-DIAGRAM marker not found in index.htm." }
$endIdx = $html.IndexOf($end, $startIdx)
if ($endIdx -lt 0) { throw "END ECOSYSTEM-DIAGRAM marker not found in index.htm." }
$endIdx += $end.Length

$combined = $begin + "`r`n" + $figure + "`r`n  " + $end
$newHtml = $html.Substring(0, $startIdx) + $combined + $html.Substring($endIdx)

if ($newHtml -ne $html) {
    [System.IO.File]::WriteAllText($index, $newHtml, $utf8)
    Write-Host "Inlined ecosystem diagram into index.htm." -ForegroundColor Green
} else {
    Write-Host "index.htm already up to date." -ForegroundColor DarkGray
}
