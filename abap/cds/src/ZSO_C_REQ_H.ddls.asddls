@AccessControl.authorizationCheck: #INHERITED
@EndUserText.label: 'Sales Order Request Header - Projection View'

@Metadata.allowExtensions: true

///
/// Fiori Elements: Header Info (Object Page title + subtitle)
///
@UI.headerInfo: {
  typeName:       'Sales Order Request',
  typeNamePlural: 'Sales Order Requests',
  title:          { type: #STANDARD, value: 'RequestId'  },
  description:    { type: #STANDARD, value: 'CustomerId' }
}

///
/// Fiori Elements: KPI / Quick View (optional, can remove if not used)
///
@UI.chart: [{
  qualifier:             'TotalAmountChart',
  chartType:             #BAR,
  title:                 'Total Amount',
  measures:              ['TotalAmount'],
  measureAttributes: [{
    measure:    'TotalAmount',
    role:       #AXIS_1,
    asDataPoint: true
  }]
}]

define view entity ZSO_C_REQ_H
  provider contract transactional_query
  as projection on ZSO_R_REQ_H

{
      ///
      /// Object Page Facets (defined on any field — here on the first field)
      ///
      @UI.facet: [
        ///  General Information section
        { id:            'GeneralInfo',
          type:          #IDENTIFICATION_REFERENCE,
          label:         'General Information',
          position:      10 },
        ///  Items child table
        { id:            'Items',
          type:          #LINEITEM_REFERENCE,
          label:         'Items',
          position:      20,
          targetElement: '_Items' },
        ///  Approval details (Approver + Rejection Reason)
        { id:            'ApprovalDetails',
          type:          #IDENTIFICATION_REFERENCE,
          label:         'Approval Details',
          position:      30 }
      ]

      ///
      /// REQUEST ID
      ///
      @UI.selectionField:  [{ position: 10 }]
      @UI.lineItem:        [{ position: 10, label: 'Request ID' }]
      @UI.identification:  [{ position: 10, label: 'Request ID' }]
  key RequestId,

      ///
      /// CUSTOMER ID  — with value help
      ///
      @Consumption.valueHelpDefinition: [{
        entity:     { name: 'ZSO_VH_CUSTOMER', element: 'CustomerId' },
        additionalBinding: [{
          localElement:  'CustomerId',
          element:       'CustomerId',
          usage:         #RESULT
        }]
      }]
      @UI.selectionField: [{ position: 20 }]
      @UI.lineItem:       [{ position: 20, label: 'Customer' }]
      @UI.identification: [{ position: 20, label: 'Customer ID' }]
      CustomerId,

      ///
      /// REQUEST DATE
      ///
      @UI.selectionField: [{ position: 30 }]
      @UI.lineItem:       [{ position: 30, label: 'Request Date' }]
      @UI.identification: [{ position: 30, label: 'Request Date' }]
      RequestDate,

      ///
      /// TOTAL AMOUNT
      ///
      @UI.lineItem:       [{ position: 40, label: 'Total Amount' }]
      @UI.identification: [{ position: 40, label: 'Total Amount' }]
      @UI.dataPoint: {
        qualifier:   'TotalAmount',
        title:       'Total Amount',
        criticalityCalculation: {
          improvementDirection: #TARGET,
          toleranceRangeLowValue: 1,
          toleranceRangeHighValue: 9999
        }
      }
      TotalAmount,

      ///
      /// CURRENCY  — hidden from UI, used as unit reference
      ///
      @UI.hidden: true
      Currency,

      ///
      /// STATUS  — with value help + criticality colour
      ///
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZSO_VH_STATUS', element: 'Status' }
      }]
      @UI.selectionField: [{ position: 40 }]
      @UI.lineItem: [{
        position:                   50,
        label:                      'Status',
        criticality:                'StatusCriticality',
        criticalityRepresentation:  #WITH_ICON
      }]
      @UI.identification: [{
        position:    50,
        label:       'Status',
        criticality: 'StatusCriticality'
      }]
      @UI.textArrangement: #TEXT_ONLY
      Status,

      ///
      /// APPROVER  — shown only in Approval Details facet (position > 50)
      ///
      @UI.identification: [{ position: 60, label: 'Approver' }]
      Approver,

      ///
      /// REJECTION REASON  — shown only in Approval Details facet
      ///
      @UI.identification: [{ position: 70, label: 'Rejection Reason' }]
      RejectionReason,

      ///
      /// Admin fields  — hidden from all Fiori Elements UI panels
      ///
      @UI.hidden: true
      CreatedBy,
      @UI.hidden: true
      CreatedAt,
      @UI.hidden: true
      ChangedBy,
      @UI.hidden: true
      ChangedAt,

      ///
      /// CRITICALITY VIRTUAL FIELD
      /// Drives colour-coding: 3=Green(Approved) 2=Yellow(Pending) 1=Red(Rejected) 0=None(Draft)
      ///
      case Status
        when 'APPROVED' then 3
        when 'PENDING'  then 2
        when 'REJECTED' then 1
        else                 0
      end                           as StatusCriticality : abap.int1,

      ///
      /// ACTIONS — declared as FOR_ACTION entries on @UI.lineItem / @UI.identification
      /// Actual enable/disable is controlled by BDEF get_instance_features
      ///

      /// Submit — visible only when Status = DRAFT
      @UI.lineItem: [{
        type:        #FOR_ACTION,
        dataAction:  'submit',
        label:       'Submit',
        position:    10,
        emphasized:  true
      }]
      @UI.identification: [{
        type:        #FOR_ACTION,
        dataAction:  'submit',
        label:       'Submit',
        position:    10,
        emphasized:  true
      }]
      @UI.hidden: #( Status <> 'DRAFT' )
      RequestId as SubmitAction     : redirected to ZSO_C_REQ_H,

      /// Approve — visible only when Status = PENDING
      @UI.lineItem: [{
        type:       #FOR_ACTION,
        dataAction: 'approve',
        label:      'Approve',
        position:   20
      }]
      @UI.identification: [{
        type:       #FOR_ACTION,
        dataAction: 'approve',
        label:      'Approve',
        position:   20
      }]
      @UI.hidden: #( Status <> 'PENDING' )
      RequestId as ApproveAction    : redirected to ZSO_C_REQ_H,

      /// Reject — visible only when Status = PENDING
      @UI.lineItem: [{
        type:       #FOR_ACTION,
        dataAction: 'reject',
        label:      'Reject',
        position:   30
      }]
      @UI.identification: [{
        type:       #FOR_ACTION,
        dataAction: 'reject',
        label:      'Reject',
        position:   30
      }]
      @UI.hidden: #( Status <> 'PENDING' )
      RequestId as RejectAction     : redirected to ZSO_C_REQ_H,

      /// Resubmit — visible only when Status = REJECTED
      @UI.lineItem: [{
        type:       #FOR_ACTION,
        dataAction: 'resubmit',
        label:      'Resubmit',
        position:   40
      }]
      @UI.identification: [{
        type:       #FOR_ACTION,
        dataAction: 'resubmit',
        label:      'Resubmit',
        position:   40
      }]
      @UI.hidden: #( Status <> 'REJECTED' )
      RequestId as ResubmitAction   : redirected to ZSO_C_REQ_H,

      ///
      /// Associations  — redirected to projection child
      ///
      _Items : redirected to composition child ZSO_C_REQ_I
}
