# Security Attack Surface & Penetration Test Audit

## 1. Executive Summary

This security review documents the technical defense measures implemented against common enterprise application vulnerability vectors, specifically addressing direct service invocation, authorization bypass attempts, payload tampering, and information leakage.

---

## 2. Attack Surface Assessment

```
                      ┌─────────────────────────────────┐
                      │    Hostile External Requester   │
                      │    (Using Postman / cURL)       │
                      └────────────────┬────────────────┘
                                       │
            Attempts Direct OData V4 Call to /approve or /reject
                                       │
                  ┌────────────────────┴────────────────────┐
                  ▼                                         ▼
         [ CDS DCL KERNEL GATE ]                   [ RAP RUNTIME GATE ]
         Does row pass instance                    Does sy-uname match
         CreatedBy / Approver filter?              instance Approver attribute?
                  │                                         │
                  ▼                                         ▼
            SQL ZERO ROWS                             HTTP 403 FORBIDDEN
            (Instance invisible)                      (Operation blocked)
```

---

## 3. Vulnerability Testing Scenarios & Results

### Vector 1: Direct OData Action Invocation Bypass
- **Attack Scenario**: An authenticated requester discovers the OData V4 action URL `/SalesOrderRequest(<uuid>)/approve` and submits an HTTP `POST` directly to approve their own sales order without manager consent.
- **Defense Mechanism**:
  1. At database level, CDS DCL `ZSO_R_REQ_H.dcl` restricts read/write to `CreatedBy = $user` with activity `02/03`, denying access to `approve` activity `ZA`.
  2. At RAP runtime, `get_instance_authorizations` checks `ls_req-Approver = sy-uname`. If `sy-uname` does not match, `%action-approve = if_abap_behv=>auth-unauthorized` is returned.
- **Audit Outcome**: **BLOCKED ✅** (HTTP 403 Forbidden).

---

### Vector 2: Parameter Tampering & Financial Total Overwrite
- **Attack Scenario**: A user submits a draft modification payload attempting to overwrite `TotalAmount` directly via HTTP `PATCH` without adding line items.
- **Defense Mechanism**:
  1. `TotalAmount` is explicitly declared as `field ( readonly ) TotalAmount;` in BDEF `ZSO_R_REQ_H.bdef.asbdef`.
  2. The RAP determination `calculateTotalAmount` recalculates the total strictly from the persisted child items table (`ZSO_REQ_I`). Direct client updates to `TotalAmount` are silently discarded by the framework.
- **Audit Outcome**: **BLOCKED ✅** (Calculated server-side only).

---

### Vector 3: Horizontal Privilege Escalation via UUID Guessing
- **Attack Scenario**: An attacker scripts random UUID lookups against `/SalesOrderRequest(sysuuid)` to inspect orders placed by competing sales representatives or other corporate divisions.
- **Defense Mechanism**:
  - CDS DCL injects `WHERE CreatedBy = $user` directly into the generated SQL statement at the HANA engine level.
  - If the requested UUID belongs to another user, HANA returns empty results (`HTTP 404 Not Found`).
- **Audit Outcome**: **BLOCKED ✅** (Row-level tenant isolation).

---

### Vector 4: Information Leakage in Error Responses
- **Attack Scenario**: Provoking system dump or technical stack traces by injecting malformed characters or SQL syntax into inputs.
- **Defense Mechanism**:
  - All validations report controlled business errors via `%msg = new_message_with_text(...)`.
  - Database table names, internal table definitions, and ABAP kernel callstacks are completely shielded from OData response payloads.
- **Audit Outcome**: **BLOCKED ✅** (Zero internal technical disclosures).

---

### Vector 5: Replay Attacks & Concurrent Double Approval
- **Attack Scenario**: An automated script fires simultaneous parallel approval requests to duplicate fulfillment.
- **Defense Mechanism**:
  - The first transaction acquires an exclusive lock on `ZSO_REQ_H` and updates `Status = 'APPROVED'` and system timestamp `ChangedAt`.
  - The second transaction detects `ls_req-Status = 'APPROVED'` and is rejected by the idempotent status guard without modifying state or logging duplicate history.
- **Audit Outcome**: **BLOCKED ✅** (Strict state consistency).
