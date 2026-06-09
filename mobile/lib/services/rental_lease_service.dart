import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import '../models/rental_album_note.dart';
import '../models/rental_album_photo.dart';
import '../models/rental_contract_attachment.dart';
import '../models/rental_group_member.dart';
import '../models/rental_lease.dart';
import '../models/rental_payment_installment.dart';
import '../models/rental_payment_policy.dart';
import 'rental_payment_logic.dart';
import 'rental_payment_notification_service.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// บริหารสัญญาเช่า + แชทกลุ่ม — scaffold สำหรับ Phase 27
class RentalLeaseService extends ChangeNotifier {
  RentalLeaseService._();
  static final RentalLeaseService instance = RentalLeaseService._();

  static const _prefsKey = 'rental_leases_v2';

  final List<RentalLease> _leases = [];
  bool _loaded = false;
  bool _dbHydrated = false;

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  List<RentalLease> get allLeases => List.unmodifiable(_leases);

  List<RentalLease> leasesForUser(String? userId) {
    if (userId == null || userId.isEmpty) return demoLeases;
    return _leases
        .where(
          (l) => l.isActive && l.members.any((m) => m.userId == userId),
        )
        .toList();
  }

  List<RentalLease> get demoLeases =>
      _leases.where((l) => l.id.startsWith('demo-lease-')).toList();

