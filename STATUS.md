# Project Status — Construction AI OS

> **last_updated: 2026-08-05**
> **current_phase: P1 (deployment foundation) + P2 (trusted records), running in parallel**
> **current_milestone: WF02 I1 — deployment package and operating guides**
> **pilot_ready: no**

*This page is written for the whole team. Technical terms are explained in
[GLOSSARY.md](GLOSSARY.md).*

---

## In one paragraph

The eight main services have been built and tested separately. On 2026-08-05, an independently
reviewed document-pipeline candidate corrected the production Docling runtime by adding the pinned
`libgl1` dependency and proved the MR027 page-one extraction trace. The basic design and deployment
package have passed review, but live operating checks are not finished. **Nothing is connected to the
client's live source folder, and the platform is not pilot-ready.**

---

## What we're working on right now

### WF02 I1 — deployment package, operating guides, and integration proof

**State:** accepted base package; operating checks are still open.

The team has reviewed and accepted the way the services are packaged, started, separated by
permission, and protected from unsafe database changes. The checks that do not require Docker or
PostgreSQL passed, including the API, rules engine, shared libraries, and release builds.

The accepted package code is available remotely, but it has not been integrated in staging or
deployed:

| Repo | Current evidence |
|---|---|
| `construction-document-api` | Accepted base `6d23789` is on `origin/main`; later drill work through `77db2fb` is on a remote review branch |
| `construction-document-pipeline` | Accepted commit `d3554ae` is on a remote review branch |
| `construction-rules-engine` | Accepted commit `dced448` is on a remote review branch |

Today, four commits on the API verification branch strengthened the operating-test harness: local
image checks, process-local Git trust, Docker-shim handling, and deterministic offline dependency
validation (`e2e315f`, `330d9a0`, `b3e8267`, `b52f504`). These changes are verified locally; they
are not evidence of remote integration, staging deployment, or pilot readiness. A later offline
recovery validation passed without network or Docker use.

**To finish WF02 I1, we still need to:**

- Approve and verify the tool that encrypts production backups.
- Run and record the Docker/PostgreSQL checks for build, database setup, readiness, backup and
  recovery, replay, permissions, schedules, and rollback. The earlier governed drill stopped in
  the test harness before those scenarios began; a fresh successful run is still required.
- Configure a staging environment. There is no staging environment yet.

**Movement on 2026-07-31:** local test-harness and offline-validation reliability work completed.
Still blocked on: B1, B2, B3, B4, B5, B6.

**Movement on 2026-08-02:** verified S1a gateway-session work advanced through `b463636`.
It adds server-scoped dashboard sessions and a repeatable local demo path. Evidence records a
release build, formatting checks, 22 core-unit tests, 9 targeted integration tests, and green CI
(38 tests). It remains candidate evidence: independent acceptance, merge, staging deployment,
and cloud-issuer proof are still open. Dashboard documentation candidate `1e071aa` is local only.

**Movement on 2026-08-03:** merged API reads `0aea15a` (submittal register) and `c65db8c`
(quarantine), with matching shared-contract merges `04f9eb3` and `bdd7b31`. Dashboard commit
`0dda204` adds the real submittal surface. GitHub checks for these commits succeeded (API Windows
core and Docker build; contracts .NET and Python; dashboard build-and-test and verification).
This is implementation and CI evidence only: staging, full operating proof, and pilot readiness
remain open. A redacted demo status site was also deployed in `9b08d79` with successful endpoint
and redaction checks.

