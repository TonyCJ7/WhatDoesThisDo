# WhatDoesThisDo agent setup for Windows (PowerShell 5.1 or later).
# Run from a clone:  powershell -ExecutionPolicy Bypass -File setup\setup-windows.ps1
# Or remotely:       irm https://raw.githubusercontent.com/TonyCJ7/WhatDoesThisDo/main/setup/setup-windows.ps1 | iex
param(
  [ValidateSet("claude", "cursor", "both")] [string] $Agent,
  [ValidateSet("project", "global")] [string] $Scope,
  [string] $Folder,
  [switch] $Yes
)

$ErrorActionPreference = "Stop"
$RawUrl = "https://raw.githubusercontent.com/TonyCJ7/WhatDoesThisDo/main/agent"
$DefaultFolder = "docs/whatdoesthisdo/references"

function Ask([string] $Prompt, [string] $Default) {
  if ($Yes) { return $Default }
  $answer = Read-Host "$Prompt [$Default]"
  if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
  return $answer.Trim()
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("whatdoesthisdo-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
  $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { "" }
  $localAgent = if ($scriptDir) { Join-Path (Split-Path $scriptDir -Parent) "agent" } else { "" }

  if ($localAgent -and (Test-Path (Join-Path $localAgent "skill/SKILL.md"))) {
    $src = $localAgent
  } else {
    $src = Join-Path $tmp "agent"
    New-Item -ItemType Directory -Path (Join-Path $src "skill") | Out-Null
    foreach ($file in @("skill/SKILL.md", "rule-block.md", "cursor-rule.mdc")) {
      Invoke-WebRequest -Uri "$RawUrl/$file" -OutFile (Join-Path $src $file) -UseBasicParsing
    }
  }

  $root = ""
  try { $root = (git rev-parse --show-toplevel 2>$null); if ($LASTEXITCODE -ne 0) { $root = "" } } catch { $root = "" }

  if (-not $Agent) { $Agent = Ask "Agent to set up (claude, cursor, both)" "both" }
  if (-not $Scope) { $Scope = Ask "Scope (project, global)" "project" }

  if ($Agent -notin @("claude", "cursor", "both")) { throw "agent must be claude, cursor or both" }
  if ($Scope -notin @("project", "global")) { throw "scope must be project or global" }

  if ($Scope -eq "project" -and -not $root) {
    Write-Error "not inside a git repository; run from your project or use -Scope global"
    exit 1
  }

  if (-not $Folder) { $Folder = Ask "References folder, relative to the repository root" $DefaultFolder }
  $Folder = $Folder.TrimEnd("/", "\").Replace("\", "/")

  $home_ = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
  $base = if ($Scope -eq "project") { $root } else { $home_ }

  function Substitute([string] $Path) {
    return (Get-Content -Raw -Path $Path).Replace($DefaultFolder, $Folder)
  }

  function WriteText([string] $Path, [string] $Text) {
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
  }

  function WriteBlock([string] $Path) {
    $block = (Substitute (Join-Path $src "rule-block.md")).TrimEnd("`r", "`n")
    $kept = ""
    if (Test-Path $Path) {
      $existing = Get-Content -Raw -Path $Path
      $kept = [regex]::Replace($existing, "(?s)<!-- whatdoesthisdo:start -->.*?<!-- whatdoesthisdo:end -->\r?\n?", "").TrimEnd("`r", "`n", " ")
    }
    if ($kept) { WriteText $Path "$kept`n`n$block`n" } else { WriteText $Path "$block`n" }
  }

  $skillTarget = Join-Path $base ".claude/skills/whatdoesthisdo/SKILL.md"
  $plan = @("  $skillTarget")

  if ($Agent -ne "cursor") {
    $claudeMd = if ($Scope -eq "project") { Join-Path $root "CLAUDE.md" } else { Join-Path $home_ ".claude/CLAUDE.md" }
    $plan += "  $claudeMd  (rule block between <!-- whatdoesthisdo --> markers)"
  }

  if ($Agent -ne "claude" -and $Scope -eq "project") {
    $cursorRule = Join-Path $root ".cursor/rules/whatdoesthisdo.mdc"
    $plan += "  $cursorRule"
  }

  if ($Scope -eq "project") { $plan += "  $root/$Folder/README.md  (only if missing)" }

  Write-Output "Files to write:"
  $plan | ForEach-Object { Write-Output $_ }

  if (-not $Yes) {
    $answer = Ask "Continue? (y, n)" "y"
    if ($answer -notin @("y", "Y", "yes")) { Write-Output "nothing written"; exit 0 }
  }

  WriteText $skillTarget (Substitute (Join-Path $src "skill/SKILL.md"))

  if ($Agent -ne "cursor") { WriteBlock $claudeMd }

  if ($Agent -ne "claude" -and $Scope -eq "project") {
    WriteText $cursorRule (Substitute (Join-Path $src "cursor-rule.mdc"))
  }

  if ($Scope -eq "project") {
    $readme = Join-Path $root "$Folder/README.md"
    if (-not (Test-Path $readme)) {
      WriteText $readme "# Reference pages`n`nMarkdown pages read by the WhatDoesThisDo extension. One page per source file, at the same path as the file with a ``.md`` extension,`none entry per function or constant. The ``whatdoesthisdo`` skill describes the format.`n"
    }
  }

  Write-Output "Done."

  if ($Agent -ne "claude" -and $Scope -eq "global") {
    Write-Output ""
    Write-Output "Cursor has no global rules file. Paste this into Cursor Settings > Rules > User Rules:"
    Write-Output ""
    $body = (Substitute (Join-Path $src "cursor-rule.mdc")) -split "(?m)^---\s*$"
    Write-Output $body[-1].Trim()
  }
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
