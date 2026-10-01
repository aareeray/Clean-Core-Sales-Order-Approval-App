# CDS View Entities — ADT Creation Guide (Day 2)

## Activation Order (CRITICAL — dependencies must exist first)

Create and activate in this exact sequence:

```
1. ZSO_VH_STATUS       (no CDS dependencies)
2. ZSO_VH_CUSTOMER     (depends on released I_Customer)
3. ZSO_R_REQ_I         (no CDS dependencies — selects from table only)
4. ZSO_R_REQ_H         (depends on ZSO_R_REQ_I for composition)
5. ZSO_C_REQ_I         (depends on ZSO_R_REQ_I)
6. ZSO_C_REQ_H         (depends on ZSO_R_REQ_H, ZSO_C_REQ_I, ZSO_VH_STATUS, ZSO_VH_CUSTOMER)
```

> ⚠️ Do NOT activate ZSO_R_REQ_H before ZSO_R_REQ_I — the composition will fail.

---

## Step-by-Step in ADT

For each view:
1. File → New → Other → ABAP Repository Object → Core Data Services → **Data Definition**
2. Enter name (e.g., `ZSO_R_REQ_H`), description, package `Z_SALES_APPROVAL`
3. Template: select **"Define View Entity"** (not "Define View"!)
4. Replace generated content with the corresponding `.asddls` file
5. **Ctrl+F3** to activate

---

## I_Customer Availability Note

`ZSO_VH_CUSTOMER` uses `I_Customer` which is a released SAP API.

**To verify it's available in your system:**
1. In ADT: use Quick Open (Ctrl+Shift+A) → type `I_Customer`
2. If not found, replace with a simpler value help using `KNA1` via a custom interface view
   — but this loses clean-core compliance. Prefer `I_Customer`.

**Fallback** if `I_Customer` is unavailable (BTP Trial systems sometimes have limited APIs):

```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help - Customer (Fallback)'

define view entity ZSO_VH_CUSTOMER
  as select distinct
    cast( request_id as abap.char(10) ) as CustomerId,
    cast( customer_id as abap.char(40) ) as CustomerName
  from ZSO_REQ_H
```

---

## Object Inventory

| Object           | Type            | File                       | Status |
|------------------|-----------------|----------------------------|--------|
| ZSO_VH_STATUS    | Value Help View | ZSO_VH_STATUS.ddls.asddls  | ☐      |
| ZSO_VH_CUSTOMER  | Value Help View | ZSO_VH_CUSTOMER.ddls.asddls| ☐      |
| ZSO_R_REQ_I      | Interface View  | ZSO_R_REQ_I.ddls.asddls   | ☐      |
| ZSO_R_REQ_H      | Interface View  | ZSO_R_REQ_H.ddls.asddls   | ☐      |
| ZSO_C_REQ_I      | Projection View | ZSO_C_REQ_I.ddls.asddls   | ☐      |
| ZSO_C_REQ_H      | Projection View | ZSO_C_REQ_H.ddls.asddls   | ☐      |

---

## Quick Verification Queries

Run these in ADT ABAP Console or a scratch report after activation:

```abap
" Test 1: Interface view is accessible
SELECT TOP 5 * FROM zso_r_req_h INTO @DATA(lt_h).
WRITE: / 'ZSO_R_REQ_H rows:', lines( lt_h ).

" Test 2: Projection view is accessible
SELECT TOP 5 * FROM zso_c_req_h INTO @DATA(lt_c).
WRITE: / 'ZSO_C_REQ_H rows:', lines( lt_c ).
```

Expected: No short dump, rows = 0 (empty tables).

---

## Common Activation Errors and Fixes

| Error | Cause | Fix |
|---|---|---|
| `Association target ZSO_R_REQ_I not found` | Item view not activated yet | Activate ZSO_R_REQ_I first |
| `I_Customer is not released` | Older SAP system | Use fallback value help above |
| `provider contract transactional_query requires BDEF` | BDEF not yet created | OK — activate CDS anyway; BDEF comes Day 3 |
| `@UI.hidden: #(...)` syntax error | Older CDS compiler | Replace with feature control in BDEF only |
| `redirected to composition child ZSO_C_REQ_I not found` | ZSO_C_REQ_I not activated | Activate ZSO_C_REQ_I before ZSO_C_REQ_H |

---

## What Gets Generated (OData Metadata Preview)

After creating the service binding in Day 4, you'll see:

```xml
<EntityType Name="SalesOrderRequest">
  <Key><PropertyRef Name="RequestId"/></Key>
  <Property Name="RequestId" Type="Edm.Guid"/>
  <Property Name="CustomerId" Type="Edm.String" MaxLength="10"/>
  <Property Name="TotalAmount" Type="Edm.Decimal" Precision="15" Scale="2"/>
  <Property Name="Currency" Type="Edm.String" MaxLength="5"/>
  <Property Name="Status" Type="Edm.String" MaxLength="10"/>
  <Property Name="StatusCriticality" Type="Edm.Byte"/>
  ...
  <NavigationProperty Name="_Items" Type="SalesOrderItem"/>
</EntityType>
```
