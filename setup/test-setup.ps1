# Usage: pwsh setup/test-setup.ps1
$ErrorActionPreference = "Stop"
$script = Join-Path $PSScriptRoot "setup-windows.ps1"
$agentDir = Join-Path (Split-Path $PSScriptRoot -Parent) "agent"
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("wdtd-test-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path "$tmp/home" -Force | Out-Null
$env:HOME = "$tmp/home"
$env:USERPROFILE = "$tmp/home"

function Fail([string] $Message) { Write-Error "FAIL: $Message"; exit 1 }
function NewRepo([string] $Path) {
  New-Item -ItemType Directory -Path "$Path/src" -Force | Out-Null
  git -C $Path init -q
  Set-Content -Path "$Path/src/a.ts" -Value "x"
}
function Run([string] $Dir, [hashtable] $ScriptArgs) {
  Push-Location $Dir
  try { & $script @ScriptArgs } finally { Pop-Location }
}

try {
  NewRepo "$tmp/one"
  Set-Content -Path "$tmp/one/CLAUDE.md" -Value "# My rules`n`nKeep them."
  Run "$tmp/one/src" @{ Agent = "both"; Scope = "project"; Yes = $true } | Out-Null
  if (-not (Test-Path "$tmp/one/.claude/skills/whatdoesthisdo/SKILL.md")) { Fail "skill not written" }
  if ((Get-Content -Raw "$tmp/one/.claude/skills/whatdoesthisdo/SKILL.md") -ne (Get-Content -Raw "$agentDir/skill/SKILL.md")) { Fail "skill differs from source" }
  $claude = Get-Content -Raw "$tmp/one/CLAUDE.md"
  if ($claude -notmatch "# My rules") { Fail "existing CLAUDE.md content lost" }
  if ($claude -notmatch "Keep them.") { Fail "existing CLAUDE.md body lost" }
  if (([regex]::Matches($claude, "whatdoesthisdo:start")).Count -ne 1) { Fail "block not written once" }
  if (-not (Test-Path "$tmp/one/.cursor/rules/whatdoesthisdo.mdc")) { Fail "cursor rule not written" }
  if (-not (Test-Path "$tmp/one/docs/whatdoesthisdo/references/README.md")) { Fail "references folder not created" }

  $before = (Get-Content -Raw "$tmp/one/CLAUDE.md") + (Get-Content -Raw "$tmp/one/.cursor/rules/whatdoesthisdo.mdc")
  Run "$tmp/one" @{ Agent = "both"; Scope = "project"; Yes = $true } | Out-Null
  $after = (Get-Content -Raw "$tmp/one/CLAUDE.md") + (Get-Content -Raw "$tmp/one/.cursor/rules/whatdoesthisdo.mdc")
  if ($before -ne $after) { Fail "second run changed files" }

  NewRepo "$tmp/two"
  Run "$tmp/two" @{ Agent = "claude"; Scope = "project"; Folder = "docs/refs"; Yes = $true } | Out-Null
  if ((Get-Content -Raw "$tmp/two/CLAUDE.md") -notmatch "docs/refs/") { Fail "folder not substituted in rule block" }
  if ((Get-Content -Raw "$tmp/two/.claude/skills/whatdoesthisdo/SKILL.md") -notmatch "docs/refs/") { Fail "folder not substituted in skill" }
  if (-not (Test-Path "$tmp/two/docs/refs")) { Fail "custom references folder not created" }
  if (Test-Path "$tmp/two/.cursor") { Fail "cursor files written for claude only" }
  if ((Get-Content -Raw "$tmp/two/CLAUDE.md")[0] -ne "<") { Fail "new CLAUDE.md does not start with the block" }

  NewRepo "$tmp/three"
  Run "$tmp/three" @{ Agent = "claude"; Scope = "global"; Yes = $true } | Out-Null
  if (-not (Test-Path "$tmp/home/.claude/skills/whatdoesthisdo/SKILL.md")) { Fail "global skill not written" }
  if ((Get-Content -Raw "$tmp/home/.claude/CLAUDE.md") -notmatch "whatdoesthisdo:start") { Fail "global CLAUDE.md block not written" }
  if (Test-Path "$tmp/three/CLAUDE.md") { Fail "project CLAUDE.md written in global scope" }

  $out = (Run "$tmp/three" @{ Agent = "cursor"; Scope = "global"; Yes = $true }) -join "`n"
  if ($out -notmatch "User Rules") { Fail "cursor global did not print the paste instruction" }
  if ($out -notmatch "read its entry") { Fail "cursor global did not print the rule text" }
  if (Test-Path "$tmp/home/.cursor") { Fail "cursor global wrote a file" }

  New-Item -ItemType Directory -Path "$tmp/norepo" -Force | Out-Null
  $failed = $false
  try { Run "$tmp/norepo" @{ Agent = "both"; Scope = "project"; Yes = $true } *> $null; if ($LASTEXITCODE -ne 0) { $failed = $true } } catch { $failed = $true }
  if (-not $failed) { Fail "project scope outside a repo did not fail" }

  NewRepo "$tmp/four"
  $keys = "`n`n$([char]27)[B$([char]27)[B$([char]27)[A`nb`n`n$([char]27)[B`ndocs/refs`n`n2$([char]27)[B`n`n"
  $env:WDTD_KEYS = $keys
  Push-Location "$tmp/four"
  try { $out = (& $script) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if (-not (Test-Path "$tmp/four/.cursor/rules/whatdoesthisdo.mdc")) { Fail "interactive: agent changed from the summary to cursor was not applied" }
  if (Test-Path "$tmp/four/CLAUDE.md") { Fail "interactive: CLAUDE.md written although the final agent was cursor" }
  if ((Get-Content -Raw "$tmp/four/.claude/skills/whatdoesthisdo/SKILL.md") -notmatch "docs/refs/") { Fail "interactive: typed folder not applied" }
  if (-not (Test-Path "$tmp/four/docs/refs/README.md")) { Fail "interactive: typed folder not created" }
  if ($out -notmatch "Set up") { Fail "interactive: no success message" }
  if ($out -notmatch "Reload Window") { Fail "interactive: no reload reminder" }

  NewRepo "$tmp/five"
  $env:WDTD_KEYS = "q"
  Push-Location "$tmp/five"
  try { $out = (& $script) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if ($out -notmatch "nothing written") { Fail "quit did not say nothing written" }
  if (Test-Path "$tmp/five/.claude") { Fail "quit wrote the skill" }

  # uninstall in project scope removes what install wrote and keeps everything else
  NewRepo "$tmp/six"
  Set-Content -Path "$tmp/six/CLAUDE.md" -Value "# My rules`n`nKeep them."
  Run "$tmp/six" @{ Agent = "both"; Scope = "project"; Yes = $true } | Out-Null
  $out = (Run "$tmp/six/src" @{ Uninstall = $true; Scope = "project" }) -join "`n"
  if ($out -notmatch "Removed") { Fail "uninstall did not report what it removed" }
  if (Test-Path "$tmp/six/.claude") { Fail "uninstall left the skill folder" }
  if (Test-Path "$tmp/six/.cursor") { Fail "uninstall left the cursor rule" }
  $claude = Get-Content -Raw "$tmp/six/CLAUDE.md"
  if ($claude -notmatch "Keep them.") { Fail "uninstall lost the rest of CLAUDE.md" }
  if ($claude -match "whatdoesthisdo:start") { Fail "uninstall left the rule block" }
  if (-not (Test-Path "$tmp/six/docs/whatdoesthisdo/references/README.md")) { Fail "uninstall removed the references folder" }
  if ($out -match "User Rules") { Fail "project uninstall mentioned the pasted Cursor rule" }

  # a CLAUDE.md that held only the block is deleted, and a second uninstall finds nothing
  NewRepo "$tmp/seven"
  Run "$tmp/seven" @{ Agent = "claude"; Scope = "project"; Yes = $true } | Out-Null
  Run "$tmp/seven" @{ Uninstall = $true; Scope = "project" } | Out-Null
  if (Test-Path "$tmp/seven/CLAUDE.md") { Fail "empty CLAUDE.md not deleted" }
  $out = (Run "$tmp/seven" @{ Uninstall = $true; Scope = "project" }) -join "`n"
  if ($out -notmatch "Nothing from WhatDoesThisDo") { Fail "uninstall with nothing installed did not say so" }

  # uninstall in global scope removes under HOME and reminds about the pasted Cursor rule
  Run "$tmp/seven" @{ Agent = "both"; Scope = "global"; Yes = $true } | Out-Null
  $out = (Run "$tmp/seven" @{ Uninstall = $true; Scope = "global" }) -join "`n"
  if (Test-Path "$tmp/home/.claude/skills/whatdoesthisdo") { Fail "global uninstall left the skill" }
  if (Test-Path "$tmp/home/.claude/CLAUDE.md") { Fail "global uninstall left the CLAUDE.md block" }
  if (-not (Test-Path "$tmp/home/.claude")) { Fail "global uninstall removed ~/.claude itself" }
  if ($out -notmatch "User Rules") { Fail "global uninstall did not mention the pasted Cursor rule" }

  # interactive uninstall: down to Uninstall, project scope, confirm on the summary
  NewRepo "$tmp/eight"
  Run "$tmp/eight" @{ Agent = "both"; Scope = "project"; Yes = $true } | Out-Null
  $env:WDTD_KEYS = "`n$([char]27)[B`n`n`n"
  Push-Location "$tmp/eight"
  try { $out = (& $script) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if ($out -notmatch "Uninstalled") { Fail "interactive uninstall: no success message" }
  if (Test-Path "$tmp/eight/.claude") { Fail "interactive uninstall left the skill folder" }
  if (Test-Path "$tmp/eight/CLAUDE.md") { Fail "interactive uninstall left CLAUDE.md" }

  # interactive uninstall with nothing installed: enter does nothing, q leaves
  NewRepo "$tmp/nine"
  $env:WDTD_KEYS = "`n$([char]27)[B`n`n`nq"
  Push-Location "$tmp/nine"
  try { $out = (& $script) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if ($out -notmatch "nothing removed") { Fail "interactive empty uninstall did not say nothing removed" }

  # cursor-only install and uninstall: no CLAUDE.md ever, our rule file goes, other rule files stay
  NewRepo "$tmp/ten"
  New-Item -ItemType Directory -Path "$tmp/ten/.cursor/rules" -Force | Out-Null
  Set-Content -Path "$tmp/ten/.cursor/rules/mine.mdc" -Value "mine"
  Run "$tmp/ten" @{ Agent = "cursor"; Scope = "project"; Yes = $true } | Out-Null
  Run "$tmp/ten" @{ Uninstall = $true; Scope = "project" } | Out-Null
  if (Test-Path "$tmp/ten/CLAUDE.md") { Fail "cursor-only uninstall created CLAUDE.md" }
  if (Test-Path "$tmp/ten/.cursor/rules/whatdoesthisdo.mdc") { Fail "cursor-only uninstall left our rule" }
  if (-not (Test-Path "$tmp/ten/.cursor/rules/mine.mdc")) { Fail "uninstall removed another rule file" }
  if (Test-Path "$tmp/ten/.claude") { Fail "cursor-only uninstall left the skill folder" }

  # a global CLAUDE.md keeps your own content around the block
  Set-Content -Path "$tmp/home/.claude/CLAUDE.md" -Value "# Mine`n`nStay."
  Run "$tmp/ten" @{ Agent = "claude"; Scope = "global"; Yes = $true } | Out-Null
  Run "$tmp/ten" @{ Uninstall = $true; Scope = "global" } | Out-Null
  $claude = Get-Content -Raw "$tmp/home/.claude/CLAUDE.md"
  if ($claude -notmatch "Stay.") { Fail "global uninstall lost your own CLAUDE.md content" }
  if ($claude -match "whatdoesthisdo:start") { Fail "global uninstall left the block" }
  Remove-Item -Force "$tmp/home/.claude/CLAUDE.md"

  # uninstall touches nothing else in the project, and a reinstall after it works
  NewRepo "$tmp/eleven"
  Run "$tmp/eleven" @{ Agent = "both"; Scope = "project"; Yes = $true } | Out-Null
  Set-Content -Path "$tmp/eleven/extra.txt" -Value "x"
  Run "$tmp/eleven" @{ Uninstall = $true; Scope = "project" } | Out-Null
  if (-not (Test-Path "$tmp/eleven/extra.txt")) { Fail "uninstall removed a file it did not write" }
  if (-not (Test-Path "$tmp/eleven/src/a.ts")) { Fail "uninstall removed a source file" }
  Run "$tmp/eleven" @{ Agent = "both"; Scope = "project"; Yes = $true } | Out-Null
  if (-not (Test-Path "$tmp/eleven/.claude/skills/whatdoesthisdo/SKILL.md")) { Fail "reinstall did not write the skill" }
  if ((Get-Content -Raw "$tmp/eleven/CLAUDE.md") -notmatch "whatdoesthisdo:start") { Fail "reinstall did not write the block" }
  if (-not (Test-Path "$tmp/eleven/.cursor/rules/whatdoesthisdo.mdc")) { Fail "reinstall did not write the cursor rule" }

  # uninstall in project scope outside a repository stops with an error
  $failed = $false
  try { Run "$tmp/norepo" @{ Uninstall = $true; Scope = "project" } *> $null; if ($LASTEXITCODE -ne 0) { $failed = $true } } catch { $failed = $true }
  if (-not $failed) { Fail "uninstall outside a repo did not fail" }

  # interactive: from the install summary, 1 switches to Uninstall, 2 revisits the scope, enter removes
  NewRepo "$tmp/twelve"
  Run "$tmp/twelve" @{ Agent = "both"; Scope = "project"; Yes = $true } | Out-Null
  $env:WDTD_KEYS = "`n`n`n`n`n1$([char]27)[B`n`n2`n`n"
  Push-Location "$tmp/twelve"
  try { $out = (& $script) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if ($out -notmatch "Uninstalled") { Fail "mode switch: no uninstall success message" }
  if (Test-Path "$tmp/twelve/.claude") { Fail "mode switch: skill folder not removed" }

  # interactive: q on an uninstall summary that lists files removes nothing
  Run "$tmp/twelve" @{ Agent = "both"; Scope = "project"; Yes = $true } | Out-Null
  $env:WDTD_KEYS = "`n$([char]27)[B`n`nq"
  Push-Location "$tmp/twelve"
  try { $out = (& $script) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if ($out -notmatch "nothing removed") { Fail "quit on uninstall summary did not say nothing removed" }
  if (-not (Test-Path "$tmp/twelve/.claude/skills/whatdoesthisdo/SKILL.md")) { Fail "quit on uninstall summary removed the skill" }

  # interactive install: global scope, back from the folder screen, jump keys 3 and 4
  NewRepo "$tmp/thirteen"
  $env:WDTD_KEYS = "`n`n`n$([char]27)[B`nb`n`n3`n4`n`n"
  Push-Location "$tmp/thirteen"
  try { $out = (& $script) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if (-not (Test-Path "$tmp/home/.claude/skills/whatdoesthisdo/SKILL.md")) { Fail "interactive global: skill not written under HOME" }
  if (Test-Path "$tmp/thirteen/.claude") { Fail "interactive global: skill written in the project" }
  if ($out -notmatch "User Rules") { Fail "interactive global: paste instruction missing" }
  Run "$tmp/thirteen" @{ Uninstall = $true; Scope = "global" } | Out-Null

  # an unknown parameter fails
  $failed = $false
  try { Run "$tmp/thirteen" @{ Bogus = $true } *> $null; if ($LASTEXITCODE -ne 0) { $failed = $true } } catch { $failed = $true }
  if (-not $failed) { Fail "unknown parameter did not fail" }

  Write-Host "setup tests passed: setup-windows.ps1"
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
