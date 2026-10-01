# IAM App & Business Catalog Setup Guide

## Overview

Authorization chain:
```
BTP Business Role
    └── Business Catalog (ZSO_BC_REQUESTER / ZSO_BC_APPROVER / ZSO_BC_ADMIN)
            └── IAM App (ZSO_APPROVAL_IAM)
                    └── OData V4 Service (ZSO_SB_REQ_H)
                            └── DCL Roles (ZSO_R_REQ_H_REQUESTER / _APPROVER / _ADMIN)
                                    └── Auth Object (ZSO_APPROVAL) checked via pfcg_auth
```

---

## Step 1: Create Authorization Object ZSO_APPROVAL

> ⚠️ Do this FIRST — DCL activation will fail if the auth object doesn't exist.

In ADT or ABAP GUI (transaction SU21):
1. New → Authorization Object
2. Object Class: Create `ZSOA` (Sales Order Approval) if needed
3. Authorization Object: `ZSO_APPROVAL`
4. Description: `Sales Order Approval Authorization`
5. Add fields:

   | Field Name  | Data Element | Description      |
   |-------------|--------------|------------------|
   | `ACTVT`     | `ACTVT`      | Activity         |
   | `STATUS`    | `ZSO_E_STATUS` | Request Status |
   | `CUSTOMER_ID` | `ZSO_E_CUSTOMER_ID` | Customer ID |

6. Permitted activities: `01`, `02`, `03`, `ZA`, `ZR`
7. Save and activate

---

## Step 2: Create IAM App ZSO_APPROVAL_IAM

In ADT → Project Explorer → right-click package `Z_SALES_APPROVAL`:
1. New → Other → ABAP Repository Object → Identity and Access Management → **IAM App**
2. Fill in:

   | Field | Value |
   |---|---|
   | App ID | `ZSO_APPROVAL_IAM` |
   | Description | `Sales Order Approval IAM App` |
   | App Type | `ERP: Fiori Launchpad App` |

3. On the **Services** tab:
   - Add service: `ZSO_SB_REQ_H` (your published OData V4 binding)
   - Authorization Default: `Write`

4. On the **Authorizations** tab, define authorization defaults:

   ### Default for REQUESTER
   | Object | Field | Value |
   |---|---|---|
   | `ZSO_APPROVAL` | `ACTVT` | `01`, `02`, `03` |
   | `ZSO_APPROVAL` | `STATUS` | `DRAFT`, `PENDING`, `REJECTED`, `APPROVED` |
   | `ZSO_APPROVAL` | `CUSTOMER_ID` | `*` |

   ### Default for APPROVER
   | Object | Field | Value |
   |---|---|---|
   | `ZSO_APPROVAL` | `ACTVT` | `03`, `ZA`, `ZR` |
   | `ZSO_APPROVAL` | `STATUS` | `PENDING`, `APPROVED`, `REJECTED` |
   | `ZSO_APPROVAL` | `CUSTOMER_ID` | `*` |

   ### Default for ADMIN
   | Object | Field | Value |
   |---|---|---|
   | `ZSO_APPROVAL` | `ACTVT` | `*` |
   | `ZSO_APPROVAL` | `STATUS` | `*` |
   | `ZSO_APPROVAL` | `CUSTOMER_ID` | `*` |

5. **Publish** the IAM app (click Publish in the editor toolbar)

---

## Step 3: Create Business Catalogs

In ADT → New → Identity and Access Management → **Business Catalog**

### Catalog 1: ZSO_BC_REQUESTER

| Field | Value |
|---|---|
| Catalog ID | `ZSO_BC_REQUESTER` |
| Description | `Sales Order - Requester` |
| IAM App | `ZSO_APPROVAL_IAM` |
| Auth Variant | REQUESTER defaults |

DCL Role Mapping:
- Business Catalog `ZSO_BC_REQUESTER` → DCL role `ZSO_R_REQ_H_REQUESTER`

