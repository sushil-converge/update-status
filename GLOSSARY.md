# Glossary

Decoder ring for `STATUS.md`. If a term isn't here, it isn't defined for this project — say so
rather than guessing.

## Phases (the canonical forward sequence, set 2026-07-19)

| Code | Name | Meaning |
|---|---|---|
| **P0** | Client-data lock | Get a real, accepted sample and expected output for every pilot workflow |
| **P1** | Trustworthy deployment spine | All components running together in a secure, observed, replayable staging path with real identity and project scope |
| **P2** | Trusted records | The registers maintain themselves correctly from real client sources: WF02, WF03, WF04, WF11, limited WF05 |
| **P3** | Quality operating loop | Plan → requirement → assignment → evidence → verification, end to end: WF12, WF01, WF07, WF13, WF16, WF18 |
| **P4** | Pilot extension | Bounded WF09, WF06, bounded WF24, WF14 |
| **P5** | Hardening and release | Client acceptance, shadow mode, assisted mode, runbooks, signed sign-off |

## Milestones (M0–M10) — historical

The earlier plan. **M-numbers are completed foundation work and do not control the forward order.**
Anything still labelled by M-number in `STATUS.md` is history, not a live workstream. M0 baseline,
M1 ingress, M2 email, M3 pipeline, M4 rules/registers, M5 dashboard are built. M6–M10 (knowledge
layer, closeout, agents, multi-tenant hardening, expansion) were superseded by the P0–P5 sequence.

## Workflow codes

| Code | Workflow |
|---|---|
| **WF01** | Quality Work Control |
| **WF02** | Submittal log — canonical submittal record from a client-maintained workbook. *The current focus.* |
| **WF03** | Registry Reconciliation — match real submittal/RAR documents to hosted submittal records |
| **WF04** | Revision Intelligence — active/superseded chains, current controlled revision, material changes |
| **WF05** | RFI capability (limited, optional support) |
| **WF06** | NCR extraction and trends |
| **WF07** | Inspection and ITP Tracker |
| **WF09** | Punch Evidence — QM-selected scope, photos, Word evidence report |
| **WF11** | Email Intelligence — governed correspondence and attachment linking |
| **WF12** | Two-Week Lookahead Parser |
| **WF13** | Assignment and Evidence Tracker |
| **WF14** | Morning Brief |
| **WF16** | Daily Quality Report Intelligence |
| **WF18** | Role Dashboards — Project QM and corporate leadership |
| **WF24** | Deterministic safeguards — cited missing-prerequisite and missing-evidence warnings |
| WF08, WF10, WF15, WF17, WF19–WF23, WF25–WF27 | Deferred beyond the pilot |

Slice suffixes within a workflow (e.g. **WF02 R0/R1**, **WF02 I0/I1**) are implementation rounds.
`R` rounds are contract/producer/persistence work; `I` rounds are integration and deployment work.

## Construction and client terms

| Term | Meaning |
|---|---|
| **GC** | General contractor — the client |
| **QM** | Quality Manager |
| **Project QM** | Quality Manager for one project. One of the two pilot personas. |
| **Corporate QM (CQM)** | Supervises Project QMs across all projects. The second pilot persona. |
| **Submittal** | A document a contractor submits for review and approval before work proceeds |
| **RAR** | Review and Approval Response — the returned package for a submittal |
| **QWP** | Quality Work Plan |
| **ITP** | Inspection and Test Plan |
| **RFSI** | Request For Site Inspection — a request, *not* proof the inspection occurred or passed |
| **RFI** | Request For Information |
| **NCR** | Non-Conformance Report. AI may extract state and evidence but **never closes an NCR.** |
| **Transmittal** | Cover document accompanying a set of transmitted documents |
| **Punch list** | Outstanding items to fix before closeout |
| **Closeout / turnover** | End-of-project handover: O&M manuals, spare parts, warranties, training |
| **As-Built** | Drawings reflecting what was actually built |
| **Two-week lookahead (2WLA)** | The rolling short-term construction schedule |
| **Hold point** | A point where work stops until an inspection is passed |
| **Unifier** | Oracle Primavera Unifier — the client's project management system |

## Platform terms

| Term | Meaning |
|---|---|
| **Shared contracts** | Versioned schemas (`submittal.v1`, `transmittal.v1`, `rfi.v1`, …) that every service agrees on. Changing one is a cross-repo event. |
| **Register** | A self-maintaining table of records (submittal register, closeout register) with full cell-level history |
| **Cell history** | Every prior value of every field, with who/when/why. Never overwritten. |
| **Provenance** | The link from an extracted fact back to the exact document and location it came from |
| **Review queue** | Where low-confidence extractions go for a human decision |
| **Quarantine** | Where malformed or unroutable inputs go instead of failing silently |
| **Reconciliation** | Comparing hosted records with a re-imported client source; divergences enter review and **never silently overwrite** |
| **Replay** | Re-running processing from stored events to prove idempotency |
| **Correlation ID** | One identifier traced across every service for a single document's journey |
| **Gateway** | The server-side authorization boundary. Browser route guards are explicitly *not* an authorization boundary. |
| **RLS** | Row-Level Security — database-enforced tenant and project isolation |
| **Docling** | The document parsing engine used as the deterministic spine |
| **Golden corpus** | Sample documents with expected-output fixtures; regressions fail CI |

## Status vocabulary — these words are not interchangeable

| Term | Means |
|---|---|
| **Built** | Code exists and its own tests pass locally |
| **Accepted** | An independent bounded review checked it against the approved spec and signed off |
| **Pushed** | Committed to the shared remote. Accepted-but-unpushed is a real and common state here. |
| **Integrated** | Runs together with the other services through production entrypoints |
| **Deployed** | Running in a configured staging or production environment |
| **Pilot-ready** | Running against the client's real data with runbooks exercised and readiness evidence recorded |

A component can be *built, accepted and pushed* and still be nowhere near *pilot-ready*. Most of the
platform is exactly in that state right now.
