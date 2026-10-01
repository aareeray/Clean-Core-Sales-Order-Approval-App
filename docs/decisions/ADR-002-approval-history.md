# ADR-002: Dedicated Append-Only Approval History Entity

## Status
Accepted

## Context
Enterprise compliance (SOX, ISO 27001, internal financial auditing) requires an immutable, sequential audit trail of all decision points in an order's lifecycle.

## Problem
The initial design stored only the latest `Status`, `Approver`, and `RejectionReason` on the header table `ZSO_REQ_H`. Prior statuses and intermediate approver comments were permanently overwritten, making retrospective forensic audits impossible.

## Decision
We introduced an append-only persistence table `ZSO_APPR_HIST`, modeled as a child composition entity `ZSO_R_REQ_HIST` under `ZSO_R_REQ_H` and projected as `ZSO_C_REQ_HIST` on the Fiori Object Page.
Every lifecycle transition (`SUBMITTED`, `ASSIGNED`, `APPROVED`, `REJECTED`, `RESUBMITTED`, `ESCALATED`) records a new step with actor, role, timestamp, previous status, new status, and comment.

## Alternatives Considered
1. **SAP Change Documents (CDHDR / CDPOS)**: Legacy DDIC change documents are generic, do not capture structured business commentary cleanly, and require non-standard CDS exposure in ABAP Cloud.
2. **Generic Audit Log Service**: Introduces external dependencies for core transactional logging.
3. **Dedicated RAP Composition Child Table**: Chosen approach. Provides native OData V4 navigation, direct Fiori Object Page lineitem rendering, and strict transactional consistency within the RAP LUW.

## Consequences
- **Positive**: Complete audit compliance with immutable timestamping and user attribution.
- **Positive**: Direct visibility of approval journey directly on the Fiori Object Page.
- **Negative / Trade-off**: Incremental storage consumption across high-volume transaction lifecycles.
