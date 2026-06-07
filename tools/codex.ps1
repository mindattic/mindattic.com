<#
.SYNOPSIS
  Codex documentation CLI for mindattic.com (CODE: MAC).

.DESCRIPTION
  Subcommands:
    doctor  - validate the docs/ canon (front-matter, IDs, cross-refs, cited paths,
              story evidence, JSON data, digest freshness). Exits non-zero on any hard error.
    digest  - regenerate docs/BIBLE.digest.md from BIBLE.md (S1, S3, S5 Laws, S9), a
              status index, and the latest amendment head.

  No build step, no module dependencies. Windows PowerShell 5.1 compatible. This file is
  intentionally pure ASCII on disk: non-ASCII glyphs are built from code points at runtime, and
  every regex matches them via \uXXXX escapes, so a BOM-less read under PS 5.1 (ANSI) never
  mangles a literal.

.EXAMPLE
  pwsh tools/codex.ps1 doctor
  pwsh tools/codex.ps1 digest
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('doctor', 'digest')]
  [string]$Command = 'doctor'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Glyphs built from code points so the source stays pure ASCII.
$SECT        = [char]0x00A7                                             # section sign
$SYM_DONE    = [char]0x2705                                             # check mark button
$SYM_PARTIAL = [System.Char]::ConvertFromUtf32(0x1F7E1)                 # yellow circle
$SYM_PLANNED = [char]0x2B1C                                             # white large square
$SYM_CUT     = [System.Char]::ConvertFromUtf32(0x1F5D1) + [char]0xFE0F  # wastebasket + VS16

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DocsDir  = Join-Path $RepoRoot 'docs'
$DataDir  = Join-Path $DocsDir 'data'
$RfcDir   = Join-Path $DocsDir 'rfc'
$Bible    = Join-Path $DocsDir 'BIBLE.md'
$Stories  = Join-Path $DocsDir 'USER_STORIES.md'
$Amend    = Join-Path $DocsDir 'AMENDMENTS.md'
$Digest   = Join-Path $DocsDir 'BIBLE.digest.md'

# ----------------------------------------------------------------------------- helpers
function Read-Text([string]$Path) {
  return [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
}

function Get-FrontMatter([string]$Text) {
  # optional leading BOM (U+FEFF) then a --- ... --- block
  if ($Text -notmatch "(?s)^\uFEFF?---\r?\n(.*?)\r?\n---\r?\n") { return $null }
  $block = $Matches[1]
  $map = @{}
  foreach ($line in ($block -split "\r?\n")) {
    if ($line -match '^\s*([A-Za-z0-9_]+)\s*:\s*(.*?)\s*$') {
      $map[$Matches[1]] = $Matches[2]
    }
  }
  return $map
}

function Get-CodexDocs {
  $files = @()
  foreach ($f in @($Bible, $Stories, $Amend)) {
    if (Test-Path $f) { $files += $f }
  }
  if (Test-Path $RfcDir)  { $files += (Get-ChildItem -Path $RfcDir  -Filter '*.md'   -File -ErrorAction SilentlyContinue | ForEach-Object FullName) }
  if (Test-Path $DataDir) { $files += (Get-ChildItem -Path $DataDir -Filter '*.json' -File -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -ne '_schema' } | ForEach-Object FullName) }
  return $files
}

$script:Errors   = New-Object System.Collections.Generic.List[string]
$script:Warnings = New-Object System.Collections.Generic.List[string]
$script:Checks   = New-Object System.Collections.Generic.List[string]
function Fail([string]$m)  { $script:Errors.Add($m) }
function Warn([string]$m)  { $script:Warnings.Add($m) }
function Pass([string]$m)  { $script:Checks.Add($m) }

