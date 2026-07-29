# Task: daily STATUS.md update

You are the Construction AI OS orchestrator performing the end-of-day status update.
This is an unattended run. Nobody will answer questions. Make the best accurate update you can
from evidence in the working tree, and record uncertainty explicitly rather than guessing.

## The only file you may modify

`project-status/STATUS.md`

Do not modify `status.json`, `CHANGELOG.md`, `DECISIONS.md`, `GLOSSARY.md`, `README.md`,
`CLAUDE.md`, `AGENTS.md`, or `UPDATING.md`. Do not modify anything in the component repos.
Do not modify anything anywhere else in the workspace. One file. That is the whole job.

## Read first, in this order

1. `project-status/STATUS.md` — the current state you are updating.
2. `project-status/UPDATING.md` — the writing rules. They are binding.
3. `project-status/GLOSSARY.md` — the status vocabulary. Use these words precisely.

## Then gather evidence

Look at the last **2 days** of activity (a wider window than one day, so a Monday run still catches
Friday evening work; deduplicate against what STATUS.md already reports).

- `git -C <repo> log --since=2.days --format='%ad %h %s' --date=short` for each of:
  `construction-shared-contracts`, `construction-sync-agent`, `unifier-connector`,
  `construction-email-agent`, `construction-document-api`, `construction-document-pipeline`,
  `construction-rules-engine`, `construction-dashboard`.
- `git -C <repo> status --short` for each — uncommitted work is real work and often the most
  current signal.
- `plans/progress/Construction-AI-OS-milestone-progress.md` — the authoritative checklist.
- `plans/handoffs/` and `plans/evidence/` — newest files first. New evidence folders under
  `evidence/` (e.g. `wf02-*`) indicate which gate is actively being exercised.
- `Construction AI OS Handbook/17 - Development Roadmap.md` — only if the phase or workflow order
  appears to have changed.

## Then update STATUS.md

Apply, in order:

1. **Always bump `last_updated`** in the header block to today's date, even if nothing else
   changed. A same-day timestamp with no other edit is a meaningful signal: it says "checked, no
   movement." Never leave the date stale.
2. Update `current_phase` and `current_milestone` in the header if the evidence shows they moved.
3. Rewrite **"What we're working on right now"** so it describes the present. Move superseded detail
   out; do not accumulate history in this section. Cite short commit hashes where a claim of
   acceptance or completion needs backing.
4. Reconcile the **blocker table**. Add new blockers with the next free `B` number. Remove a blocker
   only when there is concrete evidence it closed — and when you remove one, say so in your final
   summary so a human can log it. Never renumber existing blockers; the IDs are referenced elsewhere.
5. Reorder **"What's next"** only if the dependency order genuinely changed. If it did, do **not**
   silently reorder — leave the order alone and flag it in your final summary as needing a
   `DECISIONS.md` entry from a human.
6. Refresh the **component table's** last-activity dates and commits.
7. Update the **phase table** row status only where evidence supports it.

If nothing moved: bump `last_updated`, add or refresh a single line at the end of "What we're
working on right now" reading `**No movement since <date>.** Still blocked on: <blocker IDs>.`
and change nothing else.

## Writing rules — these are not optional

- **Write for the whole team, not only engineers.** Use short sentences and everyday words. Keep
  exact status words such as `built`, `accepted`, `pushed`, `integrated`, `deployed`, and
  `pilot-ready`, but explain what they mean in context. Avoid implementation detail unless it is
  needed to explain progress, evidence, a failure, or a blocker.
- **Keep the public mirror redacted.** Never write client or vendor names, source filenames,
  workbook or project identifiers, exact client folder paths, email addresses, exact client row
  ranges, or client documents into `STATUS.md`. Use a neutral description that preserves the gate
  and its owner.
- **Never upgrade status language.** `built` ≠ `accepted` ≠ `pushed` ≠ `integrated` ≠ `deployed` ≠
  `pilot-ready`. Use the word the evidence supports and no stronger one. A commit existing locally
  means *built*, not *pushed*. A passing test suite means *built*, not *accepted* — acceptance
  requires a bounded independent review. Check whether a commit is actually on the remote before
  writing "pushed".
- **Never drop a blocker** to make the update read better.
- **Never estimate a completion percentage.**
- **Keep caveats attached to claims.** "Verified end to end against a local Compose stack" — not
  "verified end to end."
- **Do not invent** WF numbers, contract names, dates, or commit hashes. If you cannot verify
  something, write what you can verify and note the gap.
- **Record rejections and failures.** A failed gate is status. Deleting it makes the document less
  trustworthy, not more.
- Keep the file's existing structure and heading order. You are updating content, not redesigning it.

## Then save it

Check your own work before saving. Run `git -C project-status status --short`. If any file other
than `STATUS.md` shows as changed, undo those changes and stop — report what happened instead of
saving. Only `STATUS.md` should be modified.

If only `STATUS.md` changed:

```
git -C project-status add STATUS.md
git -C project-status commit -m "status: daily update <today's date>"
git -C project-status push
```

If the push fails, say so clearly in your final message. The commit is still saved locally.

## Do not

- Do not run builds, tests, migrations, Docker, or any component's tooling. This is a read-and-
  write-one-markdown-file task.
- Do not open pull requests or create branches. Commit straight to the main branch.
- Do not commit anything other than `STATUS.md`.
- Do not touch any file under `plans/`, `evidence/`, `tmp/`, or `transfer/`.

## Final output

Your final message must be **at most 8 lines**, plain text, in this shape:

```
UPDATED: yes|no-change
PHASE: <current phase>
MILESTONE: <current milestone>
MOVED: <one line, or "nothing">
BLOCKERS ADDED: <IDs or none>
BLOCKERS CLOSED: <IDs or none>
NEEDS HUMAN: <one line, or "nothing">
```

This message is written to the run log and read by a human the next morning. Anything you were
unsure about, anything you chose not to change, and anything that needs a `DECISIONS.md` or
`CHANGELOG.md` entry goes on the `NEEDS HUMAN` line.
