# Enterprise Interview & 5-Minute Portfolio Demonstration Guide

## 1. 5-Minute High-Impact Demonstration Script

Use this script during technical interviews, portfolio walkthroughs, or stakeholder presentations.

---

### Minute 0:00 – 0:45 | The Business Context & Clean Core Challenge
> *"In traditional SAP environments, custom approval processes were notorious for breaking standard code — developers wrote user exits in `MV45AFZZ` or directly mutated standard sales order tables. When upgrading to S/4HANA, these modifications became massive technical debt.*
> 
> *Today, I want to show you how I built an enterprise-grade Sales Order Approval system that is **100% Clean Core compliant**, using the ABAP RESTful Application Programming Model (RAP), modern CDS View Entities, OData V4, and Fiori Elements."*

---

### Minute 0:45 – 1:30 | Creating a Draft & Validation Safeguards
> *(Navigate to the List Report screen, click **+ Create**)*
> 
> *"Here in the Fiori Elements application, the user creates a new sales order draft. 
> Notice that when I enter a customer and line items, RAP automatically triggers our managed determinations — calculating line item net amounts and total order values on the fly.*
> 
> *If I try to enter a negative quantity or miss a mandatory field, our server-side validations immediately raise localized `%msg` errors. Because this is RAP Managed with Draft, the user's working state is safely preserved without polluting the active database tables."*

---

### Minute 1:30 – 2:30 | Approval Simulation & Configurable Routing
> *(Open the Approval Simulation tool)*
> 
> *"Before submitting, a sales representative wants to know: 'Who will need to approve this 65,000 EUR order?'*
> 
> *Rather than hard-coding thresholds like `IF Amount > 10,000 THEN Director`, we designed a dynamic configuration table and a centralized domain engine: `ZCL_SO_ROUTING_ENGINE`.*
> 
> *When I click **Simulate Approval**, the engine evaluates our live routing matrix in memory. It immediately informs the user that this order requires Level 1 Director approval with a 72-hour SLA — **with zero database persistence and zero workflow noise**.*
> 
> *This exact same engine powers the live submission, guaranteeing a **Single Source of Truth**."*

---

### Minute 2:30 – 3:30 | Submission, SLA Monitoring & Audit Trail
> *(Click **Submit** on the order)*
> 
> *"When I click **Submit**, the order transitions from `DRAFT` to `PENDING`.
> Notice three things that happen simultaneously:
> 1. **Approver Assignment**: The routing engine assigns `DIR_SCHMIDT`.
> 2. **SLA Calculation**: An approval due date is calculated, setting the SLA status to `ON_TRACK`.
> 3. **Append-Only History**: If we scroll to the **Approval History** section on the Object Page, you see Step 1 permanently logged with timestamp, user, role, and initial status.*
> 
> *Every single transition is immutable and audit-compliant."*

---

### Minute 3:30 – 4:15 | Approver Review, Rejection Dialog & Escalation
> *(Switch user role to Approver / Director)*
> 
> *"Now logging in as Director `DIR_SCHMIDT`. Notice that our feature control and instance authorization now enable the **Approve**, **Reject**, and **Escalate** actions.*
> 
> *If the approver clicks **Reject**, an action parameter dialog appears requiring a mandatory rejection reason. Once confirmed, the order moves to `REJECTED`, the SLA completes, and the reason is recorded directly in the audit history.*
> 
> *Furthermore, if an order sits pending past its due date, either an authorized manager or our SAP Build Process Automation timer triggers the `escalate` action, advancing the order to senior leadership with full audit logging."*

---

### Minute 4:15 – 5:00 | Operational Cockpit & Clean Core Summary
> *(Navigate to the Operational Cockpit / Analytics tab)*
> 
> *"Finally, for operational leadership, we have an **Operational Cockpit** powered by real-time analytical CDS view entities. Leaders can immediately see pending bottlenecks, average approval turnaround times, and SLA breach volumes.*
> 
> *To summarize: this application achieves zero standard modifications, runs on released SAP APIs, isolates business rules from code, and provides full automated test coverage across 30 ABAP Unit test methods."*

---

## 2. "Why This Architecture?" — Deep-Dive Interview Answers

When asked technical follow-up questions, use these concise architectural justifications:

### Q1: Why RAP (RESTful Application Programming Model)?
- **Answer**: RAP is the strategic, standard programming model for ABAP Cloud. It delivers native draft capabilities, transactional integrity (managed LUW), built-in OData V4 protocol support, and automatic feature control with standard SAP runtime efficiency.

### Q2: Why Fiori Elements instead of Freestyle SAPUI5?
- **Answer**: Clean Core extends to UI development. Fiori Elements delivers 80% of enterprise UI requirements via CDS `@UI` metadata annotations. This ensures consistent UX, automatic responsiveness across devices, automatic accessibility compliance, and zero custom JavaScript maintenance when SAP upgrades design themes (e.g. from Quartz to Horizon).

### Q3: Why CDS Data Control Language (DCL)?
- **Answer**: DCL enforces row-level instance security at the database kernel level by automatically injecting SQL `WHERE` clauses (`CreatedBy = $user` or `Approver = $user`). This eliminates the risk of memory-level data leakage and prevents developers from forgetting authorization checks in custom reports.

### Q4: Why externalize the workflow to SAP Build Process Automation?
- **Answer**: Long-running asynchronous workflows, human approvals, email distributions, and boundary timers should not run as polling loops or long-lived database locks inside the ABAP transactional layer. Externalizing orchestration to SBPA keeps the core clean and scalable.

### Q5: Why separate the Approval History into an append-only entity?
- **Answer**: Overwriting status and approver fields on a single header table violates SOX and financial audit standards. An append-only child table (`ZSO_APPR_HIST`) provides an immutable, chronological timeline of every transition, actor, comment, and escalation.

### Q6: Why share the routing engine between live approval and simulation?
- **Answer**: Having a single source of truth (`ZCL_SO_ROUTING_ENGINE`) ensures that the simulation preview seen by a sales rep is 100% mathematically and logically identical to what the backend RAP BO will execute upon submission, eliminating rule divergence bugs.
