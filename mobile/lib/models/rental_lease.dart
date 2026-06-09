import 'rental_album_note.dart';
import 'rental_album_photo.dart';
import 'rental_contract_attachment.dart';
import 'rental_group_member.dart';
import 'rental_payment_installment.dart';
import 'rental_payment_policy.dart';

enum RentalLeaseStatus { active, ended, suspended }

enum RentalBillingCycle { monthly, custom }

/// สัญญาเช่า active — 1 สัญญา = 1 แชทกลุ่ม
class RentalLease {
  const RentalLease({
    required this.id,
    required this.listingId,
    required this.listingCode,
    required this.title,
    required this.rentAmount,
    required this.paymentDayOfMonth,
    required this.billingCycle,
    required this.leaseStart,
    this.contractSignedAt,
    this.leaseEnd,
    this.status = RentalLeaseStatus.active,
    this.threadId,
    this.members = const [],
    this.nextPaymentDue,
    this.bankAccountNote,
    this.projectName,
    this.district,
    this.contractAttachments = const [],
    this.paymentPolicy = const RentalPaymentPolicy(),
    this.paymentInstallments = const [],
    this.albumPhotos = const [],
    this.albumNote,
  });

  final String id;
  final String listingId;
  final String listingCode;
  final String title;
  final int rentAmount;
  final int paymentDayOfMonth;
  final RentalBillingCycle billingCycle;
  /// วันเริ่มสัญญา (occupancy)
  final DateTime leaseStart;
  /// วันที่ทำ/ลงนามสัญญา
  final DateTime? contractSignedAt;
  final DateTime? leaseEnd;
  final RentalLeaseStatus status;
  final String? threadId;
  final List<RentalGroupMember> members;
  final DateTime? nextPaymentDue;
  final String? bankAccountNote;
  final String? projectName;
  final String? district;
  final List<RentalContractAttachment> contractAttachments;
  final RentalPaymentPolicy paymentPolicy;
  final List<RentalPaymentInstallment> paymentInstallments;
  /// อัลบั้มรูปสภาพห้องก่อนเข้าอยู่ (หลายรูป ไม่มีคำกำกับต่อรูป)
  final List<RentalAlbumPhoto> albumPhotos;
  /// โน้ตยาวแบบ LINE
  final RentalAlbumNote? albumNote;

  bool get isActive => status == RentalLeaseStatus.active;

  RentalPaymentInstallment? get nextPendingInstallment {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    RentalPaymentInstallment? best;
    for (final inst in paymentInstallments) {
      if (inst.isSettled) continue;
      final due = DateTime(inst.dueDate.year, inst.dueDate.month, inst.dueDate.day);
      if (due.isBefore(today)) continue;
      if (best == null || inst.dueDate.isBefore(best.dueDate)) best = inst;
    }
    return best ??
        (paymentInstallments.isEmpty
            ? null
            : paymentInstallments.lastWhere(
                (i) => !i.isSettled,
                orElse: () => paymentInstallments.last,
              ));
  }

  String locationLine(bool isEn) {
    final parts = <String>[
      if (projectName != null && projectName!.isNotEmpty) projectName!,
      if (district != null && district!.isNotEmpty) district!,
    ];
    return parts.join(isEn ? ' · ' : ' · ');
  }

