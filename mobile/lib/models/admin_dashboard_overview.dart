class AdminDashboardOverview {
  const AdminDashboardOverview({
    this.projects = 0,
    this.listingsPublished = 0,
    this.listingsTotal = 0,
    this.leadsTotal = 0,
    this.leadsNew = 0,
    this.chatWaiting = 0,
    this.appointmentsPending = 0,
    this.offersPending = 0,
    this.moderationImages = 0,
    this.moderationFlags = 0,
    this.importsPending = 0,
    this.usersTotal = 0,
    this.demandPostsOpen = 0,
    this.customerRequirementsPending = 0,
    this.availabilityAlertsDue = 0,
    this.viewingCalendarAttention = 0,
    this.updatedAt,
  });

  final int projects;
  final int listingsPublished;
  final int listingsTotal;
  final int leadsTotal;
  final int leadsNew;
  final int chatWaiting;
  final int appointmentsPending;
  final int offersPending;
  final int moderationImages;
  final int moderationFlags;
  final int importsPending;
  final int usersTotal;
  final int demandPostsOpen;
  final int customerRequirementsPending;
  /// ประกาศที่จะว่างภายใน 30 วัน (available_again)
  final int availabilityAlertsDue;
  /// งานปฏิทินที่ต้องทำ — ยังไม่ระบุคนพา / รอยืนยัน / หลังนัดดู
  final int viewingCalendarAttention;
  final DateTime? updatedAt;

  int get attentionTotal =>
      chatWaiting +
      leadsNew +
      appointmentsPending +
      offersPending +
      moderationImages +
      moderationFlags +
      importsPending +
      customerRequirementsPending +
      availabilityAlertsDue;

  /// ตัวเลขบนไอคอนปฏิทิน — ยังไม่เปิดดู หรือคำขอนัดที่รอดูแล
  int get viewingCalendarBadge => viewingCalendarAttention > 0
      ? viewingCalendarAttention
      : appointmentsPending;

  AdminDashboardOverview copyWith({
    int? availabilityAlertsDue,
    int? viewingCalendarAttention,
  }) {
    return AdminDashboardOverview(
      projects: projects,
      listingsPublished: listingsPublished,
      listingsTotal: listingsTotal,
      leadsTotal: leadsTotal,
      leadsNew: leadsNew,
      chatWaiting: chatWaiting,
      appointmentsPending: appointmentsPending,
      offersPending: offersPending,
      moderationImages: moderationImages,
      moderationFlags: moderationFlags,
      importsPending: importsPending,
      usersTotal: usersTotal,
      demandPostsOpen: demandPostsOpen,
      customerRequirementsPending: customerRequirementsPending,
      availabilityAlertsDue:
          availabilityAlertsDue ?? this.availabilityAlertsDue,
      viewingCalendarAttention:
          viewingCalendarAttention ?? this.viewingCalendarAttention,
      updatedAt: updatedAt,
    );
  }
}
