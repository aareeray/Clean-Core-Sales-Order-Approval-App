"! @testing ZSO_BP_REQ_H
CLASS zso_test_req_h DEFINITION
  PUBLIC
  FINAL
  FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.

    "=======================================================================
    " Test infrastructure
    "=======================================================================
    TYPES:
      tt_keys    TYPE TABLE FOR ACTION IMPORT zso_r_req_h\\SalesOrderRequest~submit,
      tt_keys_rj TYPE TABLE FOR ACTION IMPORT zso_r_req_h\\SalesOrderRequest~reject.

    DATA:
      mo_cut        TYPE REF TO lhc_salesorderrequest,  " Class Under Test
      mo_env        TYPE REF TO if_abap_behv_test_environment,
      ms_header_key TYPE zso_req_h,
      mv_test_uuid  TYPE sysuuid_x16.

    METHODS:
      "--- Lifecycle ---
      setup          FOR TESTING,
      teardown       FOR TESTING,

      "--- Helpers ---
      create_test_header
        IMPORTING
          iv_status          TYPE zso_e_status DEFAULT 'DRAFT'
          iv_customer        TYPE abap.char(10) DEFAULT 'CUST001'
          iv_amount          TYPE abap.curr(15,2) DEFAULT 1000
          iv_rejection       TYPE abap.char(255) DEFAULT ''
          iv_created_by      TYPE syuname DEFAULT 'TESTUSER'
          iv_approver        TYPE abap.char(12) DEFAULT '',

      assert_no_failed
        IMPORTING
          it_failed  TYPE STANDARD TABLE
          iv_context TYPE string,

      assert_has_failed
        IMPORTING
          it_failed  TYPE STANDARD TABLE
          iv_context TYPE string,

      assert_status_equals
        IMPORTING
          iv_expected TYPE zso_e_status
          iv_context  TYPE string,

      "--- Validation Tests ---
      test_validateCustomer_valid         FOR TESTING,
      test_validateCustomer_invalid       FOR TESTING,
      test_validateAmount_positive        FOR TESTING,
      test_validateAmount_zero            FOR TESTING,
      test_validateAmount_negative        FOR TESTING,
      test_validateRejectionReason_present FOR TESTING,
      test_validateRejectionReason_missing FOR TESTING,

      "--- Action Tests ---
      test_submit_from_draft              FOR TESTING,
      test_submit_from_pending            FOR TESTING,
      test_approve_pending                FOR TESTING,
      test_approve_wrong_user             FOR TESTING,
      test_reject_with_reason             FOR TESTING,
      test_reject_no_reason               FOR TESTING,
      test_resubmit_rejected              FOR TESTING,
      test_resubmit_approved              FOR TESTING.

ENDCLASS.


