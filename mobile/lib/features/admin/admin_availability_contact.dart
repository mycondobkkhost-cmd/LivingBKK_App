import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/availability_alert.dart';
import '../../models/vault_asset.dart';
import '../../services/chat_service.dart';
import '../../services/registry_asset_ops_service.dart';
import '../../services/vault_repository.dart';
import '../../theme/admin_theme.dart';
import 'admin_asset_registry_widgets.dart';

/// ติดต่อเจ้าของตามกฎคลังลับ — เบอร์อยู่ในคลังลับ · แอดมินขอสิทธิ์จาก SUPER+
class AdminAvailabilityContactActions {
  AdminAvailabilityContactActions._();

  static bool hasAccess({
    required String listingId,
    required String adminTier,
  }) =>
      RegistryAssetOpsService.instance.hasChatAccess(
        entityType: 'listing',
        entityId: listingId,
        adminTier: adminTier,
      );

  static bool hasPendingRequest(String listingId) =>
      RegistryAssetOpsService.instance.hasPendingChatRequest(
        entityType: 'listing',
        entityId: listingId,
      );

  static Future<void> requestContactAccess(
    BuildContext context, {
    required AvailabilityAlertItem item,
  }) async {
    final s = context.s;
    final reasonCtrl = TextEditingController(
      text: s.adminAvailabilityRequestDefaultReason(item.listingCode),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.adminAvailabilityRequestContactTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.adminAvailabilityVaultPhoneHint, style: AdminTheme.caption),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: s.adminRegistryChatRequestReason,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.adminRegistryChatRequestSubmit),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      reasonCtrl.dispose();
      return;
    }
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminRegistryChatRequestNeedReason)),
      );
      return;
    }
    RegistryAssetOpsService.instance.requestChatAccess(
      entityType: 'listing',
      entityId: item.listingId,
      actor: 'แอดมิน',
      reason: reason,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminRegistryChatRequestSent)),
    );
  }

  static Future<void> openOwnerChat(
    BuildContext context, {
    required AvailabilityAlertItem item,
    required String adminTier,
  }) async {
    final s = context.s;
    if (!hasAccess(listingId: item.listingId, adminTier: adminTier)) {
      await requestContactAccess(context, item: item);
      return;
    }
    final room = ChatService.instance.roomForListing(item.listingCode);
    if (room != null) {
      context.go('/admin/console?room=${room.id}');
      return;
    }
    context.go('/admin/console');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminAvailabilityChatHint(item.listingCode))),
    );
  }

  static Future<void> openVaultListing(
    BuildContext context, {
    required AvailabilityAlertItem item,
    required String adminTier,
    required bool confidential,
  }) async {
    final s = context.s;
    try {
      final detail = await VaultRepository.instance.detail(
        entityType: 'listing',
        entityId: item.listingId,
      );
      if (!context.mounted) return;
      await openAssetRegistryDetailSheet(
        context: context,
        detail: detail,
        confidential: confidential,
        adminTier: adminTier,
        isDemoPreview: VaultRepository.instance.isDemoPreview,
      );
    } catch (_) {
      if (!context.mounted) return;
      final summary = VaultAssetSummary(
        id: item.listingId,
        entityType: 'listing',
        entityId: item.listingId,
        listingId: item.listingId,
        listingCode: item.listingCode,
        titlePreview: item.title,
      );
      await openAssetRegistryDetailSheet(
        context: context,
        detail: VaultAssetDetail(summary: summary, payload: {}),
        confidential: confidential,
        adminTier: adminTier,
        isDemoPreview: true,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminAvailabilityOpenRegistryFallback)),
      );
    }
  }
}
