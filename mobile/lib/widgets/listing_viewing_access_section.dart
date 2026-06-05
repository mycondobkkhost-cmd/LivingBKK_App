import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/listing_viewing_access.dart';
import '../theme/app_theme.dart';

/// ชุดคำถาม「การนัดดูในอนาคต」— ไม่บังคับกรอกครบ
class ListingViewingAccessSection extends StatelessWidget {
  const ListingViewingAccessSection({
    super.key,
    required this.value,
    required this.onChanged,
    this.noteController,
  });

  final ListingViewingAccess value;
  final ValueChanged<ListingViewingAccess> onChanged;
  final TextEditingController? noteController;

  ListingViewingAccess _with({ListingViewingAccess Function(ListingViewingAccess v)? fn}) {
    var v = value.copyWith(note: noteController?.text);
    if (fn != null) v = fn(v);
    return v;
  }

  void _emit(ListingViewingAccess next) => onChanged(next.copyWith(note: noteController?.text));

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ownerSelected = value.modes.contains(ListingViewingAccess.modeOwnerOpen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.viewingAccessSectionTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 6),
        Text(s.viewingAccessSectionIntro, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.event_available_outlined, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.viewingAccessFollowUpHint, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.viewingAccessFollowUpToggle, style: const TextStyle(fontSize: 14)),
          subtitle: Text(s.viewingAccessFollowUpSubtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          value: value.followUpLater,
          activeColor: AppTheme.primary,
          onChanged: (v) => _emit(_with(fn: (x) => x.copyWith(followUpLater: v))),
        ),
        const SizedBox(height: 8),
        Text(s.viewingAccessModesQuestion, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        Text(s.viewingAccessModesOptional, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.viewingAccessModeOwnerOpen),
          subtitle: ownerSelected
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(s.viewingAccessNotice1Day),
                        selected: value.ownerNoticeDays == 1,
                        onSelected: (_) => _emit(
                          _with(fn: (x) => x.copyWith(ownerNoticeDays: 1)),
                        ),
                      ),
                      ChoiceChip(
                        label: Text(s.viewingAccessNotice2Days),
                        selected: value.ownerNoticeDays == 2 || value.ownerNoticeDays == null,
                        onSelected: (_) => _emit(
                          _with(fn: (x) => x.copyWith(ownerNoticeDays: 2)),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
          value: ownerSelected,
          onChanged: (v) {
            if (v == true) {
              _emit(_with(fn: (x) {
                final modes = Set<String>.from(x.modes)
                  ..add(ListingViewingAccess.modeOwnerOpen);
                return x.copyWith(
                  modes: modes,
                  ownerNoticeDays: x.ownerNoticeDays ?? 2,
                );
              }));
            } else {
              _emit(_with(fn: (x) {
                final modes = Set<String>.from(x.modes)
                  ..remove(ListingViewingAccess.modeOwnerOpen);
                return x.copyWith(modes: modes, clearOwnerNoticeDays: true);
              }));
            }
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.viewingAccessModeJuristic),
          subtitle: Text(s.viewingAccessModeJuristicHint, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          value: value.modes.contains(ListingViewingAccess.modeJuristicKey),
          onChanged: (v) => _emit(_with(fn: (x) {
            final modes = Set<String>.from(x.modes);
            if (v == true) {
              modes.add(ListingViewingAccess.modeJuristicKey);
            } else {
              modes.remove(ListingViewingAccess.modeJuristicKey);
            }
            return x.copyWith(modes: modes);
          })),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.viewingAccessModeMailbox),
          subtitle: Text(s.viewingAccessModeMailboxHint, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          value: value.modes.contains(ListingViewingAccess.modeMailboxKey),
          onChanged: (v) => _emit(_with(fn: (x) {
            final modes = Set<String>.from(x.modes);
            if (v == true) {
              modes.add(ListingViewingAccess.modeMailboxKey);
            } else {
              modes.remove(ListingViewingAccess.modeMailboxKey);
            }
            return x.copyWith(modes: modes);
          })),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: noteController,
          onChanged: (_) => _emit(_with()),
          decoration: InputDecoration(
            labelText: s.viewingAccessNoteLabel,
            hintText: s.viewingAccessNoteHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
          maxLength: 200,
        ),
      ],
    );
  }
}
