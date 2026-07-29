# Agent instructions

This file exists so that agents following the `AGENTS.md` convention (Codex, Copilot, Cursor, Amp,
and others) get the same guidance as Claude.

**Read [CLAUDE.md](CLAUDE.md) and follow it exactly.** It is the single set of instructions for this
repository. There is no separate behaviour for different assistants.

Quick version, if you read nothing else:

- This repo is a **status mirror**, not a codebase. No source code here.
- Read `STATUS.md` first, then `GLOSSARY.md`. Answer only from these files.
- Check `last_updated` in `STATUS.md`; warn the reader if it's more than ~7 days old.
- Never blur **built** vs **accepted** vs **pushed** vs **deployed** vs **running on real client
  data**. They are distinct gates here and the distinction is the whole point of the document.
- Never drop blockers from a summary.
- Never estimate a completion percentage.
- This repository is public. Never add client or vendor names, source filenames, workbook or project
  identifiers, exact client folder paths, email addresses, or client documents.
- Do not edit `STATUS.md` or open PRs.
