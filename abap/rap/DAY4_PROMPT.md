# Day 4 - Service Definition and Binding

/build-feature create-service

Create the OData V4 service layer:

1. Service Definition: ZSO_SD_REQ_H
   - Expose ZSO_C_REQ_H as SalesOrderRequest
   - Expose ZSO_C_REQ_I as SalesOrderItem (via navigation)
   - Include all actions: submit, approve, reject, resubmit

2. Service Binding: ZSO_SB_REQ_H
   - Type: OData V4 - UI
   - Bound to ZSO_SD_REQ_H
   - Publish the service

3. After creation:
   - Activate the service binding
   - Test in ABAP environment service preview
   - Verify entity set SalesOrderRequest is accessible
   - Verify all 4 custom actions are listed
   - Verify draft-related operations work (POST to /SalesOrderRequest with Prefer: respond-async)

All objects in Z_SALES_APPROVAL. Assign to transport request.
