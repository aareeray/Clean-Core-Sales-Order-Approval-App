# Workflow Context Mapping

## ABAP → SBPA (Trigger Payload)

Maps ABAP RAP entity fields to SBPA workflow context variables.

| SBPA Context Variable | Source in ABAP | Type | Example |
|---|---|---|---|
| `requestId` | `ls_req-RequestId` (sysuuid_x16 → string) | string | `"550e8400-e29b-41d4-a716-446655440000"` |
| `customerId` | `ls_req-CustomerId` | string | `"CUST001"` |
| `requestDate` | `ls_req-RequestDate` (dats → ISO 8601) | string | `"2026-10-01"` |
| `totalAmount` | `ls_req-TotalAmount` (curr → number) | number | `12500.00` |
| `currency` | `ls_req-Currency` | string | `"EUR"` |
| `requesterEmail` | Resolved from `sy-uname` via released API | string | `"john.doe@company.com"` |
| `requesterName` | Resolved from `sy-uname` via released API | string | `"John Doe"` |
| `serviceUrl` | Hardcoded constant (Communication Arrangement) | string | `"https://<host>/sap/opu/odata4/..."` |

### UUID Conversion (ABAP → String)

```abap
" sysuuid_x16 → standard GUID string for SBPA context
DATA(lv_guid_str) = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ).
" OR convert raw UUID to display format:
DATA(lv_uuid_display) = |{ ls_req-RequestId STYLE = GUID_WITH_DASHES }|.
```

### Date Conversion (ABAP dats → ISO 8601)

```abap
" abap.dats '20261001' → '2026-10-01'
DATA(lv_date_iso) = |{ ls_req-RequestDate DATE = ISO }|.
```

### Amount Conversion (ABAP curr → JSON number)

```abap
" No conversion needed — ABAP curr maps cleanly to JSON number.
" Use CONV decfloat34( ls_req-TotalAmount ) for safe JSON serialisation.
DATA(lv_amount) = CONV decfloat34( ls_req-TotalAmount ).
```

### User → Email Resolution

```abap
" Use released API to get user email from username
DATA(lo_user) = cl_abap_user_attributes=>get_instance( sy-uname ).
DATA(lv_email) = lo_user->get_email( ).
DATA(lv_display_name) = lo_user->get_display_name( ).
```

---

## SBPA → ABAP (OData V4 Action URLs)

### approve action

```
POST {serviceUrl}SalesOrderRequest(RequestId={requestId},IsActiveEntity=true)/ZSO_SD_REQ_H.approve
Content-Type: application/json
Body: {}
```

### reject action

```
POST {serviceUrl}SalesOrderRequest(RequestId={requestId},IsActiveEntity=true)/ZSO_SD_REQ_H.reject
Content-Type: application/json
Body: { "RejectionReason": "{rejectionReason}" }
```

> **Important**: `IsActiveEntity=true` — SBPA calls the active (non-draft) entity.
> The request must be activated (Draft → Active) before the workflow can call approve/reject.
> The `submit` RAP action should call `draft activate` before triggering the workflow.

---

## SBPA Internal Context Flow

```
Trigger payload received
    ↓
context.requestId      = "550e8400-..."
context.totalAmount    = 12500.00
context.currency       = "EUR"
context.requesterEmail = "john.doe@company.com"
    ↓
Gateway: totalAmount >= 10000 → branch_director
    ↓
Director task opened in My Inbox
Approver fills form:
  decision         = "REJECTED"
  rejectionReason  = "Budget exceeded for Q4"
    ↓
context.approverDecision = "REJECTED"
context.rejectionReason  = "Budget exceeded for Q4"
    ↓
Service task calls:
POST .../reject
Body: { "RejectionReason": "Budget exceeded for Q4" }
    ↓
ABAP RAP: Status = REJECTED, RejectionReason saved
    ↓
Email sent to john.doe@company.com
```

---

## My Inbox Form Context Variables (Read-Only Display)

These context variables are displayed in the My Inbox task form as read-only info:

| Form Field | Context Variable | Format |
|---|---|---|
| Request ID | `${requestId}` | UUID string |
| Customer | `${customerId}` | String |
| Request Date | `${requestDate}` | ISO date |
| Total Amount | `${totalAmount} ${currency}` | e.g. "12,500.00 EUR" |
| Submitted By | `${requesterName}` | Display name |

---

## Resubmit Flow (New Workflow Instance)

When a requester resubmits after rejection:
1. Requester calls `resubmit` RAP action → Status = DRAFT, Approver cleared
2. Requester edits the request → calls `submit` again
3. `submit` → Status = PENDING → `save_modified` fires → **new workflow instance** created

Each submission creates an independent SBPA workflow instance.
There is no "resume" of the previous rejected instance — a fresh instance starts.
