# P06-M2 Medical Scenario Contract

## 1. Purpose

Define a Medical scenario against the qualified 4HRS Workspace Pattern
before any Medical runtime implementation is created.

This milestone is contract-only.

It does NOT:
- modify backend code
- modify frontend code
- modify database schema
- process real patient information
- provide diagnosis
- provide treatment recommendations
- make autonomous clinical decisions
- claim production medical readiness


## 2. Source Pattern

SOURCE_PATTERN=P06-M1
SOURCE_COMMIT=62b765e

Canonical reusable flow:

Submission
→ Queue
→ Decision
→ History
→ Evidence
→ Seal


## 3. Scenario Identity

SCENARIO_ID=medical-review
DISPLAY_NAME=4HRS Medical Review
SCENARIO_TYPE=Administrative Review Lab
DATA_CLASS=Synthetic Only

Purpose:

Demonstrate domain reuse using a non-clinical,
human-reviewed medical-support workflow.


## 4. Safety Boundary

The Medical scenario is a Lab / demonstration workflow.

It MUST NOT:

- contain real patient identifiers
- contain real medical records
- diagnose disease
- recommend treatment
- approve or deny real patient care
- replace licensed clinical judgment
- represent reviewer identity as authenticated unless authentication is implemented

All qualification data must be synthetic.


## 5. Workspace Mapping

Generic Workspace:

Dashboard
Submission
Queue
Decision
History
Evidence

Medical presentation:

Dashboard
New Review
Review Queue
History
Evidence


## 6. Medical Submission Contract

The Medical domain payload is:

- requester
- department
- case_reference
- request_type
- priority
- summary

Field semantics:

### requester

Person submitting the review request.

### department

Synthetic organizational unit.

Examples:

- Internal Medicine
- Radiology
- Nursing
- Pharmacy

### case_reference

Synthetic case identifier.

Example:

MED-LAB-001

It MUST NOT contain a real patient identifier.

### request_type

Administrative review category.

Examples:

- Specialist Review Request
- Documentation Review
- Resource Coordination
- Follow-up Review

### priority

Allowed values:

- ROUTINE
- PRIORITY

Priority is workflow metadata only.

It MUST NOT be interpreted as clinical triage.

### summary

Short synthetic description of the review request.

No real PHI or medical record content is allowed.


## 7. Workflow Contract

Initial state:

PENDING_REVIEW

Allowed terminal transitions:

PENDING_REVIEW
→ ACCEPTED

PENDING_REVIEW
→ RETURNED

No other transition is allowed in v1.

A terminal case MUST NOT be decided again.


## 8. Decision Actions

Medical UI vocabulary:

ACCEPTED
→ 接受

RETURNED
→ 退回補充

The Decision action is performed by a human reviewer.

The system records the decision.

The system does not make the decision autonomously.


## 9. Decision Evidence Contract

Reuse shared evidence semantics:

- status
- created_at
- decided_at
- decided_by
- decision_note

Medical presentation labels:

status
→ 覆核結果

created_at
→ 申請時間

decided_at
→ 覆核時間

decided_by
→ 覆核人

decision_note
→ 覆核說明


## 10. Identity Assurance

Current decided_by semantics:

SELF_ASSERTED

The reviewer name is entered by the user.

It is NOT:

- authenticated identity
- verified medical license identity
- enterprise IAM identity

The UI and evidence model must not claim otherwise.


## 11. Unknown Evidence Semantics

Unknown historical evidence remains unknown.

If decided_by is absent:

UI:
未記錄

Evidence export:
NULL / empty


If decision_note is absent:

UI:
未記錄

Evidence export:
NULL / empty


If decided_at is absent:

UI:
未記錄

Evidence export:
NULL / empty


Missing evidence MUST NOT be reconstructed from terminal status.


## 12. Dashboard Contract

Medical Dashboard metrics:

- Total Reviews
- Pending Review
- Accepted
- Returned

Recent activity:

- newest review requests
- status
- requester
- request type

Trend:

- submissions by created_at

The dashboard must not imply medical outcome quality.


## 13. Search / Filter Contract

Searchable fields:

- case_reference
- requester
- department
- request_type
- status

Status filter:

- ALL
- PENDING_REVIEW
- ACCEPTED
- RETURNED


## 14. Detail View Contract

Medical Detail View must present:

- case identity
- requester
- department
- request type
- priority
- summary
- workflow status
- submission time

When decided:

- decision outcome
- reviewer
- review note
- decision time


## 15. History Contract

History contains terminal cases only:

- ACCEPTED
- RETURNED

PENDING_REVIEW cases MUST NOT appear in History.

History is evidence presentation.

It is not a substitute for a full audit log.


## 16. Evidence Export Contract

Evidence CSV must contain:

Domain fields:

- id
- requester
- department
- case_reference
- request_type
- priority
- summary

Shared lifecycle evidence:

