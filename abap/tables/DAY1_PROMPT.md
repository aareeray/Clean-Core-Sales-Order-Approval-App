# Day 1 — Database Tables & Package

Paste this prompt into Antigravity Agent Manager:

---

/build-feature create-database-tables

Create the ABAP Cloud database tables for the Sales Order Approval app.

## Package
Create package: Z_SALES_APPROVAL
  - Application component: CA-GTF or custom
  - Package type: Development
Create a Transport Request and assign all objects to it.

## Table 1: ZSO_REQ_H (Header)

Fields (use @EndUserText.label on each):
  MANDT        MANDT         (key, client)
  REQUEST_ID   SYSUUID_X16   (key, UUID)
  CUSTOMER_ID  CHAR 10
  REQUEST_DATE DATS
  TOTAL_AMOUNT CURR 15,2
  CURRENCY     CUKY 5
  STATUS       CHAR 10       (DRAFT/PENDING/APPROVED/REJECTED)
  APPROVER     CHAR 12
  REJECTION_REASON CHAR 255
  CREATED_BY   CHAR 12
  CREATED_AT   UTCLONG
  CHANGED_BY   CHAR 12
  CHANGED_AT   UTCLONG

## Table 2: ZSO_REQ_I (Item)

Fields:
  MANDT        MANDT         (key, client)
  REQUEST_ID   SYSUUID_X16   (key, FK to ZSO_REQ_H)
  ITEM_NO      NUMC 6        (key)
  MATERIAL     CHAR 40
  QUANTITY     QUAN 13,3
  UNIT         UNIT 3
  UNIT_PRICE   CURR 15,2
  NET_AMOUNT   CURR 15,2
  CURRENCY     CUKY 5

## Domain
  ZSO_D_STATUS: CHAR 10, fixed values: DRAFT, PENDING, APPROVED, REJECTED

## Data Elements
  ZSO_E_REQUEST_ID, ZSO_E_STATUS (use ZSO_D_STATUS), ZSO_E_TOTAL_AMT

Use ONLY ABAP Cloud released syntax.
