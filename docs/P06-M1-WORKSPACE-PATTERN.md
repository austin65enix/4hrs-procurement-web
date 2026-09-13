# P06-M1 Qualified Workspace Pattern Extraction

## 1. Purpose

Extract the reusable 4HRS workspace pattern from the qualified
Procurement Workspace baseline without changing application runtime behavior.

This milestone performs pattern identification only.

It does NOT:
- build the Medical scenario
- build the Campus scenario
- generalize the database schema
- refactor the application into a framework
- introduce authentication
- change production or publication scope


## 2. Source Baseline

SOURCE_TAG=p05-workspace-v1.0.0
SEAL_COMMIT=44a8020

The source baseline has already qualified:

- Dashboard
- New Request
- Requests
- Search / Filter
- Request Detail
- Approve / Reject
- History
- Decision Trace
- Evidence CSV
- SQLite persistence


## 3. Qualified Workspace Pattern

The reusable process pattern is:

CREATE
  ↓
PENDING QUEUE
  ↓
DECISION
  ↓
HISTORY
  ↓
EVIDENCE VIEW
  ↓
EVIDENCE EXPORT
  ↓
QUALIFICATION / SEAL

Canonical representation:

Submission
→ Queue
→ Decision
→ History
→ Evidence
→ Seal


## 4. Pattern Layers

### Layer A — Runtime / Operations Shell

Reusable concept:

- Dockerized application
- persistent data volume
- health endpoint
- start operation
- verify operation
- backup operation
- recovery operation
- runtime health qualification

Current implementation is not yet domain-neutral.

Procurement-specific identifiers still exist in:

- service name
- container name
- image name
- volume name
- database filename
- console text
- verification messages

Classification:

REUSE_MODE=PARAMETERIZE


### Layer B — Workspace Shell

Reusable structure:

- Dashboard
- New Submission
- Work Queue
- History

Procurement currently presents these as:

- Dashboard
- New Request
- Requests
- History

Reusable capabilities:

- workspace navigation
- active workspace state
- dashboard summary
- recent activity
- search
- status filter
- detail expansion
- history rendering

Classification:

REUSE_MODE=TEMPLATE


### Layer C — Workflow Kernel

Qualified Procurement transition:

PENDING
→ APPROVED

or

PENDING
→ REJECTED

Current invariant:

Only PENDING records may be decided.

A previously decided record must not be decided again.

Reusable concepts:

- initial queue state
- terminal decision state
- fail-closed transition
- single decision boundary
- decision metadata capture

Domain status vocabulary may change in future scenarios.

Classification:

REUSE_MODE=POLICY_TEMPLATE


### Layer D — Decision Evidence

Reusable evidence structure:

- outcome
- actor
- reason
- submission timestamp
- decision timestamp

Current fields:

- status
- created_at
- decided_at
- decided_by
- decision_note

Evidence semantics:

- unknown historical metadata remains NULL
- missing legacy evidence must not be fabricated
- UI presentation may display "未記錄"
- evidence export preserves raw NULL / empty values
- decided_by is currently self-asserted identity
- decided_by is NOT authenticated identity

Classification:

REUSE_MODE=DIRECT_CONCEPT


### Layer E — Domain Data Model

Procurement-specific fields:

- applicant
- item_name
- quantity
- unit_price
- total_amount

Procurement-specific storage:

- purchase_requests
- procurement.db

Procurement-specific API vocabulary:

- /requests
- /approve
- /reject

These MUST NOT be treated as universal 4HRS fields.

A new domain must explicitly define its own submission payload.

Classification:

REUSE_MODE=REPLACE


### Layer F — Domain Presentation

Procurement-specific presentation includes:

- 採購申請
- 採購品項
- 單價
- 總金額
- 核准
- 駁回

These labels are domain vocabulary, not framework vocabulary.

Reusable presentation concepts are:

- submission form
- queue item
- decision action
- history item
- evidence detail
- dashboard summary

Classification:

REUSE_MODE=REPLACE_LABELS_AND_FIELDS


### Layer G — Evidence Export

Reusable structure:

- export currently filtered records
- preserve raw evidence fields
- UTF-8 CSV
- include lifecycle timestamps
- include decision metadata

Domain fields precede the shared evidence fields.

Shared evidence fields:

- status
- created_at
- decided_at
- decided_by
- decision_note

Classification:

REUSE_MODE=TEMPLATE


### Layer H — Qualification / Seal

Reusable qualification sequence:

Q1 Runtime / Health
Q2 Create Submission
Q3 Queue Presence
Q4 Decision Input
Q5 API Decision Record
Q6 Persistence
Q7 Detail / History Evidence
Q8 Evidence Export
Q9 Legacy / Unknown Evidence Semantics
Q10 Git Baseline Seal

Each scenario must use a controlled qualification case.

Each scenario must preserve unknown evidence rather than inventing values.

Classification:

REUSE_MODE=DIRECT_PATTERN


