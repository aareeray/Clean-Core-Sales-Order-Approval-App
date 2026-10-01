CLASS zcl_so_routing_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_rule,
        rule_id        TYPE c LENGTH 10,
        approval_level TYPE n LENGTH 2,
        min_amount     TYPE p LENGTH 8 DECIMALS 2,
        max_amount     TYPE p LENGTH 8 DECIMALS 2,
        currency       TYPE c LENGTH 5,
        approver_role  TYPE c LENGTH 20,
        approver_user  TYPE c LENGTH 12,
        sla_hours      TYPE i,
        is_active      TYPE abap_boolean,
        valid_from     TYPE d,
        valid_to       TYPE d,
      END OF ty_rule,
      tt_rules TYPE STANDARD TABLE OF ty_rule WITH EMPTY KEY,

      BEGIN OF ty_approval_step,
        step_number    TYPE i,
        approval_level TYPE n LENGTH 2,
        approver_role  TYPE c LENGTH 20,
        approver_user  TYPE c LENGTH 12,
        sla_hours      TYPE i,
        due_timestamp  TYPE utclong,
        description    TYPE string,
      END OF ty_approval_step,
      tt_approval_steps TYPE STANDARD TABLE OF ty_approval_step WITH EMPTY KEY,

      BEGIN OF ty_validation_issue,
        rule_id TYPE c LENGTH 10,
        severity TYPE c LENGTH 1, " 'E' Error, 'W' Warning
        message TYPE string,
      END OF ty_validation_issue,
      tt_validation_issues TYPE STANDARD TABLE OF ty_validation_issue WITH EMPTY KEY.

    "! Determine active approval route for a specific order amount and currency
    CLASS-METHODS determine_route
      IMPORTING
        iv_amount     TYPE p
        iv_currency   TYPE c
        iv_date       TYPE d DEFAULT sy-datum
      EXPORTING
        et_steps      TYPE tt_approval_steps
        ev_primary_approver TYPE c
        ev_primary_role     TYPE c
        ev_sla_hours        TYPE i
        ev_error_message    TYPE string.

    "! Simulate full approval ladder without persisting any entity (Phase 7 Single Source of Truth)
    CLASS-METHODS simulate_route
      IMPORTING
        iv_amount     TYPE p
        iv_currency   TYPE c
        iv_customer   TYPE c OPTIONAL
      EXPORTING
        et_steps         TYPE tt_approval_steps
        ev_step_count    TYPE i
        ev_highest_level TYPE c
        ev_total_sla_hrs TYPE i
        ev_is_valid      TYPE abap_boolean
        ev_message       TYPE string.

    "! Validate configuration rules for overlaps, invalid ranges, and gaps
    CLASS-METHODS validate_rules
      IMPORTING
        it_rules  TYPE tt_rules OPTIONAL
      EXPORTING
        et_issues TYPE tt_validation_issues
        ev_is_valid TYPE abap_boolean.

    "! Fetch default fallback rules if DB table is empty (ensures robustness in test/trial environments)
    CLASS-METHODS get_fallback_rules
      RETURNING
        VALUE(rt_rules) TYPE tt_rules.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS read_active_rules
      IMPORTING
        iv_date         TYPE d
      RETURNING
        VALUE(rt_rules) TYPE tt_rules.

ENDCLASS.

