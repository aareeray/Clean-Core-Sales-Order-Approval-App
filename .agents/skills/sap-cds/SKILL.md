---
name: sap-cds
description: >
  Skill for developing CDS (Core Data Services) view entities on ABAP Cloud.
  Covers interface views, projection views, associations, value helps, and
  all @UI annotations required for Fiori Elements OData V4 apps.
---

# SAP CDS View Entity Skill

## Overview

Use this skill when creating or modifying CDS view entities for the
Sales Order Approval app. Always use `define view entity` syntax.

---

## Interface View: Header (ZSO_R_REQ_H)

`.cds
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Sales Order Request Header - Interface View'

define view entity ZSO_R_REQ_H
  as select from ZSO_REQ_H as Header

  composition [0..*] of ZSO_R_REQ_I as _Items

{
  key Header.REQUEST_ID      as RequestId,
      Header.CUSTOMER_ID     as CustomerId,
      Header.REQUEST_DATE    as RequestDate,

      @Semantics.amount.currencyCode: 'Currency'
      Header.TOTAL_AMOUNT    as TotalAmount,
      Header.CURRENCY        as Currency,

      Header.STATUS          as Status,
      Header.APPROVER        as Approver,
      Header.REJECTION_REASON as RejectionReason,

      @Semantics.user.createdBy: true
      Header.CREATED_BY      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      Header.CREATED_AT      as CreatedAt,
      @Semantics.user.lastChangedBy: true
      Header.CHANGED_BY      as ChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      Header.CHANGED_AT      as ChangedAt,

      -- Association
      _Items
}
`

---

## Interface View: Items (ZSO_R_REQ_I)

`.cds
@AccessControl.authorizationCheck: #INHERITED
@EndUserText.label: 'Sales Order Request Item - Interface View'

define view entity ZSO_R_REQ_I
  as select from ZSO_REQ_I as Item

  association to parent ZSO_R_REQ_H as _Header
    on .RequestId = _Header.RequestId

{
  key Item.REQUEST_ID        as RequestId,
  key Item.ITEM_NO           as ItemNo,
      Item.MATERIAL          as Material,

      @Semantics.quantity.unitOfMeasure: 'Unit'
      Item.QUANTITY          as Quantity,
      Item.UNIT              as Unit,

      @Semantics.amount.currencyCode: 'Currency'
      Item.UNIT_PRICE        as UnitPrice,
      @Semantics.amount.currencyCode: 'Currency'
      Item.NET_AMOUNT        as NetAmount,
      Item.CURRENCY          as Currency,

      -- Association back to header
      _Header
}
`

---

## Projection View: Header (ZSO_C_REQ_H)

