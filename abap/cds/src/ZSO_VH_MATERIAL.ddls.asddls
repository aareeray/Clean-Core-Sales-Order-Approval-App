@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help - Material / Product Master'
@ObjectModel.resultSet.sizeCategory: #M
@Search.searchable: true

define view entity ZSO_VH_MATERIAL
  as select from I_Product as Product
  association [0..1] to I_ProductDescription as _Text
    on  $projection.MaterialId = _Text.Product
    and _Text.Language         = $session.system_language
{
      @Search.defaultSearchElement: true
  key Product.Product             as MaterialId,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      _Text.ProductDescription    as MaterialDescription,

      Product.BaseUnit            as BaseUnit,
      Product.ProductType         as ProductType
}
