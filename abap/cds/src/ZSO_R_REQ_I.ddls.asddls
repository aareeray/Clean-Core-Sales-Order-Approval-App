@AccessControl.authorizationCheck: #INHERITED
@EndUserText.label: 'Sales Order Request Item - Interface View'
@Metadata.ignorePropagatedAnnotations: false

define view entity ZSO_R_REQ_I
  as select from ZSO_REQ_I as Item

  association to parent ZSO_R_REQ_H as _Header
    on $projection.RequestId = _Header.RequestId

{
      ///
      /// Key Fields
      ///
  key Item.request_id           as RequestId,
  key Item.item_no              as ItemNo,

      ///
      /// Business Fields
      ///
      Item.material             as Material,

      @Semantics.quantity.unitOfMeasure: 'Unit'
      Item.quantity             as Quantity,

      @Semantics.unitOfMeasure: true
      Item.unit                 as Unit,

      @Semantics.amount.currencyCode: 'Currency'
      Item.unit_price           as UnitPrice,

      @Semantics.amount.currencyCode: 'Currency'
      Item.net_amount           as NetAmount,

      @Semantics.currencyCode: true
      Item.currency             as Currency,

      ///
      /// Associations
      ///
      _Header
}