`.cds
@AccessControl.authorizationCheck: #INHERITED
@EndUserText.label: 'Sales Order Request Header - Projection View'

@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName:       'Sales Order Request',
  typeNamePlural: 'Sales Order Requests',
  title:          { type: #STANDARD, value: 'RequestId' },
  description:    { type: #STANDARD, value: 'CustomerId' }
}

define view entity ZSO_C_REQ_H
  provider contract transactional_query
  as projection on ZSO_R_REQ_H

{
  @UI.facet: [
    { id: 'HeaderData',   type: #IDENTIFICATION_REFERENCE,
      label: 'General Information', position: 10 },
    { id: 'ItemsTable',   type: #LINEITEM_REFERENCE,
      label: 'Items',               position: 20,
      targetElement: '_Items' },
    { id: 'ApprovalData', type: #IDENTIFICATION_REFERENCE,
      label: 'Approval Details',    position: 30 }
  ]

  @UI.selectionField: [{ position: 10 }]
  @UI.lineItem:       [{ position: 10, label: 'Request ID' }]
  @UI.identification: [{ position: 10, label: 'Request ID' }]
  key RequestId,

  @UI.selectionField: [{ position: 20 }]
  @UI.lineItem:       [{ position: 20, label: 'Customer' }]
  @UI.identification: [{ position: 20, label: 'Customer ID' }]
  CustomerId,

  @UI.selectionField: [{ position: 30 }]
  @UI.lineItem:       [{ position: 30, label: 'Request Date' }]
  @UI.identification: [{ position: 30, label: 'Request Date' }]
  RequestDate,

  @UI.lineItem:       [{ position: 40, label: 'Total Amount' }]
  @UI.identification: [{ position: 40, label: 'Total Amount' }]
  TotalAmount,

  Currency,

  @UI.selectionField: [{ position: 40 }]
  @UI.lineItem:       [{ position: 50, label: 'Status',
    criticality: 'StatusCriticality', criticalityRepresentation: #WITHOUT_ICON }]
  @UI.identification: [{ position: 50, label: 'Status' }]
  Status,

  @UI.identification: [{ position: 60, label: 'Approver' }]
  Approver,

  @UI.identification: [{ position: 70, label: 'Rejection Reason' }]
  RejectionReason,

  CreatedBy,
  CreatedAt,
  ChangedBy,
  ChangedAt,

  -- Criticality helper (virtual or calculated)
  case Status
    when 'APPROVED' then 3  -- Green
    when 'REJECTED' then 1  -- Red
    when 'PENDING'  then 2  -- Yellow
    else                 0  -- None
  end as StatusCriticality,

  -- Actions (declared here, implemented in BDEF)
  @UI.lineItem: [{ type: #FOR_ACTION, dataAction: 'submit',   label: 'Submit'   }]
  @UI.identification: [{ type: #FOR_ACTION, dataAction: 'submit',   label: 'Submit'   }]
  @UI.hidden: #( Status <> 'DRAFT' )
  RequestId as SubmitAction    : redirected to ZSO_C_REQ_H,

  @UI.lineItem: [{ type: #FOR_ACTION, dataAction: 'approve',  label: 'Approve'  }]
  @UI.identification: [{ type: #FOR_ACTION, dataAction: 'approve',  label: 'Approve'  }]
  RequestId as ApproveAction   : redirected to ZSO_C_REQ_H,

  @UI.lineItem: [{ type: #FOR_ACTION, dataAction: 'reject',   label: 'Reject'   }]
  @UI.identification: [{ type: #FOR_ACTION, dataAction: 'reject',   label: 'Reject'   }]
  RequestId as RejectAction    : redirected to ZSO_C_REQ_H,

  @UI.lineItem: [{ type: #FOR_ACTION, dataAction: 'resubmit', label: 'Resubmit' }]
  @UI.identification: [{ type: #FOR_ACTION, dataAction: 'resubmit', label: 'Resubmit' }]
  RequestId as ResubmitAction  : redirected to ZSO_C_REQ_H,

  -- Associations (projected)
  _Items : redirected to composition child ZSO_C_REQ_I
}
`

---

## Value Help Annotations

Add to the projection view fields:

`.cds
  -- Customer value help (via search help or CDS-based)
  @Consumption.valueHelpDefinition: [{
    entity: { name: 'ZSO_VH_CUSTOMER', element: 'CustomerId' }
  }]
  CustomerId,

  -- Status value help (fixed values)
  @Consumption.valueHelpDefinition: [{
    entity: { name: 'ZSO_VH_STATUS', element: 'Status' }
  }]
  Status,
`

---

## Key Rules

1. **Interface views**: `@AccessControl.authorizationCheck: #CHECK`
2. **Item interface view**: `@AccessControl.authorizationCheck: #INHERITED`
3. **Projection views**: `@AccessControl.authorizationCheck: #INHERITED` + `provider contract transactional_query`
4. **Never use** deprecated `define view` — always `define view entity`.
5. **Semantics annotations** are mandatory on amount/quantity/timestamp fields.
6. **All `@UI` annotations** go on the **projection view**, not the interface view.
7. **Criticality** for status: `3` = green, `2` = yellow, `1` = red, `0` = none.
