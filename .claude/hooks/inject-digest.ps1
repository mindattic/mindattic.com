<#
  SessionStart hook: inject docs/BIBLE.digest.md as authoritative context.
  Emits Claude Code hook JSON on stdout. Windows PowerShell 5.1 / Win-1252 safe:
  all non-ASCII is escaped to \uXXXX so the JSON is pure ASCII.
  If the digest is missing/empty, emits {}.
#>
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$digest = Join-Path $repoRoot 'docs/BIBLE.digest.md'

if (-not (Test-Path $digest)) { Write-Output '{}'; exit 0 }

$content = [System.IO.File]::ReadAllText($digest, [System.Text.UTF8Encoding]::new($false))
if ([string]::IsNullOrWhiteSpace($content)) { Write-Output '{}'; exit 0 }

$preamble = @"
[mindattic.com / Codex] The following is the AUTHORITATIVE project digest, generated from
docs/BIBLE.md (the single source of truth) and docs/AMENDMENTS.md. Treat it as ground truth for
what mindattic.com is, what it is NOT, and its laws. An amendment always wins over the bible.
For full detail, read docs/BIBLE.md, docs/USER_STORIES.md, and docs/AMENDMENTS.md.

"@

$full = $preamble + $content

# JSON-encode with all non-ASCII escaped to \uXXXX (avoid encoding surprises in PS 5.1).
$sb = New-Object System.Text.StringBuilder
foreach ($ch in $full.ToCharArray()) {
  $code = [int][char]$ch
  switch ($ch) {
    '"'  { [void]$sb.Append('\"') }
    '\'  { [void]$sb.Append('\\') }
    "`b" { [void]$sb.Append('\b') }
    "`f" { [void]$sb.Append('\f') }
    "`n" { [void]$sb.Append('\n') }
    "`r" { [void]$sb.Append('\r') }
    "`t" { [void]$sb.Append('\t') }
    default {
      if ($code -lt 32 -or $code -gt 126) {
        [void]$sb.Append('\u' + $code.ToString('x4'))
      } else {
        [void]$sb.Append($ch)
      }
    }
  }
}
$escaped = $sb.ToString()

$json = '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"' + $escaped + '"}}'
Write-Output $json
exit 0
