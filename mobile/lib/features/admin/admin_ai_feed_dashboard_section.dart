import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_ai_feed_item.dart';
import '../../services/admin_ai_feed_repository.dart';
import '../../services/admin_ai_feed_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_routing.dart';
import 'admin_ai_feed_sheet.dart';

/// สรุปการ์ด AI ล่าสุดบน Dashboard
class AdminAiFeedDashboardSection extends StatefulWidget {
  const AdminAiFeedDashboardSection({super.key});

  @override
  State<AdminAiFeedDashboardSection> createState() =>
      _AdminAiFeedDashboardSectionState();
}

class _AdminAiFeedDashboardSectionState
    extends State<AdminAiFeedDashboardSection> {
  List<AdminAiFeedItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AdminAiFeedService.instance.addListener(_onFeedChanged);
    _load();
  }

  @override
  void dispose() {
    AdminAiFeedService.instance.removeListener(_onFeedChanged);
    super.dispose();
  }

  void _onFeedChanged() => _load();

  Future<void> _load() async {
    final items = await AdminAiFeedRepository.instance.fetchOpen(limit: 3);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _openItem(AdminAiFeedItem item) async {
    await AdminAiFeedRepository.instance.markStatus(item.id, 'read');
    AdminAiFeedService.instance.decrementOpen();
    if (!mounted) return;
    if (item.threadId != null && item.threadId!.isNotEmpty) {
      context.go(adminConsoleChatPath(roomId: item.threadId!));
      return;
    }
    final link = item.deepLink;
    if (link != null && link.isNotEmpty) context.go(link);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final count = AdminAiFeedService.instance.openCount;

    if (_loading && _items.isEmpty && count == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.adminAiFeedDashboardTitle(count),
                  style: AdminTheme.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => showAdminAiFeedSheet(context),
                child: Text(s.adminAiFeedViewAll),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (_items.isEmpty)
            Text(s.adminAiFeedEmpty, style: AdminTheme.hint)
          else
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: AdminTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _openItem(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  item.summary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AdminTheme.hint.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
