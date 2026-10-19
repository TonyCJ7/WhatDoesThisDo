# WhatDoesThisDo agent setup for Windows (PowerShell 5.1 or later).
# Run from a clone:  powershell -ExecutionPolicy Bypass -File setup\setup-windows.ps1
# Or remotely:       irm https://raw.githubusercontent.com/TonyCJ7/WhatDoesThisDo/main/setup/setup-windows.ps1 | iex
# Without parameters it asks on screen: arrow keys move, enter selects, b goes back, q quits.
param(
  [ValidateSet("claude", "cursor", "both")] [string] $Agent,
  [ValidateSet("project", "global")] [string] $Scope,
  [string] $Folder,
  [switch] $Yes
)

$ErrorActionPreference = "Stop"
$RawUrl = "https://raw.githubusercontent.com/TonyCJ7/WhatDoesThisDo/main/agent"
$DefaultFolder = "docs/whatdoesthisdo/references"
$ScriptedKeys = $null
if ($env:WDTD_KEYS) { $ScriptedKeys = [System.Collections.Generic.Queue[char]]::new([char[]] $env:WDTD_KEYS) }

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
  $home_ = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }

  # ---------- keyboard ----------

  function Read-ScriptedChar { if ($ScriptedKeys.Count -eq 0) { return $null } return $ScriptedKeys.Dequeue() }

  function Read-Key {
    if ($ScriptedKeys) {
      $ch = Read-ScriptedChar
      if ($null -eq $ch) { return "quit" }
      if ($ch -eq [char] 27) {
        $c2 = Read-ScriptedChar
        if ($c2 -eq "[") {
          $c3 = Read-ScriptedChar
          switch ($c3) { "A" { return "up" } "B" { return "down" } "D" { return "back" } default { return "other" } }
        }
        return "other"
      }
      switch ($ch) {
        "`n" { return "enter" } "`r" { return "enter" }
        "j" { return "down" } "k" { return "up" }
        "b" { return "back" } "q" { return "quit" }
        "1" { return "1" } "2" { return "2" } "3" { return "3" }
        default { return "other" }
      }
    }

    $k = [Console]::ReadKey($true)
    switch ($k.Key) {
      "UpArrow" { return "up" } "DownArrow" { return "down" } "LeftArrow" { return "back" } "Enter" { return "enter" }
      "D1" { return "1" } "D2" { return "2" } "D3" { return "3" }
    }
    switch ($k.KeyChar) {
      "j" { return "down" } "k" { return "up" } "b" { return "back" } "q" { return "quit" }
      "1" { return "1" } "2" { return "2" } "3" { return "3" }
      default { return "other" }
    }
  }

  function Read-TextLine {
    if ($ScriptedKeys) {
      $sb = [Text.StringBuilder]::new()
      while ($true) { $ch = Read-ScriptedChar; if ($null -eq $ch -or $ch -eq "`n") { break }; if ($ch -ne "`r") { [void] $sb.Append($ch) } }
      return $sb.ToString()
    }
    return (Read-Host)
  }

  function Clear-Screen { try { [Console]::Clear() } catch { } }

  # ---------- screens ----------

  function Show-Header([string] $Step) {
    Write-Host "WhatDoesThisDo setup" -ForegroundColor White -NoNewline
    Write-Host "  $Step" -ForegroundColor DarkGray
    Write-Host ""
  }

  function Show-Menu([string] $Question, [int] $Current, [string[]] $Options) {
    Write-Host $Question
    Write-Host ""
    for ($i = 1; $i -le $Options.Count; $i++) {
      if ($i -eq $Current) { Write-Host "  > $($Options[$i - 1])" -ForegroundColor Cyan } else { Write-Host "    $($Options[$i - 1])" }
    }
    Write-Host ""
    Write-Host "up/down move · enter select · b back · q quit" -ForegroundColor DarkGray
  }

  # returns the chosen index, "back" or "quit"
  function Select-Option([string] $Step, [string] $Question, [int] $Current, [string[]] $Options) {
    while ($true) {
      Clear-Screen
      Show-Header $Step
      Show-Menu $Question $Current $Options
      switch (Read-Key) {
        "up" { if ($Current -gt 1) { $Current-- } }
        "down" { if ($Current -lt $Options.Count) { $Current++ } }
        "enter" { return $Current }
        "back" { return "back" }
        "quit" { return "quit" }
      }
    }
  }

  function Get-AgentIndex { switch ($script:Agent) { "claude" { 2 } "cursor" { 3 } default { 1 } } }
  function Get-ScopeIndex { if ($script:Scope -eq "global") { 2 } else { 1 } }
  function Get-AgentLabel { switch ($script:Agent) { "claude" { "Claude Code" } "cursor" { "Cursor" } default { "Both Claude Code and Cursor" } } }
  function Get-ScopeLabel { if ($script:Scope -eq "global") { "Everywhere for me  (~/.claude)" } else { "This project  ($root)" } }

  function Show-AgentScreen {
    $choice = Select-Option "step 1 of 3" "Which agent should follow the documentation rule?" (Get-AgentIndex) @("Both Claude Code and Cursor", "Claude Code", "Cursor")
    switch ($choice) { 1 { $script:Agent = "both" } 2 { $script:Agent = "claude" } 3 { $script:Agent = "cursor" } }
    return $choice
  }

  function Show-ScopeScreen {
    $projectOption = if ($root) { "This project only          $root" } else { "This project only          (not inside a git repository)" }
    while ($true) {
      $choice = Select-Option "step 2 of 3" "Where should this apply?" (Get-ScopeIndex) @($projectOption, "Everywhere for me          ~/.claude on this machine")
      if ($choice -eq 1 -and -not $root) { continue }
      if ($choice -eq 1) { $script:Scope = "project" }
      if ($choice -eq 2) { $script:Scope = "global" }
      return $choice
    }
  }

  function Show-FolderScreen {
    if (-not $script:Folder) { $script:Folder = $DefaultFolder }
    while ($true) {
      $choice = Select-Option "step 3 of 3" "Where do the reference pages live, relative to the repository root?" 1 @("Keep  $($script:Folder)", "Type another folder")
      if ($choice -ne 2) { return $choice }
      Write-Host ""
      Write-Host "Folder: " -NoNewline
      $line = (Read-TextLine).Trim().TrimEnd("/", "\").Replace("\", "/")
      if ($line) { $script:Folder = $line }
    }
  }

  function Get-PlanLines {
    $base = if ($script:Scope -eq "project") { $root } else { $home_ }
    $lines = @("  $base/.claude/skills/whatdoesthisdo/SKILL.md")
    if ($script:Agent -ne "cursor") {
      if ($script:Scope -eq "project") { $lines += "  $root/CLAUDE.md  (rule block between <!-- whatdoesthisdo --> markers)" }
      else { $lines += "  $home_/.claude/CLAUDE.md  (rule block between <!-- whatdoesthisdo --> markers)" }
    }
    if ($script:Agent -ne "claude" -and $script:Scope -eq "project") { $lines += "  $root/.cursor/rules/whatdoesthisdo.mdc" }
    if ($script:Scope -eq "project") { $lines += "  $root/$($script:Folder)/README.md  (only if missing)" }
    return $lines
  }

  function Invoke-Interactive {
    $screen = 1
    $fromSummary = $false
    while ($true) {
      if ($screen -eq 4) {
        Clear-Screen
        Show-Header "summary"
        Write-Host "  1  Agent    $(Get-AgentLabel)"
        Write-Host "  2  Scope    $(Get-ScopeLabel)"
        Write-Host "  3  Folder   $($script:Folder)"
        Write-Host ""
        Write-Host "Files to write:" -ForegroundColor White
        Get-PlanLines | ForEach-Object { Write-Host $_ }
        Write-Host ""
        Write-Host "enter write · 1 2 3 change a step · q quit" -ForegroundColor DarkGray
        $key = Read-Key
        if ($key -eq "enter") { Clear-Screen; return $true }
        if ($key -eq "quit") { Clear-Screen; Write-Output "nothing written"; return $false }
        if ($key -in @("1", "2", "3")) { $screen = [int] $key; $fromSummary = $true }
        continue
      }
      if ($screen -eq 1) { $choice = Show-AgentScreen }
      elseif ($screen -eq 2) { $choice = Show-ScopeScreen }
      else { $choice = Show-FolderScreen }
      if ($choice -eq "quit") { Clear-Screen; Write-Output "nothing written"; return $false }
      if ($choice -eq "back") { if ($screen -gt 1) { $screen-- }; continue }
      if ($fromSummary) { $screen = 4; $fromSummary = $false } else { $screen++ }
    }
  }

  # ---------- write ----------

  function Get-Substituted([string] $Path) { return (Get-Content -Raw -Path $Path).Replace($DefaultFolder, $script:Folder) }

  function Write-Text([string] $Path, [string] $Text) {
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
  }

  function Write-Block([string] $Path) {
    $block = (Get-Substituted (Join-Path $src "rule-block.md")).TrimEnd("`r", "`n")
    $kept = ""
    if (Test-Path $Path) {
      $existing = Get-Content -Raw -Path $Path
      $kept = [regex]::Replace($existing, "(?s)<!-- whatdoesthisdo:start -->.*?<!-- whatdoesthisdo:end -->\r?\n?", "").TrimEnd("`r", "`n", " ")
    }
    if ($kept) { Write-Text $Path "$kept`n`n$block`n" } else { Write-Text $Path "$block`n" }
  }

  function Write-Files {
    $base = if ($script:Scope -eq "project") { $root } else { $home_ }
    Write-Text (Join-Path $base ".claude/skills/whatdoesthisdo/SKILL.md") (Get-Substituted (Join-Path $src "skill/SKILL.md"))
    if ($script:Agent -ne "cursor") {
      $claudeMd = if ($script:Scope -eq "project") { Join-Path $root "CLAUDE.md" } else { Join-Path $home_ ".claude/CLAUDE.md" }
      Write-Block $claudeMd
    }
    if ($script:Agent -ne "claude" -and $script:Scope -eq "project") {
      Write-Text (Join-Path $root ".cursor/rules/whatdoesthisdo.mdc") (Get-Substituted (Join-Path $src "cursor-rule.mdc"))
    }
    if ($script:Scope -eq "project") {
      $readme = Join-Path $root "$($script:Folder)/README.md"
      if (-not (Test-Path $readme)) {
        Write-Text $readme "# Reference pages`n`nMarkdown pages read by the WhatDoesThisDo extension. One page per source file, at the same path as the file with a ``.md`` extension,`none entry per function or constant. The ``whatdoesthisdo`` skill describes the format.`n"
      }
    }
    Write-Output "Done. Written:"
    Get-PlanLines | ForEach-Object { Write-Output ($_ -replace "  \(only if missing\)", "") }
    if ($script:Agent -ne "claude" -and $script:Scope -eq "global") {
      Write-Output ""
      Write-Output "Cursor has no global rules file. Paste this into Cursor Settings > Rules > User Rules:"
      Write-Output ""
      $body = (Get-Substituted (Join-Path $src "cursor-rule.mdc")) -split "(?m)^---\s*$"
      Write-Output $body[-1].Trim()
    }
  }

  # ---------- main ----------

  if ($Yes) {
    if (-not $Agent) { $Agent = "both" }
    if (-not $Scope) { $Scope = "project" }
    if (-not $Folder) { $Folder = $DefaultFolder }
  } elseif (-not $Agent -or -not $Scope -or -not $Folder) {
    if (-not (Invoke-Interactive)) { exit 0 }
  }

  if ($Agent -notin @("claude", "cursor", "both")) { throw "agent must be claude, cursor or both" }
  if ($Scope -notin @("project", "global")) { throw "scope must be project or global" }
  $Folder = $Folder.TrimEnd("/", "\").Replace("\", "/")

  if ($Scope -eq "project" -and -not $root) {
    Write-Error "not inside a git repository; run from your project or use -Scope global"
    exit 1
  }

  if ($Yes) { Write-Output "Files to write:"; Get-PlanLines | ForEach-Object { Write-Output $_ } }
  Write-Files
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
