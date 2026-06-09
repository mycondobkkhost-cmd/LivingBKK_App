import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/demo_cast_simulation.dart';
import '../features/admin/admin_nav_model.dart';
import '../features/contact/chat_link_detail_sheets.dart';
import '../l10n/app_strings.dart';
import '../services/appointment_repository.dart';
import '../services/chat_service.dart';
import '../utils/admin_listing_nav.dart';
import '../utils/admin_routing.dart';
import '../utils/reference_codes.dart';

/// หน้าปัจจุบัน — ใช้ย้อนกลับหลังเปิดแชท/รายละเอียดจากแท็ก
AdminNavId? adminReturnNavFromContext(BuildContext context) {
  final uri = GoRouterState.of(context).uri;
  if (uri.path.startsWith('/admin/lead/')) return AdminNavId.leads;
  if (uri.path.startsWith('/admin/console')) return AdminNavId.inbox;
  return AdminNavId.fromQueryName(uri.queryParameters['nav']);
}

Future<String?> resolveLeadIdFromRef(String ref) async {
  final code = ref.trim();
  if (code.isEmpty) return null;
  for (final lead in DemoCastSimulation.leads()) {
    if (lead['transaction_ref']?.toString() == code) {
      return lead['id']?.toString();
    }
  }
  return null;
}

bool isNavigableListingCode(String code) {
  final upper = code.trim().toUpperCase();
  if (upper.isEmpty || ReferenceCodes.isSpecialListingCode(upper)) {
    return false;
  }
  return upper.startsWith('RENT-') ||
      upper.startsWith('SALE-') ||
      ReferenceCodes.isInventoryCode(upper) ||
      ReferenceCodes.pirListingPattern.hasMatch(upper);
}

/// กดแท็ก/รหัสอ้างอิงหลังบ้าน — ปุ่มคัดลอกแยกต่างหาก (ไม่เรียกฟังก์ชันนี้)
Future<void> openAdminReferenceCode(
  BuildContext context, {
  required String code,
  String? leadId,
  String? listingId,
  String? listingCode,
  String? threadId,
}) async {
  final trimmed = code.trim();
  if (trimmed.isEmpty) return;
  final upper = trimmed.toUpperCase();
  final s = AppStrings.of(context);
  final returnNav = adminReturnNavFromContext(context);

  if (upper.startsWith('SP-') ||
      upper.startsWith('CL-') ||
      upper.startsWith('PR-')) {
    await showProfileTagDetailSheet(context, trimmed, adminView: true);
    return;
  }
  if (upper.startsWith('VR-')) {
    await showViewingRequestDetailSheet(context, trimmed, adminView: true);
    return;
  }

  if (upper.startsWith('LEAD-')) {
    final id = leadId ?? await resolveLeadIdFromRef(trimmed);
    if (!context.mounted) return;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.notFoundLead)),
      );
      return;
    }
    final path = '/admin/lead/$id';
    if (GoRouterState.of(context).uri.path == path) return;
    await context.push(path);
    return;
  }

  if (upper.startsWith('CHAT-')) {
    final room = ChatService.instance.roomByTransactionRef(trimmed) ??
        (threadId != null ? ChatService.instance.roomById(threadId) : null);
    if (!context.mounted) return;
    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.notFoundChat)),
      );
      return;
    }
    final fromQ =
        returnNav != null ? '&${kAdminReturnNavKey}=${returnNav.name}' : '';
    if (kIsWeb) {
      await context.push('/admin/console?room=${room.id}$fromQ');
    } else {
      await context.push('/admin/chat/${room.id}');
    }
    return;
  }

  if (upper.startsWith('APPT-')) {
    final appt = await AppointmentRepository().fetchByTransactionRef(trimmed);
    if (!context.mounted) return;
    if (appt?.leadId != null && appt!.leadId!.isNotEmpty) {
      await context.push('/admin/lead/${appt.leadId}');
      return;
    }
    await context.push('/admin?nav=viewingCalendar');
    return;
  }

  if (isNavigableListingCode(trimmed)) {
    await openAdminListing(
      context,
      listingId: listingId,
      listingCode: trimmed,
    );
    return;
  }

  if (listingCode != null &&
      listingCode.trim().isNotEmpty &&
      listingCode.trim().toUpperCase() == upper) {
    await openAdminListing(
      context,
      listingId: listingId,
      listingCode: listingCode,
    );
  }
}

VoidCallback? adminReferenceNavigateHandler(
  BuildContext context, {
  required String code,
  String? leadId,
  String? listingId,
  String? listingCode,
  String? threadId,
}) {
  if (code.trim().isEmpty) return null;
  return () => openAdminReferenceCode(
        context,
        code: code,
        leadId: leadId,
        listingId: listingId,
        listingCode: listingCode,
        threadId: threadId,
      );
}
