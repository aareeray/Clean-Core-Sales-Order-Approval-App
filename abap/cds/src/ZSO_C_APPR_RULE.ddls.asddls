@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Approval Routing Rule - Admin Projection View'

@UI.headerInfo: {
  typeName:       'Approval Rule',
  typeNamePlural: 'Approval Routing Rules',
  title:          { type: #STANDARD, value: 'RuleId' },
  description:    { type: #STANDARD, value: 'ApproverRole' }
}

define view entity ZSO_C_APPR_RULE
  as projection on ZSO_I_APPR_RULE
{
      @UI.facet: [
        { id:            'RuleDetails',
          type:          #IDENTIFICATION_REFERENCE,
          label:         'Rule Configuration Details',
          position:      10 },
        { id:            'AuditDetails',
          type:          #FIELDGROUP_REFERENCE,
          label:         'Administrative Tracking',
          targetQualifier: 'AuditData',
          position:      20 }
      ]

      @UI.lineItem:        [{ position: 10, label: 'Rule ID' }]
      @UI.identification:  [{ position: 10, label: 'Rule ID' }]
  key RuleId,

      @UI.selectionField:  [{ position: 10 }]
      @UI.lineItem:        [{ position: 20, label: 'Approval Level' }]
      @UI.identification:  [{ position: 20, label: 'Approval Level (01=First, 02=Second)' }]
      ApprovalLevel,

      @Semantics.amount.currencyCode: 'Currency'
      @UI.lineItem:        [{ position: 30, label: 'Min Amount' }]
      @UI.identification:  [{ position: 30, label: 'Minimum Order Amount' }]
      MinAmount,

      @Semantics.amount.currencyCode: 'Currency'
      @UI.lineItem:        [{ position: 40, label: 'Max Amount' }]
      @UI.identification:  [{ position: 40, label: 'Maximum Order Amount (0=Unlimited)' }]
      MaxAmount,

      @Semantics.currencyCode: true
      @UI.lineItem:        [{ position: 50, label: 'Currency' }]
      @UI.identification:  [{ position: 50, label: 'Currency' }]
      Currency,

      @UI.selectionField:  [{ position: 20 }]
      @UI.lineItem:        [{ position: 60, label: 'Approver Role' }]
      @UI.identification:  [{ position: 60, label: 'Authorized Approver Role' }]
      ApproverRole,

      @UI.lineItem:        [{ position: 70, label: 'Default User' }]
      @UI.identification:  [{ position: 70, label: 'Default Approver User / Queue' }]
      ApproverUser,

      @UI.lineItem:        [{ position: 80, label: 'SLA (Hours)' }]
      @UI.identification:  [{ position: 80, label: 'Allowed SLA Duration (Hours)' }]
      SlaHours,

      @UI.selectionField:  [{ position: 30 }]
      @UI.lineItem:        [{ position: 90, label: 'Active Status' }]
      @UI.identification:  [{ position: 90, label: 'Active Indicator' }]
      IsActive,

      @UI.identification:  [{ position: 100, label: 'Valid From' }]
      ValidFrom,

      @UI.identification:  [{ position: 110, label: 'Valid To' }]
      ValidTo,

      @UI.fieldGroup:      [{ position: 10, qualifier: 'AuditData', label: 'Created By' }]
      CreatedBy,

      @UI.fieldGroup:      [{ position: 20, qualifier: 'AuditData', label: 'Created At' }]
      CreatedAt,

      @UI.fieldGroup:      [{ position: 30, qualifier: 'AuditData', label: 'Changed By' }]
      ChangedBy,

      @UI.fieldGroup:      [{ position: 40, qualifier: 'AuditData', label: 'Changed At' }]
      ChangedAt
}
