<#
.SYNOPSIS
    Renders the demo status page, bakes it into the Worker, and deploys to Cloudflare.

.DESCRIPTION
    Pipeline:
        demo-status.json  ->  demo-status.html  ->  src/status.gen.js  ->  wrangler deploy

    demo-status.json stays the single source of truth. Nothing here edits it.

    Produces two variants in one build: the full page, and a redacted one with the client
    name, contract number, submittal identifiers and the client-performance observation
    removed. Which one is served is decided at deploy time by PUBLIC_MODE in wrangler.toml,
    so switching does not require a rebuild.

.EXAMPLE
    pwsh build-and-deploy.ps1 -NewSlug      # first run: mint a slug
    pwsh build-and-deploy.ps1               # subsequent: rebuild and deploy
    pwsh build-and-deploy.ps1 -BuildOnly    # render + bake, do not deploy
#>
[CmdletBinding()]
param(
    [switch] $NewSlug,
    [switch] $BuildOnly,
    [ValidateSet('full', 'redacted')] [string] $Mode
)

$ErrorActionPreference = 'Stop'
$here     = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $here '..')).Path
$jsonPath = Join-Path $repoRoot 'demo-status.json'
$htmlPath = Join-Path $repoRoot 'demo-status.html'
$genPath  = Join-Path $here 'src\status.gen.js'
$tomlPath = Join-Path $here 'wrangler.toml'
$redactionsPath = Join-Path $here 'redactions.local.json'

# ---------------------------------------------------------------- 1. mint a slug
if ($NewSlug) {
    # 14 chars, lowercase alphanumeric — same shape as the Boardly slugs.
    $alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray()
    $bytes = [byte[]]::new(14)
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    $slug = -join ($bytes | ForEach-Object { $alphabet[$_ % $alphabet.Length] })

    $toml = Get-Content -LiteralPath $tomlPath -Raw
    $toml = [regex]::Replace($toml, '(?m)^SLUG\s*=\s*".*"$', ('SLUG = "{0}"' -f $slug))
    Set-Content -LiteralPath $tomlPath -Value $toml -Encoding UTF8
    Write-Output "NEW_SLUG=$slug"
    Write-Warning 'The previous URL is now dead. That is the only revocation this design has.'
}

if ($Mode) {
    $toml = Get-Content -LiteralPath $tomlPath -Raw
    $toml = [regex]::Replace($toml, '(?m)^PUBLIC_MODE\s*=\s*".*"$', ('PUBLIC_MODE = "{0}"' -f $Mode))
    Set-Content -LiteralPath $tomlPath -Value $toml -Encoding UTF8
    Write-Output "MODE=$Mode"
}

# ---------------------------------------------------------------- 2. render
& (Join-Path $repoRoot 'scripts\render-demo-status.ps1') | ForEach-Object { Write-Output $_ }
if (-not (Test-Path -LiteralPath $htmlPath)) { throw "Render produced no HTML at $htmlPath." }

$full = Get-Content -LiteralPath $htmlPath -Raw
$data = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json

# ---------------------------------------------------------------- 3. redacted variant
# Deliberately conservative: it removes identifiers rather than trying to reword prose.
# Anything it cannot confidently redact stays out of the redacted build entirely.
$redacted = $full

# The patterns live in redactions.local.json, NOT here. To redact a term you have to name
# it, so a hardcoded list would publish the client name and contract number to this repo —
# which is public — even while the deployed page stays clean. The .local. file is covered by
# the existing '*.local.*' ignore rule.
#
# Ordering is the caller's responsibility and it matters: most-specific first, because the
# submittal reference is a superstring of the contract number. See the comment in that file.
if (-not (Test-Path -LiteralPath $redactionsPath)) {
    throw @"
Redaction config missing: $redactionsPath
Refusing to build. A 'redacted' page built without patterns would be the full page wearing
a safe label, which is worse than no redaction at all.
See status-site/README.md for the file's shape.
"@
}
$cfg = Get-Content -LiteralPath $redactionsPath -Raw | ConvertFrom-Json
if (-not $cfg.redactions -or @($cfg.redactions).Count -eq 0) {
    throw "No redaction patterns in $redactionsPath. Refusing to build a 'redacted' page with an empty rule set."
}
foreach ($r in $cfg.redactions) {
    $redacted = [regex]::Replace($redacted, $r.pattern, $r.with)
}
# The headline card names a specific document and its age. Strip the block wholesale rather
# than trusting a regex to neuter the sentence. This single replace consumes the entire
# headline block up to the next <h2> — hero div included — so the page never carries a
# stray hero afterwards. (A second hero-only sweep once lived here; it was dead code, the
# hero is already gone by this point.)
$redacted = [regex]::Replace(
    $redacted,
    "(?s)<h2>The headline</h2>.*?</div>\s*(?=<h2>)",
    "<h2>The headline</h2><div class='card'><p>Withheld in the shared view. Ask Sushil.</p></div>")

