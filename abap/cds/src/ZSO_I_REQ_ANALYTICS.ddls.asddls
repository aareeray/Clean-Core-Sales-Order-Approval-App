@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Approval Analytics - Cube View'
@Analytics.dataCategory: #CUBE

define view entity ZSO_I_REQ_ANALYTICS
  as select from ZSO_REQ_H
{
      ///
      /// Dimensions
      ///
  key customer_id       as CustomerId,
  key status            as Status,
  key approver          as Approver,
  key sla_status        as SlaStatus,
  key currency          as Currency,
      request_date      as RequestDate,

      ///
      /// Aggregated Measures
      ///
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'Currency'
      total_amount      as TotalAmount,

      @Aggregation.default: #SUM
      cast( 1 as abap.int4 ) as TotalRequests,

      @Aggregation.default: #SUM
      cast( case status when 'DRAFT' then 1 else 0 end as abap.int4 ) as DraftRequests,

      @Aggregation.default: #SUM
      cast( case status when 'PENDING' then 1 else 0 end as abap.int4 ) as PendingRequests,

      @Aggregation.default: #SUM
      cast( case status when 'APPROVED' then 1 else 0 end as abap.int4 ) as ApprovedRequests,

      @Aggregation.default: #SUM
      cast( case status when 'REJECTED' then 1 else 0 end as abap.int4 ) as RejectedRequests,

      @Aggregation.default: #SUM
      cast( case when sla_status = 'BREACHED' or sla_status = 'ESCALATED' then 1 else 0 end as abap.int4 ) as SlaBreachedRequests,

      @Aggregation.default: #AVG
      dats_days_between(request_date, $session.system_date) as AvgDaysWaiting
}
