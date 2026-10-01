# Current State Assessment — Clean-Core Sales Order Approval App

## 1. Executive Summary

This document captures the current baseline state of the **Clean-Core Sales Order Approval Application** prior to enterprise-grade enhancements. The application was built as a modern ABAP Cloud RAP (RESTful Application Programming) Business Object with draft capabilities, exposed via OData V4 to an SAP Fiori Elements List Report and Object Page frontend, accompanied by SAP Build Process Automation (SBPA) workflow specifications and CDS DCL security roles.

While the existing system demonstrates valid ABAP Cloud syntax and RAP patterns, it currently functions as a **demonstration prototype**. This assessment catalogues the existing architecture, identifies architectural limitations and technical debt, and establishes the baseline for enterprise hardening.

---

## 2. Current Architecture Diagram

```mermaid
graph TD
    subgraph UI ["User Interface Layer"]
        FE["SAP Fiori Elements (V4)<br/>com.company.salesorderapproval"]
        FLP["SAP Launchpad Sandbox / Work Zone"]
        FE --> FLP
    end

    subgraph ServiceLayer ["Service Exposure Layer"]
        SB["Service Binding (OData V4 - UI)<br/>ZSO_SB_REQ_H"]
        SD["Service Definition<br/>ZSO_SD_REQ_H"]
        FE -->|OData V4 HTTP| SB
        SB --> SD
    end

    subgraph CDS ["CDS View Entity Layer"]
        C_H["Projection View (Header)<br/>ZSO_C_REQ_H"]
        C_I["Projection View (Items)<br/>ZSO_C_REQ_I"]
        R_H["Interface View (Header)<br/>ZSO_R_REQ_H"]
        R_I["Interface View (Items)<br/>ZSO_R_REQ_I"]
        VH_S["Value Help (Status)<br/>ZSO_VH_STATUS"]
        VH_C["Value Help (Customer)<br/>ZSO_VH_CUSTOMER"]

        SD --> C_H
        SD --> C_I
        SD --> VH_S
        SD --> VH_C
        C_H -->|Projects| R_H
        C_I -->|Projects| R_I
        R_H -->|Composition [1..*]| R_I
        R_I -->|Association to Parent| R_H
    end

    subgraph RAP ["RAP Business Object Layer"]
        BDEF["Behavior Definition<br/>ZSO_R_REQ_H (Managed with Draft, strict 2)"]
        BIMP["Behavior Implementation Class<br/>ZSO_BP_REQ_H"]
        BDEF -.-> BIMP
        R_H -.-> BDEF
    end

    subgraph Security ["Authorization Layer (DCL)"]
        DCL_H["DCL Access Control<br/>ZSO_R_REQ_H.dcl"]
        DCL_I["DCL Access Control<br/>ZSO_R_REQ_I.dcl"]
        AO["Authorization Object<br/>ZSO_APPROVAL"]
        DCL_H --> AO
        DCL_I --> DCL_H
    end

    subgraph Persistence ["Persistence Layer (SAP HANA Cloud)"]
        TAB_H[("Header Table<br/>ZSO_REQ_H")]
        TAB_I[("Item Table<br/>ZSO_REQ_I")]
        DRAFT_H[("Draft Header Table<br/>ZSO_DREQ_H")]
        DRAFT_I[("Draft Item Table<br/>ZSO_DREQ_I")]

        R_H --> TAB_H
        R_I --> TAB_I
        BDEF --> DRAFT_H
        BDEF --> DRAFT_I
    end

    subgraph Workflow ["Process Layer (SBPA)"]
        SBPA["SAP Build Process Automation<br/>WORKFLOW_DEFINITION.json"]
        BIMP -.->|Additional Save Trigger| SBPA
    end
```

---

## 3. Inventory of Existing Artifacts

