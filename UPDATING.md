# How to update this repo

For the orchestrator. Team members should open a GitHub Issue instead of editing.

## Cadence

Update whenever a gate closes or a blocker changes — and **at minimum once a week**, even if the
update is "no movement, still blocked on X." A stale status file is worse than a short one, because
readers can't tell the difference between "nothing changed" and "nobody updated it."

## The update, in order

1. **`STATUS.md`** — the only file that must always change.
   - Bump `last_updated` in the header block. This is what assistants check for staleness.
   - Update `current_milestone` and `current_phase` if they moved.
   - Rewrite "What we're working on right now" to describe the *present*, not the history.
   - Add, remove or re-scope blockers in the table. Removing a blocker without a `CHANGELOG.md`
     entry loses the fact that it was ever there.
   - Reorder "What's next" only if the dependency order genuinely changed — and if it did, write a
     `DECISIONS.md` entry explaining why.
   - Refresh the component table's last-activity commits.

2. **`status.json`** — mirror the same facts. Keep the two in sync; assistants may read either.
   Same `last_updated` value, same blocker IDs, same next-up ordering.

3. **`CHANGELOG.md`** — prepend a dated entry: what moved, what's newly blocked or unblocked,
   what's next. Keep it factual. This is the file people read to answer "what happened this week."

4. **`DECISIONS.md`** — only when a decision was actually made. Prepend it. Never delete a
   superseded decision; mark it superseded and add the new one. The log's value is that it explains
   *why*, including why something changed.

5. **`GLOSSARY.md`** — add any new WF code, term or repo the update introduced. If a reader would
   have to ask "what's that", it belongs here.

## Writing rules

These are what make the file trustworthy to both humans and assistants:

- **Write for non-engineers first.** Lead with what changed, why it matters, what is blocked, and
  what happens next. Use short sentences and everyday words. Keep exact status vocabulary, but
  explain technical detail instead of assuming the reader already knows it.
- **Keep the public mirror redacted.** Never add client or vendor names, source filenames, workbook
  or project identifiers, exact client folder paths, email addresses, exact client row ranges, or client
  documents. Use a neutral description that preserves the gate and its owner.
- **Never upgrade status language.** Built ≠ accepted ≠ pushed ≠ integrated ≠ deployed ≠ pilot-ready.
  Use the exact word that's true. `GLOSSARY.md` defines all six.
- **Keep the caveat attached to the claim.** "Verified end to end" and "verified end to end against a
  local Compose stack, not a deployed environment" are different statements. Write the second one.
- **Name the gate, not just the state.** "Blocked" is unhelpful; "blocked on the approved live source
  folder path" is actionable without identifying the client.
- **No completion percentages.** Ever. Describe the phase and the open gate.
- **Commit hashes are evidence, not decoration.** Include them where a claim of acceptance needs
  backing. Short hashes are fine.
- **Rejections are worth recording.** The 2026-07-22 I0 rejection is in the changelog because it
  shows the review process catching a real defect. Deleting failures makes the record less credible,
  not more.

## Automated daily run (Codex)

`STATUS.md` is updated automatically by Codex every weekday at 18:00 via a Windows Scheduled Task.

| File | Role |
|---|---|
| `.codex/update-status.md` | The task prompt Codex executes. Edit this to change what the update does. |
| `scripts/update-status.ps1` | Wrapper: runs `codex exec`, guards the diff, commits, pushes. |
| `scripts/register-task.ps1` | One-time registration of the Scheduled Task. |
| `.codex/logs/` | Per-run log and Codex's final summary. Gitignored. |

**Scope of the automated run: `STATUS.md` only.** It bumps `last_updated`, rewrites the "right now"
section, reconciles the blocker table, and refreshes the component table. It does **not** touch
`status.json`, `CHANGELOG.md`, `DECISIONS.md` or `GLOSSARY.md` — those need judgement about what
counts as a decision or a milestone, and an unattended agent should not be making that call.

**So the manual part is:** read the `NEEDS HUMAN` line in the morning's log, and roughly weekly,
reconcile `status.json` with `STATUS.md`, prepend a `CHANGELOG.md` entry covering the week, and add
a `DECISIONS.md` entry if a real decision was made. The daily automation keeps the front page honest
between those passes.

If the run reports `UPDATED: no-change` while STATUS.md is genuinely stale, or the guardrail trips
(exit code 2 — Codex touched files outside `STATUS.md`), check `.codex/logs/` before trusting the
next run.

### Prompt for a manual full update

When doing the weekly manual pass, or a full update by hand:

> Update the project-status repo. Read `STATUS.md`, `status.json`, `CHANGELOG.md`, `DECISIONS.md` and
> `UPDATING.md` first. Then review the last N days of commits across the component repos and the
> current milestone progress notes. Apply the update following `UPDATING.md` exactly: bump
> `last_updated`, rewrite the "right now" section, reconcile the blocker table, mirror everything into
> `status.json`, and prepend a `CHANGELOG.md` entry. Add a `DECISIONS.md` entry only if a real
> decision was made, and a `GLOSSARY.md` entry for any new term. Do not upgrade status language, do
> not drop blockers, do not estimate percentages. Then commit and push.
