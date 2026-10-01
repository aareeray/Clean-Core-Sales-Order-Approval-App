@AccessControl.authorizationCheck: #INHERITED
@EndUserText.label: 'Sales Order Request Item - Projection View'

@Metadata.allowExtensions: true

define view entity ZSO_C_REQ_I
  provider contract transactional_query
  as projection on ZSO_R_REQ_I

{
      ///
      /// Key Fields
      ///
      @UI.lineItem:       [{ position: 10, label: 'Request ID' }]
      @UI.identification: [{ position: 10, label: 'Request ID' }]
      @UI.hidden: true
  key RequestId,

      @UI.lineItem:       [{ position: 20, label: 'Item No.' }]
      @UI.identification: [{ position: 20, label: 'Item No.' }]
  key ItemNo,

      ///
      /// Business Fields
      ///
      @UI.lineItem:       [{ position: 30, label: 'Material' }]
      @UI.identification: [{ position: 30, label: 'Material' }]
      Material,

      @UI.lineItem:       [{ position: 40, label: 'Quantity' }]
      @UI.identification: [{ position: 40, label: 'Quantity' }]
      Quantity,

      @UI.lineItem:       [{ position: 50, label: 'Unit' }]
      @UI.identification: [{ position: 50, label: 'Unit of Measure' }]
      Unit,

      @UI.lineItem:       [{ position: 60, label: 'Unit Price' }]
      @UI.identification: [{ position: 60, label: 'Unit Price' }]
      UnitPrice,

      @UI.lineItem:       [{ position: 70, label: 'Net Amount' }]
      @UI.identification: [{ position: 70, label: 'Net Amount' }]
      NetAmount,

      @UI.hidden: true
      Currency,

      ///
      /// Association back to header (required for redirection)
      ///
      _Header : redirected to parent ZSO_C_REQ_H
}
