import 'package:flutter/material.dart';

import '../data/listing_form_options.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// จุดเด่นทรัพย์ — แสดง ~5 รายการแนะนำก่อน ที่เหลืออยู่หลัง「ดูเพิ่มเติม」
class ListingHashtagPicker extends StatefulWidget {
  const ListingHashtagPicker({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    required this.listingType,
    this.propertyType,
    this.showHint = true,
  });

  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;
  final String listingType;
  final String? propertyType;
  final bool showHint;

  @override
  State<ListingHashtagPicker> createState() => _ListingHashtagPickerState();
}

class _ListingHashtagPickerState extends State<ListingHashtagPicker> {
  bool _expanded = false;

  List<String> get _topIds => ListingFormOptions.suggestedHashtagIds(
        listingType: widget.listingType,
        propertyType: widget.propertyType,
      );

  List<ListingFormOption> get _moreTags {
    final top = _topIds.toSet();
    return ListingFormOptions.hashtags
        .where((h) => !top.contains(h.id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _syncExpandedFromSelection();
  }

  @override
  void didUpdateWidget(ListingHashtagPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIds != widget.selectedIds) {
      _syncExpandedFromSelection();
    }
  }

  void _syncExpandedFromSelection() {
    final top = _topIds.toSet();
    if (widget.selectedIds.any((id) => !top.contains(id))) {
      _expanded = true;
    }
  }

  void _toggle(String id, bool selected) {
    final next = Set<String>.from(widget.selectedIds);
    if (selected) {
      next.add(id);
    } else {
      next.remove(id);
    }
    widget.onChanged(next);
  }

  Widget _chip(ListingFormOption tag, AppStrings s) {
    return FilterChip(
      label: Text(tag.label(s.isEnglish)),
      selected: widget.selectedIds.contains(tag.id),
      onSelected: (v) => _toggle(tag.id, v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final topTags =
        _topIds.map(ListingFormOptions.hashtagById).toList(growable: false);
    final more = _moreTags;
    final extraSelected = widget.selectedIds
        .where((id) => !_topIds.contains(id))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHint) ...[
          Text(
            s.createListingHashtagsHint,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final tag in topTags) _chip(tag, s)],
        ),
        if (more.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(
                _expanded
                    ? s.createListingHashtagsShowLess
                    : s.createListingHashtagsShowMore(more.length),
              ),
            ),
          ),
          if (extraSelected > 0 && !_expanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                s.createListingHashtagsExtraSelected(extraSelected),
                style: TextStyle(fontSize: 11, color: AppTheme.primary),
              ),
            ),
          if (_expanded) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final tag in more) _chip(tag, s)],
            ),
          ],
        ],
      ],
    );
  }
}
