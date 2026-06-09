import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../config/env.dart';
import '../l10n/app_strings.dart';
import '../models/rental_group_member.dart';
import '../models/rental_lease.dart';
import '../models/rental_payment_installment.dart';
import '../state/locale_controller.dart';
import 'in_app_notification_hub.dart';
import 'supabase_service.dart';
import 'system_push_notification.dart';

/// แจ้งเตือนชำระค่าเช่า — ในแอป + push นอกแอป (Web Notifications / FCM)
class RentalPaymentNotificationService {
  RentalPaymentNotificationService._();
  static final RentalPaymentNotificationService instance =
      RentalPaymentNotificationService._();

  AppStrings get _s => AppStrings(LocaleController.instance?.isEnglish ?? false);

  String _dateFmt(DateTime d) {
    final fmt = DateFormat(_s.isEnglish ? 'd MMM yyyy' : 'd MMM yyyy');
    return fmt.format(d);
  }

  List<String> _userIdsForRoles(
    RentalLease lease,
    Iterable<RentalMemberRole> roles,
  ) {
    final roleSet = roles.toSet();
    return lease.members
        .where((m) => roleSet.contains(m.role))
        .map((m) => m.userId)
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> _deliver({
    required String type,
    required String title,
    required String body,
    required RentalLease lease,
    RentalPaymentInstallment? inst,
    required List<String> recipientUserIds,
    Map<String, String> extra = const {},
  }) async {
    final hubText = '$title · $body';
    InAppNotificationHub.instance.show(hubText, countAsUnread: false);

    await showSystemPushNotification(
      title: title,
      body: body,
      tag: 'rental-${lease.id}-${inst?.id ?? type}',
    );

    if (!Env.isConfigured || !SupabaseService.isReady) return;
    if (recipientUserIds.isEmpty) return;

    try {
      await SupabaseService.client!.functions.invoke(
        'notify-rental-payment',
        body: {
          'event': type,
          'lease_id': lease.id,
          'listing_code': lease.listingCode,
          if (inst != null) ...{
            'installment_id': inst.id,
            'installment_sequence': inst.sequence,
            'due_date': inst.dueDate.toIso8601String(),
          },
          'recipient_user_ids': recipientUserIds,
          ...extra,
        },
      );
    } catch (e) {
      debugPrint('notify-rental-payment skipped: $e');
    }
  }

  Future<void> notifyPaymentReminder({
    required RentalLease lease,
    required RentalPaymentInstallment inst,
    required int daysBefore,
  }) async {
    final title = _s.rentalPushReminderTitle;
    final body = _s.rentalPushReminderBody(
      lease.listingCode,
      inst.sequence,
      daysBefore,
      _dateFmt(inst.dueDate),
    );
    await _deliver(
      type: 'reminder',
      title: title,
      body: body,
      lease: lease,
      inst: inst,
      recipientUserIds: _userIdsForRoles(lease, [RentalMemberRole.tenant]),
      extra: {'days_before': '$daysBefore'},
    );
  }

  Future<void> notifyAdminConfirmed({
    required RentalLease lease,
    required RentalPaymentInstallment inst,
    String? note,
  }) async {
    final title = _s.rentalPushAdminConfirmedTitle;
    final body = _s.rentalPushAdminConfirmedBody(
      lease.listingCode,
      inst.sequence,
      _dateFmt(inst.dueDate),
    );
    await _deliver(
      type: 'admin_confirmed',
      title: title,
      body: body,
      lease: lease,
      inst: inst,
      recipientUserIds: _userIdsForRoles(
        lease,
        [RentalMemberRole.tenant, RentalMemberRole.owner],
      ),
      extra: note != null && note.isNotEmpty ? {'note': note} : const {},
    );
  }

  Future<void> notifySlipSubmitted({
    required RentalLease lease,
    required RentalPaymentInstallment inst,
    required String uploadedBy,
  }) async {
    final title = _s.rentalPushSlipTitle;
    final body = _s.rentalPushSlipBody(
      lease.listingCode,
      inst.sequence,
      uploadedBy,
    );
    await _deliver(
      type: 'slip_submitted',
      title: title,
      body: body,
      lease: lease,
      inst: inst,
      recipientUserIds: _userIdsForRoles(
        lease,
        [RentalMemberRole.owner, RentalMemberRole.agent, RentalMemberRole.admin],
      ),
    );
  }
}
