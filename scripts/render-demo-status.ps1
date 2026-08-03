<#
.SYNOPSIS
    Renders demo-status.html from demo-status.json.

.DESCRIPTION
    demo-status.json is the single source of truth. This script produces a self-contained
    HTML view of it — no CDN, no build step, no network. Open the output in a browser or
    commit it so GitHub Pages / a raw preview can serve it.

    Read-only with respect to the JSON. It never writes back.

.EXAMPLE
    pwsh scripts/render-demo-status.ps1
    pwsh scripts/render-demo-status.ps1 -Open
#>
[CmdletBinding()]
param(
    [string] $JsonPath = (Join-Path $PSScriptRoot '..\demo-status.json'),
    [string] $OutPath  = (Join-Path $PSScriptRoot '..\demo-status.html'),
    [switch] $Open
)

$ErrorActionPreference = 'Stop'

$jsonFull = (Resolve-Path -LiteralPath $JsonPath).Path
$data = Get-Content -LiteralPath $jsonFull -Raw | ConvertFrom-Json

function HtmlEncode([object] $Value) {
    if ($null -eq $Value) { return '' }
    [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

# state -> css class. Unknown states fall through to 'unknown' rather than being dropped,
# so a typo in the JSON shows up on the page instead of disappearing.
function StateClass([string] $State) {
    switch ($State) {
        'passed'      { 'ok' }
        'accepted'    { 'ok' }
        'complete'    { 'ok' }
        'in_progress' { 'active' }
        'current'     { 'active' }
        'pending'     { 'idle' }
        'not_started' { 'idle' }
        'open'        { 'warn' }
        'verify'      { 'warn' }
        'blocked'     { 'bad' }
        'failed'      { 'bad' }
        'realised'    { 'bad' }
        default       { 'unknown' }
    }
}

$daysLeft = try {
    [int]([datetime]::Parse($data.demo_date) - [datetime]::Parse($data.last_updated)).TotalDays
} catch { $null }

$sb = [System.Text.StringBuilder]::new()
function W([string] $Line) { [void]$sb.AppendLine($Line) }

W '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">'
W '<meta name="viewport" content="width=device-width, initial-scale=1">'
W ("<title>Demo Status — {0}</title>" -f (HtmlEncode $data.project))
W @'
<style>
  :root{--bg:#0f1115;--card:#171a21;--line:#252a34;--fg:#e6e8ec;--dim:#9aa2b1;
        --ok:#3fb950;--active:#d29922;--idle:#6e7681;--warn:#db6d28;--bad:#f85149;--unknown:#a371f7;
        --accent:#c2410c}
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--fg);
       font:15px/1.55 ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif}
  .wrap{max-width:1080px;margin:0 auto;padding:32px 20px 72px}
  h1{font-size:24px;margin:0 0 4px} h2{font-size:16px;margin:34px 0 12px;
     text-transform:uppercase;letter-spacing:.08em;color:var(--dim)}
  .sub{color:var(--dim);margin-bottom:22px;font-size:14px}
  .hero{background:var(--card);border:1px solid var(--line);border-left:3px solid var(--accent);
        border-radius:10px;padding:18px 20px;margin-bottom:8px}
  .hero .id{font-family:ui-monospace,Consolas,monospace;font-size:17px;color:var(--accent)}
  .grid{display:grid;gap:12px;grid-template-columns:repeat(auto-fit,minmax(215px,1fr))}
  .card{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px 16px}
  .card h3{margin:0 0 6px;font-size:14px} .card p{margin:0;color:var(--dim);font-size:13px}
  .metric{font-size:27px;font-weight:600} .metric small{font-size:13px;color:var(--dim);font-weight:400}
  table{width:100%;border-collapse:collapse;margin-top:6px;font-size:14px}
  th,td{text-align:left;padding:9px 10px;border-bottom:1px solid var(--line);vertical-align:top}
  th{color:var(--dim);font-weight:500;font-size:12px;text-transform:uppercase;letter-spacing:.06em}
  code{font-family:ui-monospace,Consolas,monospace;font-size:13px;color:var(--accent)}
  .pill{display:inline-block;padding:1px 9px;border-radius:999px;font-size:11px;
        text-transform:uppercase;letter-spacing:.05em;border:1px solid}
  .ok{color:var(--ok);border-color:var(--ok)} .active{color:var(--active);border-color:var(--active)}
  .idle{color:var(--idle);border-color:var(--idle)} .warn{color:var(--warn);border-color:var(--warn)}
  .bad{color:var(--bad);border-color:var(--bad)} .unknown{color:var(--unknown);border-color:var(--unknown)}
  .days{display:flex;gap:5px;flex-wrap:wrap;margin:10px 0 4px}
  .day{flex:1;min-width:52px;text-align:center;padding:9px 4px;border-radius:7px;
       background:var(--card);border:1px solid var(--line);font-size:12px}
  .day.done{border-color:var(--ok)} .day.now{border-color:var(--active);background:#1e1c14}
  .day b{display:block;font-size:15px}
  .note{background:#1a1512;border:1px solid var(--warn);border-radius:8px;padding:11px 14px;
        color:#e8c9b0;font-size:13px;margin:10px 0}
  ul.never{margin:6px 0 0;padding-left:20px;color:var(--dim);font-size:13px}
  ul.never li{margin:4px 0}
  footer{margin-top:44px;color:var(--idle);font-size:12px;border-top:1px solid var(--line);padding-top:14px}
</style></head><body><div class="wrap">
'@

W ("<h1>Demo Status — {0}</h1>" -f (HtmlEncode $data.track))
$daysTxt = if ($null -ne $daysLeft) { " · {0} days out" -f $daysLeft } else { '' }
W ("<div class='sub'>Updated {0} · demo {1}{2} · day {3} of {4}</div>" -f
    (HtmlEncode $data.last_updated), (HtmlEncode $data.demo_date), $daysTxt,
    (HtmlEncode $data.current.day), (HtmlEncode $data.current.of))

W ("<div class='card' style='margin-bottom:18px'><p>{0}</p></div>" -f (HtmlEncode $data.summary))

# ---- headline
W '<h2>The headline</h2>'
W ("<div class='hero'><div class='id'>{0}</div><p style='margin-top:6px;color:var(--dim)'>{1}</p></div>" -f
    (HtmlEncode $data.headline.submittal), (HtmlEncode $data.headline.why))

# ---- day strip
W '<h2>Fifteen days</h2><div class="days">'
foreach ($g in $data.gates) {
    $cls = if ($g.state -eq 'passed') { 'day done' } elseif ($g.day -eq $data.current.day) { 'day now' } else { 'day' }
    W ("<div class='{0}'><b>{1}</b>{2}</div>" -f $cls, $g.day, (HtmlEncode $g.date))
}
W '</div>'
W '<table><tr><th>Day</th><th>Gate</th><th>State</th></tr>'
foreach ($g in $data.gates) {
    W ("<tr><td>{0}</td><td>{1}</td><td><span class='pill {2}'>{3}</span></td></tr>" -f
        $g.day, (HtmlEncode $g.gate), (StateClass $g.state), (HtmlEncode $g.state))
}
W '</table>'

# ---- tiers
W '<h2>Four depths</h2><div class="grid">'
foreach ($t in $data.tiers) {
    W ("<div class='card'><h3>{0} — {1} <span class='pill {2}'>{3}</span></h3><p>{4}</p><p style='margin-top:8px'><code>{5}</code></p></div>" -f
        (HtmlEncode $t.id), (HtmlEncode $t.name), (StateClass $t.status), (HtmlEncode $t.status),
        (HtmlEncode $t.meaning), (HtmlEncode ($t.workflows -join ' · ')))
}
W '</div>'
W ("<div class='note'><b>Cut order.</b> {0}</div>" -f (HtmlEncode $data.cut_order))

# ---- rounds
W '<h2>Rounds</h2><table><tr><th>Round</th><th>What</th><th>Repo</th><th>Day</th><th>State</th></tr>'
foreach ($r in $data.rounds) {
    W ("<tr><td><code>{0}</code></td><td>{1}</td><td>{2}</td><td>{3}</td><td><span class='pill {4}'>{5}</span></td></tr>" -f
        (HtmlEncode $r.id), (HtmlEncode $r.title), (HtmlEncode $r.repo), $r.day,
        (StateClass $r.state), (HtmlEncode $r.state))
}
W '</table>'

# ---- blockers
if (@($data.blockers).Count -gt 0) {
    W '<h2>Blockers</h2><table><tr><th>#</th><th>What</th><th>Owner</th><th>Blocks</th></tr>'
    foreach ($b in $data.blockers) {
        W ("<tr><td><code>{0}</code></td><td><b>{1}</b><br><span style='color:var(--dim);font-size:13px'>{2}</span></td><td>{3}</td><td>{4}</td></tr>" -f
            (HtmlEncode $b.id), (HtmlEncode $b.title), (HtmlEncode $b.detail),
            (HtmlEncode $b.owner), (HtmlEncode ($b.blocks -join ', ')))
    }
    W '</table>'
}

# ---- prerequisites
W '<h2>Waiting on Sushil</h2><table><tr><th>#</th><th>What</th><th>By day</th><th>State</th></tr>'
foreach ($p in $data.prerequisites) {
    W ("<tr><td><code>{0}</code></td><td>{1}</td><td>{2}</td><td><span class='pill {3}'>{4}</span></td></tr>" -f
        (HtmlEncode $p.id), (HtmlEncode $p.title), $p.due_day, (StateClass $p.state), (HtmlEncode $p.state))
}
W '</table>'

# ---- counts
W '<h2>What we expect the import to find</h2>'
W ("<div class='note'>{0}</div>" -f (HtmlEncode $data.counts.note))
W '<div class="grid">'
foreach ($pair in @(
    @{ label = 'Candidate rows'; value = $data.counts.candidate_rows },
    @{ label = 'Accepted';       value = $data.counts.accepted },
    @{ label = 'Quarantined';    value = $data.counts.quarantined },
    @{ label = 'Logical keys';   value = $data.counts.logical_keys },
    @{ label = 'Multi-version';  value = $data.counts.multi_version_keys })) {
    W ("<div class='card'><div class='metric'>{0}</div><p>{1}</p></div>" -f $pair.value, (HtmlEncode $pair.label))
}
W '</div>'

# ---- risks
W '<h2>Risks</h2><table><tr><th>#</th><th>Risk</th><th>Likelihood</th><th>Response</th></tr>'
foreach ($r in $data.risks) {
    W ("<tr><td><code>{0}</code></td><td>{1}</td><td><span class='pill {2}'>{3}</span></td><td style='color:var(--dim)'>{4}</td></tr>" -f
        (HtmlEncode $r.id), (HtmlEncode $r.title), (StateClass $r.likelihood),
        (HtmlEncode $r.likelihood), (HtmlEncode $r.response))
}
W '</table>'

# ---- never
W '<h2>The line that does not move</h2><ul class="never">'
foreach ($n in $data.never) { W ("<li>{0}</li>" -f (HtmlEncode $n)) }
W '</ul>'

W ("<footer>Rendered from <code>demo-status.json</code> on {0}. The JSON is the source — edit it, not this page.<br>{1}</footer>" -f
    (Get-Date -Format 'yyyy-MM-dd HH:mm'), (HtmlEncode $data.note_on_freshness))
W '</div></body></html>'

# Honour -OutPath fully, directory and all. GetFullPath resolves a relative path and
# normalises '..' segments; the default value already points at the repo root next to the
# JSON, so unattended runs are unaffected.
$outFull = [System.IO.Path]::GetFullPath($OutPath)
$outDir  = Split-Path -Parent $outFull
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}
Set-Content -LiteralPath $outFull -Value $sb.ToString() -Encoding UTF8

Write-Output "RENDERED=$outFull"
Write-Output ("SOURCE_UPDATED={0}" -f $data.last_updated)
if ($null -ne $daysLeft) { Write-Output "DAYS_TO_DEMO=$daysLeft" }

$stale = @($data.rounds | Where-Object { $_.state -eq 'verify' }).Count +
         @($data.prerequisites | Where-Object { $_.state -eq 'verify' }).Count
if ($stale -gt 0) {
    Write-Warning "$stale item(s) still at state 'verify'. That means the file is stale, not that the round is stalled."
}

if ($Open) { Start-Process $outFull }
