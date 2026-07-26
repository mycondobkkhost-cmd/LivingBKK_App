import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_ai_feed_item.dart';
import '../../services/admin_ai_feed_service.dart';
import '../../services/admin_ai_feed_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_routing.dart';

Future<void> showAdminAiFeedSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AdminTheme.surface,
    builder: (ctx) => const _AdminAiFeedSheet(),
  );
}

class _AdminAiFeedSheet extends StatefulWidget {
  const _AdminAiFeedSheet();

  @override
  State<_AdminAiFeedSheet> createState() => _AdminAiFeedSheetState();
}

class _AdminAiFeedSheetState extends State<_AdminAiFeedSheet> {
  List<AdminAiFeedItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await AdminAiFeedRepository.instance.fetchOpen();
    await AdminAiFeedService.instance.refresh();
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
    Navigator.pop(context);
    if (item.threadId != null && item.threadId!.isNotEmpty) {
      context.go(adminConsoleChatPath(roomId: item.threadId!));
      return;
    }
    final link = item.deepLink;
    if (link != null && link.isNotEmpty) {
      context.go(link);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.adminAiFeedTitle,
                      style: AdminTheme.title.copyWith(fontSize: 18),
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: s.refresh,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            s.adminAiFeedEmpty,
                            style: TextStyle(color: AdminTheme.textMuted),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            return _FeedCard(
                              item: item,
                              onOpen: () => _openItem(item),
                              onDismiss: () async {
                                await AdminAiFeedRepository.instance
                                    .markStatus(item.id, 'dismissed');
                                AdminAiFeedService.instance.decrementOpen();
                                _load();
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.item,
    required this.onOpen,
    required this.onDismiss,
  });

  final AdminAiFeedItem item;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = item.isUrgent ? AppTheme.error : AppTheme.primary;
    return Material(
      color: AdminTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AdminTheme.border),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(item.summary, style: const TextStyle(fontSize: 13)),
              if (item.suggestedAction != null &&
                  item.suggestedAction!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.suggestedAction!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AdminTheme.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