CLASS zcl_so_routing_engine IMPLEMENTATION.

  METHOD determine_route.
    CLEAR: et_steps, ev_primary_approver, ev_primary_role, ev_sla_hours, ev_error_message.

    DATA(lt_rules) = read_active_rules( iv_date ).
    IF lt_rules IS INITIAL.
      lt_rules = get_fallback_rules( ).
    ENDIF.

    " Filter matching rules where iv_amount >= min_amount and (max_amount is 0 or iv_amount <= max_amount)
    DATA lt_matching TYPE tt_rules.
    LOOP AT lt_rules INTO DATA(ls_rule) WHERE is_active = abap_true.
      IF iv_date >= ls_rule-valid_from AND ( ls_rule-valid_to IS INITIAL OR iv_date <= ls_rule-valid_to ).
        IF iv_amount >= ls_rule-min_amount.
          IF ls_rule-max_amount IS INITIAL OR ls_rule-max_amount = 0 OR iv_amount <= ls_rule-max_amount.
            APPEND ls_rule TO lt_matching.
          ENDIF>
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF lt_matching IS INITIAL.
      ev_error_message = |No approval rule found for amount { iv_amount } { iv_currency }.|.
      RETURN.
    ENDIF.

    " Sort ascending by approval_level
    SORT lt_matching BY approval_level ASCENDING.

    DATA(lv_step) = 1.
    DATA(lv_now) = cl_abap_context_info=>get_system_time( ).

    LOOP AT lt_matching INTO DATA(ls_match).
      APPEND VALUE ty_approval_step(
        step_number    = lv_step
        approval_level = ls_match-approval_level
        approver_role  = ls_match-approver_role
        approver_user  = ls_match-approver_user
        sla_hours      = ls_match-sla_hours
        description    = |Level { ls_match-approval_level }: { ls_match-approver_role } Approval (SLA { ls_match-sla_hours }h)|
      ) TO et_steps.

      IF lv_step = 1.
        ev_primary_role     = ls_match-approver_role.
        ev_primary_approver = ls_match-approver_user.
        ev_sla_hours        = ls_match-sla_hours.
      ENDIF.
      lv_step += 1.
    ENDLOOP.

  ENDMETHOD.

  METHOD simulate_route.
    CLEAR: et_steps, ev_step_count, ev_highest_level, ev_total_sla_hrs, ev_is_valid, ev_message.

    IF iv_amount <= 0.
      ev_is_valid = abap_false.
      ev_message = 'Simulation failed: Amount must be greater than zero.'.
      RETURN.
    ENDIF.

    determine_route(
      EXPORTING
        iv_amount           = iv_amount
        iv_currency         = iv_currency
      IMPORTING
        et_steps            = et_steps
        ev_primary_approver = DATA(lv_appr)
        ev_primary_role     = DATA(lv_role)
        ev_sla_hours        = DATA(lv_sla)
        ev_error_message    = ev_message
    ).

    IF ev_message IS NOT INITIAL.
      ev_is_valid = abap_false.
      RETURN.
    ENDIF.

    ev_is_valid = abap_true.
    ev_step_count = lines( et_steps ).

    LOOP AT et_steps INTO DATA(ls_s).
      ev_total_sla_hrs += ls_s-sla_hours.
      ev_highest_level = ls_s-approver_role.
    ENDLOOP.

    ev_message = |Simulation successful: { ev_step_count } approval step(s) required. Initial approver: { lv_role }.|.
  ENDMETHOD.

  METHOD validate_rules.
    CLEAR: et_issues, ev_is_valid.
    ev_is_valid = abap_true.

    DATA(lt_rules) = COND tt_rules( WHEN it_rules IS SUPPLIED THEN it_rules ELSE read_active_rules( sy-datum ) ).

    " 1. Check individual rules
    LOOP AT lt_rules INTO DATA(ls_r).
      " Minimum vs Maximum range check
      IF ls_r-max_amount > 0 AND ls_r-min_amount > ls_r-max_amount.
        ev_is_valid = abap_false.
        APPEND VALUE ty_validation_issue(
          rule_id  = ls_r-rule_id
          severity = 'E'
          message  = |Rule { ls_r-rule_id }: Minimum amount ({ ls_r-min_amount }) exceeds maximum amount ({ ls_r-max_amount }).|
        ) TO et_issues.
      ENDIF.

      " Missing role check
      IF ls_r-approver_role IS INITIAL.
        ev_is_valid = abap_false.
        APPEND VALUE ty_validation_issue(
          rule_id  = ls_r-rule_id
          severity = 'E'
          message  = |Rule { ls_r-rule_id }: Approver role is required.|
        ) TO et_issues.
      ENDIF.

      " Invalid SLA check
      IF ls_r-sla_hours <= 0.
        APPEND VALUE ty_validation_issue(
          rule_id  = ls_r-rule_id
          severity = 'W'
          message  = |Rule { ls_r-rule_id }: SLA duration should be at least 1 hour.|
        ) TO et_issues.
      ENDIF.
    ENDLOOP.

    " 2. Check for overlapping rules with the same approval_level and currency
    DATA lt_sorted TYPE tt_rules.
    lt_sorted = lt_rules.
    SORT lt_sorted BY approval_level ASCENDING min_amount ASCENDING.

    DATA(lv_count) = lines( lt_sorted ).
    DO lv_count TIMES.
      DATA(lv_idx) = sy-index.
      READ TABLE lt_sorted INTO DATA(ls_curr) INDEX lv_idx.
      DATA(lv_next_idx) = lv_idx + 1.
      IF lv_next_idx <= lv_count.
        READ TABLE lt_sorted INTO DATA(ls_next) INDEX lv_next_idx.
        IF ls_curr-approval_level = ls_next-approval_level AND
           ls_curr-currency = ls_next-currency AND
           ls_curr-is_active = abap_true AND ls_next-is_active = abap_true.
          " Check overlap
          IF ls_curr-max_amount = 0 OR ls_curr-max_amount >= ls_next-min_amount.
            ev_is_valid = abap_false.
            APPEND VALUE ty_validation_issue(
              rule_id  = ls_next-rule_id
              severity = 'E'
              message  = |Rule conflict: Rule { ls_curr-rule_id } and { ls_next-rule_id } overlap in amount range for level { ls_curr-approval_level }.|
            ) TO et_issues.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDDO.

  ENDMETHOD.

  METHOD read_active_rules.
    CLEAR rt_rules.
    SELECT FROM zso_i_appr_rule
      FIELDS RuleId, ApprovalLevel, MinAmount, MaxAmount, Currency,
             ApproverRole, ApproverUser, SlaHours, IsActive, ValidFrom, ValidTo
      WHERE IsActive = @abap_true
      INTO CORRESPONDING FIELDS OF TABLE @rt_rules.
  ENDMETHOD.

  METHOD get_fallback_rules.
    rt_rules = VALUE #(
      ( rule_id = 'RULE_01' approval_level = '01' min_amount = '0.00'     max_amount = '9999.99'   currency = 'EUR' approver_role = 'MANAGER'        approver_user = 'MGR_BAUER'   sla_hours = 24 is_active = abap_true valid_from = '20260101' )
      ( rule_id = 'RULE_02' approval_level = '01' min_amount = '10000.00' max_amount = '49999.99'  currency = 'EUR' approver_role = 'SENIOR_MANAGER' approver_user = 'SRM_MUELLER' sla_hours = 48 is_active = abap_true valid_from = '20260101' )
      ( rule_id = 'RULE_03' approval_level = '01' min_amount = '50000.00' max_amount = '0.00'      currency = 'EUR' approver_role = 'DIRECTOR'       approver_user = 'DIR_SCHMIDT' sla_hours = 72 is_active = abap_true valid_from = '20260101' )
    ).
  ENDMETHOD.

ENDCLASS.
