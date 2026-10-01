@EndUserText.label: 'Sales Order Request Status'

define domain ZSO_D_STATUS
  data_type CHAR
  length    10
{
  'DRAFT'    as #DRAFT    @EndUserText.label: 'Draft';
  'PENDING'  as #PENDING  @EndUserText.label: 'Pending Approval';
  'APPROVED' as #APPROVED @EndUserText.label: 'Approved';
  'REJECTED' as #REJECTED @EndUserText.label: 'Rejected';
}
