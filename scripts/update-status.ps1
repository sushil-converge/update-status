<#
.SYNOPSIS
    Daily end-of-workday STATUS.md update, run by Codex CLI unattended.

.DESCRIPTION
    Pipes .codex/update-status.md into `codex exec -` with the Construction root as the
    workspace, then commits and pushes STATUS.md if (and only if) it changed.

    Codex is given workspace-write sandbox, which lets it write inside the workspace root.
    The prompt constrains it to a single file; this script additionally refuses to commit
    anything other than STATUS.md, so a misbehaving run cannot quietly ship other edits.

.PARAMETER WorkspaceRoot
    Construction root. Codex runs here so it can read every component repo and plans/.

.PARAMETER DryRun
    Run Codex and show the diff, but do not commit or push.

.EXAMPLE
    .\update-status.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [string]$WorkspaceRoot = 'D:\Vault\Projects\Construction',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --- Paths -------------------------------------------------------------------

$StatusRepo  = Join-Path $WorkspaceRoot 'project-status'
$PromptFile  = Join-Path $StatusRepo   '.codex\update-status.md'
$StatusFile  = Join-Path $StatusRepo   'STATUS.md'
$LogDir      = Join-Path $StatusRepo   '.codex\logs'
$Stamp       = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$RunLog      = Join-Path $LogDir "run_$Stamp.log"
$LastMsg     = Join-Path $LogDir "last_$Stamp.txt"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'HH:mm:ss'), $Level, $Message
    Write-Host $line
    Add-Content -LiteralPath $RunLog -Value $line -Encoding utf8
}

Write-Log "=== STATUS.md update starting ==="
Write-Log "Workspace: $WorkspaceRoot"

# --- Preflight ---------------------------------------------------------------

foreach ($p in @($WorkspaceRoot, $StatusRepo, $PromptFile, $StatusFile)) {
    if (-not (Test-Path -LiteralPath $p)) {
        Write-Log "Missing required path: $p" 'FATAL'
        exit 1
    }
}

$codex = Get-Command codex -ErrorAction SilentlyContinue
if (-not $codex) {
    Write-Log "Codex CLI not found on PATH. Install it, or hardcode the full path below." 'FATAL'
    exit 1
}
Write-Log "Codex: $($codex.Source)"

# Refuse to run on a dirty STATUS.md - we would not be able to tell our change from a human's.
$preDirty = & git -C $StatusRepo status --porcelain -- 'STATUS.md'
if ($preDirty) {
    Write-Log "STATUS.md has uncommitted local changes. Commit or discard them first." 'FATAL'
    exit 1
}

# Record the pre-run hash so we can tell whether Codex actually changed anything.
$preHash = (Get-FileHash -LiteralPath $StatusFile -Algorithm SHA256).Hash

# Refresh the component repos' view of the world. Read-only; never touches working trees.
Write-Log "Fetching component repos (read-only)..."
Get-ChildItem -LiteralPath $WorkspaceRoot -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName '.git') } |
    ForEach-Object {
        & git -C $_.FullName fetch --quiet --all 2>&1 | Out-Null
        Write-Log "  fetched $($_.Name)"
    }

# --- Run Codex ---------------------------------------------------------------

Write-Log "Running codex exec..."

$prompt = Get-Content -LiteralPath $PromptFile -Raw

# codex exec reads the prompt from stdin when given "-".
# --sandbox workspace-write : allow file writes inside the workspace root
# --cd                      : set the workspace root (all component repos are visible)
# -o                        : write the final agent message to a file for the morning read
$prompt | & codex exec - `
    --cd $WorkspaceRoot `
    --sandbox workspace-write `
    -o $LastMsg 2>&1 |
    Tee-Object -FilePath $RunLog -Append

$codexExit = $LASTEXITCODE
Write-Log "codex exec exit code: $codexExit"

if ($codexExit -ne 0) {
    Write-Log "Codex run failed. Not committing. See $RunLog" 'ERROR'
    exit $codexExit
}

if (Test-Path -LiteralPath $LastMsg) {
    Write-Log "--- Codex summary ---"
    Get-Content -LiteralPath $LastMsg | ForEach-Object { Write-Log "  $_" }
    Write-Log "---------------------"
}

# --- Guardrail: only STATUS.md may have changed -------------------------------

$changed = & git -C $StatusRepo status --porcelain |
    ForEach-Object { $_.Substring(3).Trim().Trim('"') } |
    Where-Object { $_ -and ($_ -notlike '.codex/logs/*') }

$unexpected = $changed | Where-Object { $_ -ne 'STATUS.md' }
if ($unexpected) {
    Write-Log "Codex modified files it should not have: $($unexpected -join ', ')" 'ERROR'
    Write-Log "Reverting those files. STATUS.md is left in place for manual review." 'ERROR'
    foreach ($f in $unexpected) {
        & git -C $StatusRepo checkout -- $f 2>&1 | Out-Null
    }
    Write-Log "Not committing. Inspect $StatusRepo manually." 'ERROR'
    exit 2
}

$postHash = (Get-FileHash -LiteralPath $StatusFile -Algorithm SHA256).Hash
if ($preHash -eq $postHash) {
    Write-Log "STATUS.md unchanged - Codex made no edit. Nothing to commit." 'WARN'
    Write-Log "This is worth checking: the prompt asks it to bump last_updated every run."
    exit 0
}

# --- Commit and push ----------------------------------------------------------

if ($DryRun) {
    Write-Log "DryRun: showing diff, not committing."
    & git -C $StatusRepo --no-pager diff -- STATUS.md
    exit 0
}

$today = Get-Date -Format 'yyyy-MM-dd'
& git -C $StatusRepo add -- STATUS.md
& git -C $StatusRepo commit -m "status: daily update $today" 2>&1 | Tee-Object -FilePath $RunLog -Append

if ($LASTEXITCODE -ne 0) {
    Write-Log "git commit failed." 'ERROR'
    exit 3
}

& git -C $StatusRepo push 2>&1 | Tee-Object -FilePath $RunLog -Append

if ($LASTEXITCODE -ne 0) {
    Write-Log "git push failed - the commit is local. Push manually or check credentials." 'ERROR'
    exit 4
}

Write-Log "Pushed. === done ==="
exit 0
