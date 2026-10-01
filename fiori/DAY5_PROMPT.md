# Day 5 - Fiori Elements App

/build-feature create-fiori-app

Using the sap-fiori skill, create a Fiori Elements List Report + Object Page app.

Using SAP Business Application Studio Fiori generator:
  - Template: List Report Object Page
  - Data source: BTP ABAP environment system
  - OData V4 service: ZSO_SB_REQ_H
  - Main entity: SalesOrderRequest
  - Module name: salesorderapproval
  - Namespace: com.company
  - Title: Sales Order Approval

List Report configuration (all via @UI annotations on ZSO_C_REQ_H):
  - Filters: Status (pos 10), CustomerId (pos 20), RequestDate (pos 30)
  - Columns: RequestId, CustomerId, RequestDate, TotalAmount (with currency), Status (with criticality)
  - Toolbar actions: Submit, Approve, Reject, Resubmit (feature-controlled by BDEF)

Object Page configuration:
  - headerInfo: typeName Sales Order Request, title from RequestId, description from Status
  - Facets:
    * General Information (IDENTIFICATION_REFERENCE, pos 10)
    * Items (LINEITEM_REFERENCE targeting _Items, pos 20)
    * Approval Details (IDENTIFICATION_REFERENCE, pos 30)
  - Identification fields: RequestId, CustomerId, RequestDate, TotalAmount, Status
  - Approval Details: Approver, RejectionReason
  - Action buttons visible based on BDEF feature control

Ensure draft support (minUI5Version 1.84.0, routerClass sap.fe.core.AppComponent).
minUI5Version: 1.84.0
