@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help - Customer'
@ObjectModel.resultSet.sizeCategory: #M
@Search.searchable: true

define view entity ZSO_VH_CUSTOMER
  as select from I_Customer as Customer

{
  key Customer.Customer       as CustomerId,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      Customer.CustomerName   as CustomerName,

      Customer.Country        as Country,
      Customer.City           as City
}