# ----------------------------------------------------------------------------- doctor
function Invoke-Doctor {
  $validLayers   = @('bible', 'stories', 'amendments', 'rfc', 'data')
  $validStatuses = @('living', 'done', 'partial', 'planned', 'cut')

  if (-not (Test-Path $Bible)) { Fail "docs/BIBLE.md is missing." }

  # --- 1. front-matter on every codex doc ---
  $docs = @(Get-CodexDocs)
  foreach ($f in $docs) {
    $rel = $f.Substring($RepoRoot.Length).TrimStart('\', '/')
    if ($f -like '*.json') {
      try {
        $j = Read-Text $f | ConvertFrom-Json
        if (-not ($j.PSObject.Properties.Name -contains 'codex')) { Fail "$rel : JSON data file missing 'codex' field." }
      } catch { Fail "$rel : invalid JSON ($($_.Exception.Message))." }
      continue
    }
    $txt = Read-Text $f
    $fm = Get-FrontMatter $txt
    if ($null -eq $fm) { Fail "$rel : missing YAML front-matter."; continue }
    foreach ($k in @('codex', 'project', 'code', 'layer', 'status', 'updated')) {
      if (-not $fm.ContainsKey($k)) { Fail "$rel : front-matter missing '$k'." }
    }
    if ($fm.ContainsKey('layer')  -and ($validLayers   -notcontains $fm['layer']))  { Fail "$rel : invalid layer '$($fm['layer'])'." }
    if ($fm.ContainsKey('status') -and ($validStatuses -notcontains $fm['status'])) { Fail "$rel : invalid status '$($fm['status'])'." }
    if ($fm.ContainsKey('updated') -and ($fm['updated'] -notmatch '^\d{4}-\d{2}-\d{2}$')) { Fail "$rel : 'updated' not YYYY-MM-DD." }
  }
  if ($script:Errors.Count -eq 0) { Pass "front-matter valid on $($docs.Count) codex doc(s)" }

  # --- 2. unique anchors + resolving cross-refs ---
  $mdFiles = @($docs | Where-Object { $_ -like '*.md' })
  $allAnchors = @{}
  $dupAnchors = @{}
  foreach ($f in $mdFiles) {
    $txt = Read-Text $f
    foreach ($m in [regex]::Matches($txt, '\{#([A-Za-z0-9\u00A7.\-]+)\}')) {
      $a = $m.Groups[1].Value
      if ($allAnchors.ContainsKey($a)) { $dupAnchors[$a] = $true }
      else { $allAnchors[$a] = $f }
    }
  }
  # token-style IDs defined by convention (amendment / story / law headings & bold labels)
  $tokenIds = @{}
  foreach ($f in $mdFiles) {
    $txt = Read-Text $f
    foreach ($m in [regex]::Matches($txt, '(MAC-(?:A\d+|US-[A-Za-z0-9]+|LAW-\d+))')) {
      $tokenIds[$m.Groups[1].Value] = $true
    }
  }
  foreach ($a in $dupAnchors.Keys) { Fail "duplicate anchor '{#$a}'." }
  if ($dupAnchors.Count -eq 0) { Pass "all $($allAnchors.Count) anchors unique" }

  # cross-ref links: [text](target#anchor) or [text](#anchor)
  $refCount = 0
  foreach ($f in $mdFiles) {
    $dir = Split-Path -Parent $f
    $txt = Read-Text $f
    foreach ($m in [regex]::Matches($txt, '\]\(([^)\s]*?)#([A-Za-z0-9\u00A7.\-]+)\)')) {
      $refCount++
      $path = $m.Groups[1].Value
      $anchor = $m.Groups[2].Value
      if ([string]::IsNullOrEmpty($path)) {
        if (-not ($allAnchors.ContainsKey($anchor) -or $tokenIds.ContainsKey($anchor))) { Fail "$(Split-Path -Leaf $f): in-file ref to missing anchor '#$anchor'." }
      } else {
        $target = Join-Path $dir $path
        if (Test-Path $target) {
          if ($target -like '*.md') {
            if (-not ($allAnchors.ContainsKey($anchor) -or $tokenIds.ContainsKey($anchor))) { Fail "$(Split-Path -Leaf $f): ref '$path#$anchor' -> anchor not found." }
          }
        } elseif ($path -notmatch 'HouseRules') {
          Fail "$(Split-Path -Leaf $f): ref target '$path' does not exist."
        }
      }
    }
  }
  if ($script:Errors.Count -eq 0) { Pass "$refCount cross-ref link(s) resolve" }

  # --- 3. JSON data validates; entity ids unique ---
  $dataFiles = @($docs | Where-Object { $_ -like '*.json' })
  if ($dataFiles.Count -gt 0) {
    $ids = @{}
    foreach ($f in $dataFiles) {
      try {
        $j = Read-Text $f | ConvertFrom-Json
        $items = if ($j -is [System.Array]) { $j } elseif ($j.PSObject.Properties.Name -contains 'items') { $j.items } else { @($j) }
        foreach ($it in $items) {
          if ($it.PSObject.Properties.Name -contains 'id') {
            if ($ids.ContainsKey($it.id)) { Fail "duplicate data id '$($it.id)'." } else { $ids[$it.id] = $true }
          }
        }
      } catch { Fail "$(Split-Path -Leaf $f): JSON parse error." }
    }
    Pass "validated $($dataFiles.Count) data file(s); $($ids.Count) entity id(s)"
  } else {
    Pass "no L5 data files (website domain; catalogs are generated regions)"
  }

  # --- 4. every done story cites an evidence/test token ---
  if (Test-Path $Stories) {
    $stxt = Read-Text $Stories
    $doneLines = [regex]::Matches($stxt, "(?m)^\s*-\s+\*\*(MAC-US-[A-Za-z0-9]+)\s*\u2705\*\*.*$")
    foreach ($m in $doneLines) {
      $id = $m.Groups[1].Value
      $idx = $stxt.IndexOf($m.Value)
      $window = $stxt.Substring($idx, [Math]::Min(700, $stxt.Length - $idx))
      if ($window -notmatch '(?i)\(verified by') { Fail "$id : done story has no 'verified by' evidence." }
    }
    Pass "$($doneLines.Count) done-story evidence citation(s) present"
  }

  # --- 5. code paths cited in the bible exist on disk ---
  if (Test-Path $Bible) {
    $btxt = Read-Text $Bible
    $cited = @{}
    foreach ($m in [regex]::Matches($btxt, '`([A-Za-z0-9_][A-Za-z0-9_./\-]*\.[A-Za-z0-9]+|[A-Za-z0-9_][A-Za-z0-9_./\-]*/)`')) {
      $p = $m.Groups[1].Value
      if ($p -match '^(MindAttic\.|https?:|data:|\.\./|node_|npm$)') { continue }
      if ($p -match '^(react|vue|svelte)') { continue }
      # paths the bible cites as ABSENT/retired by design (LAW-1, LAW-4): not expected on disk
      if ($p -match '^(dist/|deploy\.(ps1|bat)$)') { continue }
      $cited[$p] = $true
    }
    # Build a set of every file/dir leaf name in the repo (excluding .git) once.
    $leaves = @{}
    foreach ($it in (Get-ChildItem -Path $RepoRoot -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\\.git\\' })) {
      $leaves[$it.Name] = $true
    }
    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($p in $cited.Keys) {
      $full = Join-Path $RepoRoot $p
      $leaf = ($p.TrimEnd('/','\') -split '[\\/]')[-1]
      if ((Test-Path $full) -or $leaves.ContainsKey($leaf)) { continue }
      [void]$missing.Add($p)
    }
    foreach ($p in $missing) { Fail "BIBLE cites '$p' but it does not exist on disk." }
    if ($missing.Count -eq 0) { Pass "all $($cited.Count) bible-cited repo path(s) exist" }
  }

  # --- 6. digest freshness (generatedFrom BIBLE/AMENDMENTS) ---
  if (Test-Path $Digest) {
    $dt = (Get-Item $Digest).LastWriteTimeUtc
    foreach ($src in @($Bible, $Amend)) {
      if (Test-Path $src) {
        $st = (Get-Item $src).LastWriteTimeUtc
        if ($st -gt $dt) { Warn "BIBLE.digest.md is stale (source $(Split-Path -Leaf $src) newer). Run: codex.ps1 digest" }
      }
    }
    if ($script:Warnings.Count -eq 0) { Pass "digest is fresh" }
  } else {
    Warn "docs/BIBLE.digest.md missing. Run: codex.ps1 digest"
  }

  # --- report ---
  Write-Host ""
  Write-Host "Codex doctor - mindattic.com (MAC)" -ForegroundColor Cyan
  Write-Host "-----------------------------------"
  foreach ($c in $script:Checks)   { Write-Host "  [PASS] $c" -ForegroundColor Green }
  foreach ($w in $script:Warnings) { Write-Host "  [WARN] $w" -ForegroundColor Yellow }
  foreach ($e in $script:Errors)   { Write-Host "  [FAIL] $e" -ForegroundColor Red }
  Write-Host ""
  if ($script:Errors.Count -gt 0) {
    Write-Host "doctor FAILED: $($script:Errors.Count) error(s), $($script:Warnings.Count) warning(s)." -ForegroundColor Red
    exit 1
  }
  Write-Host "doctor OK: $($script:Checks.Count) check(s) passed, $($script:Warnings.Count) warning(s)." -ForegroundColor Green
  exit 0
}

# ----------------------------------------------------------------------------- digest
function Get-Section([string]$Text, [string]$AnchorId) {
  $pat = "(?ms)^##\s+.*?\{#" + [regex]::Escape($AnchorId) + "\}\s*\r?\n(.*?)(?=^##\s|\z)"
  $m = [regex]::Match($Text, $pat)
  if ($m.Success) { return $m.Groups[1].Value.Trim() }
  return ''
}

function Invoke-Digest {
  if (-not (Test-Path $Bible)) { throw "docs/BIBLE.md not found." }
  $b = Read-Text $Bible

  $one   = Get-Section $b "MAC-${SECT}1"
  $isnot = Get-Section $b "MAC-${SECT}3"
  $laws  = Get-Section $b "MAC-${SECT}5"
  $gloss = Get-Section $b "MAC-${SECT}9"

  # status index from USER_STORIES
  $counts = [ordered]@{ $SYM_DONE = 0; $SYM_PARTIAL = 0; $SYM_PLANNED = 0; $SYM_CUT = 0 }
  if (Test-Path $Stories) {
    $s = Read-Text $Stories
    foreach ($sym in @($SYM_DONE, $SYM_PARTIAL, $SYM_PLANNED, $SYM_CUT)) {
      $counts[$sym] = ([regex]::Matches($s, "MAC-US-[A-Za-z0-9]+\s*$([regex]::Escape($sym))")).Count
    }
  }

  # latest amendment head
  $amendHead = ''
  if (Test-Path $Amend) {
    $a = Read-Text $Amend
    $ms = [regex]::Matches($a, "(?m)^##\s+(MAC-A\d+\s+.*)$")
    if ($ms.Count -gt 0) { $amendHead = $ms[$ms.Count - 1].Groups[1].Value.Trim() }
  }

  $today = (Get-Date).ToString('yyyy-MM-dd')
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine("<!-- GENERATED by tools/codex.ps1 digest - do not hand-edit. generatedFrom: MAC-BIBLE -->")
  [void]$sb.AppendLine("# AUTHORITATIVE - full detail in docs/BIBLE.md")
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("> mindattic.com (MAC) digest, regenerated $today. This is the source of truth for")
  [void]$sb.AppendLine("> what mindattic.com is and the laws that keep it coherent. For anything not here,")
  [void]$sb.AppendLine("> read docs/BIBLE.md.")
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("## The one sentence")
  [void]$sb.AppendLine($one)
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("## What it is NOT")
  [void]$sb.AppendLine($isnot)
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("## The Laws")
  [void]$sb.AppendLine($laws)
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("## Glossary")
  [void]$sb.AppendLine($gloss)
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("## Status index (user stories)")
  [void]$sb.AppendLine("- done: $($counts[$SYM_DONE])  partial: $($counts[$SYM_PARTIAL])  planned: $($counts[$SYM_PLANNED])  cut: $($counts[$SYM_CUT])")
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("## Latest amendment")
  if ($amendHead) { [void]$sb.AppendLine("- $amendHead (amendment wins over the bible)") }
  else { [void]$sb.AppendLine("- (none)") }
  [void]$sb.AppendLine("")

  [System.IO.File]::WriteAllText($Digest, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
  Write-Host "Wrote docs/BIBLE.digest.md ($([Math]::Round((Get-Item $Digest).Length / 1KB, 1)) KB)." -ForegroundColor Green
}

switch ($Command) {
  'doctor' { Invoke-Doctor }
  'digest' { Invoke-Digest }
}
