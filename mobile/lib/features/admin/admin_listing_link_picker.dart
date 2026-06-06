import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_message.dart';
import '../../models/listing_public.dart';
import '../../services/listing_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/localized_content.dart';

/// เลือกประกาศเพื่อส่งเป็นการ์ดลิงก์ในแชทแอดมิน
class AdminListingLinkPicker {
  static Future<List<ChatMessageLink>?> show(
    BuildContext context, {
    int maxPick = 5,
  }) async {
    final repo = ListingRepository();
    List<ListingPublic> pool;
    try {
      pool = await repo.fetchPublished();
    } catch (_) {
      pool = const [];
    }

    if (!context.mounted) return null;
    final s = AppStrings.of(context);

    return showModalBottomSheet<List<ChatMessageLink>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return _PickerBody(pool: pool, maxPick: maxPick, s: s);
      },
    );
  }
}

class _PickerBody extends StatefulWidget {
  const _PickerBody({
    required this.pool,
    required this.maxPick,
    required this.s,
  });

  final List<ListingPublic> pool;
  final int maxPick;
  final AppStrings s;

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> {
  final _query = TextEditingController();
  final _picked = <ListingPublic>{};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<ListingPublic> get _filtered {
    final needle = _query.text.trim().toLowerCase();
    return widget.pool.where((l) {
      if (needle.isEmpty) return true;
      return l.listingCode.toLowerCase().contains(needle) ||
          l.localizedTitle(widget.s.isEnglish).toLowerCase().contains(needle) ||
          (l.projectName ?? '').toLowerCase().contains(needle);
    }).take(40).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final filtered = _filtered;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.adminSendListingCardsTitle,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _query,
                decoration: InputDecoration(
                  hintText: s.adminSendListingCardsHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final l = filtered[i];
                    final selected = _picked.contains(l);
                    final price = NumberFormat('#,###').format(l.priceNet);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (on) {
                        setState(() {
                          if (on == true) {
                            if (_picked.length < widget.maxPick) _picked.add(l);
                          } else {
                            _picked.remove(l);
                          }
                        });
                      },
                      title: Text(
                        '${l.listingCode} · ${l.localizedTitle(s.isEnglish)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '฿$price',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              FilledButton(
                onPressed: _picked.isEmpty
                    ? null
                    : () {
                        final links = _picked
                            .map(
                              (l) => ChatMessageLink(
                                label:
                                    '${l.listingCode} · ฿${NumberFormat('#,###').format(l.priceNet)}',
                                kind: ChatMessageLinkKind.listing,
                                listingId: l.id,
                                projectName: l.projectName,
                              ),
                            )
                            .toList();
                        Navigator.pop(context, links);
                      },
                child: Text(s.adminSendListingCardsConfirm(_picked.length)),
              ),
            ],
          ),
        );
      },
    );
  }
}