- status
- created_at
- decided_at
- decided_by
- decision_note

Raw stored evidence must be exported.

Presentation strings such as "未記錄"
must not replace missing raw values.


## 17. Medical Reuse Mapping

| Generic Pattern | Procurement | Medical |
|---|---|---|
| Submission | Purchase Request | Review Request |
| Queue | PENDING | PENDING_REVIEW |
| Positive Decision | APPROVED | ACCEPTED |
| Negative / Return Decision | REJECTED | RETURNED |
| Submitter | applicant | requester |
| Domain Reference | item_name / id | case_reference |
| Actor | decided_by | reviewer |
| Reason | decision_note | review note |
| Submission Time | created_at | created_at |
| Decision Time | decided_at | decided_at |
| History | Closed purchases | Completed reviews |
| Evidence Export | Procurement CSV | Medical Review CSV |


## 18. Controlled Qualification Case

CASE_ID=MED-LAB-001

Synthetic payload:

requester:
Austin

department:
Internal Medicine

case_reference:
MED-LAB-001

request_type:
Specialist Review Request

priority:
ROUTINE

summary:
Synthetic review request for workflow qualification.

Expected workflow:

CREATE
→ PENDING_REVIEW
→ ACCEPTED

Expected decision evidence:

decided_by:
Austin

decision_note:
P06-M2 synthetic medical review acceptance

Expected evidence:

- created_at exists
- decided_at exists
- decided_at >= created_at
- decided_by exists
- decision_note exists
- History contains the case
- Evidence CSV contains the case


## 19. Qualification Profile

Future Medical scenario qualification:

Q1 Runtime / Health
Q2 Create Synthetic Review
Q3 Pending Review Queue
Q4 Human Decision Input
Q5 API Decision Record
Q6 Persistence
Q7 Detail Evidence
Q8 History Evidence
Q9 CSV Evidence Export
Q10 Baseline Seal


## 20. Reuse Decisions

Directly reusable:

- Workspace navigation concept
- queue concept
- decision boundary
- decision evidence model
- History concept
- Evidence export semantics
- qualification / seal pattern

Parameterize:

- application title
- scenario identity
- status labels
- action labels
- dashboard labels
- runtime identifiers

Replace:

- procurement payload
- purchase_requests table
- procurement-specific API vocabulary
- procurement form fields
- procurement presentation text


## 21. Explicit Non-Reuse

The following Procurement fields MUST NOT appear
in the Medical domain model:

- item_name
- quantity
- unit_price
- total_amount

The Medical scenario is not a renamed Procurement form.


## 22. Scenario Invariants

MED-INV-01

Every case has a stable synthetic case reference.


MED-INV-02

Every new case starts at:

PENDING_REVIEW


MED-INV-03

Only PENDING_REVIEW may transition.


MED-INV-04

Allowed decisions are:

ACCEPTED
RETURNED


MED-INV-05

Decision evidence includes:

- outcome
- actor
- reason
- timestamp


MED-INV-06

Unknown historical metadata remains unknown.


MED-INV-07

No real PHI is permitted.


MED-INV-08

Priority is not clinical triage.


MED-INV-09

Human decision authority is preserved.


MED-INV-10

The Medical scenario must be qualified before receiving a baseline seal.


## 23. Implementation Boundary

P06-M2 defines the scenario contract only.

Current result:

MEDICAL_SCENARIO_CONTRACT=YES
MEDICAL_RUNTIME_IMPLEMENTATION=NO
MEDICAL_DATABASE_IMPLEMENTATION=NO
MEDICAL_UI_IMPLEMENTATION=NO

PROCUREMENT_RUNTIME_UNCHANGED=YES


## 24. Next Milestone

Recommended:

P06-M3 — Medical Scenario Materialization

Purpose:

Create the first Medical runtime implementation
from this scenario contract without mutating
the sealed Procurement baseline.


## 25. M2 Exit Contract

SOURCE_PATTERN=P06-M1

SCENARIO_IDENTITY_DEFINED=YES
DOMAIN_PAYLOAD_DEFINED=YES
WORKFLOW_POLICY_DEFINED=YES
DECISION_EVIDENCE_DEFINED=YES
DASHBOARD_CONTRACT_DEFINED=YES
SEARCH_FILTER_CONTRACT_DEFINED=YES
HISTORY_CONTRACT_DEFINED=YES
EXPORT_CONTRACT_DEFINED=YES
QUALIFICATION_PROFILE_DEFINED=YES

REAL_PATIENT_DATA_ALLOWED=NO
AUTONOMOUS_CLINICAL_DECISION=NO
AUTHENTICATED_REVIEWER_IDENTITY=NO

APPLICATION_CODE_CHANGE=NO
DATABASE_CHANGE=NO
RUNTIME_BEHAVIOR_CHANGE=NO

P06-M2_RESULT=PASS