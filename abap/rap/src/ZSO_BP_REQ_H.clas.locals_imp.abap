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
    METHODS setInitialStatus    FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderRequest~setInitialStatus.
    METHODS calculateTotalAmount FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderRequest~calculateTotalAmount.
    METHODS setChangedAt        FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderRequest~setChangedAt.

    ///
    /// Additional Save (side-effects after save sequence)
    ///
    METHODS save_modified FOR ADDITIONAL SAVE.

ENDCLASS.

CLASS lhc_salesorderrequest IMPLEMENTATION.

  "==========================================================================
  " FEATURE CONTROL
  " Controls which actions/operations are enabled for each instance
  " based on current Status value.
  "==========================================================================
  METHOD get_instance_features.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_failed).

    result = VALUE #( FOR ls_req IN lt_requests (
      %tky             = ls_req-%tky

      "--- Standard operations ---
      %update          = COND #( WHEN ls_req-Status = 'DRAFT'
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )
      %delete          = COND #( WHEN ls_req-Status = 'DRAFT'
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )

      "--- Actions ---
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

      "--- Draft actions ---
      %action-Edit     = COND #( WHEN ls_req-Status = 'DRAFT' OR ls_req-Status IS INITIAL
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )
    ) ).

  ENDMETHOD.

  "==========================================================================
  " INSTANCE AUTHORIZATION
  " Controls who can perform which actions based on Status + user identity.
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
      %action-approve   = COND #( WHEN ls_req-Approver  = sy-uname AND ls_req-Status = 'PENDING'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
      %action-reject    = COND #( WHEN ls_req-Approver  = sy-uname AND ls_req-Status = 'PENDING'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
      %action-resubmit  = COND #( WHEN ls_req-CreatedBy = sy-uname AND ls_req-Status = 'REJECTED'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
    ) ).

  ENDMETHOD.

  "==========================================================================
  " ACTION: submit
  " DRAFT → PENDING. Sets Approver based on TotalAmount threshold.
  "==========================================================================
  METHOD submit.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status TotalAmount )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_read_failed).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-Status <> 'DRAFT'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Only DRAFT requests can be submitted' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      DATA(lv_approver) = COND abap.char(12)(
        WHEN ls_req-TotalAmount >= 10000 THEN 'DIRECTOR'
        ELSE                                  'MANAGER'
      ).

      APPEND VALUE #(
        %tky     = ls_req-%tky
        Status   = 'PENDING'
        Approver = lv_approver
      ) TO lt_updates.
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( Status Approver ) WITH lt_updates
      REPORTED DATA(ls_reported).

    " Re-read and return updated instances
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
  " ACTION: approve
  " PENDING → APPROVED.
  "==========================================================================
  METHOD approve.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status )
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
                    text     = 'Only PENDING requests can be approved' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky   = ls_req-%tky
        Status = 'APPROVED'
      ) TO lt_updates.
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( Status ) WITH lt_updates
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
  " ACTION: reject
  " PENDING → REJECTED. RejectionReason from action parameter is mandatory.
  "==========================================================================
  METHOD reject.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_read_failed).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_requests INTO DATA(ls_req).
      " Retrieve the action parameter for this instance
      DATA(ls_key) = keys[ KEY draft %tky = ls_req-%tky ].

      IF ls_req-Status <> 'PENDING'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Only PENDING requests can be rejected' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      IF ls_key-%param-RejectionReason IS INITIAL.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Rejection reason is mandatory' )
          %element-RejectionReason = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky            = ls_req-%tky
        Status          = 'REJECTED'
        RejectionReason = ls_key-%param-RejectionReason
      ) TO lt_updates.
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( Status RejectionReason ) WITH lt_updates
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
  " REJECTED → DRAFT. Clears rejection reason and approver.
  "==========================================================================
  METHOD resubmit.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_read_failed).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-Status <> 'REJECTED'.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky  = ls_req-%tky
          %msg  = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                    text     = 'Only REJECTED requests can be resubmitted' )
          %element-Status = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky            = ls_req-%tky
        Status          = 'DRAFT'
        Approver        = ''
        RejectionReason = ''
      ) TO lt_updates.
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( Status Approver RejectionReason ) WITH lt_updates
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
  " VALIDATION: validateCustomer
  " Customer ID must not be empty.
  "==========================================================================
  METHOD validateCustomer.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( CustomerId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_failed).

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-CustomerId IS INITIAL.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky                  = ls_req-%tky
          %state_area           = 'VALIDATE_CUSTOMER'
          %msg                  = new_message_with_text(
                                    severity = if_abap_behv_message=>severity-error
                                    text     = 'Customer ID is required' )
          %element-CustomerId   = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  "==========================================================================
  " VALIDATION: validateAmount
  " Total amount must be greater than zero.
  "==========================================================================
  METHOD validateAmount.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( TotalAmount Currency )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_failed).

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-TotalAmount <= 0.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky                  = ls_req-%tky
          %state_area           = 'VALIDATE_AMOUNT'
          %msg                  = new_message_with_text(
                                    severity = if_abap_behv_message=>severity-error
                                    text     = 'Total amount must be greater than zero' )
          %element-TotalAmount  = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
      ENDIF.

      IF ls_req-Currency IS INITIAL.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky               = ls_req-%tky
          %state_area        = 'VALIDATE_CURRENCY'
          %msg               = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Currency is required' )
          %element-Currency  = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  "==========================================================================
  " VALIDATION: validateRejectionReason
  " RejectionReason must be filled when status is REJECTED.
  " (Secondary check — primary check is in the reject action itself)
  "==========================================================================
  METHOD validateRejectionReason.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status RejectionReason )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(lt_failed).

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-Status = 'REJECTED' AND ls_req-RejectionReason IS INITIAL.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-SalesOrderRequest.
        APPEND VALUE #(
          %tky                      = ls_req-%tky
          %state_area               = 'VALIDATE_REJECTION_REASON'
          %msg                      = new_message_with_text(
                                        severity = if_abap_behv_message=>severity-error
                                        text     = 'Rejection reason is required when status is REJECTED' )
          %element-RejectionReason  = if_abap_behv=>mk-on
          %element-Status           = if_abap_behv=>mk-on
        ) TO reported-SalesOrderRequest.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  "==========================================================================
  " DETERMINATION: setInitialStatus
  " Sets Status = 'DRAFT' on newly created requests.
  "==========================================================================
  METHOD setInitialStatus.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_requests INTO DATA(ls_req).
      IF ls_req-Status IS INITIAL.
        APPEND VALUE #(
          %tky   = ls_req-%tky
          Status = 'DRAFT'
        ) TO lt_updates.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( Status ) WITH lt_updates
      REPORTED DATA(ls_reported).

  ENDMETHOD.

  "==========================================================================
  " DETERMINATION: calculateTotalAmount
  " Sums NetAmount of all child items and updates TotalAmount on the header.
  "==========================================================================
  METHOD calculateTotalAmount.

    " Read header keys
    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( TotalAmount Currency )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_headers).

    " Read all child items for these header keys
    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest BY \_Items
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_headers INTO DATA(ls_header).
      " Sum all item net amounts for this header
      DATA(lv_total) = REDUCE abap.curr(15,2)(
        INIT total = CONV abap.curr(15,2)( 0 )
        FOR  item  IN lt_items
        WHERE ( RequestId = ls_header-RequestId )
        NEXT  total = total + item-NetAmount
      ).

      " Get currency from first item (all items share same currency)
      DATA(lv_currency) = VALUE abap.cuky(
        ( lt_items[ RequestId = ls_header-RequestId ]-Currency ) OPTIONAL
      ).

      APPEND VALUE #(
        %tky        = ls_header-%tky
        TotalAmount = lv_total
        Currency    = COND #( WHEN lv_currency IS NOT INITIAL
                              THEN lv_currency
                              ELSE ls_header-Currency )
      ) TO lt_updates.
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( TotalAmount Currency ) WITH lt_updates
      REPORTED DATA(ls_reported).

  ENDMETHOD.

  "==========================================================================
  " DETERMINATION: setChangedAt
  " Sets ChangedBy and ChangedAt on every create/update.
  " Note: For managed RAP with @Semantics.systemDateTime.lastChangedAt,
  " the framework auto-populates ChangedAt. This determination is a
  " safety net and for explicit control.
  "==========================================================================
  METHOD setChangedAt.

    READ ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        FIELDS ( ChangedBy ChangedAt )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    DATA lt_updates TYPE TABLE FOR UPDATE zso_r_req_h\\SalesOrderRequest.

    LOOP AT lt_requests INTO DATA(ls_req).
      APPEND VALUE #(
        %tky      = ls_req-%tky
        ChangedBy = sy-uname
        ChangedAt = cl_abap_context_info=>get_system_date( ) && cl_abap_context_info=>get_system_time( )
      ) TO lt_updates.
    ENDLOOP.

    MODIFY ENTITIES OF zso_r_req_h IN LOCAL MODE
      ENTITY SalesOrderRequest
        UPDATE FIELDS ( ChangedBy ChangedAt ) WITH lt_updates
      REPORTED DATA(ls_reported).

  ENDMETHOD.

  "==========================================================================
  " ADDITIONAL SAVE
  " Called after the save sequence completes. Use for side-effects that must
  " happen after the main entity is persisted (e.g., triggering workflow).
  " NEVER commit here — RAP handles the commit.
  "==========================================================================
  METHOD save_modified.

    " Read newly submitted requests (Status changed to PENDING)
    " to trigger the SAP Build Process Automation workflow
    " Implementation note: use cl_bpa_* released APIs or HTTP client
    " to POST to the SBPA trigger endpoint. Keep this method lightweight.

    " Placeholder: log the save for traceability
    " In production: add SBPA API call here for workflow trigger on submit

  ENDMETHOD.

ENDCLASS.
