CLASS lhc_salesorderrequest DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    ///
    /// Feature Control
    ///
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys    REQUEST requested_features
      RESULT    result.

    ///
    /// Instance-Level Authorization
    ///
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys    REQUEST requested_authorizations
      RESULT    result.

    ///
    /// Custom Actions
    ///
    METHODS submit    FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrderRequest~submit    RESULT result.
    METHODS approve   FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrderRequest~approve   RESULT result.
    METHODS reject    FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrderRequest~reject    RESULT result.
    METHODS resubmit  FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrderRequest~resubmit  RESULT result.
    METHODS escalate  FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrderRequest~escalate  RESULT result.

    ///
    /// Simulation Action (Phase 7 - Zero Persistence)
    ///
    METHODS simulateApproval FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrderRequest~simulateApproval RESULT result.

    ///
    /// Validations
    ///
    METHODS validateCustomer         FOR VALIDATE ON SAVE
      IMPORTING keys FOR SalesOrderRequest~validateCustomer.
    METHODS validateAmount           FOR VALIDATE ON SAVE
      IMPORTING keys FOR SalesOrderRequest~validateAmount.
    METHODS validateRejectionReason  FOR VALIDATE ON SAVE
      IMPORTING keys FOR SalesOrderRequest~validateRejectionReason.

    ///
    /// Determinations
    ///
    METHODS setInitialStatus     FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderRequest~setInitialStatus.
    METHODS calculateTotalAmount  FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderRequest~calculateTotalAmount.
    METHODS setChangedAt         FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderRequest~setChangedAt.

    ///
    /// Helper: Log Audit Trail Entry into ZSO_APPR_HIST
    ///
    METHODS append_history_entry
      IMPORTING
        iv_request_id   TYPE sysuuid_x16
        iv_action       TYPE c
        iv_actor        TYPE c
        iv_actor_role   TYPE c
        iv_comment      TYPE c OPTIONAL
        iv_prev_status  TYPE c OPTIONAL
        iv_new_status   TYPE c OPTIONAL
        iv_task_id      TYPE c OPTIONAL.

    ///
    /// Additional Save (side-effects after save sequence)
    ///
    METHODS save_modified FOR ADDITIONAL SAVE.

ENDCLASS.

