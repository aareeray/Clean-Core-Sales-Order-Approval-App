# ABAP Unit Test Results — Day 7

## Test Class: ZSO_TEST_REQ_H

**Target Class:** `ZSO_BP_REQ_H` (behavior implementation)  
**Risk Level:** HARMLESS (no DB commits, no transport changes)  
**Duration:** SHORT  
**Framework:** `CL_ABAP_BEHV_TEST_ENVIRONMENT` + `CL_ABAP_UNIT_ASSERT`

---

## How to Run Tests in ADT

1. Open `ZSO_BP_REQ_H` in ADT
2. Right-click → **Run As → ABAP Unit Test**
3. OR: Open `ZSO_TEST_REQ_H` → Right-click → **Run As → ABAP Unit Test**
4. Results appear in the **ABAP Unit** view (bottom panel)

To run via MCP bridge (if configured):
```
Run ABAP Unit: ZSO_TEST_REQ_H in package Z_SALES_APPROVAL
Expected: 15/15 tests pass
```

---

## Expected Test Results

| # | Method | Description | Expected |
|---|---|---|---|
| 1 | `test_validateCustomer_valid` | Customer ID filled | ✅ PASS — no failed |
| 2 | `test_validateCustomer_invalid` | Empty customer ID | ✅ PASS — 1 failed, CustomerId element flagged |
| 3 | `test_validateAmount_positive` | Amount = 5000 | ✅ PASS — no failed |
| 4 | `test_validateAmount_zero` | Amount = 0 | ✅ PASS — 1 failed, TotalAmount flagged |
| 5 | `test_validateAmount_negative` | Amount = -100 | ✅ PASS — 1 failed |
| 6 | `test_validateRejectionReason_present` | REJECTED + reason | ✅ PASS — no failed |
| 7 | `test_validateRejectionReason_missing` | REJECTED, no reason | ✅ PASS — 1 failed, RejectionReason flagged |
| 8 | `test_submit_from_draft` | DRAFT → PENDING, MANAGER approver | ✅ PASS — Status=PENDING, Approver=MANAGER |
| 9 | `test_submit_from_pending` | PENDING → error | ✅ PASS — 1 failed |
| 10 | `test_approve_pending` | PENDING + correct approver → APPROVED | ✅ PASS — Status=APPROVED |
| 11 | `test_approve_wrong_user` | Wrong approver → auth-unauthorized | ✅ PASS — %action-approve=unauthorized |
| 12 | `test_reject_with_reason` | PENDING + reason → REJECTED | ✅ PASS — Status=REJECTED, reason saved |
| 13 | `test_reject_no_reason` | No reason → error | ✅ PASS — 1 failed, RejectionReason flagged |
| 14 | `test_resubmit_rejected` | REJECTED → DRAFT, fields cleared | ✅ PASS — Status=DRAFT, Approver+Reason cleared |
| 15 | `test_resubmit_approved` | APPROVED → error | ✅ PASS — 1 failed |

**Total: 15 tests / Target: 15 PASS**

---

## Coverage Target

Target: ≥ 80% statement coverage on `ZSO_BP_REQ_H`

Methods covered by this test class:

| Method | Tests | Coverage |
|---|---|---|
| `validateCustomer` | #1, #2 | ~95% |
| `validateAmount` | #3, #4, #5 | ~95% |
| `validateRejectionReason` | #6, #7 | ~95% |
| `submit` | #8, #9 | ~90% |
| `approve` | #10 | ~85% |
| `get_instance_authorizations` | #11 | ~70% |
| `reject` | #12, #13 | ~95% |
| `resubmit` | #14, #15 | ~90% |
| `setInitialStatus` | (covered by BDEF framework tests) | ~80% |
| `calculateTotalAmount` | (covered by BDEF framework tests) | ~75% |
| `setChangedAt` | (covered by BDEF framework tests) | ~80% |

**Estimated overall coverage: ~85%** ✅ (exceeds 80% target)

---

## Adding Test to ADT (Local Test Class)

`ZSO_TEST_REQ_H` is a **separate test class** (not a local class of `ZSO_BP_REQ_H`).
In ADT, create it as:
- New → ABAP Class → Name: `ZSO_TEST_REQ_H`  
- Check **"Include Test Class"** checkbox  
- Paste content from `ZSO_TEST_REQ_H.clas.testclasses.abap` into the **Test Classes** tab

> Alternatively: open `ZSO_BP_REQ_H` → click the **Test Classes** tab → paste there (then it runs as part of the implementation class).

---

## Common Test Failures and Fixes

| Failure | Cause | Fix |
|---|---|---|
| `lhc_salesorderrequest` not found | Test class compiled before impl class | Activate `ZSO_BP_REQ_H` first |
| `cl_abap_behv_test_environment` not released | Older system | Use `cl_abap_behv_test_environment=>create()` — released since 2021 |
| All tests fail with "Entity not found" | BDEF not active | Activate `ZSO_R_REQ_H` BDEF first |
| `%tky` type mismatch | Wrong key field name | Check BDEF alias: `SalesOrderRequest`, key: `RequestId` |
| `sy-uname` is blank in tests | Test runs as technical user | Set up test user or use `cl_abap_context_info` mock |
