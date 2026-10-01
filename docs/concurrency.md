# Concurrency, Locking & Optimistic Isolation Analysis

## 1. Concurrency Architecture in ABAP Cloud RAP

In high-volume enterprise sales approval workflows, multiple users, asynchronous workflow callbacks, and automated timer daemons frequently access the same business order simultaneously.

The Clean-Core Sales Order Approval application utilizes **RAP Optimistic Locking with ETag** backed by timestamps (`utclong`) to guarantee transactional isolation without long-lived, blocking database locks.

```
       User A (Director)                            User B (Delegate)
              │                                             │
      Reads Request 1001                            Reads Request 1001
      [ETag: 10:00:00.000]                          [ETag: 10:00:00.000]
              │                                             │
       Clicks 'Approve'                              Clicks 'Approve'
              │                                             │
     Compares ETag: Matches!                                │
     Status = APPROVED                                      │
     New ETag: 10:00:05.123                                 │
     Committed ✅                                           │
              │                                             │
              │                                      Compares ETag:
              │                                      Client: 10:00:00.000
              │                                      Server: 10:00:05.123
              │                                             │
              │                                      ETAG MISMATCH ❌
              │                                      HTTP 412 PRECONDITION FAILED
```

---

## 2. Real-World Concurrency Test Scenarios

### Test Scenario 1: Double Approval Conflict (Two Users Approving Simultaneously)
- **Preconditions**: Request `SO-2026-0001` is `PENDING`. User A (Director) and User B (Authorized Delegate) have the same order open in their browser tabs.
- **Execution**: Both users click **Approve** within milliseconds of each other.
- **Observed Behavior**:
  - **User A's transaction**: Arrives first, acquires the short-lived RAP transactional lock, verifies `Status = 'PENDING'`, updates `Status = 'APPROVED'`, stamps `ChangedAt = NOW()`, and commits.
  - **User B's transaction**: Arrives second. ETag check on `ChangedAt` fails because User A modified the record. The framework returns HTTP 412 (Precondition Failed).
  - Even if User B refreshes before clicking, User B's action hits the backend status guard (`IF ls_req-Status = 'APPROVED'`), which returns: `"Order is already approved. Duplicate approval ignored"`.
- **Outcome**: **PASSED ✅** (Single valid approval transition; exactly one audit history record).

---

### Test Scenario 2: Concurrent Requester Edit vs. Approver Action
- **Preconditions**: Request `SO-2026-0004` is in `DRAFT`.
- **Execution**: Requester edits line items while another user attempts a state transition.
- **Observed Behavior**:
  - The requester's draft changes are isolated in draft table `ZSO_DREQ_H` and `ZSO_DREQ_I`.
  - The active persistence table `ZSO_REQ_H` remains unlocked until the requester executes `draft action Activate`.
  - Upon activation, the ETag master validates that no external actor changed the active entity.
- **Outcome**: **PASSED ✅** (Zero database lock contention; draft state cleanly separated).

---

### Test Scenario 3: Asynchronous Workflow Engine Network Retry Callback
- **Preconditions**: SAP Build Process Automation executes an automated task completion call: `POST /SalesOrderRequest(<id>)/approve`. Due to an intermediate corporate proxy timeout, SBPA does not receive the HTTP 200 response and triggers an automated retry after 10 seconds.
- **Execution**: The second identical `POST /approve` arrives at the ABAP backend.
- **Observed Behavior**:
  - The backend reads `Status = 'APPROVED'`.
  - Instead of throwing a technical runtime exception or adding a duplicate `APPROVED` entry into `ZSO_APPR_HIST`, the idempotent status guard gracefully recognizes the target state has already been achieved.
  - Returns a controlled response; no duplicate history step, no duplicate outbound events.
- **Outcome**: **PASSED ✅** (100% Idempotent; zero duplicate business effects).
