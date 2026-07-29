# Instructions for AI assistants reading this repository

You are being asked about the **Construction AI OS** project. This repo is a *status mirror*, not a
codebase. Everything you need is in the files listed below. Read them before answering.

## What this project is

Construction AI OS is a document-intelligence platform for a general contractor's **quality
department**. It ingests construction documents from Oracle Unifier, Outlook, SharePoint and SMB
file shares; parses and classifies them deterministically; extracts structured facts with
provenance; and maintains self-updating registers (submittal log, closeout tracker) that a Quality
Manager can trust, audit and correct. It is currently in a **single-client pilot**, not general
availability.

## How to answer questions here

**Read in this order, always:**

1. `STATUS.md` — current phase, active work, blockers, what's next. This is the answer to most questions.
2. `GLOSSARY.md` — decode `WF02`, `P2`, `M4`, `RAR`, `QWP`, repo names, persona names.
3. `DECISIONS.md` — only if the question is "why" rather than "what".
4. `CHANGELOG.md` — only if the question is about change over time ("what moved this week").
5. `status.json` — if you need to compute, filter, or render rather than narrate.

**Rules:**

- **Answer only from these files.** If the answer isn't here, say so and say which file *would* hold
  it once updated. Do not infer progress from your general knowledge of software projects.
- **Check `last_updated` in STATUS.md before answering.** If it is more than ~7 days before today's
  date, lead with that: the status may be stale and the reader should confirm with the orchestrator.
- **Distinguish "built" from "deployed" — this project makes that distinction constantly.** A
  component being code-complete and locally tested is *not* the same as integrated, deployed, or
  pilot-ready. Never upgrade the language. If STATUS.md says "statically accepted, operational gates
  blocked", do not summarize that as "done".
- **Distinguish "accepted" from "pushed" from "running against real client data."** These are three
  separate gates in this project and STATUS.md tracks them separately.
- **Preserve blockers.** If a work item is gated on a missing client sample or an unexecuted
  verification, mention the gate. A summary that drops the blockers is wrong even if every other
  sentence is true.
- **Don't invent contracts, schemas, WF numbers, dates or commit hashes.** If a WF number isn't in
  `GLOSSARY.md`, say it's not defined here.
- **Percentages are not tracked and should not be estimated.** Do not say "the project is ~60%
  complete." Describe the phase and the gate instead.

## Tone for team members

Most readers are project members, not engineers on this codebase. Translate: say "the submittal log
now updates itself from the client's spreadsheet, but it isn't running on the client's real folder
yet" rather than quoting commit hashes — unless the person asks for the technical detail, in which
case give it precisely.

## Structure of the work

Progress is tracked as phases **P0 → P5** (the canonical sequence, revised 2026-07-19), not as the
older **M0 → M10** milestones. M-numbers still appear as completed foundation work and in historical
notes; they do **not** control the forward order. If a question mixes the two, explain the
difference — it's a common source of confusion.

Within P2, work is sequenced by **workflow (WF) number** in a dependency-safe order. The order is
deliberate and should not be reordered casually: see `DECISIONS.md`.

## What you should not do

- Do not open pull requests or edit `STATUS.md`. Only the orchestrator updates it (see `UPDATING.md`).
- Do not treat GitHub Issues in this repo as project status. They are questions from team members.
- This repository is public. Never add or infer client or vendor names, source filenames, workbook
  or project identifiers, exact client folder paths, email addresses, or client documents. Detailed
  evidence stays in the private working repositories.
