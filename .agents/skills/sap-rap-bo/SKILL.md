---
name: sap-rap-bo
description: >
  Skill for developing RAP (RESTful ABAP Programming Model) Business Objects
  on ABAP Cloud. Covers managed RAP with draft, behavior definitions,
  validations, determinations, and actions for the Sales Order Approval app.
---

# SAP RAP Business Object Skill

## Overview

Use this skill when creating or modifying the RAP Business Object for the
Sales Order Approval app (`ZSO_R_REQ_H`). All development must follow
ABAP Cloud rules and use only released APIs.

---

## Behavior Definition Template (BDEF)

`.abap
managed implementation in class ZSO_BP_REQ_H unique;
strict ( 2 );
with draft;

define behavior for ZSO_R_REQ_H alias SalesOrderRequest
  persistent table ZSO_REQ_H
  draft table ZSO_DREQ_H
  etag master ChangedAt
  lock master total etag ChangedAt
  authorization master ( instance )
  with additional save
{
  -- Standard CUD operations
  create;
  update;
  delete;

  -- Draft actions
  draft action Edit;
  draft action Activate optimized;
  draft action Discard;
  draft action Resume;
  draft determine action Prepare;

  -- Custom actions
  action ( features : instance ) submit   result [1] ;
  action ( features : instance ) approve  result [1] ;
  action ( features : instance ) reject   parameter ZSO_P_REJECT result [1] ;
  action ( features : instance ) resubmit result [1] ;

  -- Validations (on save)
  validation validateCustomer       on save { create; update; }
  validation validateAmount         on save { create; update; }
  validation validateRejectionReason on save { field RejectionReason; }

  -- Determinations
  determination setInitialStatus    on modify { create; }
  determination calculateTotalAmount on modify { field ItemNetAmount; }
  determination setChangedAt        on modify { create; update; }

  -- Field controls
  field ( readonly ) RequestId, CreatedBy, CreatedAt, ChangedBy, ChangedAt, Status;
  field ( mandatory ) CustomerId, RequestDate;

  -- Associations
  association _Items { create; with draft; }

  mapping for ZSO_REQ_H corresponding
  {
    RequestId        = REQUEST_ID;
    CustomerId       = CUSTOMER_ID;
    RequestDate      = REQUEST_DATE;
    TotalAmount      = TOTAL_AMOUNT;
    Currency         = CURRENCY;
    Status           = STATUS;
    Approver         = APPROVER;
    RejectionReason  = REJECTION_REASON;
    CreatedBy        = CREATED_BY;
    CreatedAt        = CREATED_AT;
    ChangedBy        = CHANGED_BY;
    ChangedAt        = CHANGED_AT;
  }
}

define behavior for ZSO_R_REQ_I alias SalesOrderItem
  persistent table ZSO_REQ_I
  draft table ZSO_DREQ_I
  lock dependent by _Header
  authorization dependent by _Header
{
  update;
  delete;
  field ( readonly ) RequestId, ItemNo;
  field ( mandatory ) Material, Quantity, Unit, UnitPrice;

  association _Header;

  mapping for ZSO_REQ_I corresponding
  {
    RequestId  = REQUEST_ID;
    ItemNo     = ITEM_NO;
    Material   = MATERIAL;
    Quantity   = QUANTITY;
    Unit       = UNIT;
    UnitPrice  = UNIT_PRICE;
    NetAmount  = NET_AMOUNT;
  }
}
`

---

## Validation Pattern

`.abap
METHOD validateCustomer.
  READ ENTITIES OF ZSO_R_REQ_H IN LOCAL MODE
    ENTITY SalesOrderRequest
      FIELDS ( CustomerId )
      WITH CORRESPONDING #( keys )
    RESULT DATA(requests)
    FAILED DATA(failed).

  LOOP AT requests INTO DATA(request).
    " Check customer exists in released API
    " Use only released ABAP Cloud customer check API
    IF request-CustomerId IS INITIAL.
      APPEND VALUE #( %tky = request-%tky ) TO failed-SalesOrderRequest.
      APPEND VALUE #(
        %tky     = request-%tky
        %state_area = 'VALIDATE_CUSTOMER'
        %msg     = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Customer ID is required' )
        %element-CustomerId = if_abap_behv=>mk-on
      ) TO reported-SalesOrderRequest.
    ENDIF.
  ENDLOOP.
ENDMETHOD.
`

---

## Determination Pattern

