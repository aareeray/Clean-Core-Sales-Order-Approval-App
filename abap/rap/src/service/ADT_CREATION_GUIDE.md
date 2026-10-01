# Service Definition & Binding — ADT Creation Guide (Day 4)

## Prerequisites

Before starting Day 4, confirm these objects are **active**:
- [ ] `ZSO_C_REQ_H` (header projection view)
- [ ] `ZSO_C_REQ_I` (items projection view)
- [ ] `ZSO_VH_STATUS` (status value help view)
- [ ] `ZSO_VH_CUSTOMER` (customer value help view)
- [ ] `ZSO_R_REQ_H` (BDEF — behavior definition)
- [ ] `ZSO_BP_REQ_H` (behavior implementation class)

---

## Part 1: Service Definition (ZSO_SD_REQ_H)

### Create in ADT

1. File → New → Other → ABAP Repository Object → Business Services → **Service Definition**
2. Name: `ZSO_SD_REQ_H`
3. Description: `Sales Order Request Service Definition`
4. Package: `Z_SALES_APPROVAL`
5. Expose entity: type `ZSO_C_REQ_H` in the wizard (it pre-fills a stub)
6. Replace the generated content entirely with `ZSO_SD_REQ_H.srvd.asdsrvd`
7. **Ctrl+F3** to activate

> ✅ On successful activation you will see: **"Service Definition ZSO_SD_REQ_H activated"**

---

## Part 2: Service Binding (ZSO_SB_REQ_H)

> Service Bindings **cannot be created as a text file** — they must be created via the ADT wizard. Use the JSON spec in `ZSO_SB_REQ_H.srvb.json` to fill in the wizard fields.

### Create in ADT

1. Right-click `ZSO_SD_REQ_H` in Project Explorer → **New Service Binding**  
   *(OR: File → New → Other → Business Services → Service Binding)*
2. Fill in the wizard:

   | Field | Value |
   |---|---|
   | Name | `ZSO_SB_REQ_H` |
   | Description | `Sales Order Request Service Binding (OData V4 UI)` |
   | Binding Type | **OData V4 - UI** |
   | Service Definition | `ZSO_SD_REQ_H` |

3. Click **Finish** — ADT creates and opens the service binding editor
4. Click **Publish Local Service Endpoint** button (top right of the editor)
5. Wait for the green checkmark — the service is now published

> ⚠️ **"OData V4 - UI" vs "OData V4 - Web API":**  
> You MUST choose **UI** for Fiori Elements draft support.  
> Web API is for programmatic/API access without draft — choosing it means draft won't work.

---

## Part 3: Verify the Service

### 3.1 — ADT Service Preview

1. Open `ZSO_SB_REQ_H` in ADT → click **Preview** (top of binding editor)
2. A browser opens with the Fiori Elements preview
3. Verify:
   - [ ] List Report loads with correct columns (RequestId, CustomerId, Status…)
   - [ ] Filters appear (Status, Customer, RequestDate)
   - [ ] Create button is present
   - [ ] Click a row → Object Page opens

### 3.2 — OData Metadata Verification

Open this URL in a browser (replace `<host>` with your BTP ABAP system host):

```
https://<host>/sap/opu/odata4/sap/zso_sb_req_h/srvd/sap/zso_sd_req_h/0001/$metadata
```

**Verify in the XML metadata document:**

```xml
<!-- Entity types exist -->
<EntityType Name="SalesOrderRequest">     ✅
<EntityType Name="SalesOrderItem">        ✅
<EntityType Name="StatusValueHelp">       ✅
<EntityType Name="CustomerValueHelp">     ✅

<!-- Actions exist (bound to SalesOrderRequest) -->
<Action Name="submit"   IsBound="true">   ✅
<Action Name="approve"  IsBound="true">   ✅
<Action Name="reject"   IsBound="true">   ✅
<Action Name="resubmit" IsBound="true">   ✅

<!-- Draft actions exist -->
<Action Name="draftActivate">             ✅
<Action Name="draftEdit">                 ✅
<Action Name="draftDiscard">              ✅
```

### 3.3 — Entity Set Read Test

```http
GET /sap/opu/odata4/sap/zso_sb_req_h/srvd/sap/zso_sd_req_h/0001/SalesOrderRequest
Accept: application/json
```

**Expected response:**
```json
{
  "@odata.context": "$metadata#SalesOrderRequest",
  "value": []
}
```
*(Empty array — tables are empty. No error = success.)*

### 3.4 — Draft Create Test

```http
POST /sap/opu/odata4/sap/zso_sb_req_h/srvd/sap/zso_sd_req_h/0001/SalesOrderRequest
Content-Type: application/json
Prefer: return=representation

{
  "CustomerId":   "CUST001",
  "RequestDate":  "2026-10-01",
  "Currency":     "EUR"
}
```

**Expected response (201 Created):**
```json
{
  "RequestId":  "<generated-uuid>",
  "CustomerId": "CUST001",
  "Status":     "DRAFT",
  "IsActiveEntity": false,
  "HasDraftEntity": true
}
```

Confirms: `setInitialStatus` determination fired (Status = DRAFT), UUID generated.

### 3.5 — Submit Action Test

```http
POST .../SalesOrderRequest(RequestId=<uuid>,IsActiveEntity=false)/ZSO_SD_REQ_H.submit
Content-Type: application/json
{}
```

**Expected (400 if amount = 0):**
```json
{
  "error": {
    "message": "Total amount must be greater than zero"
  }
}
```

Confirms: `validateAmount` fires during draft Prepare or on submit.

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| "Service not found" after publish | Binding not published | Click "Publish Local Service Endpoint" again |
| $metadata missing SalesOrderItem | ZSO_C_REQ_I not in SRVD | Add `expose ZSO_C_REQ_I as SalesOrderItem` to SRVD |
| Actions not in $metadata | BDEF not activated | Activate BDEF first, then republish binding |
| Value help 404 in List Report | VH views not exposed | Add ZSO_VH_STATUS and ZSO_VH_CUSTOMER to SRVD |
| Draft operations not working | Used "OData V4 - Web API" binding type | Delete binding, recreate with "OData V4 - UI" |
| 403 Forbidden on all requests | No IAM app / business role assigned | Day 7 — DCL and IAM setup will fix this |

---

## Object Inventory

| Object        | Type               | File                          | Status |
|---------------|--------------------|-------------------------------|--------|
| ZSO_SD_REQ_H  | Service Definition | ZSO_SD_REQ_H.srvd.asdsrvd    | ☐      |
| ZSO_SB_REQ_H  | Service Binding    | Created via ADT wizard        | ☐      |
| ZSO_SB_REQ_H  | Published          | Click "Publish Local Service Endpoint" | ☐ |

---

## Published Service URL (use in BAS Fiori Generator — Day 5)

```
/sap/opu/odata4/sap/zso_sb_req_h/srvd/sap/zso_sd_req_h/0001/
```

Save this URL — you'll need it on Day 5 when connecting the Fiori app to the service.

---

## abapGit Note

Service Bindings can be pushed to Git via abapGit only if your abapGit version
supports `.srvb` objects (version ≥ 1.119.0). If not, document the binding
manually using `ZSO_SB_REQ_H.srvb.json` as the reference.
