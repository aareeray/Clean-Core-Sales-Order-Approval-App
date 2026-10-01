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

define view entity ZSO_C_REQ_H
  provider contract transactional_query
  as projection on ZSO_R_REQ_H

{
      ///
      /// Object Page Header & Body Facets
      ///
      @UI.facet: [
        /// Header Facet 1: Total Amount DataPoint
        { id:              'HeaderAmount',
          type:            #DATAPOINT_REFERENCE,
          purpose:         #HEADER,
          targetQualifier: 'AmountDataPoint',
          position:        10 },

        /// Header Facet 2: Status DataPoint
        { id:              'HeaderStatus',
          type:            #DATAPOINT_REFERENCE,
          purpose:         #HEADER,
          targetQualifier: 'StatusDataPoint',
          position:        20 },

        /// Header Facet 3: Approver DataPoint
        { id:              'HeaderApprover',
          type:            #DATAPOINT_REFERENCE,
          purpose:         #HEADER,
          targetQualifier: 'ApproverDataPoint',
          position:        30 },

        /// Header Facet 4: Due Date DataPoint
        { id:              'HeaderDueDate',
          type:            #DATAPOINT_REFERENCE,
          purpose:         #HEADER,
          targetQualifier: 'DueDateDataPoint',
          position:        40 },

        /// Header Facet 5: SLA Status DataPoint
        { id:              'HeaderSla',
          type:            #DATAPOINT_REFERENCE,
          purpose:         #HEADER,
          targetQualifier: 'SlaDataPoint',
          position:        50 },

        /// Body Section 1: Request Details
        { id:              'GeneralInfo',
          type:            #IDENTIFICATION_REFERENCE,
          label:           'Request Details',
          position:        10 },

        /// Body Section 2: Items
        { id:              'Items',
          type:            #LINEITEM_REFERENCE,
          label:           'Items',
          position:        20,
          targetElement:   '_Items' },

        /// Body Section 3: Approval History Audit Trail
        { id:              'History',
          type:            #LINEITEM_REFERENCE,
          label:           'Approval History',
          position:        30,
          targetElement:   '_History' },

        /// Body Section 4: SLA & Escalation
        { id:              'SlaSection',
          type:            #FIELDGROUP_REFERENCE,
          label:           'SLA & Escalation',
          targetQualifier: 'SlaGroup',
          position:        40 },

        /// Body Section 5: Comments & Rejection Reason
        { id:              'RejectionSection',
          type:            #FIELDGROUP_REFERENCE,
          label:           'Comments & Rejection Reason',
          targetQualifier: 'RejectionGroup',
          position:        50 },

        /// Body Section 6: Audit Information
        { id:              'AuditSection',
          type:            #FIELDGROUP_REFERENCE,
          label:           'Audit Information',
          targetQualifier: 'AuditGroup',
          position:        60 }
      ]

      ///
      /// REQUEST ID (Anchor)
      ///
      @UI.selectionField:  [{ position: 10 }]
      @UI.lineItem:        [{ position: 10, label: 'Request ID' }]
      @UI.identification:  [{ position: 10, label: 'Request ID' }]
  key RequestId,

      ///
      /// CUSTOMER ID — with value help
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
      /// TOTAL AMOUNT — Header DataPoint & LineItem
      ///
      @Semantics.amount.currencyCode: 'Currency'
      @UI.dataPoint:      { qualifier: 'AmountDataPoint', title: 'Total Amount' }
      @UI.lineItem:       [{ position: 40, label: 'Amount' }]
      @UI.identification: [{ position: 40, label: 'Total Amount' }]
      TotalAmount,

      ///
      /// CURRENCY
      ///
      @Semantics.currencyCode: true
      Currency,

      ///
      /// STATUS — Header DataPoint, LineItem, SelectionField
      ///
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZSO_VH_STATUS', element: 'Status' }
      }]
      @UI.dataPoint:      { qualifier: 'StatusDataPoint', title: 'Status', criticality: 'StatusCriticality' }
      @UI.selectionField: [{ position: 30 }]
      @UI.lineItem:       [{ position: 50, label: 'Status', criticality: 'StatusCriticality' }]
      @UI.identification: [{ position: 50, label: 'Status', criticality: 'StatusCriticality' }]
      Status,

      ///
      /// STATUS CRITICALITY (0=Neutral, 1=Negative, 2=Critical, 3=Positive)
      ///
      @UI.hidden: true
      case Status
        when 'APPROVED' then cast( 3 as abap.int1 )
        when 'PENDING'  then cast( 2 as abap.int1 )
        when 'REJECTED' then cast( 1 as abap.int1 )
        else                 cast( 0 as abap.int1 )
      end as StatusCriticality,

      ///
      /// APPROVER — Header DataPoint & SelectionField
      ///
      @UI.dataPoint:      { qualifier: 'ApproverDataPoint', title: 'Approver' }
      @UI.selectionField: [{ position: 50 }]
      @UI.lineItem:       [{ position: 60, label: 'Approver' }]
      @UI.identification: [{ position: 60, label: 'Approver' }]
      Approver,

      ///
      /// REJECTION REASON — in dedicated RejectionGroup facet
      ///
      @UI.fieldGroup:     [{ qualifier: 'RejectionGroup', position: 10, label: 'Rejection Reason' }]
      RejectionReason,

      ///
      /// APPROVAL DUE DATE — Header DataPoint & LineItem
      ///
      @UI.dataPoint:      { qualifier: 'DueDateDataPoint', title: 'Approval Due Date' }
      @UI.selectionField: [{ position: 60 }]
      @UI.lineItem:       [{ position: 70, label: 'Approval Due Date' }]
      @UI.fieldGroup:     [{ qualifier: 'SlaGroup', position: 10, label: 'Approval Due Date' }]
      ApprovalDueDate,

      ///
      /// SLA STATUS — Header DataPoint & LineItem
      ///
      @UI.dataPoint:      { qualifier: 'SlaDataPoint', title: 'SLA Status', criticality: 'SlaCriticality' }
      @UI.selectionField: [{ position: 70 }]
      @UI.lineItem:       [{ position: 80, label: 'SLA Status', criticality: 'SlaCriticality' }]
      @UI.fieldGroup:     [{ qualifier: 'SlaGroup', position: 20, label: 'SLA Status', criticality: 'SlaCriticality' }]
      SlaStatus,

      ///
      /// SLA CRITICALITY (3=Positive/On Track, 2=Critical/Due Soon, 1=Negative/Breached, 1=Escalated, 0=Neutral)
      ///
      @UI.hidden: true
      case SlaStatus
        when 'ON_TRACK'  then cast( 3 as abap.int1 )
        when 'DUE_SOON'  then cast( 2 as abap.int1 )
        when 'BREACHED'  then cast( 1 as abap.int1 )
        when 'ESCALATED' then cast( 1 as abap.int1 )
        else                  cast( 0 as abap.int1 )
      end as SlaCriticality,

      ///
      /// DAYS WAITING
      ///
      @UI.fieldGroup:     [{ qualifier: 'SlaGroup', position: 30, label: 'Days Waiting' }]
      DaysWaiting,

      ///
      /// ESCALATION DETAILS
      ///
      @UI.fieldGroup:     [{ qualifier: 'SlaGroup', position: 40, label: 'Escalation Level' }]
      EscalationLevel,

      @UI.fieldGroup:     [{ qualifier: 'SlaGroup', position: 50, label: 'Escalated To' }]
      EscalatedTo,

      @UI.fieldGroup:     [{ qualifier: 'SlaGroup', position: 60, label: 'Escalated At' }]
      EscalatedAt,

      ///
      /// ADMINISTRATIVE AUDIT FIELDS
      ///
      @UI.lineItem:       [{ position: 90, label: 'Created By' }]
      @UI.fieldGroup:     [{ qualifier: 'AuditGroup', position: 10, label: 'Created By' }]
      CreatedBy,

      @UI.fieldGroup:     [{ qualifier: 'AuditGroup', position: 20, label: 'Created At' }]
      CreatedAt,

      @UI.fieldGroup:     [{ qualifier: 'AuditGroup', position: 30, label: 'Changed By' }]
      ChangedBy,

      @UI.fieldGroup:     [{ qualifier: 'AuditGroup', position: 40, label: 'Changed At' }]
      ChangedAt,

      ///
      /// ACTION BUTTONS (with feature and status control)
      ///
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

      /// Escalate — visible when Status = PENDING and SLA breached or due soon
      @UI.lineItem: [{
        type:       #FOR_ACTION,
        dataAction: 'escalate',
        label:      'Escalate',
        position:   35
      }]
      @UI.identification: [{
        type:       #FOR_ACTION,
        dataAction: 'escalate',
        label:      'Escalate',
        position:   35
      }]
      @UI.hidden: #( Status <> 'PENDING' )
      RequestId as EscalateAction   : redirected to ZSO_C_REQ_H,

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
      /// Associations
      ///
      _Items   : redirected to composition child ZSO_C_REQ_I,
      _History : redirected to composition child ZSO_C_REQ_HIST
}
