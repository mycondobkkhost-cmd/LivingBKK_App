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
  final DateTime? updatedAt;

  int get attentionTotal =>
      chatWaiting +
      leadsNew +
      appointmentsPending +
      offersPending +
      moderationImages +
      moderationFlags +
      importsPending;
}
