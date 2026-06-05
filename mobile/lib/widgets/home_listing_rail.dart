import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/listing_public.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';
import 'design_system/app_property_card.dart';

/// Horizontal property rail — สไลด์รูปได้เฉพาะการ์ดที่อยู่กึ่งกลางจอ
class HomeListingRail extends StatefulWidget {
  const HomeListingRail({
    super.key,
    required this.title,
    required this.items,
    required this.onTapListing,
    required this.onViewAll,
    this.showCoAgentStrip = false,
    this.accentIndex = 0,
  });

  final String title;
  final List<ListingPublic> items;
  final void Function(ListingPublic) onTapListing;
  final VoidCallback onViewAll;
  final bool showCoAgentStrip;
  final int accentIndex;

  static const cardWidth = 280.0;
  static const cardGap = 12.0;

  /// รูป 16:9 + บล็อกข้อความ (ราคา + ชื่อโครงการ + ทำเล)
  static double railHeightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.35);
    return (cardWidth * 9 / 16 + 76) * scale;
  }

  @override
  State<HomeListingRail> createState() => _HomeListingRailState();
}

class _HomeListingRailState extends State<HomeListingRail> {
  final _scrollController = ScrollController();
  int? _centeredIndex;
  bool _railScrollLocked = false;

  void _lockRailScroll() {
    if (!_railScrollLocked) setState(() => _railScrollLocked = true);
  }

  void _unlockRailScroll() {
    if (_railScrollLocked) setState(() => _railScrollLocked = false);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateCenteredIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCenteredIndex());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCenteredIndex() {
    if (!_scrollController.hasClients || !mounted) return;

    final viewportWidth = MediaQuery.sizeOf(context).width;
    final viewportCenter = viewportWidth / 2;
    final offset = _scrollController.offset;
    const w = HomeListingRail.cardWidth;
    const gap = HomeListingRail.cardGap;
    const pad = LiLayout.pagePadding;

    int? best;
    var bestDist = double.infinity;
    for (var i = 0; i < widget.items.length; i++) {
      final cardCenter = pad + i * (w + gap) + w / 2 - offset;
      final dist = (cardCenter - viewportCenter).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }

    // เปิดสไลด์รูปเมื่อการ์ดอยู่ใกล้กึ่งกลางพอ (ไม่อยู่ขอบ = เลื่อน rail แทน)
    final centered = bestDist <= w * 0.32 ? best : null;
    if (centered != _centeredIndex) {
      setState(() => _centeredIndex = centered);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final accent = AppTheme.sectionAccents[widget.accentIndex % AppTheme.sectionAccents.length];
    final railHeight = HomeListingRail.railHeightFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LiLayout.pagePadding,
            10,
            LiLayout.pagePadding,
            6,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              ),
              TextButton(
                onPressed: widget.onViewAll,
                child: Text(
                  s.viewAll,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: railHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) {
              _updateCenteredIndex();
              return false;
            },
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              primary: false,
              physics: _railScrollLocked
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: LiLayout.pagePadding),
              itemCount: widget.items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: HomeListingRail.cardGap),
              itemBuilder: (context, i) {
                if (i == widget.items.length) {
                  return _ViewAllCard(
                    width: HomeListingRail.cardWidth * 0.42,
                    label: s.viewAll,
                    count: widget.items.length,
                    accent: accent,
                    onTap: widget.onViewAll,
                  );
                }
                final item = widget.items[i];
                return SizedBox(
                  height: railHeight,
                  width: HomeListingRail.cardWidth,
                  child: AppPropertyCard(
                    listing: item,
                    width: HomeListingRail.cardWidth,
                    compactBody: true,
                    showCoAgentStrip: widget.showCoAgentStrip,
                    enableImageSwipe: true,
                    railScrollController:
                        _centeredIndex == i ? _scrollController : null,
                    onImageDragStart: _lockRailScroll,
                    onImageDragEnd: _unlockRailScroll,
                    onTap: () => widget.onTapListing(item),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewAllCard extends StatelessWidget {
  const _ViewAllCard({
    required this.width,
    required this.label,
    required this.count,
    required this.accent,
    required this.onTap,
  });

  final double width;
  final String label;
  final int count;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: width,
      child: Material(
        color: p.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward, color: accent),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, color: accent, fontSize: 13),
                ),
                Text('$count', style: TextStyle(fontSize: 11, color: p.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
