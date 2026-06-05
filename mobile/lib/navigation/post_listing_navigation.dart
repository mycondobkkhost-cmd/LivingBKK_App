import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/env.dart';
import '../config/post_listing_menu_config.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';

/// นำทางเมนูลงประกาศ — ใช้แทน `context.push('/listing/create')` ตรงๆ
abstract final class PostListingNavigation {
  static void openCreate(BuildContext context) {
    context.push(PostListingMenuConfig.createRoute);
  }

  static void openMyListings(BuildContext context) {
    context.push(PostListingMenuConfig.myListingsRoute);
  }

  /// เปิดฟอร์มลงประกาศ — ยังไม่เข้าสู่ระบบ (รวมเข้าทดลอง) จะพาไป login ก่อน
  static void openCreateWithAuthGate(BuildContext context) {
    final s = AppStrings.of(context);
    if (!AuthService.instance.isSignedIn) {
      if (Env.isConfigured) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.configuredNotLoggedIn)),
        );
      }
      context.push('/login');
      return;
    }
    openCreate(context);
  }
}