### 3.1 Persistence Model (`abap/tables/src/`)
- **`ZSO_D_STATUS.ddls.asddls`**: Domain defining allowed status values (`DRAFT`, `PENDING`, `APPROVED`, `REJECTED`).
- **`ZSO_E_REQUEST_ID.dtel.asdtel`**, **`ZSO_E_STATUS.dtel.asdtel`**, **`ZSO_E_TOTAL_AMT.dtel.asdtel`**: ABAP Data Elements.
- **`ZSO_REQ_H.tabl.asdbtab`**: Header transparent table storing `request_id` (sysuuid_x16), `customer_id`, `request_date`, `total_amount`, `currency`, `status`, `approver`, `rejection_reason`, and admin fields (`created_by`, `created_at`, `changed_by`, `changed_at`).
- **`ZSO_REQ_I.tabl.asdbtab`**: Item table with composite key (`request_id`, `item_no`), `material`, `quantity`, `unit`, `unit_price`, `net_amount`, `currency`.
- **`ZSO_DREQ_H.tabl.asdbtab`** & **`ZSO_DREQ_I.tabl.asdbtab`**: Draft tables including administrative draft include `sych_bdl_draft_admin_inc`.

### 3.2 CDS View Hierarchy (`abap/cds/src/`)
- **`ZSO_R_REQ_H`**: Header interface CDS view entity (`@AccessControl.authorizationCheck: #CHECK`), composition to `ZSO_R_REQ_I`.
- **`ZSO_R_REQ_I`**: Item interface CDS view entity (`@AccessControl.authorizationCheck: #INHERITED`), association to parent `ZSO_R_REQ_H`.
- **`ZSO_VH_STATUS`**: Value help view selecting fixed values from domain `ZSO_D_STATUS`.
- **`ZSO_VH_CUSTOMER`**: Value help view projecting SAP released CDS view `I_Customer`.
- **`ZSO_C_REQ_H`**: Header projection view (`provider contract transactional_query`) with rich `@UI` annotations (`@UI.headerInfo`, `@UI.lineItem`, `@UI.selectionField`, `@UI.identification`, `@UI.facet`), Status criticality case expression (`0=Draft, 1=Rejected, 2=Pending, 3=Approved`), and redirected associations.
- **`ZSO_C_REQ_I`**: Item projection view with `@UI.lineItem` annotations.

### 3.3 RAP Business Object (`abap/rap/src/`)
- **`ZSO_P_REJECT.ddls.asddls`**: Abstract entity for action parameter (`RejectionReason : abap.char(255)`).
- **`ZSO_R_REQ_H.bdef.asbdef`**:
  - `managed implementation in class ZSO_BP_REQ_H unique; strict ( 2 ); with draft;`
  - ETag master `ChangedAt`, lock master `total etag ChangedAt`.
  - CRUD operations: `create`, `update`, `delete`.
  - Draft actions: `Edit`, `Activate optimized`, `Discard`, `Resume`, `Prepare`.
  - Custom actions: `submit`, `approve`, `reject` (parameter `ZSO_P_REJECT`), `resubmit`.
  - Validations: `validateCustomer`, `validateAmount`, `validateRejectionReason`.
  - Determinations: `setInitialStatus`, `calculateTotalAmount`, `setChangedAt`.
  - Additional Save hook declared (`with additional save`).
- **`ZSO_BP_REQ_H.clas.abap`** & **`locals_imp.abap`**:
  - Feature control: `get_instance_features` dynamically enables/disables buttons based on `Status`.
  - Instance authorization: `get_instance_authorizations` checks `CreatedBy` and `Approver` against `sy-uname`.
  - Action implementations: `submit`, `approve`, `reject`, `resubmit`.
  - Determinations and validations implementation.
  - Save modified hook: externalizes workflow trigger via HTTP call.

### 3.4 Service Layer (`abap/rap/src/service/`)
- **`ZSO_SD_REQ_H.srvd.asdsrvd`**: Service definition exposing `SalesOrderRequest`, `SalesOrderItem`, `StatusValueHelp`, and `CustomerValueHelp`.
- **`ZSO_SB_REQ_H.srvb.json`**: Service binding configuration for `OData V4 - UI`.

### 3.5 Security & Authorization (`abap/dcl/src/`)
- **`ZSO_R_REQ_H.dcl.asdcls`**: Instance authorization with three conditional roles (`REQUESTER`, `APPROVER`, `ADMIN`) mapped to authorization object `ZSO_APPROVAL` (`ACTVT`, `STATUS`, `CUSTOMER_ID`).
- **`ZSO_R_REQ_I.dcl.asdcls`**: Inherited authorization from header.
- **`IAM_SETUP_GUIDE.md`**: Guide for business catalogs `ZSO_BC_REQUESTER`, `ZSO_BC_APPROVER`, `ZSO_BC_ADMIN`.

