@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Operational Cockpit - Query View'

@UI.chart: [{
  qualifier: 'RequestsByStatusChart',
  chartType: #DONUT,
  title: 'Requests by Status',
  dimensions: ['Status'],
  measures: ['TotalRequests'],
  dimensionAttributes: [{ dimension: 'Status', role: #CATEGORY }],
  measureAttributes: [{ measure: 'TotalRequests', role: #AXIS_1, asDataPoint: true }]
},
{
  qualifier: 'AmountByCustomerChart',
  chartType: #BAR,
  title: 'Approval Volume by Customer',
  dimensions: ['CustomerId'],
  measures: ['TotalAmount'],
  dimensionAttributes: [{ dimension: 'CustomerId', role: #CATEGORY }],
  measureAttributes: [{ measure: 'TotalAmount', role: #AXIS_1, asDataPoint: true }]
}]

define view entity ZSO_C_REQ_ANALYTICS
  as select from ZSO_I_REQ_ANALYTICS
{
      @UI.lineItem: [{ position: 10, label: 'Customer' }]
  key CustomerId,

      @UI.lineItem: [{ position: 20, label: 'Status' }]
  key Status,

      @UI.lineItem: [{ position: 30, label: 'Approver' }]
  key Approver,

      @UI.lineItem: [{ position: 40, label: 'SLA Status' }]
  key SlaStatus,

      @Semantics.currencyCode: true
  key Currency,

      @UI.lineItem: [{ position: 50, label: 'Total Volume' }]
      @Semantics.amount.currencyCode: 'Currency'
      TotalAmount,

      @UI.lineItem: [{ position: 60, label: 'Total Count' }]
      TotalRequests,

      @UI.lineItem: [{ position: 70, label: 'Pending Count' }]
      PendingRequests,

      @UI.lineItem: [{ position: 80, label: 'Approved Count' }]
      ApprovedRequests,

      @UI.lineItem: [{ position: 90, label: 'Rejected Count' }]
      RejectedRequests,

      @UI.lineItem: [{ position: 100, label: 'SLA Breaches' }]
      SlaBreachedRequests,

      @UI.lineItem: [{ position: 110, label: 'Avg Days Waiting' }]
      AvgDaysWaiting
}