  RentalLease? leaseById(String id) {
    for (final l in _leases) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;

    if (_live) {
      await _hydrateFromDb();
    }

    if (!_dbHydrated) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final list = jsonDecode(raw);
          if (list is List) {
            for (final item in list) {
              if (item is Map) {
                _leases.add(
                  RentalLease.fromJson(Map<String, dynamic>.from(item)),
                );
              }
            }
          }
        } catch (_) {}
      }
    }

    if (_leases.isEmpty) _seedDemo();
    _ensurePaymentSchedules();
    await _seedDemoAlbumIfMissing();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _hydrateFromDb() async {
    try {
      final rows = await SupabaseService.client!
          .from('rental_leases')
          .select(
            '*, members:rental_lease_members(*), '
            'installments:rental_payment_installments(*), '
            'attachments:rental_group_attachments(*)',
          )
          .order('created_at', ascending: false)
          .limit(50);

      final parsed = <RentalLease>[];
      for (final raw in rows as List) {
        if (raw is! Map) continue;
        final lease = _leaseFromDbRow(Map<String, dynamic>.from(raw));
        if (lease != null) parsed.add(lease);
      }

      if (parsed.isNotEmpty) {
        _leases
          ..clear()
          ..addAll(parsed);
        _dbHydrated = true;
      }
    } catch (_) {}
  }

  RentalLease? _leaseFromDbRow(Map<String, dynamic> row) {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return null;

    final membersRaw = row['members'];
    final members = <RentalGroupMember>[];
    if (membersRaw is List) {
      for (final m in membersRaw) {
        if (m is Map) members.add(RentalGroupMember.fromJson(
              Map<String, dynamic>.from(m),
            ));
      }
    }

    final instRaw = row['installments'];
    final installments = <RentalPaymentInstallment>[];
    if (instRaw is List) {
      for (final inst in instRaw) {
        if (inst is Map) {
          final map = Map<String, dynamic>.from(inst);
          final status = map['status']?.toString();
          if (status == 'slip_submitted') {
            map['status'] = 'slipSubmitted';
          }
          installments.add(RentalPaymentInstallment.fromJson(map));
        }
      }
      installments.sort((a, b) => a.sequence.compareTo(b.sequence));
    }

    final attachRaw = row['attachments'];
    final attachments = <RentalContractAttachment>[];
    if (attachRaw is List) {
      for (final att in attachRaw) {
        if (att is! Map) continue;
        final map = Map<String, dynamic>.from(att);
        if (map['kind']?.toString() != 'document') continue;
        attachments.add(RentalContractAttachment(
          id: map['id']?.toString() ?? '',
          fileName: map['file_name']?.toString() ?? '',
          uploadedAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now(),
          uploadedBy: map['uploaded_by']?.toString() ?? '',
          note: map['note']?.toString(),
        ));
      }
    }

    final albumPhotos = <RentalAlbumPhoto>[];
    if (attachRaw is List) {
      for (final att in attachRaw) {
        if (att is! Map) continue;
        final map = Map<String, dynamic>.from(att);
        if (map['kind']?.toString() != 'album_photo') continue;
        albumPhotos.add(RentalAlbumPhoto(
          id: map['id']?.toString() ?? '',
          fileName: map['file_name']?.toString() ?? '',
          uploadedAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now(),
          uploadedBy: map['uploaded_by']?.toString() ?? '',
        ));
      }
    }

    RentalAlbumNote? albumNote;
    final albumNoteRaw = row['album_note'];
    if (albumNoteRaw is Map) {
      albumNote = RentalAlbumNote.fromJson(
        Map<String, dynamic>.from(albumNoteRaw),
      );
    }

    return RentalLease(
      id: id,
      listingId: row['listing_id']?.toString() ?? '',
      listingCode: row['listing_code']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      rentAmount: (row['rent_amount'] as num?)?.toInt() ?? 0,
      paymentDayOfMonth:
          (row['payment_day_of_month'] as num?)?.toInt() ?? 1,
      billingCycle: RentalBillingCycle.values.firstWhere(
        (c) => c.name == row['billing_cycle']?.toString(),
        orElse: () => RentalBillingCycle.monthly,
      ),
      leaseStart: DateTime.tryParse(row['lease_start']?.toString() ?? '') ??
          DateTime.now(),
      contractSignedAt: row['contract_signed_at'] != null
          ? DateTime.tryParse(row['contract_signed_at'].toString())
          : null,
      leaseEnd: row['lease_end'] != null
          ? DateTime.tryParse(row['lease_end'].toString())
          : null,
      status: RentalLeaseStatus.values.firstWhere(
        (s) => s.name == row['status']?.toString(),
        orElse: () => RentalLeaseStatus.active,
      ),
      threadId: row['thread_id']?.toString(),
      members: members,
      bankAccountNote: row['bank_account_note']?.toString(),
      projectName: row['project_name']?.toString(),
      district: row['district']?.toString(),
      contractAttachments: attachments,
      paymentPolicy: RentalPaymentPolicy.fromJson(
        row['payment_policy'] is Map
            ? Map<String, dynamic>.from(row['payment_policy'] as Map)
            : null,
      ),
      paymentInstallments: installments,
      albumPhotos: albumPhotos,
      albumNote: albumNote,
    );
  }

  Future<void> _seedDemoAlbumIfMissing() async {
    if (!Env.adminDemoCases && !Env.trialMode) return;
    for (var i = 0; i < _leases.length; i++) {
      final lease = _leases[i];
      if (!lease.id.startsWith('demo-lease-')) continue;
      if (lease.albumPhotos.isNotEmpty && lease.albumNote != null) continue;
      final today = DateTime.now();
      final photos = lease.albumPhotos.isNotEmpty
          ? lease.albumPhotos
          : List.generate(
              8,
              (n) => RentalAlbumPhoto(
                id: 'album-demo-${n + 1}',
                fileName: 'pre-move-in-${n + 1}.jpg',
                uploadedAt: today.subtract(const Duration(days: 118)),
                uploadedBy: 'แอดมิน · Ops',
              ),
            );
      _leases[i] = lease.copyWith(
        albumPhotos: photos,
        albumNote: lease.albumNote ??
            RentalAlbumNote(
              updatedAt: today.subtract(const Duration(days: 118)),
              updatedBy: 'แอดมิน · Ops',
              body: '''สภาพห้องก่อนเข้าอยู่ (มอบห้อง)

• ห้องนอน — ผนังไม่มีรอย แอร์ทำงานปกติ ม่านครบ
• ห้องน้ำ — สุขภัณฑ์ปกติ ไม่รั่ว
• ห้องนั่งเล่น — มีรอยขีดข่วนที่พื้น (บันทึกไว้ก่อนเข้าอยู่)
• มิเตอร์ ณ วันมอบห้อง — น้ำ 1,245 · ไฟ 8,902

รูปทั้งหมดในอัลบั้มด้านล่าง — ไม่มีคำกำกับต่อรูป อ้างอิงจากโน้ตนี้''',
            ),
      );
    }
    await _persist();
  }

  void _ensurePaymentSchedules() {
    for (var i = 0; i < _leases.length; i++) {
      final lease = _leases[i];
      if (lease.paymentInstallments.isNotEmpty) continue;
      final year = lease.paymentPolicy.policyYear ?? DateTime.now().year;
      final policy = lease.paymentPolicy.copyWith(policyYear: year);
      final installments = RentalPaymentLogic.generateInstallments(
        lease: lease.copyWith(paymentPolicy: policy),
        year: year,
      );
      _leases[i] = lease.copyWith(
        paymentPolicy: policy,
        paymentInstallments: installments,
      );
    }
  }

  void ensureDemoData() {
    if (_loaded) return;
    if (_leases.isEmpty) _seedDemo();
  }

  void _seedDemo() {
    if (!Env.adminDemoCases && !Env.trialMode) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDue = today.add(
      Duration(days: (5 - now.weekday + 7) % 7 + 7),
    );
    final year = now.year;
    final policy = RentalPaymentPolicy(
      reminderDaysBefore: const [2, 1],
      installmentsPerYear: 12,
      graceDaysLate: 3,
      penaltyPerDayAfterGrace: 100,
      policyYear: year,
    );

    var installments = RentalPaymentLogic.generateInstallments(
      lease: RentalLease(
        id: 'demo-lease-1',
        listingId: 'demo-avail-2',
        listingCode: 'RXT-2026-004522',
        title: 'ให้เช่า ไลฟ์ อ่อนนุช 1 นอน',
        rentAmount: 18500,
        paymentDayOfMonth: 5,
        billingCycle: RentalBillingCycle.monthly,
        leaseStart: today.subtract(const Duration(days: 120)),
        paymentPolicy: policy,
      ),
      year: year,
    );
    installments = installments.map((inst) {
      if (inst.dueDate.isBefore(today) && inst.dueDate.month < now.month) {
        return inst.copyWith(
          status: RentalInstallmentStatus.slipSubmitted,
          remindersPaused: true,
          slip: RentalPaymentSlip(
            id: 'slip-${inst.id}',
            fileName: 'slip-${inst.dueDate.month}-2026.jpg',
            uploadedAt: inst.dueDate.add(const Duration(days: 1)),
            uploadedBy: 'ผู้เช่า · คุณมิ้นท์',
          ),
        );
      }
      return inst;
    }).toList();

    _leases.add(
      RentalLease(
        id: 'demo-lease-1',
        listingId: 'demo-avail-2',
        listingCode: 'RXT-2026-004522',
        title: 'ให้เช่า ไลฟ์ อ่อนนุช 1 นอน',
        projectName: 'Life Asoke Hype',
        district: 'วัฒนา',
        rentAmount: 18500,
        paymentDayOfMonth: 5,
        billingCycle: RentalBillingCycle.monthly,
        contractSignedAt: today.subtract(const Duration(days: 125)),
        leaseStart: today.subtract(const Duration(days: 120)),
        leaseEnd: today.add(const Duration(days: 245)),
        threadId: 'demo-rental-thread-1',
        nextPaymentDue: nextDue,
        bankAccountNote:
            'KBANK · 123-4-56789-0 · ชื่อบัญชีตามสัญญา (ไม่แสดงเบอร์)',
        contractAttachments: [
          RentalContractAttachment(
            id: 'demo-contract-1',
            fileName: 'สัญญาเช่า-Life-Onnut-2026.pdf',
            uploadedAt: today.subtract(const Duration(days: 125)),
            uploadedBy: 'demo@realxtateth.com',
            note: 'สัญญาฉบับลงนาม',
          ),
        ],
        paymentPolicy: policy,
        paymentInstallments: installments,
        albumPhotos: List.generate(
          8,
          (n) => RentalAlbumPhoto(
            id: 'album-demo-${n + 1}',
            fileName: 'pre-move-in-${n + 1}.jpg',
            uploadedAt: today.subtract(const Duration(days: 118)),
            uploadedBy: 'แอดมิน · Ops',
          ),
        ),
        albumNote: RentalAlbumNote(
          updatedAt: today.subtract(const Duration(days: 118)),
          updatedBy: 'แอดมิน · Ops',
          body: '''สภาพห้องก่อนเข้าอยู่ (มอบห้อง)

• ห้องนอน — ผนังไม่มีรอย แอร์ทำงานปกติ ม่านครบ
• ห้องน้ำ — สุขภัณฑ์ปกติ ไม่รั่ว
• ห้องนั่งเล่น — มีรอยขีดข่วนที่พื้น (บันทึกไว้ก่อนเข้าอยู่)
• มิเตอร์ ณ วันมอบห้อง — น้ำ 1,245 · ไฟ 8,902

รูปทั้งหมดในอัลบั้มด้านล่าง — ไม่มีคำกำกับต่อรูป อ้างอิงจากโน้ตนี้''',
        ),
        members: const [
          RentalGroupMember(
            userId: 'demo-tenant',
            role: RentalMemberRole.tenant,
            displayLabel: 'ผู้เช่า · คุณมิ้นท์',
            profileTagCode: 'SP-2026-00088',
          ),
          RentalGroupMember(
            userId: 'demo-owner',
            role: RentalMemberRole.owner,
            displayLabel: 'เจ้าของ · คุณสมชาย',
          ),
          RentalGroupMember(
            userId: 'demo-agent',
            role: RentalMemberRole.agent,
            displayLabel: 'เอเจ้นท์ · PR-2026-00012',
            profileTagCode: 'PR-2026-00012',
          ),
          RentalGroupMember(
            userId: 'demo-admin',
            role: RentalMemberRole.admin,
            displayLabel: 'แอดมิน · Ops',
          ),
        ],
      ),
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_leases.map((l) => l.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  void _replaceLease(RentalLease updated) {
    final i = _leases.indexWhere((l) => l.id == updated.id);
    if (i >= 0) {
      _leases[i] = updated;
    }
  }

  Future<void> updateLeaseDates({
    required String leaseId,
    required DateTime contractSignedAt,
    required DateTime leaseStart,
    DateTime? leaseEnd,
  }) async {
    await ensureLoaded();
    final cur = leaseById(leaseId);
    if (cur == null) return;
    _replaceLease(
      cur.copyWith(
        contractSignedAt: contractSignedAt,
        leaseStart: leaseStart,
        leaseEnd: leaseEnd,
        clearLeaseEnd: leaseEnd == null,
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> attachContract({
    required String leaseId,
    required String fileName,
    required String uploadedBy,
    String? note,
  }) async {
    await ensureLoaded();
    final cur = leaseById(leaseId);
    if (cur == null) return;
    final attachment = RentalContractAttachment(
      id: 'att-${DateTime.now().millisecondsSinceEpoch}',
      fileName: fileName,
      uploadedAt: DateTime.now(),
      uploadedBy: uploadedBy,
      note: note,
      mimeType: _guessMime(fileName),
    );
    _replaceLease(
      cur.copyWith(
        contractAttachments: [...cur.contractAttachments, attachment],
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> removeAttachment({
    required String leaseId,
    required String attachmentId,
  }) async {
    await ensureLoaded();
    final cur = leaseById(leaseId);
    if (cur == null) return;
    _replaceLease(
      cur.copyWith(
        contractAttachments: cur.contractAttachments
            .where((a) => a.id != attachmentId)
            .toList(),
      ),
    );
    await _persist();
    notifyListeners();
  }

  String? _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    return null;
  }

  RentalLease createLeaseGroup({
    required String listingId,
    required String listingCode,
    required String title,
    required List<RentalGroupMember> members,
    required int rentAmount,
    required int paymentDayOfMonth,
    RentalBillingCycle billingCycle = RentalBillingCycle.monthly,
  }) {
    final id = 'lease-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final lease = RentalLease(
      id: id,
      listingId: listingId,
      listingCode: listingCode,
      title: title,
      rentAmount: rentAmount,
      paymentDayOfMonth: paymentDayOfMonth,
      billingCycle: billingCycle,
      contractSignedAt: now,
      leaseStart: now,
      threadId: 'rental-thread-$id',
      members: members,
      nextPaymentDue: _nextDueDate(paymentDayOfMonth),
    );
    _leases.add(lease);
    _persist();
    notifyListeners();
    return lease;
  }

  Future<void> updatePaymentPolicy({
    required String leaseId,
    required RentalPaymentPolicy policy,
    bool regenerateInstallments = false,
  }) async {
    await ensureLoaded();
    final cur = leaseById(leaseId);
    if (cur == null) return;
    final year = policy.policyYear ?? DateTime.now().year;
    final nextPolicy = policy.copyWith(policyYear: year);
    var installments = cur.paymentInstallments;
    if (regenerateInstallments || installments.isEmpty) {
      installments = RentalPaymentLogic.generateInstallments(
        lease: cur.copyWith(paymentPolicy: nextPolicy),
        year: year,
      );
    }
    _replaceLease(
      cur.copyWith(
        paymentPolicy: nextPolicy,
        paymentInstallments: installments,
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> sendPaymentReminder({
    required String leaseId,
    required String installmentId,
    required int daysBefore,
  }) async {
    await ensureLoaded();
    final cur = leaseById(leaseId);
    if (cur == null) return;
    final updated = cur.paymentInstallments.map((inst) {
      if (inst.id != installmentId) return inst;
      if (inst.isSettled) return inst;
      final sent = [...inst.remindersSentDaysBefore];
      if (!sent.contains(daysBefore)) sent.add(daysBefore);
      sent.sort((a, b) => b.compareTo(a));
      return inst.copyWith(remindersSentDaysBefore: sent);
    }).toList();
    _replaceLease(cur.copyWith(paymentInstallments: updated));
    await _persist();
    notifyListeners();

    final inst = updated.firstWhere((i) => i.id == installmentId);
    await RentalPaymentNotificationService.instance.notifyPaymentReminder(
      lease: cur,
      inst: inst,
      daysBefore: daysBefore,
    );
  }

  Future<void> runDueReminders({required String leaseId}) async {
    await ensureLoaded();
    final cur = leaseById(leaseId);
    if (cur == null) return;
    final pending = RentalPaymentLogic.pendingReminders(lease: cur);
    for (final item in pending) {
      await sendPaymentReminder(
        leaseId: leaseId,
        installmentId: item.inst.id,
        daysBefore: item.daysBefore,
      );
    }
  }

  Future<void> adminConfirmPayment({
    required String leaseId,
    required String installmentId,
    required String confirmedBy,
    String? note,
  }) async {
    await ensureLoaded();
    final cur = leaseById(leaseId);
    if (cur == null) return;
    final now = DateTime.now();
    final updated = cur.paymentInstallments.map((inst) {
      if (inst.id != installmentId) return inst;
      return inst.copyWith(
        status: RentalInstallmentStatus.confirmed,
        remindersPaused: true,
        adminConfirmedAt: now,
        adminConfirmedBy: confirmedBy,
        adminConfirmNote: note,
      );
    }).toList();
    _replaceLease(cur.copyWith(paymentInstallments: updated));
    await _persist();
    notifyListeners();

    final inst = updated.firstWhere((i) => i.id == installmentId);
    await RentalPaymentNotificationService.instance.notifyAdminConfirmed(
      lease: cur,
      inst: inst,
      note: note,
    );
  }

  Future<void> submitPaymentSlip({
    required String leaseId,
    required String installmentId,
    required String fileName,
    required String uploadedBy,
    String? note,
  }) async {
    await ensureLoaded();
    final cur = leaseById(leaseId);
    if (cur == null) return;
    final slip = RentalPaymentSlip(
      id: 'slip-${DateTime.now().millisecondsSinceEpoch}',
      fileName: fileName,
      uploadedAt: DateTime.now(),
      uploadedBy: uploadedBy,
      note: note,
    );
    final updated = cur.paymentInstallments.map((inst) {
      if (inst.id != installmentId) return inst;
      return inst.copyWith(
        status: RentalInstallmentStatus.slipSubmitted,
        remindersPaused: true,
        slip: slip,
      );
    }).toList();
    _replaceLease(cur.copyWith(paymentInstallments: updated));
    await _persist();
    notifyListeners();

    final inst = updated.firstWhere((i) => i.id == installmentId);
    await RentalPaymentNotificationService.instance.notifySlipSubmitted(
      lease: cur,
      inst: inst,
      uploadedBy: uploadedBy,
    );
  }

  Future<int> addAlbumPhotosBulk({
    required String leaseId,
    required List<String> fileNames,
    required String uploadedBy,
  }) async {
    await ensureLoaded();
    final cur = leaseById(leaseId);
    if (cur == null) return 0;
    final now = DateTime.now();
    final added = <RentalAlbumPhoto>[];
    for (final name in fileNames) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      added.add(
        RentalAlbumPhoto(
          id: 'album-${now.millisecondsSinceEpoch}-${added.length}',
          fileName: trimmed,
          uploadedAt: now,
          uploadedBy: uploadedBy,
        ),
      );
    }
    if (added.isEmpty) return 0;
    _replaceLease(
      cur.copyWith(albumPhotos: [...cur.albumPhotos, ...added]),
    );
    await _persist();
    notifyListeners();
    return added.length;
  }

  Future<void> removeAlbumPhoto({
    required String leaseId,
    required String photoId,
  }) async {
    await ensureLoaded();
    final cur = leaseById(leaseId);
    if (cur == null) return;
    _replaceLease(
      cur.copyWith(
        albumPhotos: cur.albumPhotos.where((p) => p.id != photoId).toList(),
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> saveAlbumNote({
    required String leaseId,
    required String body,
    required String updatedBy,
  }) async {
    await ensureLoaded();
    final cur = leaseById(leaseId);
    if (cur == null) return;
    _replaceLease(
      cur.copyWith(
        albumNote: RentalAlbumNote(
          body: body,
          updatedAt: DateTime.now(),
          updatedBy: updatedBy,
        ),
      ),
    );
    await _persist();
    notifyListeners();
  }

  DateTime _nextDueDate(int dayOfMonth) {
    final now = DateTime.now();
    var due = DateTime(now.year, now.month, dayOfMonth.clamp(1, 28));
    if (!due.isAfter(now)) {
      due = DateTime(now.year, now.month + 1, dayOfMonth.clamp(1, 28));
    }
    return due;
  }
}