### 3.6 Frontend Application (`fiori/salesorderapproval/`)
- SAP Fiori Elements List Report and Object Page (`manifest.json`, `Component.js`, `xs-app.json`, `ui5.yaml`).
- Interactive local preview environment with zero external dependencies (`preview-server.js`, `mock-data.json`, `preview/index.html`).

### 3.7 Automated Tests (`abap/rap/src/tests/`)
- **`ZSO_TEST_REQ_H.clas.testclasses.abap`**: 15 ABAP Unit test methods using `cl_abap_behv_test_environment` and `cl_abap_unit_assert`.

---

## 4. Current Limitations & Technical Debt

| Area | Current Implementation | Enterprise Limitation | Risk / Impact |
|---|---|---|---|
| **Approval Routing** | Hard-coded `IF TotalAmount >= 10000 THEN 'DIRECTOR' ELSE 'MANAGER'` in `submit` action. | Hard-coded business logic requires code modification, testing, and transport request for every business policy change. | High: Business cannot adjust approval tiers, delegations, or multi-level approvals without developer intervention. |
| **Audit Trail / History** | Only current `Status`, `Approver`, and `RejectionReason` stored on `ZSO_REQ_H`. Prior statuses are overwritten. | No historical log of transitions, who approved when, what comments were entered, or intermediate steps. | Critical: Fails SOX, ISO 27001, and corporate audit compliance requirements. |
| **SLA & Escalation** | No due dates, no breach detection, no escalation logic. | Approvals can stall indefinitely in `PENDING` without alerts or manager escalation. | High: Orders get delayed, impacting customer delivery and sales cycles. |
| **Fiori UX Details** | List report lacks filter/column for SLA, approver, or date ranges. Object page has only General Info and Items. | Incomplete operational visibility; approvers cannot prioritize urgent orders. | Medium: Poor user experience for high-volume approvers. |
| **Operational Analytics** | No analytical CDS views, cubes, or aggregation queries. | Executives have no dashboard to monitor bottlenecks, average approval durations, or rejection patterns. | Medium: Lack of operational intelligence. |
| **Approval Simulation** | No mechanism to pre-calculate approval requirements prior to submission. | Requesters cannot know who will need to approve their order until after they submit it. | Medium: Surprise rejections or delays. |
| **Authorization Rigor** | Positive tests exist; negative tests for authorization and security bypass are missing. | Server-side enforcement not validated against hostile payload manipulation. | High: Potential security loopholes. |
| **Concurrency Safeguards** | ETag exists on `ChangedAt`, but multi-user conflict scenarios and idempotent transition guarantees are untested. | Risk of race conditions during simultaneous approvals. | Medium: Inconsistent state. |

---

## 5. Architectural Upgrade Roadmap

To transition this application to enterprise-grade production, the following enhancements are mapped to the existing codebase:

1. **Configurable Approval Matrix**: Create configuration table `ZSO_APPR_RULE`, CDS view entity `ZSO_I_APPR_RULE`, and reusable domain engine `ZCL_SO_ROUTING_ENGINE`.
2. **Approval Audit History**: Create append-only table `ZSO_APPR_HIST`, CDS entity `ZSO_R_REQ_HIST`, compose into `ZSO_R_REQ_H`, and expose on Object Page.
3. **SLA Management**: Add SLA fields to `ZSO_REQ_H` / `ZSO_R_REQ_H`, implement SLA determination and escalation action in BDEF.
4. **Fiori Elements Enhancement**: Upgrade `ZSO_C_REQ_H` with SLA criticality, history facet, side effects, and enhanced filter/column sets.
5. **Analytical Cockpit**: Create CDS analytical view `ZSO_I_REQ_ANALYTICS` and operational metrics query.
6. **Approval Simulation**: Expose unbound/RAP simulation function powered by the single-source-of-truth routing engine.
7. **Negative & Concurrency Unit Testing**: Expand `ZSO_TEST_REQ_H` with comprehensive negative assertions, authorization bypass tests, and concurrency validations.
