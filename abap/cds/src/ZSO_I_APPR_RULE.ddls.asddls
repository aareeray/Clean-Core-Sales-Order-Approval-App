@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Approval Routing Rule - Interface View'

define view entity ZSO_I_APPR_RULE
  as select from ZSO_APPR_RULE
{
  key rule_id        as RuleId,
      approval_level as ApprovalLevel,
      @Semantics.amount.currencyCode: 'Currency'
      min_amount     as MinAmount,
      @Semantics.amount.currencyCode: 'Currency'
      max_amount     as MaxAmount,
      @Semantics.currencyCode: true
      currency       as Currency,
      approver_role  as ApproverRole,
      approver_user  as ApproverUser,
      sla_hours      as SlaHours,
      is_active      as IsActive,
      valid_from     as ValidFrom,
      valid_to       as ValidTo,
      created_by     as CreatedBy,
      created_at     as CreatedAt,
      changed_by     as ChangedBy,
      changed_at     as ChangedAt
}
