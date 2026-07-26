enum RentalMaintenanceStatus { open, inProgress, resolved, cancelled }

class RentalMaintenanceTicket {
  const RentalMaintenanceTicket({
    required this.id,
    required this.leaseId,
    required this.title,
    required this.description,
    required this.openedBy,
    required this.openedAt,
    this.status = RentalMaintenanceStatus.open,
    this.resolvedAt,
  });

  final String id;
  final String leaseId;
  final String title;
  final String description;
  final String openedBy;
  final DateTime openedAt;
  final RentalMaintenanceStatus status;
  final DateTime? resolvedAt;

  bool get isOpen =>
      status == RentalMaintenanceStatus.open ||
      status == RentalMaintenanceStatus.inProgress;

  Duration get age => DateTime.now().difference(openedAt);

  bool isSlaBreached({int slaHours = 48}) =>
      isOpen && age.inHours >= slaHours;

  RentalMaintenanceTicket copyWith({
    RentalMaintenanceStatus? status,
    DateTime? resolvedAt,
  }) {
    return RentalMaintenanceTicket(
      id: id,
      leaseId: leaseId,
      title: title,
      description: description,
      openedBy: openedBy,
      openedAt: openedAt,
      status: status ?? this.status,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lease_id': leaseId,
        'title': title,
        'description': description,
        'opened_by': openedBy,
        'opened_at': openedAt.toIso8601String(),
        'status': status.name,
        if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
      };

  factory RentalMaintenanceTicket.fromJson(Map<String, dynamic> j) {
    return RentalMaintenanceTicket(
      id: j['id']?.toString() ?? '',
      leaseId: j['lease_id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      openedBy: j['opened_by']?.toString() ?? '',
      openedAt: DateTime.tryParse(j['opened_at']?.toString() ?? '') ??
          DateTime.now(),
      status: RentalMaintenanceStatus.values.firstWhere(
        (s) => s.name == j['status']?.toString(),
        orElse: () => RentalMaintenanceStatus.open,
      ),
      resolvedAt: j['resolved_at'] != null
          ? DateTime.tryParse(j['resolved_at'].toString())
          : null,
    );
  }
}
