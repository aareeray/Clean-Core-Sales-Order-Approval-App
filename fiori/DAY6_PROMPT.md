# Day 6 - Approval Workflow (SAP Build Process Automation)

/build-feature create-approval-workflow

Using the SAP_WORKFLOW_ARCHITECT agent, design the approval workflow:

Trigger: RAP action "submit" is called on SalesOrderRequest
  - The submit action sets Status = PENDING and sets Approver field
  - The SBPA workflow is triggered via an event or API call after submit

Workflow logic:
  Step 1: Read TotalAmount from context
    - If TotalAmount < 10,000: route to Manager role (APPROVER_MANAGER)
    - If TotalAmount >= 10,000: route to Director role (APPROVER_DIRECTOR)

  Step 2: Approver decision (My Inbox task)
    - Approve -> call OData V4 action /SalesOrderRequest(<key>)/approve
               -> Status becomes APPROVED
               -> Notify requester via email
    - Reject  -> capture rejection reason in form
              -> call OData V4 action /SalesOrderRequest(<key>)/reject with RejectionReason parameter
              -> Status becomes REJECTED
              -> Notify requester via email with reason

  Step 3: If rejected, requester can resubmit (triggers new workflow instance)

Deliver:
  1. SBPA workflow definition (JSON or description of trigger + steps + context mapping)
  2. API connection config: OData V4 endpoint URL, authentication method (OAuth2)
  3. Context mapping: how RequestId, TotalAmount, Approver map to workflow context
  4. My Inbox task form fields: Approve/Reject buttons, RejectionReason textarea
  5. Email notification template content
