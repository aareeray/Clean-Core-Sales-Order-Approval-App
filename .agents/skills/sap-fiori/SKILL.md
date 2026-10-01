---
name: sap-fiori
description: >
  Skill for building SAP Fiori Elements List Report and Object Page apps
  using OData V4, CDS annotations, and SAP Business Application Studio
  generators. Covers the Sales Order Approval app UI layer.
---

# SAP Fiori Elements App Skill

## Overview

Use this skill when building or modifying the Fiori Elements frontend for the
Sales Order Approval app. All UI configuration is annotation-driven (no custom
controllers unless strictly necessary).

---

## App Descriptor (manifest.json) Template

`.json
{
  "_version": "1.59.0",
  "sap.app": {
    "id": "com.company.salesorderapproval",
    "type": "application",
    "title": "Sales Order Approval",
    "description": "Manage and approve sales order requests",
    "applicationVersion": { "version": "1.0.0" },
    "dataSources": {
      "mainService": {
        "uri": "/sap/opu/odata4/sap/zso_sb_req_h/srvd/sap/zso_sd_req_h/0001/",
        "type": "OData",
        "settings": { "odataVersion": "4.0" }
      }
    }
  },
  "sap.ui": {
    "technology": "UI5",
    "icons": { "icon": "sap-icon://sales-order" },
    "fullWidth": false
  },
  "sap.ui5": {
    "minUI5Version": "1.84.0",
    "dependencies": {
      "libs": {
        "sap.m":         {},
        "sap.ui.core":   {},
        "sap.fe.templates": {}
      }
    },
    "routing": {
      "config": { "routerClass": "sap.fe.core.AppComponent" },
      "routes": [
        {
          "name":    "SalesOrderRequestList",
          "pattern": "",
          "target":  "SalesOrderRequestList"
        },
        {
          "name":    "SalesOrderRequestObjectPage",
          "pattern": "SalesOrderRequest({key})",
          "target":  "SalesOrderRequestObjectPage"
        }
      ],
      "targets": {
        "SalesOrderRequestList": {
          "type":       "Component",
          "id":         "SalesOrderRequestList",
          "name":       "sap.fe.templates.ListReport",
          "options": {
            "settings": {
              "entitySet":              "SalesOrderRequest",
              "navigationSettings":     { "SalesOrderRequest": { "detail": { "route": "SalesOrderRequestObjectPage" } } },
              "initialLoad":            true,
              "filterSettings":         { "dateSettings": { "useDateRange": true } }
            }
          }
        },
        "SalesOrderRequestObjectPage": {
          "type": "Component",
          "id":   "SalesOrderRequestObjectPage",
          "name": "sap.fe.templates.ObjectPage",
          "options": {
            "settings": {
              "entitySet":              "SalesOrderRequest",
              "editableHeaderContent":  false,
              "showAnchorBar":          true
            }
          }
        }
      }
    }
  }
}
`

---

## List Report Configuration

### Required Filters (@UI.selectionField)

| Field        | Position | Label        |
|--------------|----------|--------------|
| Status       | 10       | Status       |
| CustomerId   | 20       | Customer     |
| RequestDate  | 30       | Request Date |

### Required Columns (@UI.lineItem)

| Field        | Position | Label        | Notes                       |
|--------------|----------|--------------|-----------------------------|
| RequestId    | 10       | Request ID   | Link to object page         |
| CustomerId   | 20       | Customer     |                             |
| RequestDate  | 30       | Request Date |                             |
| TotalAmount  | 40       | Total Amount | Show with currency          |
| Status       | 50       | Status       | With criticality color      |

### Toolbar Actions

| Action    | Type          | Label     | Visibility Condition     |
|-----------|---------------|-----------|--------------------------|
| Submit    | FOR_ACTION    | Submit    | Status = DRAFT           |
| Approve   | FOR_ACTION    | Approve   | Status = PENDING         |
| Reject    | FOR_ACTION    | Reject    | Status = PENDING         |
| Resubmit  | FOR_ACTION    | Resubmit  | Status = REJECTED        |

---

## Object Page Configuration

### Header (@UI.headerInfo)

`.cds
@UI.headerInfo: {
  typeName:       'Sales Order Request',
  typeNamePlural: 'Sales Order Requests',
  title:          { type: #STANDARD, value: 'RequestId' },
  description:    { type: #STANDARD, value: 'Status'    }
}
`

### Facets (@UI.facet)

| ID           | Type                       | Label              | Position |
|--------------|----------------------------|--------------------|----------|
| HeaderData   | #IDENTIFICATION_REFERENCE  | General Information| 10       |
| ItemsTable   | #LINEITEM_REFERENCE        | Items              | 20       |
| ApprovalData | #IDENTIFICATION_REFERENCE  | Approval Details   | 30       |

### General Information Section (@UI.identification)

| Field          | Position | Label           |
|----------------|----------|-----------------|
| RequestId      | 10       | Request ID      |
| CustomerId     | 20       | Customer ID     |
| RequestDate    | 30       | Request Date    |
| TotalAmount    | 40       | Total Amount    |
| Status         | 50       | Status          |

### Approval Details Section

| Field          | Position | Label            |
|----------------|----------|------------------|
| Approver       | 10       | Approver         |
| RejectionReason| 20       | Rejection Reason |

---

## Action Button Visibility Rules

Use feature control in the BDEF (`get_instance_features`) to enable/disable actions:

| Action    | Enabled When                       |
|-----------|------------------------------------|
| Submit    | Status = 'DRAFT'                   |
| Approve   | Status = 'PENDING'                 |
| Reject    | Status = 'PENDING'                 |
| Resubmit  | Status = 'REJECTED'                |

The Fiori Elements framework automatically shows/hides action buttons based on
`if_abap_behv=>fc-o-enabled` / `if_abap_behv=>fc-o-disabled` from the BDEF.

---

## Draft Editing Support

- The service binding must be type **OData V4 - UI** (not Web API).
- Draft is enabled in the BDEF with `with draft` and draft tables (`ZSO_DREQ_H`, `ZSO_DREQ_I`).
- Fiori Elements handles draft indicator, draft conflict detection, and activation automatically.
- Do NOT implement custom draft handling unless absolutely required.

---

## SAP Business Application Studio Generator Steps

1. Open BAS → New Project from Template → SAP Fiori Application
2. Template: **List Report Object Page**
3. Data source: **Connect to a System** → select BTP ABAP environment
4. Service: `ZSO_SB_REQ_H` (OData V4)
5. Main entity: `SalesOrderRequest`
6. Navigation entity: Leave default (items handled via facet)
7. Project attributes:
   - Module name: `salesorderapproval`
   - Namespace: `com.company`
   - Title: `Sales Order Approval`

---

## Key Rules

1. **OData V4 only** — do not use OData V2 for new development.
2. **All annotations on projection view** `ZSO_C_REQ_H` — not the interface view.
3. **Action buttons** controlled via BDEF feature control, not JavaScript.
4. **Draft support** is mandatory — this is a transactional Fiori app.
5. **Never hardcode** user/role checks in frontend; use BDEF feature control.
6. **Criticality** colors: 3=green (Approved), 2=yellow (Pending), 1=red (Rejected).
