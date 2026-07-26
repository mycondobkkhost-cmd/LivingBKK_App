/// จุดที่บังคับยอมรับข้อตกลงค่าคอมก่อนดำเนินการต่อ
enum CommissionAgreementContext {
  publishListing,
  submitOffer,
  acceptLead,
  confirmViewing,
}

extension CommissionAgreementContextDb on CommissionAgreementContext {
  String get dbValue => switch (this) {
        CommissionAgreementContext.publishListing => 'publish_listing',
        CommissionAgreementContext.submitOffer => 'submit_offer',
        CommissionAgreementContext.acceptLead => 'accept_lead',
        CommissionAgreementContext.confirmViewing => 'confirm_viewing',
      };
}