`.abap
METHOD setInitialStatus.
  READ ENTITIES OF ZSO_R_REQ_H IN LOCAL MODE
    ENTITY SalesOrderRequest
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
    RESULT DATA(requests).

  DATA updates TYPE TABLE FOR UPDATE ZSO_R_REQ_H\\SalesOrderRequest.

  LOOP AT requests INTO DATA(request).
    IF request-Status IS INITIAL.
      APPEND VALUE #(
        %tky   = request-%tky
        Status = 'DRAFT'
      ) TO updates.
    ENDIF.
  ENDLOOP.

  MODIFY ENTITIES OF ZSO_R_REQ_H IN LOCAL MODE
    ENTITY SalesOrderRequest UPDATE FIELDS ( Status ) WITH updates
    REPORTED DATA(reported_update).
ENDMETHOD.
`

---

## Action Pattern

`.abap
METHOD submit.
  READ ENTITIES OF ZSO_R_REQ_H IN LOCAL MODE
    ENTITY SalesOrderRequest
      FIELDS ( Status TotalAmount Approver )
      WITH CORRESPONDING #( keys )
    RESULT DATA(requests)
    FAILED DATA(failed).

  DATA updates TYPE TABLE FOR UPDATE ZSO_R_REQ_H\\SalesOrderRequest.

  LOOP AT requests INTO DATA(request).
    IF request-Status <> 'DRAFT'.
      APPEND VALUE #( %tky = request-%tky ) TO failed-SalesOrderRequest.
      APPEND VALUE #(
        %tky  = request-%tky
        %msg  = new_message_with_text(
                  severity = if_abap_behv_message=>severity-error
                  text     = 'Only DRAFT requests can be submitted' )
      ) TO reported-SalesOrderRequest.
      CONTINUE.
    ENDIF.

    " Determine approver based on amount
    DATA(lv_approver) = COND #(
      WHEN request-TotalAmount >= 10000 THEN 'DIRECTOR'
      ELSE                                   'MANAGER'
    ).

    APPEND VALUE #(
      %tky     = request-%tky
      Status   = 'PENDING'
      Approver = lv_approver
    ) TO updates.
  ENDLOOP.

  MODIFY ENTITIES OF ZSO_R_REQ_H IN LOCAL MODE
    ENTITY SalesOrderRequest
    UPDATE FIELDS ( Status Approver ) WITH updates
    REPORTED DATA(reported_update).

  " Return updated instances
  READ ENTITIES OF ZSO_R_REQ_H IN LOCAL MODE
    ENTITY SalesOrderRequest ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(result_requests).

  result = VALUE #( FOR r IN result_requests (
    %tky   = r-%tky
    %param = r
  ) ).
ENDMETHOD.
`

---

## Feature Control Pattern

`.abap
METHOD get_instance_features.
  READ ENTITIES OF ZSO_R_REQ_H IN LOCAL MODE
    ENTITY SalesOrderRequest
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
    RESULT DATA(requests)
    FAILED DATA(failed).

  result = VALUE #( FOR r IN requests (
    %tky              = r-%tky
    %action-submit    = COND #( WHEN r-Status = 'DRAFT'    THEN if_abap_behv=>fc-o-enabled
                                ELSE                            if_abap_behv=>fc-o-disabled )
    %action-approve   = COND #( WHEN r-Status = 'PENDING'  THEN if_abap_behv=>fc-o-enabled
                                ELSE                            if_abap_behv=>fc-o-disabled )
    %action-reject    = COND #( WHEN r-Status = 'PENDING'  THEN if_abap_behv=>fc-o-enabled
                                ELSE                            if_abap_behv=>fc-o-disabled )
    %action-resubmit  = COND #( WHEN r-Status = 'REJECTED' THEN if_abap_behv=>fc-o-enabled
                                ELSE                            if_abap_behv=>fc-o-disabled )
  ) ).
ENDMETHOD.
`

---

## Status Values Reference

| Status    | Code       | Allowed Next States       |
|-----------|------------|---------------------------|
| Draft     | `DRAFT`  | PENDING                   |
| Pending   | `PENDING`| APPROVED, REJECTED        |
| Approved  | `APPROVED`| (terminal)               |
| Rejected  | `REJECTED`| DRAFT (via resubmit)     |

---

## Key Rules

1. **Always use `%msg`** — never `MESSAGE ... TYPE`.
2. **Always read in LOCAL MODE** inside behavior implementations.
3. **ETag field** must be `ChangedAt` (type `TZNTSTMPL`).
4. **Draft table** naming: prefix persistent table name with `D` (e.g., `ZSO_DREQ_H`).
5. **Never COMMIT WORK** inside a behavior implementation — RAP handles commits.
6. **Use `CORRESPONDING #( )`** for mapping keys to avoid field name mismatches.
