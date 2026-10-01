# API Connection & OAuth2 Configuration

## Overview

Two API connections are required:
1. **ABAP → SBPA**: ABAP `save_modified` triggers the workflow via SBPA REST API
2. **SBPA → ABAP**: SBPA service tasks call OData V4 actions (approve/reject)

---

## Connection 1: ABAP → SBPA (Workflow Trigger)

### Step A: Get SBPA API Credentials

1. BTP Cockpit → Your subaccount → Instances and Subscriptions
2. Find **SAP Build Process Automation** → Click the instance
3. Create a **Service Key** (if not already done):
   - Click **Create Service Key** → name it `sbpa-api-key`
   - Download the JSON — note these fields:
     ```json
     {
       "endpoints": {
         "api": "https://spa-api-gateway-bpi-us-prod.cfapps.us10.hana.ondemand.com"
       },
       "uaa": {
         "url":       "https://your-subaccount.authentication.us10.hana.ondemand.com",
         "clientid":  "sb-clone-...",
         "clientsecret": "...",
         "tokenurl":  "https://your-subaccount.authentication.us10.hana.ondemand.com/oauth/token"
       }
     }
     ```

### Step B: Create Communication Arrangement in BTP ABAP

1. In BTP ABAP system → Transaction **SPRO** → SAP Reference IMG
   → Technical Settings → Communication Management → **Communication Arrangements**
2. Create arrangement for scenario: `SAP_COM_0009` (HTTP outbound)
3. Create a **Communication System**:
   - Host: `spa-api-gateway-bpi-us-prod.cfapps.us10.hana.ondemand.com`
   - Port: `443`, SSL: enabled
4. Create a **Communication User** with:
   - OAuth2 client credentials (clientid + clientsecret from Step A)
   - Token URL from Step A
5. Note the **Communication Arrangement name** — used in ABAP code as destination alias

### Step C: Workflow Definition ID

After creating the SBPA process (Day 6 in SBPA editor):
1. In SBPA → Monitor → Workflow Definitions
2. Note the **definitionId** (e.g., `com.company.zso.approvalprocess`)
3. Save it — needed in the ABAP trigger code

### ABAP Trigger Code Reference (save_modified hook)

The ABAP code in `ZSO_BP_REQ_H.save_modified.abap` calls:

```
POST https://spa-api-gateway-bpi-us-prod.cfapps.us10.hana.ondemand.com
     /workflow/rest/v1/workflow-instances

Headers:
  Content-Type: application/json
  Authorization: Bearer <OAuth2 token>

Body:
{
  "definitionId": "com.company.zso.approvalprocess",
  "context": {
    "requestId":      "<uuid>",
    "customerId":     "<customer>",
    "totalAmount":    12500.00,
    "currency":       "EUR",
    "requesterEmail": "user@company.com",
    "serviceUrl":     "https://<abap-host>/sap/opu/odata4/sap/zso_sb_req_h/srvd/sap/zso_sd_req_h/0001/"
  }
}

Expected Response (201 Created):
{
  "id": "<workflow-instance-id>",
  "definitionId": "com.company.zso.approvalprocess",
  "definitionVersion": "1",
  "status": "RUNNING"
}
```

---

## Connection 2: SBPA → ABAP (OData V4 Callbacks)

### Step A: Create BTP Destination for ABAP Backend

1. BTP Cockpit → Your subaccount → Connectivity → **Destinations**
2. Create new destination:

   | Property | Value |
   |---|---|
   | Name | `ZSO_ABAP_BACKEND` |
   | Type | HTTP |
   | URL | `https://<your-abap-host>/sap/opu/odata4/sap/zso_sb_req_h/srvd/sap/zso_sd_req_h/0001/` |
   | Authentication | `OAuth2ClientCredentials` |
   | Client ID | (from ABAP system communication user) |
   | Client Secret | (from ABAP system communication user) |
   | Token Service URL | `https://<your-abap-host>/sap/bc/sec/oauth2/token` |

3. Add additional properties:
   ```
   sap-client = 100
   WebIDEEnabled = true
   WebIDESystem = your-system-id
   ```

4. Test the destination → should return **200 OK**

### Step B: Add CSRF Token Handling in SBPA

OData V4 write operations require a CSRF token. Add a **pre-step** before each service task:

```
GET ${serviceUrl}$metadata
Headers:
  x-csrf-token: fetch

→ Extract x-csrf-token from response headers
→ Pass to subsequent POST calls as header: x-csrf-token: <value>
```

> **SBPA Configuration**: In each Service Task → Advanced → add header expression:
> `x-csrf-token: ${context.csrfToken}`

---

## OAuth2 Flow Summary

```
[ABAP save_modified]
    |
    ├─ GET OAuth token from SBPA UAA
    │   POST https://uaa-url/oauth/token
    │   grant_type=client_credentials
    │   → Bearer token (valid 12h)
    |
    └─ POST SBPA trigger API with Bearer token
        → Workflow instance created

[SBPA Service Task: approve/reject]
    |
    ├─ GET CSRF token from OData $metadata
    │
    └─ POST OData V4 action with
        Authorization: OAuth2 (destination ZSO_ABAP_BACKEND)
        x-csrf-token: <fetched>
        → RAP action executes → Status updated in DB
```

---

## Security Notes

- Never hardcode client secrets in ABAP code — use Communication Arrangements
- SBPA destinations are managed in BTP Cockpit — not stored in ABAP
- OAuth2 tokens are cached for their validity period (12h typical)
- Use separate service keys for DEV / QA / PROD environments
