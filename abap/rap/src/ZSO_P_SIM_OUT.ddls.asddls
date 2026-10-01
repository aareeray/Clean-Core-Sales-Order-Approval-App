@EndUserText.label: 'Approval Simulation Output Result'

define abstract entity ZSO_P_SIM_OUT
{
  StepNo        : abap.int4;
  ApprovalLevel : abap.numc(2);
  ApproverRole  : abap.char(20);
  ApproverUser  : abap.char(12);
  SlaHours      : abap.int4;
  Description   : abap.char(100);
}
