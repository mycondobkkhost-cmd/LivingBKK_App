import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../widgets/admin_mobile_layout.dart';
import 'admin_chat_panel.dart';

/// หน้าแชทแอดมิน (มือถือ) — บน Web ส่งไป console อัตโนมัติ
class AdminChatDetailPage extends StatefulWidget {
  const AdminChatDetailPage({super.key, required this.roomId});

  final String roomId;

  @override
  State<AdminChatDetailPage> createState() => _AdminChatDetailPageState();
}

class _AdminChatDetailPageState extends State<AdminChatDetailPage> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/admin/console?room=${widget.roomId}');
      });
    }
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
      appBar: AdminMobileLayout.appBar(context: context, title: Text(s.adminChatTitle)),
      safeBottom: false,
      body: AdminChatPanel(roomId: widget.roomId),
    );
  }
}
