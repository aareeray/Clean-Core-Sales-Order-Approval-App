@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Sales Order Request Header - Interface View'
@Metadata.ignorePropagatedAnnotations: false

define view entity ZSO_R_REQ_H
  as select from ZSO_REQ_H as Header

  composition [0..*] of ZSO_R_REQ_I    as _Items
  composition [0..*] of ZSO_R_REQ_HIST as _History

{
      ///
      /// Key Fields
      ///
  key Header.request_id         as RequestId,

      ///
      /// Business Fields
      ///
      Header.customer_id        as CustomerId,
      Header.request_date       as RequestDate,

      @Semantics.amount.currencyCode: 'Currency'
      Header.total_amount       as TotalAmount,

      @Semantics.currencyCode: true
      Header.currency           as Currency,

      Header.status             as Status,
      Header.approver           as Approver,
      Header.rejection_reason   as RejectionReason,

      ///
      /// SLA & Escalation Fields
      ///
      Header.approval_due_date  as ApprovalDueDate,
      Header.sla_status         as SlaStatus,
      Header.escalation_level   as EscalationLevel,
      Header.escalated_to       as EscalatedTo,
      Header.escalated_at       as EscalatedAt,
      dats_days_between(Header.request_date, $session.system_date) as DaysWaiting,

      ///
      /// Administrative Fields
      ///
      @Semantics.user.createdBy: true
      Header.created_by         as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      Header.created_at         as CreatedAt,

      @Semantics.user.lastChangedBy: true
      Header.changed_by         as ChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      Header.changed_at         as ChangedAt,

      ///
      /// Associations
      ///
      _Items,
      _History
}
