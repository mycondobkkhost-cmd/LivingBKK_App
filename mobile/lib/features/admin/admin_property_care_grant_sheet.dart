import 'package:flutter/material.dart';

import '../../config/code_glossary.dart';
import '../../l10n/app_strings.dart';
import '../../models/property_care_right.dart';
import '../../services/demo_cast_bootstrap.dart';
import '../../services/property_care_repository.dart';
import '../../utils/app_notice.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';

Future<void> showAdminPropertyCareGrantSheet(
  BuildContext context, {
  required String inventoryId,
  required String inventoryCode,
  required Future<void> Function() onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => _GrantSheet(
      hostContext: context,
      inventoryId: inventoryId,
      inventoryCode: inventoryCode,
      onSaved: onSaved,
    ),
  );
}

class _GrantSheet extends StatefulWidget {
  const _GrantSheet({
    required this.hostContext,
    required this.inventoryId,
    required this.inventoryCode,
    required this.onSaved,
  });

  final BuildContext hostContext;
  final String inventoryId;
  final String inventoryCode;
  final Future<void> Function() onSaved;

  @override
  State<_GrantSheet> createState() => _GrantSheetState();
}

class _GrantSheetState extends State<_GrantSheet> {
  final _repo = PropertyCareRepository.instance;
  final _userId = TextEditingController();
  final _notes = TextEditingController();
  String _role = 'primary_caretaker';
  String _status = 'pending_claim';
  bool _primary = true;
  bool _busy = false;
  List<PropertyCareRight> _existing = [];

  @override
  void initState() {
    super.initState();
    if (DemoCastBootstrap.shouldUseCastWorld ||
        DemoCastBootstrap.isSharedAdminSession) {
      _userId.text = PropertyCareRepository.demoOwnerUserId;
    }
    _load();
  }

  @override
  void dispose() {
    _userId.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await _repo.forInventory(
      widget.inventoryId,
      inventoryCode: widget.inventoryCode,
    );
    if (!mounted) return;
    setState(() => _existing = rows);
  }

  Future<void> _revoke(String rightId) async {
    setState(() => _busy = true);
    try {
      await _repo.revoke(rightId);
      await _load();
      await widget.onSaved();
      if (!mounted) return;
      AppNotice.show(widget.hostContext, context.s.adminCareRevokeDone);
    } catch (e) {
      if (!mounted) return;
      AppNotice.error(widget.hostContext, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _grant() async {
    final uid = _userId.text.trim();
    if (uid.isEmpty) {
      AppNotice.show(widget.hostContext, context.s.adminCareUserIdHint);
      return;
    }
    setState(() => _busy = true);
    try {
      await _repo.grant(
        userId: uid,
        careRole: _role,
        inventoryId: widget.inventoryId,
        inventoryCode: widget.inventoryCode,
        isPrimary: _primary,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        status: _status,
        inviteCode: _status == 'pending_claim'
            ? 'RX-${widget.inventoryCode.split('-').last}'
            : null,
      );
      await _load();
      await widget.onSaved();
      if (!mounted) return;
      Navigator.pop(context);
      AppNotice.show(widget.hostContext, context.s.adminCareGrantDone);
      _userId.clear();
    } catch (e) {
      if (!mounted) return;
      AppNotice.error(widget.hostContext, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final caption = CodeGlossary.captionFor(widget.inventoryCode, isEn: s.isEnglish);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.adminCareGrantTitle, style: AdminTheme.section),
            const SizedBox(height: 4),
            Text(
              '${widget.inventoryCode} · $caption',
              style: AdminTheme.caption,
            ),
            Text(s.adminCareGrantHint, style: AdminTheme.caption),
            const SizedBox(height: 12),
            if (_existing.isNotEmpty) ...[
              Text(s.adminCareCurrentList, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              for (final r in _existing)
                _CareRow(
                  right: r,
                  s: s,
                  onRevoke: r.status != 'revoked'
                      ? () => _revoke(r.id)
                      : null,
                ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _userId,
              decoration: InputDecoration(
                labelText: s.adminCareUserIdLabel,
                border: const OutlineInputBorder(),
                helperText: s.adminCareUserIdHint,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: InputDecoration(
                labelText: s.adminCareRoleLabel,
                border: const OutlineInputBorder(),
              ),
              items: CodeGlossary.careRoles.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(CodeGlossary.careRoleLabel(e.key, isEn: s.isEnglish)),
                    ),
                  )
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(
                labelText: s.adminCareStatusLabel,
                border: const OutlineInputBorder(),
              ),
              items: CodeGlossary.careStatus.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(CodeGlossary.careStatusLabel(e.key, isEn: s.isEnglish)),
                    ),
                  )
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _status = v ?? _status),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.adminCarePrimaryToggle),
              subtitle: Text(s.adminCarePrimaryHint, style: AdminTheme.caption),
              value: _primary,
              onChanged: _busy ? null : (v) => setState(() => _primary = v),
            ),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: s.adminCareNotesLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            if (_busy) const LinearProgressIndicator(),
            FilledButton.icon(
              onPressed: _busy ? null : _grant,
              icon: const Icon(Icons.verified_user_outlined),
              label: Text(s.adminCareGrantButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareRow extends StatelessWidget {
  const _CareRow({
    required this.right,
    required this.s,
    this.onRevoke,
  });

  final PropertyCareRight right;
  final AppStrings s;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        right.isPrimary ? Icons.star : Icons.person_outline,
        color: right.isPrimary ? AppTheme.primary : null,
        size: 20,
      ),
      title: Text(
        right.userDisplayName ?? right.userId,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${CodeGlossary.careRoleLabel(right.careRole, isEn: s.isEnglish)} · '
        '${CodeGlossary.careStatusLabel(right.status, isEn: s.isEnglish)}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: onRevoke == null
          ? null
          : TextButton(
              onPressed: onRevoke,
              child: Text(s.adminCareRevokeButton, style: const TextStyle(fontSize: 11)),
            ),
    );
  }
}