### Catalog 2: ZSO_BC_APPROVER

| Field | Value |
|---|---|
| Catalog ID | `ZSO_BC_APPROVER` |
| Description | `Sales Order - Approver` |
| IAM App | `ZSO_APPROVAL_IAM` |
| Auth Variant | APPROVER defaults |

DCL Role Mapping:
- Business Catalog `ZSO_BC_APPROVER` → DCL role `ZSO_R_REQ_H_APPROVER`

### Catalog 3: ZSO_BC_ADMIN

| Field | Value |
|---|---|
| Catalog ID | `ZSO_BC_ADMIN` |
| Description | `Sales Order - Administrator` |
| IAM App | `ZSO_APPROVAL_IAM` |
| Auth Variant | ADMIN defaults (all `*`) |

DCL Role Mapping:
- Business Catalog `ZSO_BC_ADMIN` → DCL role `ZSO_R_REQ_H_ADMIN`

---

## Step 4: Publish Catalogs

For each business catalog:
1. Open in ADT → click **Publish** button
2. Wait for green status indicator

---

## Step 5: Create Business Roles in BTP Cockpit

1. BTP Cockpit → Your subaccount → **Security → Role Collections**
2. Create three role collections:

   | Role Collection | Business Catalog to Include |
   |---|---|
   | `ZSO_REQUESTER_ROLE` | `ZSO_BC_REQUESTER` |
   | `ZSO_APPROVER_ROLE`  | `ZSO_BC_APPROVER`  |
   | `ZSO_ADMIN_ROLE`     | `ZSO_BC_ADMIN`     |

3. Assign each role collection to the appropriate users or user groups:
   - Regular employees → `ZSO_REQUESTER_ROLE`
   - Managers/Directors → `ZSO_APPROVER_ROLE`
   - IT / Super users → `ZSO_ADMIN_ROLE`

---

## Step 6: Authorization Test Matrix

After setup, verify with each user type:

| Test | User Role | Expected Result |
|---|---|---|
| GET /SalesOrderRequest | Requester (own requests) | Only rows where CreatedBy = current user |
| GET /SalesOrderRequest | Approver | Only rows where Approver = current user |
| GET /SalesOrderRequest | Admin | All rows |
| POST /SalesOrderRequest | Requester | 201 Created |
| POST /SalesOrderRequest | Approver | 403 Forbidden |
| POST .../submit | Requester (own DRAFT) | 200 OK — Status = PENDING |
| POST .../approve | Approver (assigned PENDING) | 200 OK — Status = APPROVED |
| POST .../approve | Requester | 403 Forbidden |
| POST .../reject | Approver with reason | 200 OK — Status = REJECTED |
| POST .../resubmit | Requester (own REJECTED) | 200 OK — Status = DRAFT |

---

## DCL Activation Order

```
1. ZSO_APPROVAL auth object (in SU21)   [manual in GUI]
2. ZSO_R_REQ_H.dcl                     [Ctrl+F3 in ADT]
3. ZSO_R_REQ_I.dcl                     [Ctrl+F3 in ADT]
4. ZSO_APPROVAL_IAM                    [Publish button]
5. ZSO_BC_REQUESTER                    [Publish button]
6. ZSO_BC_APPROVER                     [Publish button]
7. ZSO_BC_ADMIN                        [Publish button]
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| DCL activation error: auth object not found | ZSO_APPROVAL not created | Create in SU21 first |
| All users see all records | DCL not activated or wrong role mapping | Check business catalog → IAM app → DCL role chain |
| 403 on all requests | No business role assigned in BTP | Assign role collection to user in BTP cockpit |
| Requester can see other users' requests | Requester catalog has ADMIN DCL role | Check catalog → IAM app role assignment |
| Approver can create new requests | ACTVT=01 granted to approver catalog | Remove 01 from ZSO_BC_APPROVER defaults |
