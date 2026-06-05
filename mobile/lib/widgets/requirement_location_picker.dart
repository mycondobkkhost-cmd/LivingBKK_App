import 'package:flutter/material.dart';

import '../data/popular_areas.dart';
import '../l10n/app_strings.dart';
import '../models/requirement_location_entry.dart';
import '../services/project_catalog.dart';
import '../theme/app_theme.dart';
import '../utils/localized_content.dart';

/// โครงการ/อาคาร — พิมพ์ค้นหา แนะนำอัจฉริยะ เลือกได้หลายรายการ + บันทึกค่าที่พิมพ์เอง
class RequirementLocationPicker extends StatefulWidget {
  const RequirementLocationPicker({
    super.key,
    required this.entries,
    required this.onChanged,
  });

  final List<RequirementLocationEntry> entries;
  final ValueChanged<List<RequirementLocationEntry>> onChanged;

  @override
  State<RequirementLocationPicker> createState() => _RequirementLocationPickerState();
}

class _RequirementLocationPickerState extends State<RequirementLocationPicker> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<_Suggestion> _suggestions(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return [];

    final out = <_Suggestion>[];
    final seen = <String>{};

    for (final p in ProjectCatalog.instance.search(q)) {
      final label = p.displayBilingual;
      final key = label.toLowerCase();
      if (seen.add(key)) {
        out.add(_Suggestion(
          label: label,
          subtitle: [p.district, p.bts].whereType<String>().join(' · '),
          projectSlug: p.slug,
        ));
      }
    }

    final ql = q.toLowerCase();
    for (final area in PopularAreas.all) {
      if (area.nameTh.toLowerCase().contains(ql) ||
          area.nameEn.toLowerCase().contains(ql)) {
        final key = area.nameTh.toLowerCase();
        if (seen.add(key)) {
          out.add(_Suggestion(
            label: area.nameTh,
            subtitle: area.subtitleTh,
            geoZoneSlug: area.slug,
          ));
        }
      }
    }

    if (!widget.entries.any((e) => e.label.toLowerCase() == ql) && q.length >= 2) {
      out.add(_Suggestion(label: q, isCustomPrompt: true));
    }

    return out.take(8).toList();
  }

  void _add(_Suggestion s) {
    final entry = RequirementLocationEntry(
      label: s.label,
      projectSlug: s.projectSlug,
      geoZoneSlug: s.geoZoneSlug,
      isCustom: s.isCustomPrompt,
    );
    if (widget.entries.contains(entry)) return;
    widget.onChanged([...widget.entries, entry]);
    _input.clear();
    _focus.unfocus();
    setState(() {});
  }

  void _remove(RequirementLocationEntry e) {
    widget.onChanged(widget.entries.where((x) => x != e).toList());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.requirementFieldProjectBuilding,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          s.requirementFieldProjectBuildingHint,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
        ),
        const SizedBox(height: 8),
        RawAutocomplete<_Suggestion>(
          textEditingController: _input,
          focusNode: _focus,
          optionsBuilder: (text) => _suggestions(text.text),
          displayStringForOption: (o) => o.label,
          onSelected: _add,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) {
                final q = v.trim();
                if (q.isEmpty) return;
                _add(_Suggestion(label: q, isCustomPrompt: true));
              },
              decoration: InputDecoration(
                isDense: true,
                hintText: s.requirementFieldProjectBuildingPlaceholder,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  tooltip: s.requirementAddCustomLocation,
                  onPressed: () {
                    final q = _input.text.trim();
                    if (q.isEmpty) return;
                    _add(_Suggestion(label: q, isCustomPrompt: true));
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            if (options.isEmpty) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, i) {
                      final o = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Icon(
                          o.isCustomPrompt ? Icons.edit_outlined : Icons.apartment_outlined,
                          size: 20,
                          color: o.isCustomPrompt ? AppTheme.accentMid : AppTheme.primary,
                        ),
                        title: Text(
                          o.isCustomPrompt
                              ? s.requirementAddCustomLocationNamed(o.label)
                              : o.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: o.isCustomPrompt ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        subtitle: o.subtitle != null && !o.isCustomPrompt
                            ? Text(o.subtitle!, style: const TextStyle(fontSize: 11))
                            : null,
                        onTap: () => onSelected(o),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.entries.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in widget.entries)
                InputChip(
                  label: Text(e.label, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _remove(e),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Suggestion {
  const _Suggestion({
    required this.label,
    this.subtitle,
    this.projectSlug,
    this.geoZoneSlug,
    this.isCustomPrompt = false,
  });

  final String label;
  final String? subtitle;
  final String? projectSlug;
  final String? geoZoneSlug;
  final bool isCustomPrompt;
}
