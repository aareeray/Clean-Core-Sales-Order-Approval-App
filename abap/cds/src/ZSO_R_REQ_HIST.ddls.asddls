@AccessControl.authorizationCheck: #INHERITED
@EndUserText.label: 'Approval History / Audit Trail - Interface View'

define view entity ZSO_R_REQ_HIST
  as select from ZSO_APPR_HIST
  association to parent ZSO_R_REQ_H as _Header
    on $projection.RequestId = _Header.RequestId
{
  key history_id       as HistoryId,
      request_id       as RequestId,
      step_no          as StepNo,
      action           as Action,
      actor            as Actor,
      actor_role       as ActorRole,
      @Semantics.systemDateTime.createdAt: true
      action_timestamp as ActionTimestamp,
      comment_text     as CommentText,
      previous_status  as PreviousStatus,
      new_status       as NewStatus,
      workflow_task_id as WorkflowTaskId,

      _Header
}