**Movement on 2026-08-04:** dashboard PR [#2](https://github.com/sushil-converge/construction-dashboard/pull/2)
merged `7f02198`, adding evidence-aware workflow-status surfaces with a successful GitHub `verify`
check. Pipeline commits `2cd07e7` and `bb09fd6` hardened Tier B producer boundaries and preserved
native-text provenance, including added and updated tests. This is implementation and CI evidence
only; no staging, full operating, or pilot validation was recorded today.

**Movement on 2026-08-05:** pipeline candidate `71e11e3` adds the pinned Debian runtime package
`libgl1=1.7.0-1+b2` and a Docker build-time import gate for OpenCV and Docling TableFormer. An
independent review recorded 15 focused tests passing, a successful production-image build and smoke
checks, and one real-Docling MR027 page-one trace that returned `Naik-STV Joint Venture` with the
expected provenance. This is candidate and local evidence only: it does not establish merge,
staging, full operating, or pilot readiness.

---

## Blockers

| # | What is blocked | Why it matters | Owner |
|---|---|---|---|
| B1 | Docker/PostgreSQL operating checks have not been run because there is no staging environment | WF02 I1 cannot be fully accepted; P1 cannot finish | Build team |
| B2 | Production backup encryption is not fully verified | WF02 I1 cannot be fully accepted | Build team |
| B3 | We do not have the exact live submittal-source folder path | The staged WF02 pilot cannot connect to the client source | Client / IT |
| B4 | Project names, locations, staff authority, document priority, notifications, and acceptance rules are not fully confirmed | Several P2 and P3 workflows cannot be accepted | Client / product owner |
| B5 | The As-Built mapping has not been checked against the specified tracker range | The As-Built work round cannot be accepted | Product owner |
| B6 | The client Oracle administrator has not confirmed that Unifier REST services are enabled | The Unifier connector cannot go live | Client IT |

**B3–B6 need client or product-owner input.** They do not stop today's engineering work, but each
one blocks a later acceptance step.

---

## What's next, in order

Do not reorder this list. Each item depends on the work before it.

1. **Finish WF02 I1** — run the open operating checks and finish publishing the accepted package.
2. **Run the WF02 staged pilot** — connect the approved client source folder, trace one real QWP through the
   whole system, test failure and recovery, and save the evidence.
3. **Build WF03 Registry Reconciliation** — match real QWP and approval documents to the hosted
   submittal records. Any disagreement must go to human review; the system must never hide it.
4. **Connect the submittal screen to real records** — show the current row and its full history.
5. **Add controlled register editing and submittal-number rename** — only after mapping and secure
   access are accepted.
6. **Build WF04 Revision Intelligence** — show which revision is current, which is replaced, and
   what materially changed.
7. **Build WF11 Email Intelligence** — connect approved emails and attachments to the right records.
8. **Optional: limited WF05 RFI support** — do not invent a client RFI status or register.

**P2 is complete only when** a Project QM can review the real client register, understand every
disagreement, approve a correction, and identify the current controlled revision. Sending anything
outside the system remains a human decision.

**P3 comes after P2** in this order: WF12 → WF01 → WF07 → WF13 → WF16 → WF18. It has not started.

---

## Where each phase stands

| Phase | Goal | Status |
|---|---|---|
| **P0 — Client-data lock** | Collect real client examples and expected results | **Mostly complete.** Main samples are available. B3, B4, and B5 remain open. |
| **P1 — Deployment foundation** | Run all services together safely in staging and prove recovery | **Active, not complete.** Separate services exist, but staging and full-system proof are open. |
| **P2 — Trusted records** | Keep submittal and related records correct from real client sources | **Current phase.** WF02 foundations are accepted and pushed. Operating proof and later workflows remain open. |
| **P3 — Quality operating loop** | Connect planning, requirements, assignments, evidence, and verification | Not started. |
| **P4 — Pilot extension** | Add selected punch, NCR, safeguard, and Morning Brief workflows | Not started. |
| **P5 — Hardening and release** | Complete client acceptance, runbooks, and sign-off | Not started. |

---

## Foundation already built (completed, does not control forward order)

These are useful foundations, but they do **not** mean the full platform is deployed:

- **M0** — repository structure and independent implementation/review process.
- **M1** — file intake, duplicate protection, version history, audit, and quarantine. Verified
  against a local Compose setup on 2026-07-13, not a deployed environment.
- **M2** — Microsoft Graph email intake, attachments, conversations, duplicate protection, and
  polling fallback. Verified with real Microsoft Graph on 2026-07-14. Live webhook validation and
  the tenant access policy remain open.
- **M3** — document parsing, classification, extraction, source links, and human-review routing.
- **M4** — rules and registers with history, audit, replay, and comparison support. Acceptance with
  the real client log remains open.
- **M5** — dashboard screens for records, history, source links, review, risks, assignments,
  notifications, search, and Morning Brief. These use test contracts, not production integration.

---

## Components

| Repo | Plain-language role | Last activity |
|---|---|---|
| `construction-shared-contracts` | Shared data formats used by every service | 2026-08-03 `bdd7b31` |
| `construction-sync-agent` | Reads files from the shared folder | 2026-07-22 `50ef144` |
| `unifier-connector` | Connects to Oracle Unifier | 2026-07-13 `5e8dcdd` |
| `construction-email-agent` | Reads approved Microsoft 365 mailboxes | 2026-07-14 `ec1a61d` |
| `construction-document-api` | Receives files and records their history | 2026-08-03 `c65db8c` |
| `construction-document-pipeline` | Reads and classifies document contents | 2026-08-05 candidate `71e11e3` |
| `construction-rules-engine` | Applies rules and updates registers | 2026-07-22 `dced448` |
| `construction-dashboard` | User screens for Project and Corporate QMs | 2026-08-04 `7f02198` |

---

## Standing risks

| Risk | What we are doing about it |
|---|---|
| New document layouts may reduce extraction accuracy | Keep a real test collection, fail accuracy checks when results drop, and send uncertain results to people for review |
| Client-side blockers B3–B6 may delay later gates | Chase them in parallel and show exactly which acceptance step each one blocks |
| Quality-process guidance is still incomplete | Keep the system flexible and refine the flow when the product owner supplies the guidance |
| Unifier settings are not confirmed | Validate them with the client Oracle administrator before go-live |
| The project depends heavily on one builder | Keep written specifications, independent reviews, and per-repository guidance |
| AI model costs may drift | Use model routing, caching, and tenant limits |
| PyMuPDF has a commercial licensing risk | Make a licensing decision before commercial deployment |

---

## How work is run

Work is deliberately split so the same person or tool does not both build and approve a milestone:

**Claude prepares the plan and specification → Codex implements it → Claude checks the result
against the specification.**

A milestone is not complete just because code exists. Its required tests, contracts, documentation,
operating controls, and evidence must also be complete. Independent agents are used only for a
clearly defined milestone review, then stopped when that review ends.

---

*Questions or corrections should be opened as a GitHub Issue. See
[UPDATING.md](UPDATING.md) for the update rules.*
