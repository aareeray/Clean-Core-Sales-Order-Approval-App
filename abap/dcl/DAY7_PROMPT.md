# Day 7 - Authorization (DCL) and ABAP Unit Tests

/build-feature create-authorization-and-tests

## Part 1: CDS DCL Authorization (SAP_SECURITY_ENGINEER using sap-dcl skill)

Create authorization object ZSO_APPROVAL:
  Fields: ACTVT (activity), STATUS (char 10), CUSTOMER_ID (char 10)
  Activities: 01=Create, 02=Change, 03=Display, ZA=Approve, ZR=Reject

Create DCL files:
  ZSO_R_REQ_H.dcl  - instance-based, pfcg_auth on ZSO_APPROVAL
  ZSO_R_REQ_I.dcl  - inherited from header (where _Header.RequestId is not initial)

Create IAM app ZSO_APPROVAL_IAM with business catalogs:
  ZSO_BC_REQUESTER - activities 01,02,03
  ZSO_BC_APPROVER  - activities 03,ZA,ZR
  ZSO_BC_ADMIN     - all activities

Implement get_instance_authorizations in ZSO_BP_REQ_H:
  - submit: allowed only if CreatedBy = sy-uname AND Status = DRAFT
  - approve/reject: allowed only if Approver = sy-uname AND Status = PENDING
  - resubmit: allowed only if CreatedBy = sy-uname AND Status = REJECTED

## Part 2: ABAP Unit Tests (SAP_TEST_ENGINEER)

Write ABAP Unit test class ZSO_TEST_REQ_H for:

Validations:
  test_validateCustomer_valid   - customer ID provided: expect no error
  test_validateCustomer_invalid - empty customer ID: expect error message
  test_validateAmount_positive  - amount > 0: expect no error
  test_validateAmount_zero      - amount = 0: expect error message
  test_validateAmount_negative  - amount < 0: expect error message
  test_validateRejectionReason_present  - reason provided on reject: expect no error
  test_validateRejectionReason_missing  - no reason on reject: expect error message

Actions:
  test_submit_from_draft    - status DRAFT: expect status becomes PENDING
  test_submit_from_pending  - status PENDING: expect error (cannot submit)
  test_approve_pending      - status PENDING + correct approver: expect APPROVED
  test_approve_wrong_user   - wrong approver: expect authorization error
  test_reject_with_reason   - reject with reason: expect REJECTED + reason saved
  test_reject_no_reason     - reject without reason: expect error
  test_resubmit_rejected    - status REJECTED + creator: expect back to DRAFT
  test_resubmit_approved    - status APPROVED: expect error (cannot resubmit)

Use CL_ABAP_UNIT_ASSERT for all assertions.
Use ABAP Test Double Framework to mock entity reads.
Target: minimum 80% coverage on ZSO_BP_REQ_H.

Run all tests via MCP bridge and report results.
