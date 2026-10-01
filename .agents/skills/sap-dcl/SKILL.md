---
name: sap-dcl
description: >
  Skill for CDS Data Control Language (DCL) authorization in ABAP Cloud.
  Covers instance-based authorization, role definitions, and DCL syntax
  for the Sales Order Approval app security model.
---

# SAP CDS DCL Authorization Skill

## Overview

Use this skill when creating or modifying CDS DCL access controls for the
Sales Order Approval app. All authorization must use released ABAP Cloud APIs.

---

## Authorization Object Definition

Create authorization object `ZSO_APPROVAL` in transaction SU21:

| Field        | Type          | Description         |
|--------------|---------------|---------------------|
| ACTVT        | Activity      | Standard activity   |
| STATUS       | Char 10       | Request status      |
| CUSTOMER_ID  | Char 10       | Customer ID         |

Activity values:
- `01` = Create
- `02` = Change
- `03` = Display
- `ZA` = Approve
- `ZR` = Reject

---

## DCL: Header View (ZSO_R_REQ_H)

`.dcl
@MappingRole: true
define role ZSO_R_REQ_H {
  grant select on ZSO_R_REQ_H
    where (STATUS, CUSTOMER_ID) = aspect pfcg_auth( ZSO_APPROVAL, STATUS, CUSTOMER_ID,
                                                    ACTVT = '03' );
}
`

### Requester Role Restriction (Z_SO_REQUESTER)

`.dcl
@MappingRole: true
define role ZSO_R_REQ_H_REQUESTER {
  grant select on ZSO_R_REQ_H
    where CreatedBy = 
      and (STATUS, CUSTOMER_ID) = aspect pfcg_auth( ZSO_APPROVAL, STATUS, CUSTOMER_ID,
                                                    ACTVT = '03' );
}
`

### Approver Role Restriction (Z_SO_APPROVER)

`.dcl
@MappingRole: true
define role ZSO_R_REQ_H_APPROVER {
  grant select on ZSO_R_REQ_H
    where Approver = 
      and (STATUS, CUSTOMER_ID) = aspect pfcg_auth( ZSO_APPROVAL, STATUS, CUSTOMER_ID,
                                                    ACTVT = '03' );
}
`

### Admin Role (Z_SO_ADMIN) — No Instance Restriction

`.dcl
@MappingRole: true
define role ZSO_R_REQ_H_ADMIN {
  grant select on ZSO_R_REQ_H
    where (STATUS, CUSTOMER_ID) = aspect pfcg_auth( ZSO_APPROVAL, STATUS, CUSTOMER_ID,
                                                    ACTVT = '03' );
}
`

---

## DCL: Item View (ZSO_R_REQ_I) — Inherited Authorization

`.dcl
@MappingRole: true
define role ZSO_R_REQ_I {
  grant select on ZSO_R_REQ_I
    where _Header.RequestId is not initial;
}
`

The item view inherits authorization via the parent composition (`_Header`).
The `@AccessControl.authorizationCheck: #INHERITED` annotation on `ZSO_R_REQ_I`
ensures the header's DCL is applied automatically.

---

## Role Profile Definitions

### Z_SO_REQUESTER

| Auth Object   | Field       | Value(s)         |
|---------------|-------------|------------------|
| ZSO_APPROVAL  | ACTVT       | 01, 02, 03       |
| ZSO_APPROVAL  | STATUS      | DRAFT, PENDING, REJECTED, APPROVED |
| ZSO_APPROVAL  | CUSTOMER_ID | * (all)          |

Instance restriction: DCL filters `CreatedBy = \`.

### Z_SO_APPROVER

| Auth Object   | Field       | Value(s)         |
|---------------|-------------|------------------|
| ZSO_APPROVAL  | ACTVT       | 03, ZA, ZR       |
| ZSO_APPROVAL  | STATUS      | PENDING, APPROVED, REJECTED |
| ZSO_APPROVAL  | CUSTOMER_ID | * (all)          |

Instance restriction: DCL filters `Approver = \`.

### Z_SO_ADMIN

| Auth Object   | Field       | Value(s) |
|---------------|-------------|----------|
| ZSO_APPROVAL  | ACTVT       | *        |
| ZSO_APPROVAL  | STATUS      | *        |
| ZSO_APPROVAL  | CUSTOMER_ID | *        |

No instance restriction.

---

## IAM App Configuration

1. Create an IAM App in the ABAP Cloud environment:
   - App ID: `ZSO_APPROVAL_IAM`
   - App Type: `ERP (Fiori Launchpad)`
   - Associate the OData V4 service `ZSO_SB_REQ_H`

2. Create Business Catalogs:
   - `ZSO_BC_REQUESTER` — assigned to `Z_SO_REQUESTER` role
   - `ZSO_BC_APPROVER`  — assigned to `Z_SO_APPROVER` role
   - `ZSO_BC_ADMIN`     — assigned to `Z_SO_ADMIN` role

3. Publish catalogs and assign to business roles in BTP cockpit.

---

## BDEF Authorization Implementation

`.abap
METHOD get_instance_authorizations.
  READ ENTITIES OF ZSO_R_REQ_H IN LOCAL MODE
    ENTITY SalesOrderRequest
      FIELDS ( Status CreatedBy Approver )
      WITH CORRESPONDING #( keys )
    RESULT DATA(requests).

  result = VALUE #( FOR r IN requests (
    %tky                = r-%tky
    %update             = COND #( WHEN r-Status = 'DRAFT'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
    %delete             = if_abap_behv=>auth-unauthorized
    %action-submit      = COND #( WHEN r-CreatedBy = sy-uname AND r-Status = 'DRAFT'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
    %action-approve     = COND #( WHEN r-Approver = sy-uname AND r-Status = 'PENDING'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
    %action-reject      = COND #( WHEN r-Approver = sy-uname AND r-Status = 'PENDING'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
    %action-resubmit    = COND #( WHEN r-CreatedBy = sy-uname AND r-Status = 'REJECTED'
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
  ) ).
ENDMETHOD.
`

---

## Key Rules

1. **Always use `pfcg_auth`** in DCL — do not write manual WHERE conditions for role checks.
2. **Item view** must use `#INHERITED` — never `#CHECK` on child entities in a composition.
3. **Instance restriction** (`CreatedBy = \`, `Approver = \`) must be in DCL, NOT only in BDEF.
4. **IAM app** must be published before business roles can be assigned.
5. **Test authorization** by logging in with each role and verifying data visibility.
6. **Never grant** `ACTVT = '01'` (Create) to the Approver role.
