@AccessControl.authorizationCheck: #INHERITED
@EndUserText.label: 'Approval History - Projection View'

@UI.headerInfo: {
  typeName:       'Approval Step',
  typeNamePlural: 'Approval History'
}

define view entity ZSO_C_REQ_HIST
  as projection on ZSO_R_REQ_HIST
{
      @UI.facet: [
        { id: 'HistoryDetails',
          type: #IDENTIFICATION_REFERENCE,
          label: 'Step Information',
          position: 10 }
      ]

  key HistoryId,

      @UI.hidden: true
      RequestId,

      @UI.lineItem:       [{ position: 10, label: 'Step #' }]
      @UI.identification: [{ position: 10, label: 'Step #' }]
      StepNo,

      @UI.lineItem:       [{ position: 20, label: 'Action' }]
      @UI.identification: [{ position: 20, label: 'Action' }]
      Action,

      @UI.lineItem:       [{ position: 30, label: 'Actor' }]
      @UI.identification: [{ position: 30, label: 'Performed By' }]
      Actor,

      @UI.lineItem:       [{ position: 40, label: 'Role' }]
      @UI.identification: [{ position: 40, label: 'Role' }]
      ActorRole,

      @UI.lineItem:       [{ position: 50, label: 'Timestamp' }]
      @UI.identification: [{ position: 50, label: 'Timestamp' }]
      ActionTimestamp,

      @UI.lineItem:       [{ position: 60, label: 'Comment / Note' }]
      @UI.identification: [{ position: 60, label: 'Comment / Note' }]
      CommentText,

      @UI.lineItem:       [{ position: 70, label: 'Previous Status' }]
      PreviousStatus,

      @UI.lineItem:       [{ position: 80, label: 'New Status' }]
      NewStatus,

      @UI.identification: [{ position: 90, label: 'Workflow Task ID' }]
      WorkflowTaskId,

      /* Associations */
      _Header : redirected to parent ZSO_C_REQ_H
}
