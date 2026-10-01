@EndUserText.label: 'Approval Simulation Input Parameter'

define abstract entity ZSO_P_SIM_IN
{
  @Semantics.amount.currencyCode: 'Currency'
  TotalAmount : abap.curr(15,2);
  @Semantics.currencyCode: true
  Currency    : abap.cuky;
  CustomerId  : abap.char(10);
}