## 5. Reuse Matrix

| Capability | Generic Pattern | Procurement Specific | Future Action |
|---|---|---|---|
| Workspace navigation | Yes | Labels | Parameterize |
| Dashboard | Yes | Procurement counts/text | Template |
| Submission form | Structure only | Procurement fields | Replace payload |
| Queue | Yes | Request terminology | Parameterize |
| Search / Filter | Yes | Searchable domain fields | Configure |
| Detail view | Yes | Domain fields | Template |
| PENDING decision boundary | Yes | Status vocabulary | Policy |
| Actor / reason / timestamp | Yes | No | Reuse |
| History | Yes | Domain summary | Template |
| Evidence CSV | Yes | Domain columns | Template |
| SQLite persistence | Pattern | Table/schema | Replace schema |
| Docker runtime | Yes | Names | Parameterize |
| Backup / Recovery | Yes | DB identity | Parameterize |
| Qualification / Seal | Yes | Controlled case | Reuse pattern |


## 6. Core Invariants

### INV-01 — Submission Identity

Every submitted case must have a stable identity.

### INV-02 — Explicit Initial State

A new case enters an explicit workflow state.

Procurement baseline:

PENDING

### INV-03 — Controlled Decision Boundary

Only an eligible case may cross the decision boundary.

Procurement baseline:

PENDING → APPROVED
PENDING → REJECTED

### INV-04 — Decision Evidence

A post-contract decision records:

- outcome
- actor
- reason
- decision timestamp

### INV-05 — Time Lineage

created_at represents submission time.

decided_at represents decision time.

They must not be conflated.

### INV-06 — Unknown Means Unknown

Missing historical evidence remains unknown.

No actor, reason, or timestamp may be inferred merely because a terminal status exists.

### INV-07 — Raw Evidence Export

Exported evidence retains stored values.

Presentation labels such as "未記錄" must not replace raw missing values.

### INV-08 — Identity Assurance Boundary

Self-entered decided_by is an asserted identity only.

It must not be represented as authenticated identity.

### INV-09 — Qualification Before Seal

A scenario baseline is not considered qualified until an end-to-end controlled case is verified.

### INV-10 — Immutable Qualified Reference

A qualified baseline receives a Git seal/tag before domain reuse begins.


## 7. Generic Conceptual Model

The extracted conceptual model is:

Workspace
├─ Dashboard
├─ Submission
├─ Queue
├─ Decision
├─ History
└─ Evidence

Case
├─ Identity
├─ Domain Payload
├─ Workflow Status
├─ created_at
└─ Decision
   ├─ Outcome
   ├─ Actor
   ├─ Reason
   └─ decided_at

The Domain Payload is intentionally NOT generalized in P06-M1.


## 8. Procurement-Specific Components To Isolate Later

The following must be treated as domain-specific seams:

- PurchaseRequestCreate
- purchase_requests
- procurement.db
- applicant
- item_name
- quantity
- unit_price
- total_amount
- Procurement Web
- 採購申請
- procurement Docker service identity
- procurement volume identity
- procurement CSV filename


## 9. Candidate Future Extraction Seams

These are design seams only.
They are NOT implemented in P06-M1.

### Scenario Identity

Possible responsibilities:

- scenario id
- display name
- application title
- service identity

### Domain Payload Contract

Possible responsibilities:

- submission fields
- labels
- validation
- searchable fields
- summary fields

### Workflow Policy

Possible responsibilities:

- initial state
- eligible decision states
- allowed transitions
- terminal states
- action labels

### Evidence Policy

Possible responsibilities:

- required decision metadata
- evidence presentation
- evidence export fields
- unknown-value semantics

### Qualification Profile

Possible responsibilities:

- controlled case
- expected transition
- evidence assertions
- seal requirements


## 10. P06-M1 Boundary

P06-M1 extracts the qualified pattern.

It does not claim that the current Procurement code is already a reusable framework.

Current result:

QUALIFIED_APPLICATION=YES
EXTRACTED_PATTERN=YES
GENERIC_RUNTIME_IMPLEMENTATION=NO


## 11. Next Milestone

Recommended next milestone:

P06-M2 — Scenario Contract

Purpose:

Define one new domain against this extracted pattern before changing runtime code.

Candidate domains:

- Medical
- Campus
- Manufacturing
- HR
- IT Service


## 12. M1 Exit Contract

SOURCE_BASELINE_QUALIFIED=YES
WORKSPACE_PATTERN_EXTRACTED=YES
DOMAIN_SPECIFIC_SEAMS_IDENTIFIED=YES
DECISION_EVIDENCE_PATTERN_IDENTIFIED=YES
QUALIFICATION_PATTERN_IDENTIFIED=YES

APPLICATION_CODE_CHANGE=NO
DATABASE_CHANGE=NO
RUNTIME_BEHAVIOR_CHANGE=NO

P06-M1_RESULT=PASS