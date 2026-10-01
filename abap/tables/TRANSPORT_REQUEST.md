# Transport Request — Day 1: Database Tables

## Package: Z_SALES_APPROVAL

**TR Number:** _(fill in after creating in ADT)_
**Description:** Sales Order Approval App - Database Layer

---

## Creation Order in ADT (Eclipse / Antigravity)

Create objects in this exact order (dependencies must exist before dependents):

### 1. Package

1. File → New → ABAP Package
   - Name: `Z_SALES_APPROVAL`
   - Description: `Clean-Core Sales Order Approval App`
   - Package type: Development
   - Add to favorite packages

### 2. Domain

2. File → New → Other → ABAP → Domain
   - Name: `ZSO_D_STATUS`
   - Paste content from: `ZSO_D_STATUS.ddls.asddls`

### 3. Data Elements (in order — ZSO_E_REQUEST_ID has no domain dep)

3. File → New → Other → ABAP → Data Element
   - `ZSO_E_REQUEST_ID` — raw(16), no domain
   - `ZSO_E_STATUS`     — domain: ZSO_D_STATUS
   - `ZSO_E_TOTAL_AMT`  — abap.curr(15,2), no domain

### 4. Tables

4. File → New → Other → ABAP → Database Table
   - `ZSO_REQ_H`  — paste from ZSO_REQ_H.tabl.asdbtab
   - `ZSO_REQ_I`  — paste from ZSO_REQ_I.tabl.asdbtab

### 5. Draft Tables (create now, needed for Day 3)

5. File → New → Other → ABAP → Database Table
   - `ZSO_DREQ_H` — paste from ZSO_DREQ_H.tabl.asdbtab
   - `ZSO_DREQ_I` — paste from ZSO_DREQ_I.tabl.asdbtab

---

## Object Inventory

| Object          | Type         | Status |
|-----------------|--------------|--------|
| Z_SALES_APPROVAL| Package      | ☐      |
| ZSO_D_STATUS    | Domain       | ☐      |
| ZSO_E_REQUEST_ID| Data Element | ☐      |
| ZSO_E_STATUS    | Data Element | ☐      |
| ZSO_E_TOTAL_AMT | Data Element | ☐      |
| ZSO_REQ_H       | Table        | ☐      |
| ZSO_REQ_I       | Table        | ☐      |
| ZSO_DREQ_H      | Draft Table  | ☐      |
| ZSO_DREQ_I      | Draft Table  | ☐      |

---

## Activation Sequence

Activate in this order:
1. `ZSO_D_STATUS`
2. `ZSO_E_REQUEST_ID`, `ZSO_E_STATUS`, `ZSO_E_TOTAL_AMT`
3. `ZSO_REQ_H`, `ZSO_REQ_I`
4. `ZSO_DREQ_H`, `ZSO_DREQ_I`

If activation fails on a table field type (e.g., `sysuuid_x16`), check:
- ABAP Cloud release: `sysuuid_x16` is released → use it
- Alternative: declare field with type `abap.raw(16)` and assign ZSO_E_REQUEST_ID data element

---

## Foreign Key Relation (ZSO_REQ_I → ZSO_REQ_H)

After activating both tables, add the foreign key in ADT:
- On `ZSO_REQ_I.REQUEST_ID` → right-click → Add Foreign Key
- Check table: `ZSO_REQ_H`
- Match: `REQUEST_ID → REQUEST_ID`
- Check field: MANDT (automatic)
- Cardinality: N:1

---

## Quick Verification

After all objects are active, run this ABAP snippet in a scratch program to verify:

```abap
REPORT zso_verify_tables.

DATA: lt_h TYPE TABLE OF zso_req_h,
      lt_i TYPE TABLE OF zso_req_i.

" Should return empty table without runtime error
SELECT * FROM zso_req_h INTO TABLE @lt_h UP TO 1 ROWS.
SELECT * FROM zso_req_i INTO TABLE @lt_i UP TO 1 ROWS.

WRITE: / 'ZSO_REQ_H OK, rows:', lines( lt_h ).
WRITE: / 'ZSO_REQ_I OK, rows:', lines( lt_i ).
```

Expected: No short dump, output shows "OK, rows: 0".
