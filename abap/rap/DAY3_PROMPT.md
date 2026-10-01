# Day 3 - RAP Behavior Definition and Implementation

/build-feature create-rap-bo

Using the sap-rap-bo skill, create:

1. BDEF: ZSO_R_REQ_H
   - managed; strict(2); with draft;
   - Persistent table: ZSO_REQ_H, Draft table: ZSO_DREQ_H
   - etag master ChangedAt
   - authorization master (instance)
   - with additional save
   - Standard CUD + draft actions (Edit, Activate, Discard, Resume, Prepare)
   - Custom actions: submit, approve, reject (with parameter ZSO_P_REJECT), resubmit
   - Validations: validateCustomer, validateAmount, validateRejectionReason (on save)
   - Determinations: setInitialStatus, calculateTotalAmount, setChangedAt

2. Action parameter type: ZSO_P_REJECT
   - Field: RejectionReason CHAR 255

3. Behavior Implementation Class: ZSO_BP_REQ_H
   - Implement all validations with %msg error reporting
   - Implement all determinations with trigger conditions
   - Implement all 4 custom actions with status flow logic
   - Implement get_instance_features for feature control
   - Implement get_instance_authorizations for BDEF-level auth
   - Use %msg - never MESSAGE statement
   - Use READ ENTITIES IN LOCAL MODE inside implementations
   - Never COMMIT WORK inside BDEF class

4. Child BDEF: ZSO_R_REQ_I
   - lock dependent by _Header
   - authorization dependent by _Header

All objects in Z_SALES_APPROVAL. Assign to transport request.
