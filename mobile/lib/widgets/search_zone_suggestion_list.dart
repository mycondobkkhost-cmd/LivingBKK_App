import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/search_zone_catalog_entry.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// รายการแนะนำ — โครงการเปิดหน้ารายละเอียด · ทำเล/สถานีเพิ่มแท็ก
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

  static const _matchColor = Color(0xFFE86C00);

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final s = AppStrings.of(context);
    final p = context.palette;
    final q = query.trim();

    final projects =
        suggestions.where((e) => e.category == 'project').toList();
    final others =
        suggestions.where((e) => e.category != 'project').toList();

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      color: p.surface,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (projects.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                s.searchProjectsSection,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: p.textSecondary,
                ),
              ),
            ),
            for (var i = 0; i < projects.length; i++) ...[
              if (i > 0) Divider(height: 1, color: AppTheme.border),
              _ProjectRow(
                entry: projects[i],
                query: q,
                isEnglish: s.isEnglish,
                onTap: () => onOpenProject(projects[i]),
              ),
            ],
            if (others.isNotEmpty) Divider(height: 1, color: AppTheme.border),
          ],
          for (var i = 0; i < others.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppTheme.border),
            ListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              title: _highlightedTitle(
                others[i].label(s.isEnglish),
                q,
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              trailing:
                  Icon(Icons.add_circle_outline, color: p.primary, size: 22),
              onTap: () => onSelectTag(others[i]),
            ),
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

  static Widget _highlightedTitle(
    String title,
    String query,
    TextStyle baseStyle,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return Text(title, style: baseStyle);
    final lower = title.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) return Text(title, style: baseStyle);
    return RichText(
      text: TextSpan(
        style: baseStyle.copyWith(color: baseStyle.color ?? Colors.black87),
        children: [
          if (idx > 0) TextSpan(text: title.substring(0, idx)),
          TextSpan(
            text: title.substring(idx, idx + q.length),
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w800,
              color: _matchColor,
            ),
          ),
          if (idx + q.length < title.length)
            TextSpan(text: title.substring(idx + q.length)),
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
    required this.entry,
    required this.query,
    required this.isEnglish,
    required this.onTap,
  });

  final SearchZoneCatalogEntry entry;
  final String query;
  final bool isEnglish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slug = entry.projectSlug ?? entry.id;
    final title = entry.label(isEnglish);
    final imageUrl = 'https://picsum.photos/seed/$slug/120/120';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppTheme.primaryLight,
                  child: Icon(Icons.apartment, color: AppTheme.primary, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SearchZoneSuggestionList._highlightedTitle(
                title,
                query,
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            Icon(Icons.chevron_right, color: context.palette.textSecondary),
          ],
        ),
      ),
    );
  }
}
