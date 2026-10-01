  "==========================================================================
  " ADDITIONAL SAVE — SBPA Workflow Trigger
  "
  " This method replaces the placeholder save_modified from Day 3.
  " It is called AFTER the RAP save sequence completes, meaning the
  " Status = 'PENDING' record is already persisted in ZSO_REQ_H.
  "
  " Pattern:
  "   1. Find requests whose status just changed to PENDING
  "   2. Get OAuth2 token from SBPA UAA (via Communication Arrangement)
  "   3. POST workflow trigger to SBPA REST API
  "   4. Log the workflow instance ID for traceability
  "
  " IMPORTANT:
  "   - NEVER COMMIT WORK here — RAP owns the commit
  "   - Use cl_web_http_client_manager (released for ABAP Cloud)
  "   - Error handling: log and continue — don't fail the save for workflow errors
  "==========================================================================
  METHOD save_modified.

    " -----------------------------------------------------------------------
    " Step 1: Find requests that are now PENDING (just submitted)
    " We check against the create/update operations that triggered this save.
    " -----------------------------------------------------------------------
    DATA lt_pending_requests TYPE TABLE OF zso_req_h.

    " Read from DB — the save has committed Status = PENDING at this point
    IF update IS NOT INITIAL.
      SELECT * FROM zso_req_h
        FOR ALL ENTRIES IN @update-SalesOrderRequest
        WHERE request_id = @update-SalesOrderRequest-RequestId
          AND status     = 'PENDING'
        INTO TABLE @lt_pending_requests.                       "#EC CI_NOWHERE
    ENDIF.

    CHECK lt_pending_requests IS NOT INITIAL.

    " -----------------------------------------------------------------------
    " Step 2: Get OAuth2 Bearer token from SBPA UAA
    " Uses Communication Arrangement (no hardcoded credentials)
    " -----------------------------------------------------------------------
    DATA(lo_http_factory) = cl_web_http_client_manager=>create_by_http_destination(
      i_destination = cl_http_destination_provider=>create_by_comm_arrangement(
        comm_scenario  = 'ZSO_SBPA_OUTBOUND'    " Communication Scenario ID
        service_id     = 'ZSO_SBPA_TRIGGER'     " Communication Service ID
      )
    ).

    " -----------------------------------------------------------------------
    " Step 3: Trigger SBPA workflow instance for each PENDING request
    " -----------------------------------------------------------------------
    LOOP AT lt_pending_requests INTO DATA(ls_req).

      " Resolve UUID to string format for JSON
      DATA(lv_uuid_str) = |{ ls_req-request_id STYLE = GUID_WITH_DASHES }|.

      " Convert DATS to ISO date string
      DATA(lv_date_iso) = |{ ls_req-request_date DATE = ISO }|.

      " Build JSON payload
      DATA(lv_payload) = |\{"definitionId":"com.company.zso.approvalprocess","context":\{| &
                         |"requestId":"{ lv_uuid_str }",|                                 &
                         |"customerId":"{ ls_req-customer_id }",|                         &
                         |"requestDate":"{ lv_date_iso }",|                               &
                         |"totalAmount":{ ls_req-total_amount },|                         &
                         |"currency":"{ ls_req-currency }",|                              &
                         |"requesterEmail":"{ zso_get_user_email( ls_req-created_by ) }",| &
                         |"requesterName":"{ zso_get_user_name( ls_req-created_by ) }",|  &
                         |"serviceUrl":"{ zso_get_service_url( ) }"|                      &
                         |\}\}|.

      " POST to SBPA trigger endpoint
      TRY.
          DATA(lo_request)  = lo_http_factory->get_http_request( ).
          lo_request->set_method( if_web_http_client=>post ).
          lo_request->set_uri_path(
            '/workflow/rest/v1/workflow-instances' ).
          lo_request->set_header_field(
            i_name  = 'Content-Type'
            i_value = 'application/json' ).
          lo_request->set_text( lv_payload ).

          DATA(lo_response) = lo_http_factory->execute( if_web_http_client=>post ).
          DATA(lv_status)   = lo_response->get_status( )-code.

          IF lv_status = 201.
            " Success: log workflow instance ID for traceability
            " In production: write to a custom log table ZSO_WORKFLOW_LOG
            DATA(lv_response_body) = lo_response->get_text( ).
            " Parse instance ID from JSON response if needed
          ELSE.
            " Non-fatal: log warning, don't abort save
            " TODO: write to application log using cl_bali_log (released)
          ENDIF.

        CATCH cx_web_http_client_error INTO DATA(lx_http).
          " Non-fatal: log the error and continue
          " The request status is already PENDING in the DB.
          " An admin can manually trigger workflow from the monitoring app.
      ENDTRY.

    ENDLOOP.

    " Clean up HTTP client
    lo_http_factory->close( ).

  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Helper: Get user email from username via released API
  " -------------------------------------------------------------------------
  METHOD zso_get_user_email.
    TRY.
        DATA(lo_user) = cl_abap_user_attributes=>get_instance( iv_username ).
        rv_email = lo_user->get_email( ).
      CATCH cx_abap_user_not_found.
        rv_email = ''.
    ENDTRY.
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Helper: Get user display name via released API
  " -------------------------------------------------------------------------
  METHOD zso_get_user_name.
    TRY.
        DATA(lo_user) = cl_abap_user_attributes=>get_instance( iv_username ).
        rv_name = lo_user->get_display_name( ).
      CATCH cx_abap_user_not_found.
        rv_name = iv_username.
    ENDTRY.
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Helper: Get base OData service URL from constants / config
  " -------------------------------------------------------------------------
  METHOD zso_get_service_url.
    " In production: read from a custom config table or use Communication Arrangement URL
    rv_url = '/sap/opu/odata4/sap/zso_sb_req_h/srvd/sap/zso_sd_req_h/0001/'.
  ENDMETHOD.
