# Changelog

What changed in the project, by update. Newest first. One entry per `STATUS.md` update.

Each entry answers: what moved, what's newly blocked or unblocked, what's next.

---

## 2026-07-28

**Moved.** WF02 I1 operational work continued through the week: backup-encryption tooling (`age`)
acquisition, identity and ACL hardening on the governed staging path, pipeline stability fixes, and
operational drill runs with evidence capture. `construction-document-api` `279b41d` → `77db2fb`.

**Still blocked.** Docker/PostgreSQL operational gates remain unexecuted. No staging environment is
configured. WF02 I1 candidate commits remain local and unpushed.

**Next.** Finish the encryption tooling verification, execute the operational gates, push the I1
candidates.

*This repository was created on this date. Entries before it are reconstructed from the project
handbook, the milestone progress log, and repository history — they are accurate but less granular
than entries going forward will be.*

---

## 2026-07-23

**Moved.** WF02 I1 deployment packaging and operational runbooks **statically accepted** by bounded
independent review — immutable package/Compose boundary, explicit rules Hangfire migration ownership
with restricted runtime separation, production privilege attestation, cluster-identity principal
separation, migration ordering, runtime-DDL proof design, secret-safe command paths. Non-Docker
verification passed in full (API packaging 14/14, API units 22/22, rules packaging 5/5, feasible rules
tests 99/99, shared .NET 282/282, shared Python 285/285, zero-warning Release builds). Candidates:
API `6d23789`, pipeline `d3554ae`, rules `dced448`.

**Unblocked.** The P0 package grew: a representative two-week lookahead, a real daily quality report,
As-Built mapping instructions, and punch photographs were all received.

**Still blocked.** I1 operational acceptance needs an approved streaming authenticated-encryption tool
for production backups plus the unexecuted Docker/PostgreSQL gates (build, migration, readiness,
recovery, replay, runtime attestation, runtime DDL, schedule, rollback).

---

## 2026-07-22

**Moved.** WF02 I0 cross-repository compatibility **accepted and pushed** — sync `50ef144`, pipeline
`92f2f67`, API/harness `cc2b939f`, rules `d20bad9`. The pinned production-entrypoint harness proved
real sync → API → pipeline → rules flow, v1/v2 immutable history, replay idempotency, selector
boundaries, tenant isolation and complete cleanup. Pipeline CI `29908953287` and rules CI
`29908953502` passed.

**Note.** The first I0 candidates were **rejected**: substitute pipeline/rules hosts bypassed
production entrypoints and masked a real rules Worker startup defect. The corrected candidates removed
both substitutes and added a separately reviewed startup fix. This is the review process working.

**Decided.** Rules-worker access boundary — direct tenant-scoped read-only access to platform events
with a consumer-owned, payload-free checkpoint table. Also: bounded agents only, no standing
orchestrator.

---

## 2026-07-21

**Moved.** WF02 snapshot persistence and immutable full-row history accepted and pushed (`8dd8a2f`);
21/21 PostgreSQL cases, full Release regression suite, and GitHub `build-and-test` run `29831098840`
passed. `submittal-source-snapshot.v1` contract accepted and pushed (`e3297f9`). The client-workbook
source-snapshot producer was accepted and pushed (`f750ec3`).

**Unblocked.** The client supplied a complete submittal revision chain with returned review packages,
an approval package, inspection examples, nonconformance evidence, and a closeout tracker. This
closed the missing matching submittal/review sample gate for WF03 specification and fixture work.

**Found.** Real-data mismatches that must enter deterministic review, not be smoothed over: one
revision has a returned review package while its worksheet return fields are blank; another revision
has a date disagreement between the PDF and worksheet.

**Decided.** Registry scope — two registers only. AI never closes an NCR.

---

## 2026-07-20

**Moved.** Canonical `submittal.v1` contract accepted and pushed (`a56816f`, `fac688d`).

**Unblocked.** A real client submittal workbook was inspected and accepted as the first WF02 source
sample, closing the long-standing "missing real submittal log" blocker. Confirmed: the client-side
provider maintains the same workbook in place, and the file arrives through the existing folder-sync
service. The first live scope is one approved worksheet only.

**Decided.** Revision identity (one logical submittal, many versions). Register editing as a
gateway-enforced audited command.

---

## 2026-07-19

**Decided.** Canonical roadmap revision: the P0–P5 phase sequence supersedes the M-number forward
order. Completed work stays valid. No generic AI-agent or chat repository is a pilot prerequisite.

---

## 2026-07-13 → 2026-07-18 — Foundation

**M1 Ingress (2026-07-13).** Document API + sync agent built, reviewed in four rounds, verified end to
end against a live local Compose stack: token exchange, `/v1/documents` ingest, content-addressed
dedupe, `duplicate:true` idempotency, audit rows, 422 poison rejection. Staging and prod VPS deploy
left open.

**M2 Email (2026-07-14).** Email agent built and verified against **real Microsoft Graph** — delta
pickup, attachment ingest with valid sidecars, dedupe (3 documents → 2 blobs), conversation grouping,
watermark surviving restart. The live run caught a real defect replay fixtures could not (attachment
`$select` on derived-type properties → Graph 400), now fixed and guarded. Caveats: webhook
live-validation deferred (Graph rejects a localhost notification URL); Application Access Policy not
applied on the test tenant.

**M3 Pipeline (2026-07-16).** Docling spine, classification, extractors, confidence and review
routing, provenance, transmittal/RFI producers. Cleared the 95% accuracy gate.

**M4 Rules & registers (2026-07-16/17).** Deterministic YAML rules, transmittal/RFI registers with
cell history, audit, replay, reconciliation foundations. Milestone acceptance against a real client
log stayed pending — synthetic fixtures cannot satisfy it.

**M5 Dashboard (2026-07-17/18).** Next.js shell, register grids with cell history, provenance viewer,
review queue, risk, assignment, notification, search and Morning Brief surfaces. Contract-fixture
backed, not production integration.
