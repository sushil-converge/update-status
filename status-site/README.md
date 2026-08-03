# Demo status — shareable link

Serves the demo status page at an unguessable URL, in the same shape as the Boardly links:

```
https://construction-demo-status.<your-subdomain>.workers.dev/b/<slug>
```

The bare root 404s deliberately, so the hostname on its own gives nothing away.

## Setup, once

```powershell
cd D:\Vault\Projects\Construction\project-status\status-site
npm install -g wrangler          # or use npx, as the deploy script does
npx wrangler login
pwsh build-and-deploy.ps1 -NewSlug
```

`wrangler` prints the real hostname on first deploy. **Record it below** — the deploy script
can't know it.

> **Live URL:** <https://construction-demo-status.tsush.workers.dev/b/qfrxva4rb77hed>
>
> Deployed 2026-08-03, serving **`redacted`**. Slug `qfrxva4rb77hed`.
> Verified live: `/b/<slug>` 200 with `x-robots-tag: noindex, nofollow, noarchive`;
> bare root and a wrong slug both 404.

## Every update after that

```powershell
# 1. edit demo-status.json   (the single source of truth)
# 2. then:
pwsh build-and-deploy.ps1
```

That renders the HTML, bakes both variants into the Worker, and deploys. Roughly ten seconds.

## Read this before sharing the link

**The slug is the only thing protecting this page.** That is obscurity, not access control.
It isn't indexed and isn't guessable, but anyone who has the link keeps it — there are no
accounts, no expiry, and no audit of who opened it. Rotating the slug with `-NewSlug` is the
only revocation mechanism, and it breaks the link for everyone at once.

**And consider what the full page actually says.** It names the contract, names specific
submittals, and states that one of them has been sitting with the reviewer for thirteen
months with no status recorded. That is a fact about the client's own contract performance.
This repo's own README sets the standard: report status *"without exposing client-identifying
details."*

So there are two builds:

| Mode | Contains |
|---|---|
| `full` | Everything. For people who already know the client. |
| `redacted` | Contract number, submittal identifiers, client and reviewer names removed; the headline card withheld entirely. Progress, gates, tiers, blockers and risks all remain. |

Switch without rebuilding:

```powershell
pwsh build-and-deploy.ps1 -Mode redacted
```

The redaction is deliberately blunt — it strips identifiers rather than rewording prose, and
drops the headline block wholesale instead of trusting a regex to neuter the sentence. **Open
the redacted page and read it before sharing it.** An automated redaction you haven't checked
is a worse risk than no redaction, because it feels safe.

### `redactions.local.json`

The patterns are **not** in `build-and-deploy.ps1`. To redact a term you have to name it, so a
hardcoded list would publish the client name and contract number into this public repo even
while the deployed page stayed clean. They live in `status-site/redactions.local.json`, which
the existing `*.local.*` ignore rule keeps out of git.

**The build fails closed if that file is missing** — it will not quietly produce a "redacted"
page that is the full page wearing a safe label. If you clone this repo fresh you must recreate
the file before a redacted build will run:

```jsonc
{
  "redactions": [
    // most-specific FIRST: the submittal ref is a superstring of the contract number
    { "pattern": "<submittal-ref-regex>", "with": "[submittal ref]" },
    { "pattern": "<contract-regex>",      "with": "[contract]" },
    { "pattern": "<reviewer-regex>",      "with": "[reviewer]" },
    { "pattern": "<client-regex>",        "with": "[client]" }
  ],
  // literals that must NOT survive; the build throws if any does
  "verify": ["<term>", "..."]
}
```

Every build asserts that no `verify` term survived **and** that the gates, tiers, blockers and
risks sections are still present, so neither a leak nor an over-broad strip can ship unnoticed.

If the audience ever needs to be genuinely restricted rather than merely obscured, put
Cloudflare Access in front of the worker — that's real authentication, and it's a
configuration change rather than a rewrite.

## Files

| File | Role |
|---|---|
| `../demo-status.json` | **Source of truth.** Edit this. |
| `../scripts/render-demo-status.ps1` | JSON → HTML |
| `build-and-deploy.ps1` | render → bake both variants → deploy |
| `redactions.local.json` | **local only, never committed** — the redaction patterns |
| `src/index.js` | the Worker: slug routing, `noindex`, short cache |
| `src/status.gen.js` | generated, do not edit |
| `wrangler.toml` | slug and mode |

`src/status.gen.js` is generated on every build. It embeds **both** variants, so it carries the
full page — contract number, submittal identifiers, the thirteen-months observation — in clear
text regardless of which mode is deployed.

**This repository is public** (`sushil-converge/update-status`). So `src/status.gen.js` and
`../demo-status.html` are in `.gitignore` and must never be committed. Both are regenerated on
every build, so nothing is lost by keeping them out. Check `git status` before committing if you
have touched the build.

`wrangler.toml` *is* committed, slug included. That is deliberate and only safe while
`PUBLIC_MODE = "redacted"`: the slug is discoverable from this repo, so the page it serves must be
the variant that carries no client detail. **If you switch to `full`, the slug must stop being
public** — gitignore `wrangler.toml` at the same time, or the contract number becomes reachable
from the repo's file list.
