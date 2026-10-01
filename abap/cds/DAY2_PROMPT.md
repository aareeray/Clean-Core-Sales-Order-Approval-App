# Day 2 - CDS View Entities

/build-feature create-cds-views

Using the sap-cds skill, create three CDS view entities:

1. ZSO_R_REQ_H  - Interface view (header), select from ZSO_REQ_H
   - Composition to ZSO_R_REQ_I
   - @AccessControl.authorizationCheck: #CHECK
   - All semantics annotations on amount/timestamp/user fields

2. ZSO_R_REQ_I  - Interface view (items), select from ZSO_REQ_I
   - Association to parent ZSO_R_REQ_H
   - @AccessControl.authorizationCheck: #INHERITED

3. ZSO_C_REQ_H  - Projection view with UI annotations
   - provider contract transactional_query
   - @UI.headerInfo, @UI.lineItem, @UI.selectionField, @UI.identification, @UI.facet
   - @UI.hidden for status-based action visibility
   - Value helps for CustomerId and Status
   - Criticality case expression for Status field
   - Redirect associations to ZSO_C_REQ_I

Also create ZSO_C_REQ_I - Projection view for items.

All objects in package Z_SALES_APPROVAL. Assign to transport request.
Use ONLY CDS view entity syntax - never define view.
