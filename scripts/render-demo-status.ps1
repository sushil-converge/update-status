<#
.SYNOPSIS
    Renders demo-status.html from status.json (the pilot) and demo-status.json (the demo sprint).

.DESCRIPTION
    Both JSON files are sources of truth. This script is read-only with respect to them and
    never writes back. It produces a self-contained HTML view — no CDN, no build step, no
    network.

    The page is written for a reader who is NOT inside the project. Two rules follow from that,
    and both are enforced by lookup tables in this file rather than by editing the JSON:

      * Codes carry their meaning. "WF02" alone says nothing, so it renders as
        "WF02 (Submittal log)" with a plain sentence underneath.
      * No completion percentage, ever. This project does not track one — see CLAUDE.md,
        UPDATING.md, AGENTS.md. Progress is shown as a row of NAMED STAGES: which are done,
        which is current, which remain. A stage bar states a fact; a percentage invents one.

    An earlier version of this page had a filled bar computed as day / 15. That measured
    elapsed time, not work done, and would have read 100% on the final day with nothing built.

.EXAMPLE
    pwsh scripts/render-demo-status.ps1
    pwsh scripts/render-demo-status.ps1 -Open
#>
[CmdletBinding()]
param(
    [string] $JsonPath      = (Join-Path $PSScriptRoot '..\demo-status.json'),
    [string] $PilotJsonPath = (Join-Path $PSScriptRoot '..\status.json'),
    [string] $OutPath       = (Join-Path $PSScriptRoot '..\demo-status.html'),
    [switch] $Open
)

$ErrorActionPreference = 'Stop'

$jsonFull  = (Resolve-Path -LiteralPath $JsonPath).Path
$pilotFull = (Resolve-Path -LiteralPath $PilotJsonPath).Path
$data      = Get-Content -LiteralPath $jsonFull  -Raw | ConvertFrom-Json
$pilot     = Get-Content -LiteralPath $pilotFull -Raw | ConvertFrom-Json

