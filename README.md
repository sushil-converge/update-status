# Construction AI OS — Project Status

**Public team status. Read-only for most members. One purpose: tell you where the project stands
right now without exposing client-identifying details.**

This repo contains no source code. It is a status mirror maintained by the project orchestrator so that
team members — and their AI assistants (Claude, ChatGPT, Codex, Copilot) — can answer "what's happening
and what's next" without digging through eight code repositories.

## Start here

| File | What it's for |
|---|---|
| **[STATUS.md](STATUS.md)** | The current state. Read this first. |
| [status.json](status.json) | Same facts, machine-readable. For tooling and agents. |
| [DECISIONS.md](DECISIONS.md) | Why things are the way they are. Reverse-chronological. |
| [CHANGELOG.md](CHANGELOG.md) | What changed each update, dated. |
| [GLOSSARY.md](GLOSSARY.md) | WF codes, phase codes, repo names, personas. Decode the jargon. |
| [CLAUDE.md](CLAUDE.md) / [AGENTS.md](AGENTS.md) | Instructions for AI assistants reading this repo. |
| [UPDATING.md](UPDATING.md) | How the orchestrator updates this repo. |

## For team members using an AI assistant

Point your assistant at this repo and ask normally. Two ways:

**Claude Code / Codex CLI (best):** clone the repo and run the assistant inside the folder.
It will pick up `CLAUDE.md` / `AGENTS.md` automatically.

```bash
git clone https://github.com/sushil-converge/update-status.git construction-status
cd construction-status
claude          # or: codex
```

**Claude.ai / ChatGPT web:** connect the GitHub repo (Claude: Settings → Connectors → GitHub;
ChatGPT: the GitHub connector), then ask. If connectors aren't available, paste the raw contents
of `STATUS.md` and `GLOSSARY.md` into the chat.

Good questions to ask:

- "What is the team working on right now, and what's blocking it?"
- "What is WF02 and why does it come before WF03?"
- "What did we decide about editing register rows, and why?"
- "What changed since last Tuesday?"

## Ground rules

- **This repo is a report, not a source of truth for code.** Commit hashes here point at the
  real repos; the code itself lives elsewhere.
- **Don't edit STATUS.md by hand** unless you're the orchestrator. Raise questions as GitHub
  Issues instead — that keeps the status file single-authored and trustworthy.
- **This repository is public.** Never add client or vendor names, source filenames, workbook or
  project identifiers, exact client folder paths, email addresses, or client documents. Detailed
  evidence stays in the private working repositories.
