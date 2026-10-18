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

  Write-Host "setup tests passed: setup-windows.ps1"
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