function HtmlEncode([object] $Value) {
    if ($null -eq $Value) { return '' }
    [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

# state -> css class. Unknown states fall through to 'unknown' rather than being dropped,
# so a typo in the JSON shows up on the page instead of disappearing.
function StateClass([string] $State) {
    switch ($State) {
        'passed'          { 'ok' }
        'accepted'        { 'ok' }
        'complete'        { 'ok' }
        'in_progress'     { 'active' }
        'active'          { 'active' }
        'current'         { 'active' }
        'mostly_complete' { 'warn' }
        'pending'         { 'idle' }
        'not_started'     { 'idle' }
        'open'            { 'warn' }
        'verify'          { 'warn' }
        'blocked'         { 'bad' }
        'failed'          { 'bad' }
        'realised'        { 'bad' }
        default           { 'unknown' }
    }
}

# Raw JSON state values are snake_case and a couple are insider shorthand. Render them as
# words. 'verify' in particular does NOT mean the work is suspect — it means this file has
# not been reconciled against the repos yet (see note_on_freshness), so it is spelled out.
function StateLabel([string] $State) {
    switch ($State) {
        'in_progress'     { 'in progress' }
        'active'          { 'in progress' }
        'not_started'     { 'not started' }
        'mostly_complete' { 'mostly complete' }
        'verify'          { 'not yet confirmed' }
        default           { ([string]$State) -replace '_', ' ' }
    }
}

# Stage-row appearance. Deliberately has no 'done' case in use today: no pilot phase is
# complete, and the row must not imply otherwise. 'done' exists so that a phase which does
# complete renders correctly without a code change.
function StageClass([string] $State) {
    switch ($State) {
        'complete'        { 'stage done' }
        'mostly_complete' { 'stage part' }
        'active'          { 'stage doing' }
        default           { 'stage todo' }
    }
}

# ---------------------------------------------------------------- plain-language lookups
# Everything below translates an internal code into something a non-engineer can read. These
# tables must not invent meaning: each entry is sourced, and a code with no entry renders bare
# rather than being guessed at.

# Short stage names. The authoritative goal sentence renders directly beneath each one, and
# the P-code stays visible, so the translation is always traceable back to the source.
$PhaseNames = @{
    'P0' = 'The client''s real documents'
    'P1' = 'Running reliably together'
    'P2' = 'Records you can trust'
    'P3' = 'The day-to-day quality loop'
    'P4' = 'Added workflows'
    'P5' = 'Handover and sign-off'
}
# Goals, near-verbatim from the phase table in STATUS.md.
$PhaseGoals = @{
    'P0' = 'Collect real client examples and the results they should produce.'
    'P1' = 'Run all the services together safely and prove they recover from failure.'
    'P2' = 'Keep submittal and related records correct, from the client''s real sources.'
    'P3' = 'Connect planning, requirements, assignments, evidence and verification.'
    'P4' = 'Add the selected punch, non-conformance, safeguard and daily-brief workflows.'
    'P5' = 'Complete client acceptance, written operating guides and sign-off.'
}

# WF code -> glossary name. Taken VERBATIM from GLOSSARY.md.
$WfNames = @{
    'WF01' = 'Quality Work Control'
    'WF02' = 'Submittal log'
    'WF03' = 'Registry Reconciliation'
    'WF04' = 'Revision Intelligence'
    'WF05' = 'RFI capability'
    'WF06' = 'NCR extraction and trends'
    'WF07' = 'Inspection and ITP Tracker'
    'WF09' = 'Punch Evidence'
    'WF11' = 'Email Intelligence'
    'WF12' = 'Two-Week Lookahead Parser'
    'WF13' = 'Assignment and Evidence Tracker'
    'WF14' = 'Morning Brief'
    'WF16' = 'Daily Quality Report Intelligence'
    'WF18' = 'Role Dashboards'
    'WF24' = 'Deterministic safeguards'
}
# WF code -> what it actually does, in plain words. Paraphrased from the Client Requirements
# and Workflow Registry and the Workflow Catalog in Projects/Construction. Paraphrased rather
# than copied on purpose: those files carry client identifiers and this page is shared.
$WfDesc = @{
    'WF01' = 'Turns the two-week schedule into a location- and date-specific plan of what must be checked, submitted or escalated before work starts, and assigns it to named quality staff.'
    'WF02' = 'The register of submittals and their approval status, kept current from the client''s own workbook and returned review packages.'
    'WF03' = 'Compares our register against the client''s own log and surfaces every disagreement for a person to resolve. Never overwrites silently.'
    'WF04' = 'Shows which revision is current, which has been superseded, and what materially changed.'
    'WF05' = 'Pulls the question, response, dates and affected documents out of requests for information, and finds similar past ones.'
    'WF06' = 'Tracks non-conformance reports from raised, through corrective action, to disposition, and spots repeat causes. A person closes them, never the system.'
    'WF07' = 'Links each planned inspection to its hold point, its request and its result, and flags missing or late prerequisites.'
    'WF09' = 'Takes a punch scope the manager selects, collects photo evidence per item, and produces an audited report. Marks items ready for verification — never verified.'
    'WF11' = 'Reads approved mailboxes, groups conversations, and links attachments to the right records.'
    'WF12' = 'Reads the two-week schedule and extracts the activities, dates, trades and locations the other workflows depend on. Never changes the schedule.'
    'WF13' = 'Tracks who was asked to do what, when it is due, what evidence came back, and whether it was verified.'
    'WF14' = 'A daily summary for each role: what is new, due, overdue, at risk, or waiting on a decision.'
    'WF16' = 'Checks the daily report against the two-week schedule and confirms the required checklists and inspections actually happened. Flags what was missed.'
    'WF18' = 'The screens themselves: a single-project view for a Project Quality Manager, and a cross-project roll-up for corporate. Every number drills down to its evidence.'
    'WF24' = 'Fixed, rule-based warnings when an approved prerequisite or required evidence is missing, work is overdue, or revisions conflict.'
}

# Foundation milestone -> plain title. Sourced from the milestone list in STATUS.md.
$FoundationNames = @{
    'M0' = 'How the code is organised and independently reviewed'
    'M1' = 'Taking documents in from the shared folder, with duplicate protection and history'
    'M2' = 'Reading approved mailboxes and their attachments'
    'M3' = 'Reading document contents: parsing, classifying and extracting facts'
    'M4' = 'Turning documents into register entries, with history and audit'
    'M5' = 'The on-screen views'
}

# next_up id -> the plain sentence for that item, near-verbatim from the numbered
# "What's next, in order" list in STATUS.md. Acronyms are expanded here because the page is
# read by people who do not have GLOSSARY.md open.
$NextUpPlain = @{
    'WF02-I1'     = 'Run the remaining operating checks and finish publishing the approved package.'
    'WF02-STAGED' = 'Connect the approved client source folder, trace one real quality work plan through the whole system, test failure and recovery, and save the evidence.'
    'WF03'        = 'Match real quality work plans and approval documents to the submittal records we hold. Any disagreement goes to a person; the system must never hide it.'
    'WF02-READ'   = 'Connect the submittal screen to real records, showing the current row and its full history.'
    'WF02-EDIT'   = 'Allow controlled, audited edits to the register — only after the mapping and secure access are accepted.'
    'WF04'        = 'Show which revision is current, which is replaced, and what materially changed.'
    'WF11'        = 'Connect approved emails and attachments to the right records.'
    'WF05'        = 'Optional: limited support for requests for information. Do not invent a client status or register.'
}

# The JSON's own free-text fields are written for the build team and carry component names,
# commit language and infrastructure terms. The tables below are the plain-English rendering of
# those same facts, keyed by stable ids so they survive a data update. Status words that carry
# precise meaning here — accepted, pushed, deployed — are preserved, but explained rather than
# assumed (UPDATING.md: "Keep exact status vocabulary, but explain technical detail").
# Nothing is dropped: every caveat in the source has a counterpart below.
$PhaseNotes = @{
    'P0' = 'Most of the client''s real sample documents are in hand. Still open: naming and authority rules, the As-Built sheet mapping, and the exact live source folder.'
    'P1' = 'The services each work on their own. Running them all together in a test environment, and proving they recover from failure, is still open.'
    'P2' = 'The current stage. The groundwork for the submittal log has been reviewed, approved and published to the shared codebase. Proving it in day-to-day operation, and the later workflows, remain open.'
}
$FoundationChecked = @{
    'M1' = 'Checked 13 Jul 2026 on a full local test set-up'
    'M2' = 'Checked 14 Jul 2026 against the real mail service'
    'M3' = 'Passed the 95% accuracy check'
}
$FoundationOpen = @{
    'M2' = 'Live notification validation and the mailbox access policy are still open.'
    'M4' = 'Not yet signed off against the client''s own real log.'
    'M5' = 'Runs on test data; not yet connected to the live system.'
}
$PilotBlockerPlain = @{
    'B1' = 'The full set of operating checks has not been run, because there is no test environment set up yet.'
    'B2' = 'The tool that encrypts backups has not been fully verified.'
    'B3' = 'We do not have the exact folder path where the live submittals sit.'
    'B4' = 'Naming for projects and locations, who has authority to approve, which document wins when two disagree, and the notification and acceptance rules are all unconfirmed.'
    'B5' = 'The As-Built sheet mapping has not been checked against the agreed tracker range.'
    'B6' = 'The client''s Oracle administrator has not confirmed the Unifier connection is switched on.'
}
# Demo checkpoints, keyed by day. Keys are STRINGS: Lookup compares against a string, and an
# integer key would silently never match, leaving the raw engineer text on the page.
$GatePlain = @{
    '1'  = 'The written specification is saved, and the sign-in work builds.'
    '2'  = 'A faked permission request is refused, and all three copies of the code match their approved versions exactly.'
    '3'  = 'The real import runs: a seven-version history appears, and real set-aside counts replace the estimated ones.'
    '6'  = 'The register lookup is approved, and asking for another project''s data returns nothing.'
    '10' = 'Sign in, see real rows, open their real history — the whole path working end to end.'
    '13' = 'A full rehearsal runs cleanly twice, including deliberate failures.'
    '14' = 'Freeze: no more changes after end of day.'
    '15' = 'Demo day.'
}
# Tier meanings, keyed by tier id.
$TierPlain = @{
    'A' = 'Running end to end on the client''s own data, through the real system.'
    'B' = 'A real client document shown beside what the system read out of it. This is evidence that the reading works. It is not a working register and must never be described as one.'
    'C' = 'Real structure, no data behind it, and the exact missing document named on screen. This asks the client for what we need while they are watching.'
    'D' = 'Built from the three above.'
}
# Risk titles and responses, keyed by risk id.
$RiskTitlePlain = @{
    'R-8' = 'Writing build instructions against code that is still changing'
}
$RiskResponsePlain = @{
    'R-1' = 'The import was moved to day 3 for exactly this reason. If it happens, stop and work out why before any screen work.'
    'R-2' = 'Days 11 and 12 are held back as buffer. Reviews have already rejected a design twice.'
    'R-4' = 'Thirteen screens are thirteen places a placeholder could appear. Test-data generation is switched off on every one, and the reviewer checks each explicitly.'
    'R-8' = 'Tracked as the two blockers above. Do not write the import instructions until that code settles.'
}
# The standing rules. Keyed by the original sentence so that reordering the list cannot
# mismatch them, and anything reworded simply falls back to the original text.
$NeverPlain = @{
    'No fabricated row, count, status or KPI on any surface' =
        'Nothing on any screen is made up — no invented rows, counts, statuses or figures'
    'No live client system, no external send, no write-back to any client workbook' =
        'Nothing touches a live client system, nothing is sent outside, and nothing is written back to any client file'
    'No populated role map, real identity, client document or Supabase key committed to any repository' =
        'No real identities, client documents, access keys or permission lists are ever stored alongside the code'
    'Implementer session is never the reviewer session' =
        'Whoever builds a thing never also approves it'
    'Unavailable stays unavailable — never zero, never an empty grid' =
        'If something is unavailable it is shown as unavailable — never as a zero, never as an empty table'
}
$RoundPlain = @{
    'S1a'     = 'The way in: signing in, and the system working out on its own which project you are allowed to see'
    'S1a-bis' = 'Load the client''s real workbook into the system'
    'S1b'     = 'Ask the system for the submittal register and get real rows back'
    'S1c'     = 'The screen that shows the submittal register'
    'T-B'     = 'The screen that shows a real document beside what the system read out of it'
    'T-C'     = 'The screens that show real structure with the missing document named on screen'
    'T-D'     = 'The combined views, assembled from the ones above'
}
$PrereqPlain = @{
    'DO-1' = 'A demo login account, or a confirmed guest sign-in path'
    'DO-2' = 'The demo data folder created and filled'
    'DO-3' = 'The workbook placed somewhere the system can read it'
    'DO-4' = 'Replace the database key that was pasted into a chat — treat it as exposed'
    'DO-5' = 'Decide where the local set-up file should live'
    'DO-6' = 'A private home for the handbook'
}
$DemoBlockerPlain = @{
    'DO-7' = @{ title  = 'A specification file has not been saved into the shared record'
                detail = 'Because of that, the review packet cannot be tied to a fixed version of it. The content itself is correct and dated. Saving that one file closes this.' }
    'DO-8' = @{ title  = 'Three areas of the code have unsaved formatting-only changes'
                detail = 'The changes do not alter any content. But the import''s whole value is turning predicted numbers into observed ones, and numbers produced from a copy that has not been saved into the shared record cannot be tied to a fixed version.' }
}

function WfName([string] $Code) {
    $c = ([string]$Code).Trim()
    if ($WfNames.ContainsKey($c)) { $WfNames[$c] } else { $null }
}
function WfDescription([string] $Code) {
    $c = ([string]$Code).Trim()
    if ($WfDesc.ContainsKey($c)) { $WfDesc[$c] } else { $null }
}
function Lookup([hashtable] $Table, [string] $Key, [string] $Fallback) {
    $k = ([string]$Key).Trim()
    if ($Table.ContainsKey($k)) { $Table[$k] } else { $Fallback }
}

$daysLeft = try {
    [int]([datetime]::Parse($data.demo_date) - [datetime]::Parse($data.last_updated)).TotalDays
} catch { $null }

$sb = [System.Text.StringBuilder]::new()
function W([string] $Line) { [void]$sb.AppendLine($Line) }

W '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">'
W '<meta name="viewport" content="width=device-width, initial-scale=1">'
W ("<title>{0} — project status</title>" -f (HtmlEncode $pilot.project))
W @'
<style>
  :root{--bg:#0f1115;--card:#171a21;--line:#252a34;--fg:#e6e8ec;--dim:#9aa2b1;
        --ok:#3fb950;--active:#d29922;--idle:#6e7681;--warn:#db6d28;--bad:#f85149;--unknown:#a371f7;
        --accent:#c2410c}
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--fg);
       font:15px/1.6 ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif}
  .wrap{max-width:1080px;margin:0 auto;padding:32px 20px 72px}
  h1{font-size:25px;margin:0 0 4px} h2{font-size:16px;margin:34px 0 12px;
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
        text-transform:uppercase;letter-spacing:.05em;border:1px solid;white-space:nowrap}
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
  ul.wf{margin:8px 0 0;padding:0;list-style:none}
  ul.wf li{font-size:12.5px;color:var(--dim);padding:5px 0;border-top:1px solid var(--line)}
  ul.wf li:first-child{border-top:0}
  ul.wf li b{color:var(--accent);font-family:ui-monospace,Consolas,monospace;font-weight:500}
  ul.wf li span{display:block;margin-top:2px}
  .lede{font-size:15px;color:var(--fg);margin:0}
  .subtle{color:var(--dim);font-size:13px;margin:14px 0 0}
  /* stage row — named stages, never a percentage */
  .stages{display:flex;gap:6px;flex-wrap:wrap;margin:6px 0 4px}
  .stage{flex:1 1 148px;padding:11px 12px;border-radius:8px;border:1px solid var(--line);
         background:var(--card)}
  .stage .nm{display:block;font-size:13px;font-weight:600;line-height:1.35}
  .stage .cd{font-family:ui-monospace,Consolas,monospace;font-size:11px;color:var(--dim)}
  .stage .st{display:block;margin-top:7px;font-size:10.5px;text-transform:uppercase;
             letter-spacing:.05em;color:var(--dim)}
  .stage.done{border-color:var(--ok)} .stage.done .st{color:var(--ok)}
  .stage.part{border-color:var(--warn)} .stage.part .st{color:var(--warn)}
  .stage.doing{border-color:var(--active);background:#1e1c14} .stage.doing .st{color:var(--active)}
  .stage.todo{opacity:.55}
  .divider{margin:52px 0 0;padding-top:26px;border-top:2px solid var(--line)}
  .banner{font-size:19px;font-weight:600;margin:0 0 4px}
  footer{margin-top:44px;color:var(--idle);font-size:12px;border-top:1px solid var(--line);padding-top:14px}
</style></head><body><div class="wrap">
'@

# ================================================================ PART 1 — the whole project
W ("<h1>{0}</h1>" -f (HtmlEncode $pilot.project))
W ("<div class='sub'>The whole project, then the 15-day demo. Project status as of {0}.</div>" -f
    (HtmlEncode $pilot.last_updated))
W ("<div class='card' style='margin-bottom:6px'><p class='lede'>{0}</p></div>" -f
    (HtmlEncode $pilot.summary))

# ---- stage row
# Named stages, no percentage: this project does not track a completion figure and estimating
# one is forbidden (CLAUDE.md, UPDATING.md, AGENTS.md). The row states which stages are done,
# which are running and which have not begun — each of which is a fact in status.json.
$phases = @($pilot.phases)
W '<h2>Where the project stands</h2>'
W '<div class="stages">'
foreach ($p in $phases) {
    $nm = Lookup $PhaseNames $p.id ([string]$p.name)
    W ("<div class='{0}'><span class='cd'>{1}</span><span class='nm'>{2}</span><span class='st'>{3}</span></div>" -f
        (StageClass $p.status), (HtmlEncode $p.id), (HtmlEncode $nm), (HtmlEncode (StateLabel $p.status)))
}
W '</div>'

W '<table><tr><th>Stage</th><th>What it means</th><th>State</th></tr>'
foreach ($p in $phases) {
    $nm   = Lookup $PhaseNames $p.id ([string]$p.name)
    $goal = Lookup $PhaseGoals $p.id ''
    $noteTxt = Lookup $PhaseNotes $p.id ([string]$p.note)
    $detail = if ($noteTxt) { "<br><span style='color:var(--dim);font-size:12.5px'>{0}</span>" -f (HtmlEncode $noteTxt) } else { '' }
    W ("<tr><td><b>{0}</b><br><span class='cd' style='color:var(--dim);font-size:12px'>{1}</span></td><td>{2}{3}</td><td><span class='pill {4}'>{5}</span></td></tr>" -f
        (HtmlEncode $nm), (HtmlEncode $p.id), (HtmlEncode $goal), $detail,
        (StateClass $p.status), (HtmlEncode (StateLabel $p.status)))
}
W '</table>'

$readyTxt = if ($pilot.pilot_ready) { 'yes' } else { 'not yet' }
W ("<div class='note'><b>Ready to run on the client's live system: {0}.</b> No stage is fully finished. Two are running at once, and the stages after them have not begun.</div>" -f $readyTxt)

# ---- already built
# STATUS.md is explicit that these do not add up to a deployed platform, and the caveat travels
# with each item rather than being dropped — a summary that loses the caveat is wrong.
W '<h2>Already built</h2>'
W "<p class='subtle' style='margin:0 0 10px'>Finished groundwork. These are real and working, but they do <b>not</b> mean the system is running on the client's own material yet.</p>"
W '<table><tr><th>What</th><th>Still open on it</th></tr>'
foreach ($m in @($pilot.completed_foundation)) {
    $title = Lookup $FoundationNames $m.id ([string]$m.title)
    # NB: not $open — that would collide with the [switch] $Open parameter, since PowerShell
    # variable names are case-insensitive, and assigning an array to it is a binding error.
    $openItems = Lookup $FoundationOpen $m.id ''
    if (-not $openItems -and $m.caveats) { $openItems = (@($m.caveats) -join '; ') }
    $openTxt = if ($openItems) { (HtmlEncode $openItems) } else { '<span style="color:var(--ok)">nothing outstanding</span>' }
    $checked  = Lookup $FoundationChecked $m.id ''
    $verified = if ($checked) { "<br><span style='color:var(--dim);font-size:12px'>{0}</span>" -f (HtmlEncode $checked) } else { '' }
    W ("<tr><td><b>{0}</b>{1}</td><td style='color:var(--dim);font-size:13px'>{2}</td></tr>" -f
        (HtmlEncode $title), $verified, $openTxt)
}
W '</table>'

# ---- what remains
W '<h2>What remains</h2>'
W "<p class='subtle' style='margin:0 0 10px'>In order. Each item depends on the one before it, so the list is not a menu.</p>"
$pilotBlockers = @{}
foreach ($b in @($pilot.blockers)) {
    $pilotBlockers[[string]$b.id] = Lookup $PilotBlockerPlain $b.id ([string]$b.title)
}
W '<table><tr><th>#</th><th>What happens next</th><th>Waiting on</th></tr>'
foreach ($n in (@($pilot.next_up) | Sort-Object order)) {
    $plain = Lookup $NextUpPlain $n.id ([string]$n.title)
    $wait  = '<span style="color:var(--dim)">—</span>'
    if ($n.blocked_by) {
        $reasons = foreach ($bid in @($n.blocked_by)) {
            if ($pilotBlockers.ContainsKey([string]$bid)) { $pilotBlockers[[string]$bid] } else { [string]$bid }
        }
        $wait = "<span style='color:var(--bad);font-size:12.5px'>{0}</span>" -f (HtmlEncode ($reasons -join '; '))
    }
    W ("<tr><td>{0}</td><td>{1}</td><td>{2}</td></tr>" -f $n.order, (HtmlEncode $plain), $wait)
}
W '</table>'

W "<div class='note'><b>The current stage is finished only when</b> a Quality Manager can open the real client register, understand every disagreement in it, approve a correction, and see which revision is the controlled one. Sending anything outside the system stays a human decision.</div>"

# ---- what is holding things up
W '<h2>What is holding things up</h2>'
W '<table><tr><th>What</th><th>Whose side</th></tr>'
foreach ($b in @($pilot.blockers)) {
    $sideTxt = if ($b.side -eq 'client') { 'needs the client or product owner' } else { 'ours to finish' }
    $sideCls = if ($b.side -eq 'client') { 'warn' } else { 'idle' }
    W ("<tr><td>{0}</td><td><span class='pill {1}'>{2}</span></td></tr>" -f
        (HtmlEncode (Lookup $PilotBlockerPlain $b.id ([string]$b.title))), $sideCls, $sideTxt)
}
W '</table>'

# ================================================================ PART 2 — the 15-day demo
W '<div class="divider"></div>'
W ("<p class='banner'>The 15-day demo</p>")
W ("<div class='sub'>A separate, shorter push inside the project above — putting the submittal log on screen for {0}. Demo status as of {1}, day {2} of {3}.</div>" -f
    (HtmlEncode $data.demo_date), (HtmlEncode $data.last_updated),
    (HtmlEncode $data.current.day), (HtmlEncode $data.current.of))

W ("<div class='card'><p class='lede'>{0}</p><p class='subtle'>{1}</p></div>" -f
    (HtmlEncode $data.summary), (HtmlEncode $data.current.one_line))

$gatesAll    = @($data.gates)
$gatesPassed = @($gatesAll | Where-Object { $_.state -eq 'passed' }).Count
$nextGate    = @($gatesAll | Where-Object { $_.state -ne 'passed' } | Sort-Object day)[0]
if ($nextGate) {
    W ("<div class='note'><b>Next checkpoint — day {0} ({1}).</b> {2}</div>" -f
        $nextGate.day, (HtmlEncode $nextGate.date),
        (HtmlEncode (Lookup $GatePlain ([string]$nextGate.day) ([string]$nextGate.gate))))
}

# ---- headline
W '<h2>The headline</h2>'
W ("<div class='hero'><div class='id'>{0}</div><p style='margin-top:6px;color:var(--dim)'>{1}</p></div>" -f
    (HtmlEncode $data.headline.submittal), (HtmlEncode $data.headline.why))

# ---- checkpoints
W ("<h2>Checkpoints — {0} of them, {1} passed so far</h2>" -f $gatesAll.Count, $gatesPassed)
W '<div class="days">'
foreach ($g in $gatesAll) {
    $cls = if ($g.state -eq 'passed') { 'day done' } elseif ($g.day -eq $data.current.day) { 'day now' } else { 'day' }
    W ("<div class='{0}'><b>{1}</b>{2}</div>" -f $cls, $g.day, (HtmlEncode $g.date))
}
W '</div>'
W '<table><tr><th>Day</th><th>What has to be true by then</th><th>State</th></tr>'
foreach ($g in $gatesAll) {
    W ("<tr><td>{0}</td><td>{1}</td><td><span class='pill {2}'>{3}</span></td></tr>" -f
        $g.day, (HtmlEncode (Lookup $GatePlain ([string]$g.day) ([string]$g.gate))),
        (StateClass $g.state), (HtmlEncode (StateLabel $g.state)))
}
W '</table>'

# ---- tiers
# The four depths are the honest part of the demo: only tier A is the real thing running end to
# end. Tier B is evidence shown beside a document and must never be called a working register;
# tier C is deliberately empty structure whose purpose is to name the missing document on
# screen. Collapsing these into one count would misrepresent the demo.
W '<h2>Four depths — what is real, and what is not</h2>'
W "<p class='subtle' style='margin:0 0 10px'>Thirteen areas are shown at four different depths. Only the first is the live system running on real data. Nothing on any of them is made up.</p>"
W '<div class="grid">'
foreach ($t in $data.tiers) {
    W ("<div class='card'><h3>{0} — {1} <span class='pill {2}'>{3}</span></h3><p>{4}</p>" -f
        (HtmlEncode $t.id), (HtmlEncode $t.name), (StateClass $t.status), (HtmlEncode (StateLabel $t.status)),
        (HtmlEncode (Lookup $TierPlain $t.id ([string]$t.meaning))))
    W '<ul class="wf">'
    foreach ($w in $t.workflows) {
        $nm = WfName $w
        $de = WfDescription $w
        $head = if ($nm) { "<b>{0}</b> ({1})" -f (HtmlEncode $w), (HtmlEncode $nm) } else { "<b>{0}</b>" -f (HtmlEncode $w) }
        $body = if ($de) { "<span>{0}</span>" -f (HtmlEncode $de) } else { '' }
        W ("<li>{0}{1}</li>" -f $head, $body)
    }
    W '</ul></div>'
}
W '</div>'
W ("<div class='note'><b>If time runs short.</b> {0}</div>" -f (HtmlEncode $data.cut_order))

# ---- rounds
W '<h2>The work plan — in the order it gets built</h2>'
W ("<p class='subtle' style='margin:0 0 10px'>Each row is one round of work: built, reviewed, then accepted or rejected. " +
   "Day is when it starts, not when it finishes.</p>")
W '<table><tr><th>Day</th><th>What gets built</th><th>State</th></tr>'
foreach ($r in ($data.rounds | Sort-Object day)) {
    $blockNote = ''
    if ($r.state -eq 'blocked' -and $r.blocked_by) {
        $blockNote = "<br><span style='color:var(--bad);font-size:12px'>waiting on {0}</span>" -f
            (HtmlEncode (@($r.blocked_by) -join ', '))
    }
    W ("<tr><td>{0}</td><td><b>{1}</b>{2}</td><td><span class='pill {3}'>{4}</span></td></tr>" -f
        $r.day, (HtmlEncode (Lookup $RoundPlain $r.id ([string]$r.title))), $blockNote,
        (StateClass $r.state), (HtmlEncode (StateLabel $r.state)))
}
W '</table>'

# ---- blockers
if (@($data.blockers).Count -gt 0) {
    W '<h2>Blockers</h2><table><tr><th>What</th><th>Owner</th></tr>'
    foreach ($b in $data.blockers) {
        $bt = [string]$b.title; $bd = [string]$b.detail
        if ($DemoBlockerPlain.ContainsKey([string]$b.id)) {
            $bt = $DemoBlockerPlain[[string]$b.id].title
            $bd = $DemoBlockerPlain[[string]$b.id].detail
        }
        W ("<tr><td><b>{0}</b><br><span style='color:var(--dim);font-size:13px'>{1}</span></td><td>{2}</td></tr>" -f
            (HtmlEncode $bt), (HtmlEncode $bd), (HtmlEncode $b.owner))
    }
    W '</table>'
}

# ---- prerequisites
W '<h2>Still needed before the demo</h2><table><tr><th>What</th><th>By day</th><th>State</th></tr>'
foreach ($p in $data.prerequisites) {
    W ("<tr><td>{0}</td><td>{1}</td><td><span class='pill {2}'>{3}</span></td></tr>" -f
        (HtmlEncode (Lookup $PrereqPlain $p.id ([string]$p.title))), $p.due_day,
        (StateClass $p.state), (HtmlEncode (StateLabel $p.state)))
}
W '</table>'

# ---- counts
W '<h2>What we expect the import to find</h2>'
W "<div class='note'><b>These are estimates, not measurements.</b> They come from reading the spreadsheet directly, not from the system. Day 3 replaces this whole block with real numbers.</div>"
W '<div class="grid">'
foreach ($pair in @(
    @{ label = 'Rows found';                 value = $data.counts.candidate_rows },
    @{ label = 'Accepted';                   value = $data.counts.accepted },
    @{ label = 'Set aside for review';       value = $data.counts.quarantined },
    @{ label = 'Distinct submittals';        value = $data.counts.logical_keys },
    @{ label = 'With more than one version'; value = $data.counts.multi_version_keys })) {
    W ("<div class='card'><div class='metric'>{0}</div><p>{1}</p></div>" -f $pair.value, (HtmlEncode $pair.label))
}
W '</div>'

# ---- risks
W '<h2>Risks</h2><table><tr><th>Risk</th><th>Likelihood</th><th>What we are doing about it</th></tr>'
foreach ($r in $data.risks) {
    W ("<tr><td>{0}</td><td><span class='pill {1}'>{2}</span></td><td style='color:var(--dim)'>{3}</td></tr>" -f
        (HtmlEncode (Lookup $RiskTitlePlain $r.id ([string]$r.title))), (StateClass $r.likelihood),
        (HtmlEncode $r.likelihood),
        (HtmlEncode (Lookup $RiskResponsePlain $r.id ([string]$r.response))))
}
W '</table>'

# ---- never
W '<h2>The line that does not move</h2><ul class="never">'
foreach ($n in $data.never) { W ("<li>{0}</li>" -f (HtmlEncode (Lookup $NeverPlain ([string]$n) ([string]$n)))) }
W '</ul>'

W ("<footer>Generated {0}. Project status as of {1}; demo status as of {2}.<br>Anything marked &#8220;not yet confirmed&#8221; has not been checked against the code since this was written. Left there more than a day, that means the record is out of date — not that the work has stalled.</footer>" -f
    (Get-Date -Format 'yyyy-MM-dd HH:mm'), (HtmlEncode $pilot.last_updated),
    (HtmlEncode $data.last_updated))
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
Write-Output ("PILOT_UPDATED={0}" -f $pilot.last_updated)
if ($null -ne $daysLeft) { Write-Output "DAYS_TO_DEMO=$daysLeft" }

# The two files are required to carry the same last_updated (UPDATING.md). When they drift, the
# page shows both dates rather than blending them — but the drift is still worth shouting about,
# because a reader comparing the two halves is comparing different days.
if ([string]$pilot.last_updated -ne [string]$data.last_updated) {
    Write-Warning ("Source dates disagree: status.json is {0}, demo-status.json is {1}. Both dates are shown on the page." -f
        $pilot.last_updated, $data.last_updated)
}

$stale = @($data.rounds | Where-Object { $_.state -eq 'verify' }).Count +
         @($data.prerequisites | Where-Object { $_.state -eq 'verify' }).Count
if ($stale -gt 0) {
    Write-Warning "$stale item(s) still at state 'verify'. That means the file is stale, not that the round is stalled."
}

if ($Open) { Start-Process $outFull }
