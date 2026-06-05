import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
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
      return Scaffold(
        appBar: AppBar(title: Text(s.adminConsoleTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.adminChatTitle)),
      body: AdminChatPanel(roomId: widget.roomId),
    );
  }
}
