@EndUserText.label: 'Sales Order Approval Lifecycle Business Event Payload'

define abstract entity ZSO_E_EVT_PAYLOAD
{
  RequestId       : sysuuid_x16;
  CustomerId      : abap.char(10);
  @Semantics.amount.currencyCode: 'Currency'
  TotalAmount     : abap.curr(15,2);
  @Semantics.currencyCode: true
  Currency        : abap.cuky;
  Status          : ZSO_E_STATUS;
  Approver        : abap.char(12);
  EventTimestamp  : utclong;
  RejectionReason : abap.char(255);
  EscalationLevel : abap.numc(2);
}
