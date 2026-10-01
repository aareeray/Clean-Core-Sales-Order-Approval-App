# Resilience, Fault Tolerance & Error Handling Strategy

## 1. Overview & Classification of Failures

In enterprise mission-critical systems, system integration failures are inevitable. A robust Clean Core application must cleanly separate **Business Logic Errors** from **Technical Infrastructure Failures**, applying targeted recovery strategies to each.

```
                     ┌───────────────────────────────┐
                     │       Incoming Operation      │
                     └───────────────┬───────────────┘
                                     │
                    Is it a business rule violation?
                                     │
                   ┌─────────────────┴─────────────────┐
                   ▼                                   ▼
          [ BUSINESS ERROR ]                  [ TECHNICAL ERROR ]
          - Invalid Status                    - Network Timeout / 503
          - Unauthorized Action               - External Workflow Unreachable
          - Rule Matrix Gap                   - Event Broker Outage
          - Missing Rejection Reason          - Database Contention / Lock Wait
                   │                                   │
                   ▼                                   ▼
         IMMEDIATE ABORT (FAIL)               RESILIENT RECOVERY PIPELINE
         - Abort LUW transaction             - Non-blocking Outbox Staging
         - Return localized %msg             - Exponential Backoff Retries
         - Highlight field on UI             - Circuit Breaker Tripping
         - Zero state corruption             - Administrative Dead-Letter Queue
```

---

## 2. Business Errors vs. Technical Errors Matrix

| Category | Specific Scenario | Detection Point | Handling & Recovery Strategy |
|---|---|---|---|
| **Business** | User attempts to approve an already approved order (`approve` on `APPROVED`) | `lhc_salesorderrequest~approve` status guard | Idempotent rejection: return `%msg` warning `"Order is already approved. Duplicate approval ignored"`. Transaction halted safely. |
| **Business** | Requester submits order with amount <= 0 or missing customer | `validateAmount` / `validateCustomer` on save | Validation fails; sets `%element-TotalAmount = if_abap_behv=>mk-on`; highlights invalid field on Fiori Object Page with user-friendly message. |
| **Business** | Approver attempts to reject without providing mandatory reason | `lhc_salesorderrequest~reject` parameter check | Action aborted; returns error message; prompts user to fill text area in `ZSO_P_REJECT` parameter modal. |
| **Business** | Approval matrix contains no active rule for currency/amount | `zcl_so_routing_engine=>determine_route` | Returns structured error code; halts submission; alerts administrative support team to configure missing tier. |
| **Technical** | SAP Build Process Automation API unreachable (HTTP 502/503/Timeout) | `save_modified` HTTP Client call | **Non-Fatal Integration Pattern**: The core RAP database update is committed; the integration failure is recorded in the operational queue with state `RETRY_PENDING`. |
| **Technical** | SAP Event Mesh connection drop during message dispatch | Outbox Event Dispatcher | Events remain persisted in transactional outbox; background dispatcher retries with exponential backoff up to 5 attempts before marking as `DEAD_LETTER`. |
| **Technical** | Optimistic Locking collision (stale ETag upon concurrent edits) | RAP runtime ETag check on `ChangedAt` | HTTP 412 (Precondition Failed) returned to client; Fiori Elements prompts user: *"The record was updated by another user. Please refresh."* |

---

## 3. Asynchronous Resilience: The Retry & Dead-Letter Pipeline

```mermaid
graph TD
    TX["Business Action Committed<br/>(Status = PENDING)"]
    --> CALL["External Integration Call<br/>(SBPA / Event Mesh / Email)"]

    CALL -->|Success (200/201)| DONE["Operation Complete ✅"]

    CALL -->|Temporary Failure (Timeout / 503)| RETRY1["Attempt 1: Immediate Retry (1s)"]
    RETRY1 -->|Fail| RETRY2["Attempt 2: Exponential Backoff (5s)"]
    RETRY2 -->|Fail| RETRY3["Attempt 3: Delayed Retry (30s)"]

    RETRY3 -->|Success| DONE
    RETRY3 -->|Exhausted| DLQ["Dead-Letter & Operational Queue<br/>- Recorded in Support Cockpit<br/>- Error text & payload preserved<br/>- Flag: REQUIRES_INTERVENTION"]

    DLQ --> ADMIN["Administrative Support Cockpit<br/>- Review Error Message<br/>- Click 'Re-process' / 'Retry'"]
    ADMIN -->|Manual Trigger| CALL
```

---

## 4. Key Rules for Enterprise Defensibility

1. **Never Hide Technical Failures**: An application must never silently swallow an exception or mark an external integration as successful when an external delivery failed.
2. **Never Roll Back Core Business Transactions Due to Secondary Failures**: If an order approval is legally and financially committed in the database, a temporary email server timeout must **not** roll back the financial approval. The email dispatch is decoupled and queued for retry.
3. **Audit Immutability**: Every integration failure and manual recovery trigger is stamped with timestamps, error codes, and user IDs.