CLASS zso_test_req_h IMPLEMENTATION.

  "=========================================================================
  " SETUP — runs before each test method
  "=========================================================================
  METHOD setup.
    " Create test double environment for ZSO_R_REQ_H
    mo_env = cl_abap_behv_test_environment=>create(
      entity_name = 'ZSO_R_REQ_H'
    ).

    " Generate a stable UUID for all tests in this run
    TRY.
        mv_test_uuid = cl_system_uuid=>if_system_uuid_static~create_uuid_x16( ).
      CATCH cx_uuid_error.
        mv_test_uuid = '00010203040506070809101112131415'.
    ENDTRY.

    " Instantiate class under test via reflection (local class of ZSO_BP_REQ_H)
    CREATE OBJECT mo_cut TYPE lhc_salesorderrequest.
  ENDMETHOD.

  "=========================================================================
  " TEARDOWN — runs after each test method
  "=========================================================================
  METHOD teardown.
    mo_env->destroy( ).
    CLEAR: mo_cut, ms_header_key, mv_test_uuid.
  ENDMETHOD.

  "=========================================================================
  " HELPER: Inject a fake header entity into the test environment
  "=========================================================================
  METHOD create_test_header.
    ms_header_key = VALUE #(
      mandt         = sy-mandt
      request_id    = mv_test_uuid
      customer_id   = iv_customer
      request_date  = sy-datum
      total_amount  = iv_amount
      currency      = 'EUR'
      status        = iv_status
      rejection_reason = iv_rejection
      created_by    = iv_created_by
      approver      = iv_approver
      created_at    = utclong_current( )
      changed_at    = utclong_current( )
    ).

    mo_env->insert(
      entity_name = 'ZSO_R_REQ_H'
      rows        = VALUE #( ( ms_header_key ) )
    ).
  ENDMETHOD.

  "=========================================================================
  " HELPER: Assert no entries in failed table
  "=========================================================================
  METHOD assert_no_failed.
    cl_abap_unit_assert=>assert_initial(
      act     = it_failed
      msg     = |{ iv_context }: Expected no failures but got { lines( it_failed ) }|
    ).
  ENDMETHOD.

  "=========================================================================
  " HELPER: Assert at least one entry in failed table
  "=========================================================================
  METHOD assert_has_failed.
    cl_abap_unit_assert=>assert_not_initial(
      act     = it_failed
      msg     = |{ iv_context }: Expected at least one failure but got none|
    ).
  ENDMETHOD.

  "=========================================================================
  " HELPER: Assert current status of test entity
  "=========================================================================
  METHOD assert_status_equals.
    SELECT SINGLE status
      FROM zso_req_h
      WHERE request_id = @mv_test_uuid
      INTO @DATA(lv_status).

    cl_abap_unit_assert=>assert_equals(
      exp = iv_expected
      act = lv_status
      msg = |{ iv_context }: Expected Status={ iv_expected }, got={ lv_status }|
    ).
  ENDMETHOD.

  "===========================================================================
  "  V A L I D A T I O N   T E S T S
  "===========================================================================

  "-------------------------------------------------------------------------
  " test_validateCustomer_valid — CustomerId provided → no error
  "-------------------------------------------------------------------------
  METHOD test_validateCustomer_valid.
    create_test_header( iv_customer = 'CUST001' ).

    DATA lt_keys TYPE TABLE FOR VALIDATE
                    zso_r_req_h\\SalesOrderRequest~validateCustomer.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED LATE zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED LATE zso_r_req_h\\SalesOrderRequest.

    mo_cut->validateCustomer(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
    ).

    assert_no_failed(
      it_failed  = lt_failed
      iv_context = 'validateCustomer_valid'
    ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_validateCustomer_invalid — empty CustomerId → error
  "-------------------------------------------------------------------------
  METHOD test_validateCustomer_invalid.
    create_test_header( iv_customer = '' ).

    DATA lt_keys TYPE TABLE FOR VALIDATE
                    zso_r_req_h\\SalesOrderRequest~validateCustomer.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED LATE zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED LATE zso_r_req_h\\SalesOrderRequest.

    mo_cut->validateCustomer(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
    ).

    assert_has_failed(
      it_failed  = lt_failed
      iv_context = 'validateCustomer_invalid'
    ).

    " Verify that CustomerId element is flagged
    cl_abap_unit_assert=>assert_equals(
      exp = if_abap_behv=>mk-on
      act = lt_reported[ 1 ]-%element-CustomerId
      msg = 'Expected CustomerId element to be flagged'
    ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_validateAmount_positive — amount > 0 → no error
  "-------------------------------------------------------------------------
  METHOD test_validateAmount_positive.
    create_test_header( iv_amount = 5000 ).

    DATA lt_keys TYPE TABLE FOR VALIDATE
                    zso_r_req_h\\SalesOrderRequest~validateAmount.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED LATE zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED LATE zso_r_req_h\\SalesOrderRequest.

    mo_cut->validateAmount(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
    ).

    assert_no_failed( it_failed = lt_failed iv_context = 'validateAmount_positive' ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_validateAmount_zero — amount = 0 → error
  "-------------------------------------------------------------------------
  METHOD test_validateAmount_zero.
    create_test_header( iv_amount = 0 ).

    DATA lt_keys TYPE TABLE FOR VALIDATE
                    zso_r_req_h\\SalesOrderRequest~validateAmount.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED LATE zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED LATE zso_r_req_h\\SalesOrderRequest.

    mo_cut->validateAmount(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
    ).

    assert_has_failed( it_failed = lt_failed iv_context = 'validateAmount_zero' ).
    cl_abap_unit_assert=>assert_equals(
      exp = if_abap_behv=>mk-on
      act = lt_reported[ 1 ]-%element-TotalAmount
      msg = 'Expected TotalAmount element to be flagged for zero amount'
    ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_validateAmount_negative — amount < 0 → error
  "-------------------------------------------------------------------------
  METHOD test_validateAmount_negative.
    create_test_header( iv_amount = -100 ).

    DATA lt_keys TYPE TABLE FOR VALIDATE
                    zso_r_req_h\\SalesOrderRequest~validateAmount.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED LATE zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED LATE zso_r_req_h\\SalesOrderRequest.

    mo_cut->validateAmount(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
    ).

    assert_has_failed( it_failed = lt_failed iv_context = 'validateAmount_negative' ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_validateRejectionReason_present — REJECTED + reason filled → no error
  "-------------------------------------------------------------------------
  METHOD test_validateRejectionReason_present.
    create_test_header(
      iv_status    = 'REJECTED'
      iv_rejection = 'Budget exceeded'
    ).

    DATA lt_keys TYPE TABLE FOR VALIDATE
                    zso_r_req_h\\SalesOrderRequest~validateRejectionReason.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED LATE zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED LATE zso_r_req_h\\SalesOrderRequest.

    mo_cut->validateRejectionReason(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
    ).

    assert_no_failed( it_failed = lt_failed iv_context = 'validateRejectionReason_present' ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_validateRejectionReason_missing — REJECTED + no reason → error
  "-------------------------------------------------------------------------
  METHOD test_validateRejectionReason_missing.
    create_test_header(
      iv_status    = 'REJECTED'
      iv_rejection = ''
    ).

    DATA lt_keys TYPE TABLE FOR VALIDATE
                    zso_r_req_h\\SalesOrderRequest~validateRejectionReason.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED LATE zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED LATE zso_r_req_h\\SalesOrderRequest.

    mo_cut->validateRejectionReason(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
    ).

    assert_has_failed( it_failed = lt_failed iv_context = 'validateRejectionReason_missing' ).
    cl_abap_unit_assert=>assert_equals(
      exp = if_abap_behv=>mk-on
      act = lt_reported[ 1 ]-%element-RejectionReason
      msg = 'Expected RejectionReason element to be flagged'
    ).
  ENDMETHOD.

  "===========================================================================
  "  A C T I O N   T E S T S
  "===========================================================================

  "-------------------------------------------------------------------------
  " test_submit_from_draft — DRAFT → PENDING + Approver set
  "-------------------------------------------------------------------------
  METHOD test_submit_from_draft.
    create_test_header( iv_status = 'DRAFT' iv_amount = 5000 ).

    DATA lt_keys TYPE TABLE FOR ACTION IMPORT
                    zso_r_req_h\\SalesOrderRequest~submit.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_result   TYPE TABLE FOR ACTION RESULT zso_r_req_h\\SalesOrderRequest~submit.

    mo_cut->submit(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
                result   = lt_result
    ).

    assert_no_failed( it_failed = lt_failed iv_context = 'submit_from_draft' ).

    " Verify status was updated to PENDING
    cl_abap_unit_assert=>assert_equals(
      exp = 'PENDING'
      act = lt_result[ 1 ]-%param-Status
      msg = 'Expected Status = PENDING after submit'
    ).

    " Amount < 10000 → MANAGER approver
    cl_abap_unit_assert=>assert_equals(
      exp = 'MANAGER'
      act = lt_result[ 1 ]-%param-Approver
      msg = 'Expected Approver = MANAGER for amount 5000'
    ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_submit_from_pending — PENDING → error (cannot resubmit)
  "-------------------------------------------------------------------------
  METHOD test_submit_from_pending.
    create_test_header( iv_status = 'PENDING' ).

    DATA lt_keys TYPE TABLE FOR ACTION IMPORT
                    zso_r_req_h\\SalesOrderRequest~submit.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_result   TYPE TABLE FOR ACTION RESULT zso_r_req_h\\SalesOrderRequest~submit.

    mo_cut->submit(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
                result   = lt_result
    ).

    assert_has_failed( it_failed = lt_failed iv_context = 'submit_from_pending' ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_approve_pending — PENDING + correct approver → APPROVED
  "-------------------------------------------------------------------------
  METHOD test_approve_pending.
    " Set sy-uname as the approver (inject via test setup)
    create_test_header(
      iv_status   = 'PENDING'
      iv_approver = sy-uname   " current test user IS the approver
    ).

    DATA lt_keys TYPE TABLE FOR ACTION IMPORT
                    zso_r_req_h\\SalesOrderRequest~approve.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_result   TYPE TABLE FOR ACTION RESULT zso_r_req_h\\SalesOrderRequest~approve.

    mo_cut->approve(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
                result   = lt_result
    ).

    assert_no_failed( it_failed = lt_failed iv_context = 'approve_pending' ).
    cl_abap_unit_assert=>assert_equals(
      exp = 'APPROVED'
      act = lt_result[ 1 ]-%param-Status
      msg = 'Expected Status = APPROVED after approve action'
    ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_approve_wrong_user — PENDING + wrong approver → authorization error
  "-------------------------------------------------------------------------
  METHOD test_approve_wrong_user.
    " Set DIFFERENT user as the approver
    create_test_header(
      iv_status   = 'PENDING'
      iv_approver = 'OTHERAPPROVER'   " NOT sy-uname
    ).

    " The get_instance_authorizations check will deny this.
    " Since we're testing the action directly, we simulate by checking
    " that the approve action fails when Approver <> sy-uname.
    DATA lt_keys TYPE TABLE FOR ACTION IMPORT
                    zso_r_req_h\\SalesOrderRequest~approve.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_result   TYPE TABLE FOR ACTION RESULT zso_r_req_h\\SalesOrderRequest~approve.

    " Note: the BDEF framework calls get_instance_authorizations BEFORE the action.
    " In unit test, we test the authorization method directly:
    DATA lt_auth_keys TYPE TABLE FOR INSTANCE AUTHORIZATION
                        zso_r_req_h\\SalesOrderRequest.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_auth_keys.

    DATA lt_auth_result TYPE TABLE FOR INSTANCE AUTHORIZATION RESULT
                           zso_r_req_h\\SalesOrderRequest.

    mo_cut->get_instance_authorizations(
      EXPORTING keys   = lt_auth_keys
                requested_authorizations = VALUE #( %action-approve = if_abap_behv=>mk-on )
      CHANGING  result = lt_auth_result
                failed = lt_failed
                reported = lt_reported
    ).

    cl_abap_unit_assert=>assert_equals(
      exp = if_abap_behv=>auth-unauthorized
      act = lt_auth_result[ 1 ]-%action-approve
      msg = 'Expected approve to be unauthorized for wrong user'
    ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_reject_with_reason — PENDING + reason → REJECTED, reason saved
  "-------------------------------------------------------------------------
  METHOD test_reject_with_reason.
    create_test_header(
      iv_status   = 'PENDING'
      iv_approver = sy-uname
    ).

    DATA lt_keys TYPE TABLE FOR ACTION IMPORT
                    zso_r_req_h\\SalesOrderRequest~reject.
    APPEND VALUE #(
      %tky-%key-RequestId = mv_test_uuid
      %param-RejectionReason = 'Budget exceeded for current quarter'
    ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_result   TYPE TABLE FOR ACTION RESULT zso_r_req_h\\SalesOrderRequest~reject.

    mo_cut->reject(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
                result   = lt_result
    ).

    assert_no_failed( it_failed = lt_failed iv_context = 'reject_with_reason' ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'REJECTED'
      act = lt_result[ 1 ]-%param-Status
      msg = 'Expected Status = REJECTED'
    ).
    cl_abap_unit_assert=>assert_equals(
      exp = 'Budget exceeded for current quarter'
      act = lt_result[ 1 ]-%param-RejectionReason
      msg = 'Expected RejectionReason to be saved'
    ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_reject_no_reason — PENDING + empty reason → error
  "-------------------------------------------------------------------------
  METHOD test_reject_no_reason.
    create_test_header(
      iv_status   = 'PENDING'
      iv_approver = sy-uname
    ).

    DATA lt_keys TYPE TABLE FOR ACTION IMPORT
                    zso_r_req_h\\SalesOrderRequest~reject.
    APPEND VALUE #(
      %tky-%key-RequestId    = mv_test_uuid
      %param-RejectionReason = ''           " ← empty reason
    ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_result   TYPE TABLE FOR ACTION RESULT zso_r_req_h\\SalesOrderRequest~reject.

    mo_cut->reject(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
                result   = lt_result
    ).

    assert_has_failed( it_failed = lt_failed iv_context = 'reject_no_reason' ).
    cl_abap_unit_assert=>assert_equals(
      exp = if_abap_behv=>mk-on
      act = lt_reported[ 1 ]-%element-RejectionReason
      msg = 'Expected RejectionReason element to be flagged'
    ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_resubmit_rejected — REJECTED + creator → back to DRAFT
  "-------------------------------------------------------------------------
  METHOD test_resubmit_rejected.
    create_test_header(
      iv_status      = 'REJECTED'
      iv_created_by  = sy-uname      " current user IS the creator
      iv_rejection   = 'Old reason'
      iv_approver    = 'MANAGER'
    ).

    DATA lt_keys TYPE TABLE FOR ACTION IMPORT
                    zso_r_req_h\\SalesOrderRequest~resubmit.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_result   TYPE TABLE FOR ACTION RESULT zso_r_req_h\\SalesOrderRequest~resubmit.

    mo_cut->resubmit(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
                result   = lt_result
    ).

    assert_no_failed( it_failed = lt_failed iv_context = 'resubmit_rejected' ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'DRAFT'
      act = lt_result[ 1 ]-%param-Status
      msg = 'Expected Status = DRAFT after resubmit'
    ).
    " Verify rejection reason and approver are cleared
    cl_abap_unit_assert=>assert_initial(
      act = lt_result[ 1 ]-%param-Approver
      msg = 'Expected Approver to be cleared after resubmit'
    ).
    cl_abap_unit_assert=>assert_initial(
      act = lt_result[ 1 ]-%param-RejectionReason
      msg = 'Expected RejectionReason to be cleared after resubmit'
    ).
  ENDMETHOD.

  "-------------------------------------------------------------------------
  " test_resubmit_approved — APPROVED → error (cannot resubmit approved)
  "-------------------------------------------------------------------------
  METHOD test_resubmit_approved.
    create_test_header(
      iv_status     = 'APPROVED'
      iv_created_by = sy-uname
    ).

    DATA lt_keys TYPE TABLE FOR ACTION IMPORT
                    zso_r_req_h\\SalesOrderRequest~resubmit.
    APPEND VALUE #( %tky-%key-RequestId = mv_test_uuid ) TO lt_keys.

    DATA lt_failed   TYPE TABLE FOR FAILED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_reported TYPE TABLE FOR REPORTED EARLY zso_r_req_h\\SalesOrderRequest.
    DATA lt_result   TYPE TABLE FOR ACTION RESULT zso_r_req_h\\SalesOrderRequest~resubmit.

    mo_cut->resubmit(
      EXPORTING keys     = lt_keys
      CHANGING  failed   = lt_failed
                reported = lt_reported
                result   = lt_result
    ).

    assert_has_failed( it_failed = lt_failed iv_context = 'resubmit_approved' ).
  ENDMETHOD.

ENDCLASS.
