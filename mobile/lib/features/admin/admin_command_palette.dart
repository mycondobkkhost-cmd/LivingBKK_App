import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../theme/admin_theme.dart';
import '../../theme/living_bkk_brand.dart';
import 'admin_enterprise_zone.dart';
import 'admin_nav_model.dart';

/// ค้นหาและกระโดดไปหน้าหลังบ้าน — เหมาะองค์กรขนาดใหญ่
Future<void> showAdminCommandPalette({
  required BuildContext context,
  required AdminNavConfig config,
  required AdminNavId current,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _CommandPaletteDialog(config: config, current: current),
  );
}

class _CommandPaletteDialog extends StatefulWidget {
  const _CommandPaletteDialog({
    required this.config,
    required this.current,
  });

  final AdminNavConfig config;
  final AdminNavId current;

  @override
  State<_CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<_CommandPaletteDialog> {
  final _query = TextEditingController();
  String _text = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<_PaletteEntry> get _entries {
    final s = context.s;
    final isEn = s.isEnglish;
    final out = <_PaletteEntry>[];

    for (final zone in adminVisibleZones(widget.config)) {
      for (final item in adminZoneNavItems(zone, widget.config, s)) {
        for (final flat in item.flatten()) {
          out.add(
            _PaletteEntry(
              nav: flat.id,
              zone: zone,
              label: flat.label(isEn),
              icon: flat.icon,
              badge: flat.badgeCount,
            ),
          );
        }
      }
    }
    return out;
  }

  List<_PaletteEntry> get _filtered {
    final q = _text.trim().toLowerCase();
    if (q.isEmpty) return _entries;
    return _entries
        .where(
          (e) =>
              e.label.toLowerCase().contains(q) ||
              adminZoneLabel(e.zone, context.s).toLowerCase().contains(q),
        )
        .toList();
  }

  void _go(_PaletteEntry entry) {
    Navigator.pop(context);
    final id = entry.nav;
    switch (id) {
      case AdminNavId.inbox:
        context.go('/admin/console');
      case AdminNavId.queue:
        context.go('/admin/console?filter=unclaimed');
      case AdminNavId.dashboard:
        context.go('/admin');
      default:
        context.go('/admin?nav=${id.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final items = _filtered;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                onChanged: (v) => setState(() => _text = v),
                decoration: InputDecoration(
                  hintText: s.adminCommandPaletteHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                s.adminCommandPaletteSubtitle,
                style: AdminTheme.caption,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text(s.adminCommandPaletteEmpty))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final e = items[i];
                        final selected = e.nav == widget.current;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            e.icon,
                            size: 20,
                            color: selected
                                ? LivingBkkBrand.purplePrimary
                                : AdminTheme.textMuted,
                          ),
                          title: Text(
                            e.label,
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            adminZoneLabel(e.zone, s),
                            style: AdminTheme.caption.copyWith(fontSize: 10),
                          ),
                          trailing: e.badge > 0
                              ? CircleAvatar(
                                  radius: 10,
                                  backgroundColor:
                                      LivingBkkBrand.purplePrimary,
                                  child: Text(
                                    '${e.badge}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => _go(e),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteEntry {
  const _PaletteEntry({
    required this.nav,
    required this.zone,
    required this.label,
    required this.icon,
    required this.badge,
  });

  final AdminNavId nav;
  final AdminEnterpriseZone zone;
  final String label;
  final IconData icon;
  final int badge;
}