# ---- assert the redaction actually worked, and fail the build if it did not.
# An automated redaction nobody verified is more dangerous than none, because it feels safe.
# This runs on every build so the check cannot be forgotten.
$survivors = @()
foreach ($term in $cfg.verify) {
    if ($redacted -match [regex]::Escape($term)) { $survivors += $term }
}
if ($survivors.Count -gt 0) {
    throw ("REDACTION FAILED — these terms survived into the redacted page: {0}. Not deploying." -f ($survivors -join ', '))
}
# A redaction that strips the page to nothing is also a failure.
foreach ($needed in @('<h2>Fifteen days</h2>', '<h2>Four depths</h2>', '<h2>Blockers</h2>', '<h2>Risks</h2>')) {
    if ($redacted -notmatch [regex]::Escape($needed)) {
        throw "REDACTION OVERREACHED — '$needed' is missing from the redacted page. Not deploying."
    }
}
Write-Output ("REDACTION_VERIFIED={0} terms absent, structure intact" -f @($cfg.verify).Count)

# ---------------------------------------------------------------- 4. bake
function JsString([string] $s) { $s | ConvertTo-Json -Depth 1 -Compress }

$meta = [ordered]@{
    track        = $data.track
    last_updated = $data.last_updated
    demo_date    = $data.demo_date
    day          = $data.current.day
    of           = $data.current.of
    demo_ready   = $data.demo_ready
}

$gen = @"
// GENERATED — do not edit. Produced by build-and-deploy.ps1 from demo-status.json.
// Rebuild with: pwsh build-and-deploy.ps1
export const HTML_FULL = $(JsString $full);
export const HTML_REDACTED = $(JsString $redacted);
export const META = $($meta | ConvertTo-Json -Compress);
"@

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $genPath) | Out-Null
Set-Content -LiteralPath $genPath -Value $gen -Encoding UTF8
Write-Output ("BAKED={0} ({1:N0} bytes full, {2:N0} redacted)" -f $genPath, $full.Length, $redacted.Length)

# ---------------------------------------------------------------- 5. deploy
$slugNow = ([regex]::Match((Get-Content -LiteralPath $tomlPath -Raw), '(?m)^SLUG\s*=\s*"(.*)"$')).Groups[1].Value
$modeNow = ([regex]::Match((Get-Content -LiteralPath $tomlPath -Raw), '(?m)^PUBLIC_MODE\s*=\s*"(.*)"$')).Groups[1].Value

# -BuildOnly just renders and bakes (used to verify the redaction), so it must not require a
# slug — the slug is only needed to actually deploy. Return before the deploy-only guard.
if ($BuildOnly) {
    Write-Output 'BUILD_ONLY=1 — not deploying.'
    if ($slugNow -eq 'REPLACE_ME' -or [string]::IsNullOrWhiteSpace($slugNow)) {
        Write-Output 'WOULD_SERVE=(no slug yet — run with -NewSlug before deploying)'
    } else {
        Write-Output "WOULD_SERVE=/b/$slugNow (mode: $modeNow)"
    }
    return
}

if ($slugNow -eq 'REPLACE_ME' -or [string]::IsNullOrWhiteSpace($slugNow)) {
    throw 'No slug set. Run with -NewSlug first.'
}

Push-Location $here
try {
    npx wrangler deploy
}
finally { Pop-Location }

Write-Output ''
Write-Output "SLUG=$slugNow"
Write-Output "MODE=$modeNow"
Write-Output "URL=https://construction-demo-status.<your-subdomain>.workers.dev/b/$slugNow"
Write-Output '  (wrangler prints the exact hostname on first deploy — record it in README.md)'

if ($modeNow -eq 'full') {
    Write-Warning 'Serving the FULL page: client name, contract number and the thirteen-months-open observation are all live at that URL. Anyone with the link has it permanently.'
}
