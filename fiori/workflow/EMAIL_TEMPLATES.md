# Email Notification Templates

Configure these in SBPA → Settings → Email Templates.
Context variables use `${variable}` syntax — SBPA resolves them at runtime.

---

## Template 1: Submission Confirmation (to Requester)

**Template ID**: `email_template_submitted`  
**Trigger**: Send from `save_modified` ABAP code immediately after workflow is started  
*(Or configure as a notification step at the very start of the SBPA process)*

**Subject**:
```
[Sales Order Approval] Request ${requestId} submitted — Awaiting Approval
```

**Body (HTML)**:
```html
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto;">
  <div style="background: #0070f2; padding: 20px; border-radius: 4px 4px 0 0;">
    <h2 style="color: white; margin: 0;">Sales Order Request Submitted</h2>
  </div>
  <div style="padding: 24px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 4px 4px;">
    <p>Dear ${requesterName},</p>
    <p>Your Sales Order Request has been submitted and is now pending approval.</p>

    <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
      <tr style="background: #f5f5f5;">
        <td style="padding: 8px 12px; font-weight: bold; width: 40%;">Request ID</td>
        <td style="padding: 8px 12px;">${requestId}</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; font-weight: bold;">Customer</td>
        <td style="padding: 8px 12px;">${customerId}</td>
      </tr>
      <tr style="background: #f5f5f5;">
        <td style="padding: 8px 12px; font-weight: bold;">Request Date</td>
        <td style="padding: 8px 12px;">${requestDate}</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; font-weight: bold;">Total Amount</td>
        <td style="padding: 8px 12px; font-weight: bold; color: #0070f2;">${totalAmount} ${currency}</td>
      </tr>
      <tr style="background: #f5f5f5;">
        <td style="padding: 8px 12px; font-weight: bold;">Status</td>
        <td style="padding: 8px 12px;"><span style="background: #e8f4fd; color: #0070f2; padding: 2px 8px; border-radius: 12px;">Pending Approval</span></td>
      </tr>
    </table>

    <p>You will receive another email once a decision has been made.</p>
    <p style="color: #666; font-size: 12px; margin-top: 24px;">
      This is an automated notification from the Sales Order Approval system.
    </p>
  </div>
</body>
</html>
```

---

## Template 2: Approved Notification (to Requester)

**Template ID**: `email_template_approved`  
**Trigger**: SBPA notification step after `step_call_approve_api` succeeds

**Subject**:
```
[Sales Order Approval] ✅ Request ${requestId} has been APPROVED
```

**Body (HTML)**:
```html
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto;">
  <div style="background: #107e3e; padding: 20px; border-radius: 4px 4px 0 0;">
    <h2 style="color: white; margin: 0;">✅ Sales Order Request Approved</h2>
  </div>
  <div style="padding: 24px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 4px 4px;">
    <p>Dear ${requesterName},</p>
    <p>Great news! Your Sales Order Request has been <strong style="color: #107e3e;">approved</strong>.</p>

    <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
      <tr style="background: #f5f5f5;">
        <td style="padding: 8px 12px; font-weight: bold; width: 40%;">Request ID</td>
        <td style="padding: 8px 12px;">${requestId}</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; font-weight: bold;">Customer</td>
        <td style="padding: 8px 12px;">${customerId}</td>
      </tr>
      <tr style="background: #f5f5f5;">
        <td style="padding: 8px 12px; font-weight: bold;">Total Amount</td>
        <td style="padding: 8px 12px; font-weight: bold;">${totalAmount} ${currency}</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; font-weight: bold;">Status</td>
        <td style="padding: 8px 12px;"><span style="background: #f1fdf6; color: #107e3e; padding: 2px 8px; border-radius: 12px; font-weight: bold;">✅ Approved</span></td>
      </tr>
    </table>

    <p style="color: #666; font-size: 12px; margin-top: 24px;">
      This is an automated notification from the Sales Order Approval system.
    </p>
  </div>
</body>
</html>
```

---

## Template 3: Rejected Notification (to Requester)

**Template ID**: `email_template_rejected`  
**Trigger**: SBPA notification step after `step_call_reject_api` succeeds

**Subject**:
```
[Sales Order Approval] ❌ Request ${requestId} has been REJECTED — Action Required
```

**Body (HTML)**:
```html
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto;">
  <div style="background: #bb0000; padding: 20px; border-radius: 4px 4px 0 0;">
    <h2 style="color: white; margin: 0;">❌ Sales Order Request Rejected</h2>
  </div>
  <div style="padding: 24px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 4px 4px;">
    <p>Dear ${requesterName},</p>
    <p>Unfortunately, your Sales Order Request has been <strong style="color: #bb0000;">rejected</strong>.</p>

    <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
      <tr style="background: #f5f5f5;">
        <td style="padding: 8px 12px; font-weight: bold; width: 40%;">Request ID</td>
        <td style="padding: 8px 12px;">${requestId}</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; font-weight: bold;">Customer</td>
        <td style="padding: 8px 12px;">${customerId}</td>
      </tr>
      <tr style="background: #f5f5f5;">
        <td style="padding: 8px 12px; font-weight: bold;">Total Amount</td>
        <td style="padding: 8px 12px;">${totalAmount} ${currency}</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; font-weight: bold;">Status</td>
        <td style="padding: 8px 12px;"><span style="background: #fff0f0; color: #bb0000; padding: 2px 8px; border-radius: 12px; font-weight: bold;">❌ Rejected</span></td>
      </tr>
    </table>

    <div style="background: #fff8f0; border-left: 4px solid #e9730c; padding: 12px 16px; margin: 16px 0; border-radius: 0 4px 4px 0;">
      <p style="margin: 0; font-weight: bold; color: #e9730c;">Rejection Reason:</p>
      <p style="margin: 8px 0 0 0;">${rejectionReason}</p>
    </div>

    <p><strong>What to do next:</strong></p>
    <ol>
      <li>Review the rejection reason above</li>
      <li>Open the Sales Order Approval app</li>
      <li>Find request <strong>${requestId}</strong></li>
      <li>Click <strong>"Resubmit"</strong> to revise and resubmit</li>
    </ol>

    <p style="color: #666; font-size: 12px; margin-top: 24px;">
      This is an automated notification from the Sales Order Approval system.
    </p>
  </div>
</body>
</html>
```
