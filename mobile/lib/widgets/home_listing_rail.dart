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
    this.highlightRecommended = false,
    this.topInset = 0,
  });

  final String title;
  final List<ListingPublic> items;
  final void Function(ListingPublic) onTapListing;
  final VoidCallback onViewAll;
  final bool showCoAgentStrip;
  final int accentIndex;
  final bool highlightRecommended;
  /// ระยะบนก่อนหัวข้อ section — ใช้ 0 สำหรับ section ถัดไป
  final double topInset;

  static const cardGap = 10.0;

  /// ~2.5 การ์ดต่อแถว — เห็นครึ่งการ์ดถัดไปเป็น teaser
  static double cardWidthFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final available = w - 2 * LiLayout.pagePadding;
    const gaps = 2 * cardGap;
    return ((available - gaps) / 2.5).clamp(136.0, 168.0);
  }

  /// รูป 4:3 + body compact (โครงการ + หัวข้อ — สเปกอยู่บนรูป)
  static double compactCardHeight(double cardWidth) => cardWidth * 3 / 4 + 56;

  static double railHeightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
    return compactCardHeight(cardWidthFor(context)) * scale;
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
    final w = HomeListingRail.cardWidthFor(context);
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
    final cardWidth = HomeListingRail.cardWidthFor(context);
    final railHeight = HomeListingRail.railHeightFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            LiLayout.pagePadding,
            widget.topInset.clamp(0, 48),
            LiLayout.pagePadding,
            0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                ),
              ),
              TextButton(
                onPressed: widget.onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  s.viewAll,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: railHeight,
          child: ClipRect(
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
                    width: cardWidth * 0.42,
                    label: s.viewAll,
                    count: widget.items.length,
                    accent: accent,
                    onTap: widget.onViewAll,
                  );
                }
                final item = widget.items[i];
                // ListView แนวนอนบังคับความสูงเท่า viewport — จัดการ์ดชิดบน ไม่ยืดพื้นขาวใต้ body
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: cardWidth,
                    child: AppPropertyCard(
                      listing: item,
                      width: cardWidth,
                      compactBody: true,
                      highlightRecommended: widget.highlightRecommended,
                      showCoAgentStrip: widget.showCoAgentStrip,
                      enableImageSwipe: true,
                      railScrollController:
                          _centeredIndex == i ? _scrollController : null,
                      onImageDragStart: _lockRailScroll,
                      onImageDragEnd: _unlockRailScroll,
                      onTap: () => widget.onTapListing(item),
                    ),
                  ),
                );
              },
            ),
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
