@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help - Sales Order Request Status'
@ObjectModel.resultSet.sizeCategory: #XS

define view entity ZSO_VH_STATUS
  as select from ZSO_D_STATUS as StatusDomain

{
      StatusDomain.value_low  as Status,

      @UI.hidden: true
      StatusDomain.ddtext     as StatusText
}
