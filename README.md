# Construction AI OS — Project Status

**Public team status. Read-only for most members. One purpose: tell you where the project stands
right now without exposing client-identifying details.**

This repo contains no source code. It is a status mirror maintained by the project orchestrator so that
team members — and their AI assistants (Claude, ChatGPT, Codex, Copilot) — can answer "what's happening
and what's next" without digging through eight code repositories.

## Start here

Two tracks run in parallel and each has its own status page. **The pilot** is the full
multi-month build; **the demo** is a 15-day sprint to put the client's own submittal log on a
screen by 22 August. They share this repo's glossary, decisions and assistant instructions.

> **The demo-track files are deliberately not in this repo.** `DEMO-STATUS.md`,
> `demo-status.json` and `demo-status.html` name the contract and specific submittals, and this
> repository is public — see the standing rule in [CLAUDE.md](CLAUDE.md). They stay on the
> orchestrator's machine. The shareable, **redacted** view of the demo track is published at the
> URL recorded in [status-site/README.md](status-site/README.md).

| File | What it's for |
|---|---|
| **[STATUS.md](STATUS.md)** | **Pilot** — the current state. Read this first. |
| [status.json](status.json) | Same facts, machine-readable. For tooling and agents. |
| `DEMO-STATUS.md` | **Demo** — the 15-day sprint to 22 August. Updates daily. *Local only, see below.* |
| `demo-status.json` | Same facts, machine-readable. The source the HTML view renders from. *Local only.* |
| `demo-status.html` | Rendered view of the demo track. Generated; regenerate with `pwsh scripts/render-demo-status.ps1`. *Local only.* |
| [status-site/](status-site/) | Publishes a redacted demo view to a shareable URL. |
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
