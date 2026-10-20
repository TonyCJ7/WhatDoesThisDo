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
  $env:WDTD_KEYS = "`n$([char]27)[B$([char]27)[B`n`n`n"
  Push-Location "$tmp/eight"
  try { $out = (& $script) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if ($out -notmatch "Uninstalled") { Fail "interactive uninstall: no success message" }
  if (Test-Path "$tmp/eight/.claude") { Fail "interactive uninstall left the skill folder" }
  if (Test-Path "$tmp/eight/CLAUDE.md") { Fail "interactive uninstall left CLAUDE.md" }

  # interactive uninstall with nothing installed: enter does nothing, q leaves
  NewRepo "$tmp/nine"
  $env:WDTD_KEYS = "`n$([char]27)[B$([char]27)[B`n`n`nq"
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
  $env:WDTD_KEYS = "`n`n`n`n`n1$([char]27)[B$([char]27)[B`n`n2`n`n"
  Push-Location "$tmp/twelve"
  try { $out = (& $script) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if ($out -notmatch "Uninstalled") { Fail "mode switch: no uninstall success message" }
  if (Test-Path "$tmp/twelve/.claude") { Fail "mode switch: skill folder not removed" }

  # interactive: q on an uninstall summary that lists files removes nothing
  Run "$tmp/twelve" @{ Agent = "both"; Scope = "project"; Yes = $true } | Out-Null
  $env:WDTD_KEYS = "`n$([char]27)[B$([char]27)[B`n`nq"
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

  # update replaces an outdated skill and rule block, keeps the rest of CLAUDE.md, its place, and the custom folder
  NewRepo "$tmp/fourteen"
  Set-Content -Path "$tmp/fourteen/CLAUDE.md" -Value "# My rules`n`nKeep them."
  Run "$tmp/fourteen" @{ Agent = "both"; Scope = "project"; Folder = "docs/refs"; Yes = $true } | Out-Null
  Add-Content -Path "$tmp/fourteen/.claude/skills/whatdoesthisdo/SKILL.md" -Value "old line"
  $claude = (Get-Content -Raw "$tmp/fourteen/CLAUDE.md").Replace("read its entry", "read its old entry") + "`nTail rule.`n"
  [IO.File]::WriteAllText("$tmp/fourteen/CLAUDE.md", $claude)
  $out = (Run "$tmp/fourteen/src" @{ Update = $true }) -join "`n"
  if ($out -notmatch "Updated") { Fail "update did not report what it updated" }
  if ($out -match "whatdoesthisdo.mdc") { Fail "update reported the cursor rule although it was current" }
  $expected = (Get-Content -Raw "$agentDir/skill/SKILL.md").Replace("docs/whatdoesthisdo/references", "docs/refs")
  if ((Get-Content -Raw "$tmp/fourteen/.claude/skills/whatdoesthisdo/SKILL.md") -ne $expected) { Fail "update did not refresh the skill with the custom folder" }
  $claude = Get-Content -Raw "$tmp/fourteen/CLAUDE.md"
  if ($claude -notmatch "Keep them.") { Fail "update lost the rest of CLAUDE.md" }
  if ($claude -notmatch "Tail rule.") { Fail "update lost text after the block" }
  if (-not $claude.StartsWith("# My rules")) { Fail "update moved the block" }
  if ($claude -match "old entry") { Fail "update left the outdated block" }
  if (([regex]::Matches($claude, "whatdoesthisdo:start")).Count -ne 1) { Fail "update duplicated the block" }
  if ($claude -notmatch "docs/refs/") { Fail "update lost the custom folder in the block" }

  # everything current says so and changes nothing
  $before = (Get-Content -Raw "$tmp/fourteen/CLAUDE.md") + (Get-Content -Raw "$tmp/fourteen/.claude/skills/whatdoesthisdo/SKILL.md")
  $out = (Run "$tmp/fourteen" @{ Update = $true }) -join "`n"
  if ($out -notmatch "up to date") { Fail "update with current files did not say so" }
  $after = (Get-Content -Raw "$tmp/fourteen/CLAUDE.md") + (Get-Content -Raw "$tmp/fourteen/.claude/skills/whatdoesthisdo/SKILL.md")
  if ($before -ne $after) { Fail "update with current files changed something" }

  # a cursor-only setup is updated without creating CLAUDE.md
  NewRepo "$tmp/fifteen"
  Run "$tmp/fifteen" @{ Agent = "cursor"; Scope = "project"; Yes = $true } | Out-Null
  Add-Content -Path "$tmp/fifteen/.cursor/rules/whatdoesthisdo.mdc" -Value "old"
  Run "$tmp/fifteen" @{ Update = $true } | Out-Null
  if ((Get-Content -Raw "$tmp/fifteen/.cursor/rules/whatdoesthisdo.mdc") -ne (Get-Content -Raw "$agentDir/cursor-rule.mdc")) { Fail "update did not refresh the cursor rule" }
  if (Test-Path "$tmp/fifteen/CLAUDE.md") { Fail "update created CLAUDE.md for a cursor-only setup" }

  # nothing installed anywhere says so
  NewRepo "$tmp/sixteen"
  $out = (Run "$tmp/sixteen" @{ Update = $true }) -join "`n"
  if ($out -notmatch "Nothing from WhatDoesThisDo") { Fail "update with nothing installed did not say so" }

  # project and home are updated in one run, with the note to paste the Cursor rule again
  Run "$tmp/sixteen" @{ Agent = "both"; Scope = "project"; Yes = $true } | Out-Null
  Run "$tmp/sixteen" @{ Agent = "both"; Scope = "global"; Yes = $true } | Out-Null
  Add-Content -Path "$tmp/sixteen/.claude/skills/whatdoesthisdo/SKILL.md" -Value "old"
  Add-Content -Path "$tmp/home/.claude/skills/whatdoesthisdo/SKILL.md" -Value "old"
  $out = (Run "$tmp/sixteen" @{ Update = $true }) -join "`n"
  if ((Get-Content -Raw "$tmp/sixteen/.claude/skills/whatdoesthisdo/SKILL.md") -ne (Get-Content -Raw "$agentDir/skill/SKILL.md")) { Fail "update did not refresh the project skill" }
  if ((Get-Content -Raw "$tmp/home/.claude/skills/whatdoesthisdo/SKILL.md") -ne (Get-Content -Raw "$agentDir/skill/SKILL.md")) { Fail "update did not refresh the home skill" }
  if ($out -notmatch "User Rules") { Fail "update of the home skill did not mention the pasted Cursor rule" }
  Run "$tmp/sixteen" @{ Uninstall = $true; Scope = "global" } | Out-Null

  # interactive update: down to Update, enter on the summary
  NewRepo "$tmp/seventeen"
  Run "$tmp/seventeen" @{ Agent = "both"; Scope = "project"; Yes = $true } | Out-Null
  Add-Content -Path "$tmp/seventeen/.claude/skills/whatdoesthisdo/SKILL.md" -Value "old"
  $env:WDTD_KEYS = "`n$([char]27)[B`n`n"
  Push-Location "$tmp/seventeen"
  try { $out = (& $script) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if ($out -notmatch "Updated") { Fail "interactive update: no success message" }
  if ((Get-Content -Raw "$tmp/seventeen/.claude/skills/whatdoesthisdo/SKILL.md") -ne (Get-Content -Raw "$agentDir/skill/SKILL.md")) { Fail "interactive update did not refresh the skill" }

  # interactive update with everything current: enter does nothing, q leaves
  $env:WDTD_KEYS = "`n$([char]27)[B`n`nq"
  Push-Location "$tmp/seventeen"
  try { $out = (& $script) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if ($out -notmatch "nothing updated") { Fail "interactive current update did not say nothing updated" }

  # interactive: from the update summary, 1 changes the action to Install and the scope step starts on This project
  $env:WDTD_KEYS = "`n$([char]27)[B`n1$([char]27)[A`n`n`n`nq"
  Push-Location "$tmp/seventeen"
  try { $out = (& $script 6>&1) -join "`n" } finally { Pop-Location; Remove-Item Env:WDTD_KEYS }
  if ($out -notmatch "Scope\s+This project") { Fail "action switch from update did not preselect this project" }
  if ($out -notmatch "nothing written") { Fail "action switch from update did not end with nothing written" }

  Write-Host "setup tests passed: setup-windows.ps1"
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