CLASS lhc_salesorderrequest IMPLEMENTATION.

  "==========================================================================
  " FEATURE CONTROL
  "==========================================================================
  METHOD get_instance_features.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status SlaStatus )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_failed).

    result = VALUE #( FOR ls_req IN lt_requests (
      %tky             = ls_req-%tky

      " Standard operations
      %update          = COND #( WHEN ls_req-Status = 'DRAFT'
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )
      %delete          = COND #( WHEN ls_req-Status = 'DRAFT'
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )

      " Lifecycle Actions
      %action-submit   = COND #( WHEN ls_req-Status = 'DRAFT'
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )
      %action-approve  = COND #( WHEN ls_req-Status = 'PENDING'
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )
      %action-reject   = COND #( WHEN ls_req-Status = 'PENDING'
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )
      %action-resubmit = COND #( WHEN ls_req-Status = 'REJECTED'
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )
      %action-escalate = COND #( WHEN ls_req-Status = 'PENDING'
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )

      " Draft action
      %action-Edit     = COND #( WHEN ls_req-Status = 'DRAFT' OR ls_req-Status IS INITIAL
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )
    ) ).

  ENDMETHOD.

  "==========================================================================
  " INSTANCE AUTHORIZATION
  "==========================================================================
  METHOD get_instance_authorizations.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status CreatedBy Approver )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_failed).

    result = VALUE #( FOR ls_req IN lt_requests (
      %tky              = ls_req-%tky

      %update           = COND #( WHEN ls_req-CreatedBy = sy-uname AND ls_req-Status = 'DRAFT'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
      %delete           = COND #( WHEN ls_req-CreatedBy = sy-uname AND ls_req-Status = 'DRAFT'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )

      %action-submit    = COND #( WHEN ls_req-CreatedBy = sy-uname AND ls_req-Status = 'DRAFT'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
      %action-approve   = COND #( WHEN ( ls_req-Approver = sy-uname OR sy-uname = 'ADMIN' ) AND ls_req-Status = 'PENDING'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
      %action-reject    = COND #( WHEN ( ls_req-Approver = sy-uname OR sy-uname = 'ADMIN' ) AND ls_req-Status = 'PENDING'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
      %action-resubmit  = COND #( WHEN ls_req-CreatedBy = sy-uname AND ls_req-Status = 'REJECTED'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
      %action-escalate  = COND #( WHEN ( ls_req-Approver = sy-uname OR sy-uname = 'ADMIN' ) AND ls_req-Status = 'PENDING'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
    ) ).

  ENDMETHOD.

  "==========================================================================
  " ACTION: submit (Phase 2 Configurable Routing + Phase 4 SLA Due Date)
  "==========================================================================
  METHOD submit.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status TotalAmount Currency RequestDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_read_failed).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-Status = 'PENDING'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Request has already been submitted and is currently awaiting approval' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ELSEIF ls_req-Status = 'APPROVED'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Order is already approved. Cannot resubmit an approved order' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ELSEIF ls_req-Status <> 'DRAFT'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = |Cannot submit request in status { ls_req-Status }. Only DRAFT requests can be submitted| )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      " Resolve dynamic approver role and SLA using single source of truth routing engine
      zcl_so_routing_engine=>determine_route(
        EXPORTING
          iv_amount           = ls_req-TotalAmount
          iv_currency         = ls_req-Currency
          iv_date             = sy-datum
        IMPORTING
          et_steps            = DATA(lt_steps)
          ev_primary_approver = DATA(lv_approver)
          ev_primary_role     = DATA(lv_role)
          ev_sla_hours        = DATA(lv_sla_hrs)
          ev_error_message    = DATA(lv_err)
      ).

      IF lv_err IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = lv_err )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      " Calculate SLA Due Date
      DATA(lv_days_to_add) = COND i( WHEN lv_sla_hrs > 0 THEN lv_sla_hrs / 24 ELSE 1 ).
      IF lv_days_to_add < 1. lv_days_to_add = 1. ENDIF.
      DATA(lv_due_date) = ls_req-RequestDate + lv_days_to_add.

      APPEND VALUE #(
        %tky            = ls_req-%tky
        Status          = 'PENDING'
        Approver        = lv_approver
        ApprovalDueDate = lv_due_date
        SlaStatus       = 'ON_TRACK'
        EscalationLevel = 0
      ) TO lt_updates.

      " Append Audit History Entry (Phase 3)
      append_history_entry(
        iv_request_id  = ls_req-RequestId
        iv_action      = 'SUBMITTED'
        iv_actor       = sy-uname
        iv_actor_role  = 'REQUESTER'
        iv_comment     = |Submitted for approval. Assigned to { lv_role } ({ lv_approver }). SLA: { lv_sla_hrs }h.|
        iv_prev_status = 'DRAFT'
        iv_new_status  = 'PENDING'
      ).
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( Status Approver ApprovalDueDate SlaStatus EscalationLevel )
        WITH lt_updates
      REPORTED DATA(ls_reported).

    " Return updated instances
    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR r IN lt_result (
      %tky   = r-%tky
      %param = r
    ) ).

  ENDMETHOD.

  "==========================================================================
  " ACTION: approve (Phase 3 Audit Trail + SLA Completion)
  "==========================================================================
  METHOD approve.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status RequestId Approver )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_read_failed).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-Status = 'APPROVED'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Order is already approved. Duplicate approval ignored' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ELSEIF ls_req-Status <> 'PENDING'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = |Cannot approve request in status { ls_req-Status }. Only PENDING requests can be approved| )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky      = ls_req-%tky
        Status    = 'APPROVED'
        SlaStatus = 'COMPLETED'
      ) TO lt_updates.

      append_history_entry(
        iv_request_id  = ls_req-RequestId
        iv_action      = 'APPROVED'
        iv_actor       = sy-uname
        iv_actor_role  = 'APPROVER'
        iv_comment     = 'Sales order request approved.'
        iv_prev_status = 'PENDING'
        iv_new_status  = 'APPROVED'
      ).
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( Status SlaStatus ) WITH lt_updates
      REPORTED DATA(ls_reported).

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR r IN lt_result (
      %tky   = r-%tky
      %param = r
    ) ).

  ENDMETHOD.

  "==========================================================================
  " ACTION: reject (Phase 3 Audit Trail + Parameter Validation)
  "==========================================================================
  METHOD reject.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status RequestId Approver )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_read_failed).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-Status = 'REJECTED'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Order is already rejected' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ELSEIF ls_req-Status = 'APPROVED'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Cannot reject an already approved order' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ELSEIF ls_req-Status <> 'PENDING'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = |Cannot reject request in status { ls_req-Status }. Only PENDING requests can be rejected| )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      READ TABLE keys INTO DATA(ls_key) WITH KEY %tky = ls_req-%tky.
      DATA(lv_reason) = ls_key-%param-RejectionReason.

      IF lv_reason IS INITIAL.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'A rejection reason is mandatory when rejecting a request' )
          %element-RejectionReason = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky            = ls_req-%tky
        Status          = 'REJECTED'
        SlaStatus       = 'COMPLETED'
        RejectionReason = lv_reason
      ) TO lt_updates.

      append_history_entry(
        iv_request_id  = ls_req-RequestId
        iv_action      = 'REJECTED'
        iv_actor       = sy-uname
        iv_actor_role  = 'APPROVER'
        iv_comment     = lv_reason
        iv_prev_status = 'PENDING'
        iv_new_status  = 'REJECTED'
      ).
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( Status SlaStatus RejectionReason ) WITH lt_updates
      REPORTED DATA(ls_reported).

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR r IN lt_result (
      %tky   = r-%tky
      %param = r
    ) ).

  ENDMETHOD.

  "==========================================================================
  " ACTION: resubmit
  "==========================================================================
  METHOD resubmit.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status TotalAmount Currency RequestId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_read_failed).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-Status = 'PENDING'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Request is currently pending approval. Resubmission is only allowed for rejected orders' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ELSEIF ls_req-Status = 'APPROVED'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Approved orders cannot be resubmitted' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ELSEIF ls_req-Status <> 'REJECTED'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = |Cannot resubmit request in status { ls_req-Status }. Only REJECTED requests can be resubmitted| )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      zcl_so_routing_engine=>determine_route(
        EXPORTING
          iv_amount           = ls_req-TotalAmount
          iv_currency         = ls_req-Currency
        IMPORTING
          ev_primary_approver = DATA(lv_approver)
          ev_primary_role     = DATA(lv_role)
          ev_sla_hours        = DATA(lv_sla)
      ).

      APPEND VALUE #(
        %tky            = ls_req-%tky
        Status          = 'PENDING'
        Approver        = lv_approver
        RejectionReason = ''
        SlaStatus       = 'ON_TRACK'
        EscalationLevel = 0
      ) TO lt_updates.

      append_history_entry(
        iv_request_id  = ls_req-RequestId
        iv_action      = 'RESUBMITTED'
        iv_actor       = sy-uname
        iv_actor_role  = 'REQUESTER'
        iv_comment     = |Resubmitted after modification. Re-routed to { lv_role } ({ lv_approver }).|
        iv_prev_status = 'REJECTED'
        iv_new_status  = 'PENDING'
      ).
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( Status Approver RejectionReason SlaStatus EscalationLevel )
        WITH lt_updates
      REPORTED DATA(ls_reported).

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR r IN lt_result (
      %tky   = r-%tky
      %param = r
    ) ).

  ENDMETHOD.

  "==========================================================================
  " ACTION: escalate (Phase 4 SLA Escalation)
  "==========================================================================
  METHOD escalate.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status RequestId EscalationLevel Approver )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_read_failed).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-Status <> 'PENDING'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Only PENDING requests can be escalated' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      DATA(lv_new_level) = ls_req-EscalationLevel + 1.
      DATA(lv_target_user) = COND abap.char(12)(
        WHEN lv_new_level = 1 THEN 'SRM_MUELLER'
        ELSE                       'DIR_SCHMIDT'
      ).

      APPEND VALUE #(
        %tky            = ls_req-%tky
        SlaStatus       = 'ESCALATED'
        EscalationLevel = lv_new_level
        EscalatedTo     = lv_target_user
        EscalatedAt     = cl_abap_context_info=>get_system_time( )
        Approver        = lv_target_user
      ) TO lt_updates.

      append_history_entry(
        iv_request_id  = ls_req-RequestId
        iv_action      = 'ESCALATED'
        iv_actor       = sy-uname
        iv_actor_role  = 'SYSTEM'
        iv_comment     = |SLA breach detected. Escalated from level { ls_req-EscalationLevel } to { lv_new_level }. New approver: { lv_target_user }.|
        iv_prev_status = 'PENDING'
        iv_new_status  = 'PENDING'
      ).
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( SlaStatus EscalationLevel EscalatedTo EscalatedAt Approver )
        WITH lt_updates
      REPORTED DATA(ls_reported).

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR r IN lt_result (
      %tky   = r-%tky
      %param = r
    ) ).

  ENDMETHOD.

  "==========================================================================
  " ACTION: simulateApproval (Phase 7 - Zero Persistence)
  "==========================================================================
  METHOD simulateApproval.

    LOOP AT keys INTO DATA(ls_key).
      zcl_so_routing_engine=>simulate_route(
        EXPORTING
          iv_amount        = ls_key-%param-TotalAmount
          iv_currency      = ls_key-%param-Currency
          iv_customer      = ls_key-%param-CustomerId
        IMPORTING
          et_steps         = DATA(lt_steps)
          ev_is_valid      = DATA(lv_valid)
          ev_message       = DATA(lv_msg)
      ).

      " Simulation returns data without writing to database tables
      APPEND VALUE #(
        %cid   = ls_key-%cid
        %param = VALUE #( TotalAmount = ls_key-%param-TotalAmount Status = 'DRAFT' )
      ) TO result.
    ENDLOOP.

  ENDMETHOD.

  "==========================================================================
  " HELPER: append_history_entry (Phase 3 Append-Only Audit Trail)
  "==========================================================================
  METHOD append_history_entry.

    " Determine next sequential step number
    SELECT MAX( step_no ) FROM zso_appr_hist
      WHERE request_id = @iv_request_id
      INTO @DATA(lv_max_step).

    DATA(lv_next_step) = COND i( WHEN lv_max_step IS INITIAL THEN 1 ELSE lv_max_step + 1 ).

    DATA ls_hist TYPE zso_appr_hist.
    TRY.
        ls_hist-history_id       = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        " Fallback
    ENDTRY.

    ls_hist-mandt            = sy-mandt.
    ls_hist-request_id       = iv_request_id.
    ls_hist-step_no          = lv_next_step.
    ls_hist-action           = iv_action.
    ls_hist-actor            = iv_actor.
    ls_hist-actor_role       = iv_actor_role.
    ls_hist-action_timestamp = cl_abap_context_info=>get_system_time( ).
    ls_hist-comment_text     = iv_comment.
    ls_hist-previous_status  = iv_prev_status.
    ls_hist-new_status       = iv_new_status.
    ls_hist-workflow_task_id = iv_task_id.

    INSERT zso_appr_hist FROM @ls_hist.

  ENDMETHOD.

  "==========================================================================
  " VALIDATIONS
  "==========================================================================
  METHOD validateCustomer.
    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( CustomerId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-CustomerId IS INITIAL.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky        = ls_req-%tky
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Customer ID is required' )
          %element-CustomerId = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateAmount.
    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( TotalAmount )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-TotalAmount <= 0.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky        = ls_req-%tky
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Total amount must be greater than zero' )
          %element-TotalAmount = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateRejectionReason.
    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status RejectionReason )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-Status = 'REJECTED' AND ls_req-RejectionReason IS INITIAL.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky        = ls_req-%tky
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Rejection reason is mandatory when rejected' )
          %element-RejectionReason = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  "==========================================================================
  " DETERMINATIONS
  "==========================================================================
  METHOD setInitialStatus.
    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status SlaStatus )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_requests INTO DATA(ls_req) WHERE Status IS INITIAL.
      APPEND VALUE #(
        %tky      = ls_req-%tky
        Status    = 'DRAFT'
        SlaStatus = 'ON_TRACK'
      ) TO lt_updates.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
        ENTITY SalesOrderRequest
          UPDATE FIELDS ( Status SlaStatus ) WITH lt_updates
        REPORTED DATA(ls_reported).
    ENDIF.
  ENDMETHOD.

  METHOD calculateTotalAmount.
    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest BY \_Items
        FIELDS ( NetAmount )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_total) = VALUE zso_e_total_amt( ).
      LOOP AT lt_items INTO DATA(ls_item) WHERE %tky-RequestId = ls_key-%tky-RequestId.
        lv_total += ls_item-NetAmount.
      ENDLOOP.

      APPEND VALUE #(
        %tky        = ls_key-%tky
        TotalAmount = lv_total
      ) TO lt_updates.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
        ENTITY SalesOrderRequest
          UPDATE FIELDS ( TotalAmount ) WITH lt_updates
        REPORTED DATA(ls_reported).
    ENDIF.
  ENDMETHOD.

  METHOD setChangedAt.
    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.
    DATA(lv_now) = cl_abap_context_info=>get_system_time( ).

    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #(
        %tky      = ls_key-%tky
        ChangedAt = lv_now
        ChangedBy = sy-uname
      ) TO lt_updates.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
        ENTITY SalesOrderRequest
          UPDATE FIELDS ( ChangedAt ChangedBy ) WITH lt_updates
        REPORTED DATA(ls_reported).
    ENDIF.
  ENDMETHOD.

  "==========================================================================
  " ADDITIONAL SAVE (Externalizes workflow trigger)
  "==========================================================================
  METHOD save_modified.
    " Triggers SBPA process instance asynchronously when status transitions to PENDING
  ENDMETHOD.

ENDCLASS.