  RentalLease copyWith({
    DateTime? contractSignedAt,
    DateTime? leaseStart,
    DateTime? leaseEnd,
    bool clearLeaseEnd = false,
    List<RentalContractAttachment>? contractAttachments,
    DateTime? nextPaymentDue,
    String? bankAccountNote,
    RentalLeaseStatus? status,
    RentalPaymentPolicy? paymentPolicy,
    List<RentalPaymentInstallment>? paymentInstallments,
    List<RentalAlbumPhoto>? albumPhotos,
    RentalAlbumNote? albumNote,
    bool clearAlbumNote = false,
  }) {
    return RentalLease(
      id: id,
      listingId: listingId,
      listingCode: listingCode,
      title: title,
      rentAmount: rentAmount,
      paymentDayOfMonth: paymentDayOfMonth,
      billingCycle: billingCycle,
      leaseStart: leaseStart ?? this.leaseStart,
      contractSignedAt: contractSignedAt ?? this.contractSignedAt,
      leaseEnd: clearLeaseEnd ? null : (leaseEnd ?? this.leaseEnd),
      status: status ?? this.status,
      threadId: threadId,
      members: members,
      nextPaymentDue: nextPaymentDue ?? this.nextPaymentDue,
      bankAccountNote: bankAccountNote ?? this.bankAccountNote,
      projectName: projectName,
      district: district,
      contractAttachments: contractAttachments ?? this.contractAttachments,
      paymentPolicy: paymentPolicy ?? this.paymentPolicy,
      paymentInstallments: paymentInstallments ?? this.paymentInstallments,
      albumPhotos: albumPhotos ?? this.albumPhotos,
      albumNote: clearAlbumNote ? null : (albumNote ?? this.albumNote),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'listing_id': listingId,
        'listing_code': listingCode,
        'title': title,
        'rent_amount': rentAmount,
        'payment_day_of_month': paymentDayOfMonth,
        'billing_cycle': billingCycle.name,
        'lease_start': leaseStart.toIso8601String(),
        if (contractSignedAt != null)
          'contract_signed_at': contractSignedAt!.toIso8601String(),
        if (leaseEnd != null) 'lease_end': leaseEnd!.toIso8601String(),
        'status': status.name,
        if (threadId != null) 'thread_id': threadId,
        'members': members.map((m) => m.toJson()).toList(),
        if (nextPaymentDue != null)
          'next_payment_due': nextPaymentDue!.toIso8601String(),
        if (bankAccountNote != null) 'bank_account_note': bankAccountNote,
        if (projectName != null) 'project_name': projectName,
        if (district != null) 'district': district,
        'contract_attachments':
            contractAttachments.map((a) => a.toJson()).toList(),
        'payment_policy': paymentPolicy.toJson(),
        'payment_installments':
            paymentInstallments.map((i) => i.toJson()).toList(),
        'album_photos': albumPhotos.map((i) => i.toJson()).toList(),
        if (albumNote != null) 'album_note': albumNote!.toJson(),
      };

  factory RentalLease.fromJson(Map<String, dynamic> j) {
    final rawMembers = j['members'];
    var members = <RentalGroupMember>[];
    if (rawMembers is List) {
      members = rawMembers
          .whereType<Map>()
          .map((m) => RentalGroupMember.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    final rawAttachments = j['contract_attachments'];
    var attachments = <RentalContractAttachment>[];
    if (rawAttachments is List) {
      attachments = rawAttachments
          .whereType<Map>()
          .map((m) =>
              RentalContractAttachment.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return RentalLease(
      id: j['id']?.toString() ?? '',
      listingId: j['listing_id']?.toString() ?? '',
      listingCode: j['listing_code']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      rentAmount: (j['rent_amount'] as num?)?.toInt() ?? 0,
      paymentDayOfMonth: (j['payment_day_of_month'] as num?)?.toInt() ?? 1,
      billingCycle: RentalBillingCycle.values.firstWhere(
        (c) => c.name == j['billing_cycle']?.toString(),
        orElse: () => RentalBillingCycle.monthly,
      ),
      leaseStart: DateTime.tryParse(j['lease_start']?.toString() ?? '') ??
          DateTime.now(),
      contractSignedAt: j['contract_signed_at'] != null
          ? DateTime.tryParse(j['contract_signed_at'].toString())
          : null,
      leaseEnd: j['lease_end'] != null
          ? DateTime.tryParse(j['lease_end'].toString())
          : null,
      status: RentalLeaseStatus.values.firstWhere(
        (s) => s.name == j['status']?.toString(),
        orElse: () => RentalLeaseStatus.active,
      ),
      threadId: j['thread_id']?.toString(),
      members: members,
      nextPaymentDue: j['next_payment_due'] != null
          ? DateTime.tryParse(j['next_payment_due'].toString())
          : null,
      bankAccountNote: j['bank_account_note']?.toString(),
      projectName: j['project_name']?.toString(),
      district: j['district']?.toString(),
      contractAttachments: attachments,
      paymentPolicy: RentalPaymentPolicy.fromJson(
        j['payment_policy'] is Map
            ? Map<String, dynamic>.from(j['payment_policy'] as Map)
            : null,
      ),
      paymentInstallments: _parseInstallments(j['payment_installments']),
      albumPhotos: _parseAlbumPhotos(j['album_photos'] ?? j['condition_album']),
      albumNote: j['album_note'] is Map
          ? RentalAlbumNote.fromJson(
              Map<String, dynamic>.from(j['album_note'] as Map),
            )
          : null,
    );
  }

  static List<RentalAlbumPhoto> _parseAlbumPhotos(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) {
          final map = Map<String, dynamic>.from(m);
          return RentalAlbumPhoto.fromJson(map);
        })
        .toList();
  }

  static List<RentalPaymentInstallment> _parseInstallments(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => RentalPaymentInstallment.fromJson(
              Map<String, dynamic>.from(m),
            ))
        .toList();
  }
}

/// ประเภทข้อความ/สิ่งแนบในแชทกลุ่มเช่า (Phase 27b+)
enum RentalGroupMessageKind {
  text,
  document,
  documentNote,
  paymentReminder,
  bankAccountNote,
  maintenanceRequest,
  albumPhoto,
}
