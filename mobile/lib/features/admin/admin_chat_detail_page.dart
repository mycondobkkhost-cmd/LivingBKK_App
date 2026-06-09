import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../utils/admin_routing.dart';
import '../../widgets/admin_mobile_layout.dart';
import 'admin_chat_panel.dart';
import 'admin_nav_model.dart';

/// หน้าแชทแอดมิน (มือถือ) — บน Web ส่งไป console อัตโนมัติ
class AdminChatDetailPage extends StatefulWidget {
  const AdminChatDetailPage({super.key, required this.roomId});

  final String roomId;

  @override
  State<AdminChatDetailPage> createState() => _AdminChatDetailPageState();
}

class _AdminChatDetailPageState extends State<AdminChatDetailPage> {
  AdminNavId? _returnNav;
  bool _webRedirected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _returnNav ??= AdminNavId.fromQueryName(
      GoRouterState.of(context).uri.queryParameters[kAdminReturnNavKey],
    );
    if (kIsWeb && !_webRedirected) {
      _webRedirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final uri = GoRouterState.of(context).uri;
        final msg = uri.queryParameters['message'];
        final q = <String, String>{'room': widget.roomId};
        if (msg != null && msg.isNotEmpty) q['message'] = msg;
        if (_returnNav != null) q[kAdminReturnNavKey] = _returnNav!.name;
        context.go(Uri(path: '/admin/console', queryParameters: q).toString());
      });
    }
  }

  void _goBack(BuildContext context) {
    final returnNav = _returnNav;
    if (returnNav != null &&
        returnNav != AdminNavId.inbox &&
        returnNav != AdminNavId.queue) {
      context.go(adminReturnPath(returnNav));
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/admin/console');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (kIsWeb) {
      return AdminMobileLayout.scaffold(
        context: context,
        appBar: AdminMobileLayout.appBar(context: context, title: Text(s.adminConsoleTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AdminMobileLayout.scaffold(
      context: context,
      safeBottom: false,
      body: AdminChatPanel(
        roomId: widget.roomId,
        embedded: true,
        onBack: () => _goBack(context),
        backTooltip: adminChatBackTooltip(_returnNav, s),
      ),
    );
  }
}
