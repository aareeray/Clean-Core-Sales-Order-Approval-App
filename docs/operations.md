# Production Operations, Support Cockpit & Diagnostic Guide

## 1. Overview & Operational Philosophy

In enterprise production environments, operations teams (Tier 2/3 SAP Support) require dedicated visibility to diagnose, triage, and re-process orders experiencing integration disruptions, SLA breaches, or approval lockouts.

This specification documents the **Operational Support Cockpit**, designed to monitor the end-to-end health of the Sales Order Approval system.

---

## 2. Operations Dashboard Layout & Key Metrics

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                           OPERATIONAL SUPPORT COCKPIT                            │
├─────────────────────┬──────────────────────┬─────────────────────────────────────┤
│ 🚨 Active SLA Breaches│ ⚠️ Integration Retries │ 🛑 Unprocessed / Dead-Letter Events │
│         3           │          1           │                  0                  │
└─────────────────────┴──────────────────────┴─────────────────────────────────────┘
```

---

## 3. Incident Triage Matrix

The support cockpit captures actionable diagnostic fields:

| Field | Description | Purpose in Production Support |
|---|---|---|
| `RequestId` | Primary UUID / Identifier | Direct correlation with sales order and business user tickets. |
| `CustomerId` | Customer ID & Name | Identifies high-priority or strategic VIP clients requiring immediate resolution. |
| `Status` | Current transactional status | `PENDING`, `APPROVED`, `REJECTED`, `DRAFT`. |
| `SlaStatus` | Health indicator | `ON_TRACK`, `DUE_SOON`, `BREACHED`, `ESCALATED`. |
| `ErrorCategory` | Classification | `WORKFLOW_UNREACHABLE`, `TIMEOUT`, `AUTH_MISMATCH`, `RULE_GAP`. |
| `ErrorMessage` | Diagnostic message | Raw technical log (e.g. `HTTP 503 Service Unavailable on destination ZSO_ABAP_BACKEND`). |
| `RetryCount` | Execution attempts | Tracks exponential backoff retries (e.g. `Attempt 2 of 5`). |
| `LastAttemptAt` | Timestamp | Indicates when the automated retry pipeline last executed. |
| `SupportAction` | Administrative control | `[Retry Processing]`, `[Manual Re-route]`, `[Escalate to Director]`. |

---

## 4. Standard Operating Procedures (SOPs)

### SOP 1: Triaging an SLA Breached Request
1. **Detection**: Support cockpit flags an order in status `PENDING` with `SlaStatus = BREACHED`.
2. **Investigation**: Inspect `ZSO_APPR_HIST` to determine how long the current approver has held the task.
3. **Action**: 
   - Attempt automated reminder via notification dispatch.
   - If no response within 4 hours, trigger action `escalate` directly from the support cockpit.
   - Order reassigned to `DIR_SCHMIDT`, logging an administrative support comment.

### SOP 2: Recovering from Workflow Timeout (HTTP 504 / 503)
1. **Detection**: Order is in `Status = PENDING`, but external SBPA process instance failed to start (`ErrorCategory = TIMEOUT`).
2. **Root Cause**: BTP destination transient network interruption.
3. **Remediation**:
   - Verify BTP Destination connectivity in SAP BTP Cockpit.
   - Click **[Retry Processing]** in Support Cockpit.
   - The outbox dispatcher re-submits the payload to the workflow API.
   - Error cleared; audit trail records `RETRY_SUCCESSFUL`.

### SOP 3: Resolving "No Matching Approval Rule"
1. **Detection**: User attempts submission of high-value order in an unconfigured currency (e.g. 150,000 USD), producing an error: *"No approval rule found for amount 150000 USD"*.
2. **Remediation**:
   - Administrator opens **Approval Rule Admin** (`ZSO_C_APPR_RULE`).
   - Inserts new rule record for currency `USD` with amount range `50,000 - 0.00` assigned to `DIRECTOR`.
   - Re-runs `validate_rules` to confirm zero overlaps.
   - Informs sales rep to click **Submit**.
