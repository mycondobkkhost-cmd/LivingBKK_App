import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../data/demo_media.dart';
import '../models/search_zone_catalog_entry.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/living_bkk_brand.dart';

/// รายการแนะนำ — ทำเลก่อน แล้วค่อยโครงการ · ไฮไลท์คำค้นหา
class SearchZoneSuggestionList extends StatelessWidget {
  const SearchZoneSuggestionList({
    super.key,
    required this.suggestions,
    required this.query,
    required this.onSelectTag,
    required this.onOpenProject,
    this.onSeeAllProjects,
  });

  final List<SearchZoneCatalogEntry> suggestions;
  final String query;
  final ValueChanged<SearchZoneCatalogEntry> onSelectTag;
  final ValueChanged<SearchZoneCatalogEntry> onOpenProject;
  final VoidCallback? onSeeAllProjects;

  /// สีไฮไลท์คำค้นหา (โทนส้มอุ่นตามตัวอย่าง)
  static const matchColor = Color(0xFFF08A3C);

  static bool _isPlace(SearchZoneCatalogEntry e) =>
      e.category == 'location' ||
      e.category == 'landmark' ||
      e.category == 'transit' ||
      e.category == 'education';

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final s = AppStrings.of(context);
    final p = context.palette;
    final q = query.trim();

    final places = suggestions.where(_isPlace).toList();
    final projects =
        suggestions.where((e) => e.category == 'project').toList();

    return Material(
      elevation: 0,
      color: p.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (places.isNotEmpty) ...[
            _SectionLabel(label: s.searchTabLocation, palette: p),
            for (var i = 0; i < places.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 0.5, color: p.border),
              _SuggestionRow(
                entry: places[i],
                query: q,
                isEnglish: s.isEnglish,
                onTap: () => onSelectTag(places[i]),
              ),
            ],
          ],
          if (projects.isNotEmpty) ...[
            if (places.isNotEmpty)
              Divider(height: 1, thickness: 0.5, color: p.border),
            _SectionLabel(label: s.searchProjectsSection, palette: p),
            for (var i = 0; i < projects.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 0.5, color: p.border),
              _SuggestionRow(
                entry: projects[i],
                query: q,
                isEnglish: s.isEnglish,
                onTap: () => onOpenProject(projects[i]),
                showChevron: true,
              ),
            ],
          ],
          if (projects.isNotEmpty && q.isNotEmpty && onSeeAllProjects != null)
            InkWell(
              onTap: onSeeAllProjects,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Text(
                  s.searchSeeAllForQuery(q),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// ไฮไลท์ทุกตำแหน่งที่ตรงกับคำค้น (ไม่สนตัวพิมพ์)
  static Widget highlightedText(
    String title,
    String query,
    TextStyle baseStyle, {
    Color match = matchColor,
  }) {
    final q = query.trim();
    if (q.isEmpty) {
      return Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final lowerTitle = title.toLowerCase();
    final lowerQuery = q.toLowerCase();
    if (!lowerTitle.contains(lowerQuery)) {
      return Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final spans = <TextSpan>[];
    var start = 0;
    final qLen = lowerQuery.length;
    while (start < title.length) {
      final idx = lowerTitle.indexOf(lowerQuery, start);
      if (idx < 0) {
        spans.add(TextSpan(text: title.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: title.substring(start, idx)));
      }
      spans.add(
        TextSpan(
          text: title.substring(idx, idx + qLen),
          style: baseStyle.copyWith(
            color: match,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      start = idx + qLen;
    }

    return Text.rich(
      TextSpan(
        style: baseStyle.copyWith(
          color: baseStyle.color ?? AppTheme.textPrimary,
        ),
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.palette});

  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: palette.textSecondary,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.entry,
    required this.query,
    required this.isEnglish,
    required this.onTap,
    this.showChevron = false,
  });

  final SearchZoneCatalogEntry entry;
  final String query;
  final bool isEnglish;
  final VoidCallback onTap;
  final bool showChevron;

  String get _title {
    if (!isEnglish &&
        entry.category == 'location' &&
        entry.aliases.isNotEmpty) {
      final stations = entry.aliases.where((a) {
        final t = a.trim();
        if (t.isEmpty || t.length > 24) return false;
        if (t.contains('·') || t.contains(',')) return false;
        // ข้าม subtitle ภาษาอังกฤษยาวๆ
        final latin = RegExp(r'^[A-Za-z0-9\s\-–]+$');
        if (latin.hasMatch(t) && t.length > 12) return false;
        return true;
      }).toList();
      if (stations.length >= 2) {
        final parts = <String>[entry.titleTh];
        for (final a in stations) {
          if (parts.any((p) => p == a)) continue;
          parts.add(a);
        }
        return parts.join(' ');
      }
    }
    return entry.label(isEnglish);
  }

  String? get _subtitle {
    if (entry.category == 'project') return null;

    if (!isEnglish &&
        entry.category == 'location' &&
        entry.aliases.length >= 2) {
      final enParts = <String>[];
      for (final a in entry.aliases) {
        final en = _stationEn(a);
        if (en != null) enParts.add(en);
      }
      if (enParts.length >= 2) return enParts.join(', ');
    }

    final other = isEnglish ? entry.titleTh : entry.titleEn;
    if (other.trim().isEmpty) return null;
    if (other == _title) return null;
    return other;
  }

  static String? _stationEn(String th) {
    const map = <String, String>{
      'อ่อนนุช': 'Onnut',
      'อุดมสุข': 'Udomsuk',
      'พระโขนง': 'Phrakhanong',
      'บางจาก': 'Bangchak',
      'ปุณณวิถี': 'Punnawithi',
      'ทองหล่อ': 'Thonglor',
      'เอกมัย': 'Ekkamai',
      'อโศก': 'Asok',
      'พร้อมพงษ์': 'Phrom Phong',
      'นานา': 'Nana',
      'อารีย์': 'Ari',
      'บางนา': 'Bangna',
      'ลาดพร้าว': 'Lat Phrao',
    };
    return map[th.trim()];
  }

  String get _imageSeed {
    if (entry.category == 'project') {
      return entry.projectSlug ?? entry.id;
    }
    return 'zone-${entry.id}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final subtitle = _subtitle;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                DemoMedia.photo(_imageSeed, width: 96, height: 96),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: LivingBkkBrand.brandRedTint,
                  alignment: Alignment.center,
                  child: Icon(
                    entry.category == 'project'
                        ? Icons.apartment_rounded
                        : entry.category == 'transit'
                            ? Icons.train_rounded
                            : Icons.place_rounded,
                    color: LivingBkkBrand.brandRed,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchZoneSuggestionList.highlightedText(
                    _title,
                    query,
                    TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      height: 1.25,
                      color: p.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, color: p.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}
