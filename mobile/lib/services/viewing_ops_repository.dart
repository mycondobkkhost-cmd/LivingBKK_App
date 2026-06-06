import '../config/env.dart';
import '../utils/pii_sanitizer.dart';
import 'admin_repository.dart';
import 'chat_repository.dart';
import 'supabase_service.dart';

/// ประสานงานนัดดู — แอดมิน → เจ้าของ / แอดมินระดับสูง
class ViewingOpsRepository {
  final _admin = AdminRepository();
  final _chat = ChatRepository();

  Future<String?> resolveOwnerId({
    String? listingId,
    String? listingCode,
  }) async {
    if (!SupabaseService.isReady) return null;
    final client = SupabaseService.client!;
    try {
      if (listingId != null && listingId.isNotEmpty) {
        final row = await client
            .from('listings')
            .select('owner_id, created_by_id')
            .eq('id', listingId)
            .maybeSingle();
        if (row != null) {
          return row['owner_id']?.toString() ??
              row['created_by_id']?.toString();
        }
      }
      if (listingCode != null && listingCode.isNotEmpty) {
        final row = await client
            .from('listings')
            .select('owner_id, created_by_id')
            .eq('listing_code', listingCode)
            .maybeSingle();
        if (row != null) {
          return row['owner_id']?.toString() ??
              row['created_by_id']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> requestSeniorOwnerCall({
    required String leadId,
    String? appointmentId,
    String? listingCode,
    String? note,
  }) async {
    if (!Env.isConfigured || !SupabaseService.isReady) return;
    try {
      await SupabaseService.client!.functions.invoke(
        'route-lead-notification',
        body: {
          'lead_id': leadId,
          'channel': 'senior_owner_call',
          if (appointmentId != null) 'appointment_id': appointmentId,
          if (listingCode != null) 'listing_code': listingCode,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
    } catch (_) {}
    if (note != null && note.isNotEmpty && appointmentId != null) {
      try {
        await SupabaseService.client!
            .from('appointments')
            .update({
              'admin_notes': note,
            })
            .eq('id', appointmentId);
      } catch (_) {}
    }
  }

  /// ส่งโปรไฟล์ลูกค้า (ตัดเบอร์/ไลน์) ไปแชทเจ้าของ + route Lead
  Future<void> sendCensoredProfileToOwner({
    required Map<String, dynamic> lead,
    required String listingCode,
    String? listingId,
    String? listingTitle,
    String? projectName,
    String? appointmentDate,
    String? appointmentSlot,
  }) async {
    final leadId = lead['id']?.toString();
    if (leadId == null || leadId.isEmpty) {
      throw Exception('lead_id missing');
    }

    final ownerId = await resolveOwnerId(
      listingId: listingId ?? lead['listing_id']?.toString(),
      listingCode: listingCode,
    );
    if (ownerId == null || ownerId.isEmpty) {
      throw Exception('owner_not_found');
    }

    final qual = lead['qualification_json'] as Map<String, dynamic>?;
    final viewingSchedule = qual?['viewing_schedule']?.toString();

    final summary = PiiSanitizer.ownerSafeLeadSummary(
      lead,
      viewingSchedule: viewingSchedule,
      appointmentDate: appointmentDate,
      appointmentSlot: appointmentSlot,
    );

    final messageText =
        'คำขอนัดดูจากทีม PROPPITER ($listingCode)\n'
        'กรุณาพิจารณายืนยันรับเคสตามวันเวลาที่ลูกค้าขอ\n\n'
        '$summary\n\n'
        'หมายเหตุ: ไม่แสดงเบอร์โทร/Line เต็ม — ติดต่อผ่านแพลตฟอร์มเท่านั้น';

    await _chat.notifyOwnerViewingRequest(
      ownerUserId: ownerId,
      listingId: listingId ?? lead['listing_id']?.toString(),
      listingCode: listingCode,
      listingTitle: listingTitle ?? listingCode,
      projectName: projectName,
      messageText: messageText,
      leadId: leadId,
    );

    if (Env.isConfigured && SupabaseService.isReady) {
      try {
        await SupabaseService.client!.functions.invoke(
          'route-lead-notification',
          body: {'lead_id': leadId, 'channel': 'owner_viewing_profile'},
        );
      } catch (_) {}
    }
  }

  Future<String?> resolveCustomerThreadId(String? leadId) async {
    if (leadId == null || leadId.isEmpty) return null;
    final lead = await _admin.fetchLead(leadId);
    if (lead == null) return null;
    return _admin.resolveLeadThreadId(lead);
  }
}
