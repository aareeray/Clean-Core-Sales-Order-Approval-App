@EndUserText.label: 'Action Parameter: Reject Sales Order Request'
@Metadata.allowExtensions: false

///
/// Abstract entity used as input parameter for the RAP "reject" action.
/// The rejection reason is mandatory when a request is rejected.
///
define abstract entity ZSO_P_REJECT
{
  @EndUserText.label: 'Rejection Reason'
  @UI.multiLineText: true
  RejectionReason : abap.char(255);
}
