import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/contact/property_chat_page.dart';
import '../services/listing_repository.dart';
import '../services/chat_service.dart';
import 'dev_three_role_login.dart';

/// localhost — เปิดแชททรัพย์จาก `?devListing=CODE&devOpenChat=1`
class DevPovBootstrap {
  DevPovBootstrap._();

  static const paramListing = 'devListing';
  static const paramOpenChat = 'devOpenChat';

  static bool _opened = false;

  static Future<void> maybeOpenListingChat(BuildContext context) async {
    if (_opened || !kDebugMode || !DevThreeRoleLogin.isDevHost) return;
    final uri = Uri.base;
    if (uri.queryParameters[DevThreeRoleLogin.paramRole] != 'seeker') return;

    final code = uri.queryParameters[paramListing]?.trim();
    if (code == null || code.isEmpty) return;
    if (uri.queryParameters[paramOpenChat] != '1') return;

    for (var i = 0; i < 50; i++) {
      if (ChatService.instance.customerChatBackendActive) break;
      await Future.delayed(const Duration(milliseconds: 120));
      if (!context.mounted) return;
    }

    final listing = await ListingRepository().fetchByListingCode(code);
    if (!context.mounted || listing == null) return;

    _opened = true;
    openPropertyChat(
      context,
      listing,
      allowViewingRequest: true,
    );
  }
}
