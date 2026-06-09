/// รอบชำระค่าเช่า + สลิป
enum RentalInstallmentStatus { pending, slipSubmitted, confirmed }

class RentalPaymentSlip {
  const RentalPaymentSlip({
    required this.id,
    required this.fileName,
    required this.uploadedAt,
    required this.uploadedBy,
    this.note,
  });

  final String id;
  final String fileName;
  final DateTime uploadedAt;
  final String uploadedBy;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'uploaded_at': uploadedAt.toIso8601String(),
        'uploaded_by': uploadedBy,
        if (note != null) 'note': note,
      };

  factory RentalPaymentSlip.fromJson(Map<String, dynamic> j) {
    return RentalPaymentSlip(
      id: j['id']?.toString() ?? '',
      fileName: j['file_name']?.toString() ?? '',
      uploadedAt: DateTime.tryParse(j['uploaded_at']?.toString() ?? '') ??
          DateTime.now(),
      uploadedBy: j['uploaded_by']?.toString() ?? '',
      note: j['note']?.toString(),
    );
  }
}

class RentalPaymentInstallment {
  const RentalPaymentInstallment({
    required this.id,
    required this.sequence,
    required this.dueDate,
    this.status = RentalInstallmentStatus.pending,
    this.remindersSentDaysBefore = const [],
    this.remindersPaused = false,
    this.slip,
    this.adminConfirmedAt,
    this.adminConfirmedBy,
    this.adminConfirmNote,
  });

  final String id;
  final int sequence;
  final DateTime dueDate;
  final RentalInstallmentStatus status;
  /// แจ้งเตือนก่อนกี่วันที่ส่งไปแล้ว (เช่น 2, 1)
  final List<int> remindersSentDaysBefore;
  /// หยุดแจ้งเตือนเมื่อมีสลิปหรือแอดมินยืนยันแล้ว
  final bool remindersPaused;
  final RentalPaymentSlip? slip;
  /// แอดมินยืนยันรับเงินแล้ว (ไม่มีสลิปจากผู้เช่า)
  final DateTime? adminConfirmedAt;
  final String? adminConfirmedBy;
  final String? adminConfirmNote;

  bool get hasSlip => slip != null;

  bool get isAdminConfirmed =>
      status == RentalInstallmentStatus.confirmed && adminConfirmedAt != null;

  /// ปิดรอบแล้ว — สลิปหรือแอดมินยืนยัน → หยุดเตือน
  bool get isSettled =>
      remindersPaused ||
      status == RentalInstallmentStatus.slipSubmitted ||
      status == RentalInstallmentStatus.confirmed;

  int daysLate(DateTime today) {
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final now = DateTime(today.year, today.month, today.day);
    final diff = now.difference(due).inDays;
    return diff > 0 ? diff : 0;
  }

  RentalPaymentInstallment copyWith({
    RentalInstallmentStatus? status,
    List<int>? remindersSentDaysBefore,
    bool? remindersPaused,
    RentalPaymentSlip? slip,
    bool clearSlip = false,
    DateTime? adminConfirmedAt,
    String? adminConfirmedBy,
    String? adminConfirmNote,
    bool clearAdminConfirm = false,
  }) {
    return RentalPaymentInstallment(
      id: id,
      sequence: sequence,
      dueDate: dueDate,
      status: status ?? this.status,
      remindersSentDaysBefore:
          remindersSentDaysBefore ?? this.remindersSentDaysBefore,
      remindersPaused: remindersPaused ?? this.remindersPaused,
      slip: clearSlip ? null : (slip ?? this.slip),
      adminConfirmedAt:
          clearAdminConfirm ? null : (adminConfirmedAt ?? this.adminConfirmedAt),
      adminConfirmedBy:
          clearAdminConfirm ? null : (adminConfirmedBy ?? this.adminConfirmedBy),
      adminConfirmNote:
          clearAdminConfirm ? null : (adminConfirmNote ?? this.adminConfirmNote),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sequence': sequence,
        'due_date': dueDate.toIso8601String(),
        'status': status.name,
        'reminders_sent_days_before': remindersSentDaysBefore,
        'reminders_paused': remindersPaused,
        if (slip != null) 'slip': slip!.toJson(),
        if (adminConfirmedAt != null)
          'admin_confirmed_at': adminConfirmedAt!.toIso8601String(),
        if (adminConfirmedBy != null) 'admin_confirmed_by': adminConfirmedBy,
        if (adminConfirmNote != null) 'admin_confirm_note': adminConfirmNote,
      };

  factory RentalPaymentInstallment.fromJson(Map<String, dynamic> j) {
    return RentalPaymentInstallment(
      id: j['id']?.toString() ?? '',
      sequence: (j['sequence'] as num?)?.toInt() ?? 0,
      dueDate: DateTime.tryParse(j['due_date']?.toString() ?? '') ??
          DateTime.now(),
      status: RentalInstallmentStatus.values.firstWhere(
        (s) => s.name == j['status']?.toString(),
        orElse: () => RentalInstallmentStatus.pending,
      ),
      remindersSentDaysBefore: (j['reminders_sent_days_before'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      remindersPaused: j['reminders_paused'] == true,
      slip: j['slip'] is Map
          ? RentalPaymentSlip.fromJson(
              Map<String, dynamic>.from(j['slip'] as Map),
            )
          : null,
      adminConfirmedAt: j['admin_confirmed_at'] != null
          ? DateTime.tryParse(j['admin_confirmed_at'].toString())
          : null,
      adminConfirmedBy: j['admin_confirmed_by']?.toString(),
      adminConfirmNote: j['admin_confirm_note']?.toString(),
    );
  }
}
