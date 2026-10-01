# Centralized Notification Design & Delivery Architecture

## 1. Overview & Business Intent

Generic notifications (e.g. *"Your sales order was updated"*) frustrate business users, increase mean time to resolution, and lead to missed SLAs. 

The **Clean-Core Sales Order Approval App** employs a **centralized notification service** that constructs context-rich, actionable messages delivered via **SAP Fiori Launchpad Notifications**, email, and mobile push (SAP Mobile Start).

---

## 2. Notification Dispatch Matrix

| Scenario # | Event / Trigger | Recipient | Delivery Channels | Required Action |
|---|---|---|---|---|
| **1. Request Submitted** | Action `submit` | Requester | In-App, Email | Informational: Confirmation of submission with expected SLA turnaround. |
| **2. Approval Assigned** | Routing Engine resolution | Designated Approver (Manager / Director) | In-App, Email, My Inbox | **Action Required**: Review order details and approve or reject before SLA due date. |
| **3. Request Approved** | Action `approve` | Requester | In-App, Email | Informational: Order approved; automatic fulfillment initiated. |
| **4. Request Rejected** | Action `reject` | Requester | In-App, Email | **Action Required**: Review rejection reason; modify order items and resubmit. |
| **5. SLA Due Soon / Breached** | SLA Engine (< 24h or expired) | Current Approver + Approver Manager | In-App High-Priority, Push | **Urgent Action**: Immediate sign-off required to avoid executive escalation. |
| **6. Request Escalated** | Action `escalate` | Senior Approver (Director) | In-App Critical, Email | **Escalated Action**: Request escalated from subordinate due to SLA breach. |
| **7. Final Order Released** | ERP Core Release | Requester, Logistics Lead | In-App | Informational: S/4HANA Sales Order document created. |

---

## 3. Standardized Business Notification Template

Every notification payload strictly includes:
1. **Clear Semantic Header**: Identifies the exact order ID and customer.
2. **Key Financial Metrics**: Total order amount and currency.
3. **Urgency & Due Date**: Remaining SLA hours and hard deadline date.
4. **Actionable Deeplink**: Direct URL opening the Fiori Object Page with pre-filtered intent.

### Concrete Example: Approval Assigned Notification

```markdown
Title: Action Required: Sales Order Approval Request SO-2026-0001 (Acme Industrial Corp)
Priority: High
Due Date: 30-Sep-2026 17:00 UTC

Dear Approver,

Sales Order Request SO-2026-0001 for Acme Industrial Corp (CUST-1001) in the amount of 
14,500.00 EUR has been submitted by JSMITH and assigned to your queue for Level 01 approval.

Summary of Order:
- Total Amount: 14,500.00 EUR (2 Line Items)
- Key Materials: Heavy Duty Industrial Pump, High Pressure Safety Valve
- SLA Target: 48 Hours (Due by: 30-Sep-2026)

Please review and make a determination:
👉 [Open Sales Order Approval in Fiori Launchpad](#SalesOrderApproval-display?RequestId=SO-2026-0001)
```

### Concrete Example: Rejection Notification (with Mandatory Reason)

```markdown
Title: Update: Sales Order Request SO-2026-0003 REJECTED by Director
Priority: Normal

Dear Requester,

Your Sales Order Request SO-2026-0003 for Nordic Marine Logistics (Amount: 65,000.00 EUR) 
was reviewed and REJECTED by Director DIR_SCHMIDT on 30-Sep-2026 16:45 UTC.

Rejection Reason Provided:
"Exceeds quarterly discretionary budget for non-contracted client. Reapply under formal vendor contract."

Next Steps:
You may edit the line items and resubmit the request:
👉 [Modify and Resubmit Request SO-2026-0003](#SalesOrderApproval-display?RequestId=SO-2026-0003)
```

---

## 4. Centralized Factory Pattern: `ZCL_SO_NOTIFICATION_FACTORY`

To prevent copy-paste duplication across RAP actions, workflow scripts, and event handlers:
- A single domain utility class formats templates, handles internationalized text substitution via message classes, and constructs secure deeplinks using semantic objects (`SalesOrderApproval-display`).
- The dispatch layer uses the standard released SAP BTP Destination service or `cl_bcs_mail_message` without direct dependence on low-level mail servers.
