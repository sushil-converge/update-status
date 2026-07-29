# Decision Log

Why the project is the way it is. Newest first. Each entry is durable — superseded decisions are
marked, not deleted.

Format: `## YYYY-MM-DD — Title` / **Decision** / **Why** / **Consequence**.

---

## 2026-07-22 — Bounded agents only, no standing orchestrator

**Decision.** Routine work stays in the main task. Independent implementer or reviewer agents are
invoked only at an explicit phase or milestone gate, then stopped when that bounded gate completes.
No standing sub-agent orchestrator, no continuous separate implementer.

**Why.** Continuous parallel agents produced drift and duplicated review effort without improving
throughput.

**Consequence.** Review is an event with a defined scope and a defined end, which is what makes
"independently accepted" a meaningful status word in this project.

---

## 2026-07-22 — Rules-worker access boundary for WF02 delivery

**Decision.** The rules worker gets direct tenant-scoped, **read-only** access to platform events,
with a consumer-owned, **payload-free** checkpoint table in the same PostgreSQL database.

**Why.** Avoids introducing a message broker before queue metrics justify one, while keeping the
consumer unable to mutate producer state or duplicate payload storage.

**Consequence.** Durable claims, retry and restart behaviour live in the consumer. Broker migration
stays on the backlog until queue metrics demand it.

---

## 2026-07-21 — Registry scope for the pilot: two registers only

**Decision.** The pilot updates **one submittal register and one closeout register**. All other
client logs stay client-maintained. All supplied document classes enter the platform as submittals
before any class-specific projection.

**Why.** The pilot proves the trust model on the workflows the client actually depends on daily.
Broadening the register surface multiplies mapping work without proving anything new.

**Consequence.** As-built submittals update the submittal log (status level) *and* the As-Built
tracker (sheet-level comments — projection deferred to its own mapping round). O&M manuals, spare
parts, training syllabi and warranty letters update status in both the submittal log and the closeout
tracker.

---

## 2026-07-21 — AI never closes an NCR

**Decision.** AI may extract NCR state and evidence. A human closes the NCR.

**Why.** NCR closure is a signed quality authority act. The supplied evidence pair shows the same NCR
moving from open content to signed Project QM closure — the signature is the point.

**Consequence.** This is a hard boundary, not a configurable default. It generalises: external
distribution stays human-approved through the P2 exit gate.

---

## 2026-07-20 — Revision identity: one logical submittal, many versions

**Decision.** `.000`, `.001`, `.002` … are presented as **versions of one logical submittal**. The
register shows the current version as the main row; a History dropdown exposes every prior complete
row snapshot, newest first, with the full raw `Submittal #`, revision, timestamp, actor/source, and
change origin (`Client workbook import` or `Dashboard edit`). Selecting an older entry is read-only.

**Why.** Users think in submittals, not in revision-suffixed strings. But the client's raw value must
never be rewritten.

**Consequence.** The contract keeps the **normalized logical key separate from the full
revision-bearing source number**, so grouping never destroys the client's value. Every imported workbook
row and every accepted dashboard edit stays an immutable version. If the source changes a field
expected to be stable, preserve the real snapshot and **surface the difference rather than rewriting
history**.

---

## 2026-07-20 — Register editing is a gateway-enforced command, not a field update

**Decision.** Register modification is a separate audited command requiring authorization, optimistic
concurrency, immutable audit history, conflict handling, and reconciliation with later client-workbook imports.
An authorized Project QM's valid edit becomes the current hosted version **immediately** — it does not
wait for Corporate QM approval. Every edit requires a short reason, stored as the version comment and
shown in History. `Submittal #` is editable only via a special audited rename that retains former raw
and normalized numbers as aliases.

**Why.** The QM needs to correct the register in real time to trust it. Auditability, not approval
latency, is what makes that safe. Browser route guards are explicitly **not** an authorization
boundary.

**Consequence.** Stale commands fail visibly. A later conflicting client-workbook import enters
review with no silent overwrite. A source row absent from a later client workbook is retained and marked
`Missing from latest source` — import reconciliation never deletes history.

---

## 2026-07-19 — Canonical roadmap revised: P0–P5 supersedes the M-sequence

**Decision.** The forward order is now the P0–P5 phase sequence. The earlier plan — ship only
transmittal and RFI workflows at M5, and put broad closeout ahead of an end-to-end quality execution
loop — is superseded. Completed work stays valid; only the forward order changes.

**Why.** An end-to-end quality *loop* on real client data proves the product. A broader set of
half-trusted registers does not.

**Consequence.** No new generic AI-agent or chat repository is a pilot prerequisite. Create a new
service only when a selected workflow needs an independent deployable boundary. C8 KPI/report/export
and broad dashboard workflow cards do not resume ahead of trusted producers.

---

## 2026-07-16 — Registers materialize from deterministic YAML rules

**Decision.** The Automation Engine uses constrained deterministic YAML rules with a plugin loader.
Register materialization carries cell history, risk flags, tasks, dashboard-only notifications,
**draft-only email**, deterministic sweeps, replay, reconciliation, and an append-only audit chain.

**Why.** Explainability is the pilot's core promise. A QM must be able to ask "why does this row say
this?" and get a deterministic answer.

**Consequence.** Project processing requires a tenant plus a non-null project, with forced
tenant/project RLS and a per-tenant/project audit hash chain. Pre-project-invalid events with a valid
tenant use a separate tenant-only quarantine chain with no materialization. Well-formed fact types
with no enabled plugin are recorded as `ignored/no-matching-plugin`, not malformed.

---

## 2026-07-13 — Deterministic spine, AI on branches

**Decision.** Document intelligence runs a deterministic spine (Docling parse, AcroForm reader,
quality router) with AI extraction on branches, confidence scoring, and low-confidence routing to a
human review queue.

**Why.** Extraction accuracy on unseen real layouts is the project's #1 named risk. Deterministic-first
keeps failures explainable and gives the review queue a training-loop role.

**Consequence.** A golden-sample corpus with expected-JSON fixtures gates CI. Content-addressed dedupe
means duplicate content never reprocesses.

---

## 2026-07-13 — Spec-driven build with separated implementation and review

**Decision.** Claude plans and specs (Plan Mode → `docs/SPEC-*.md`) → Codex implements → Claude reviews
the diff against the spec. Definition of Done includes tests green, contract fixtures pass,
`ARCHITECTURE.md` updated, ops surface shipped, demoable to the client.

**Why.** Solo-builder bus factor. Every repo stays resumable from its spec and `CLAUDE.md`.

**Consequence.** "Independently accepted" is a distinct status from "built", and both are distinct
from "deployed". `STATUS.md` tracks all three separately.

---

## 2026-07-13 — Identity is required, from day one

**Decision.** The pilot dashboard requires login: Supabase Auth with pre-provisioned accounts and MFA
for the ~10–15 pilot users. Entra SSO is deferred to the hardening phase — same identities, upgraded
sign-in.

**Why.** Work-assignment integrity, the Corporate QM's cross-project scope, audit, and role-aware
copilot prompting all depend on an authenticated identity. A URL-only or profile-switcher dashboard
cannot support any of them.

**Consequence.** Role × project scoping exists from day one. The Project QM lands on their project's
view; the Corporate QM lands on the cross-project rollup.
