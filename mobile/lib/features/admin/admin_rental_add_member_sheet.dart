import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/rental_group_member.dart';
import '../../models/rental_lease.dart';
import '../../services/rental_lease_service.dart';
import '../../services/rental_member_lookup.dart';
import '../../theme/admin_theme.dart';

Future<bool> showAdminRentalAddMemberSheet({
  required BuildContext context,
  required RentalLease lease,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AdminRentalAddMemberSheet(lease: lease),
  );
  return result == true;
}

class _AdminRentalAddMemberSheet extends StatefulWidget {
  const _AdminRentalAddMemberSheet({required this.lease});

  final RentalLease lease;

  @override
  State<_AdminRentalAddMemberSheet> createState() =>
      _AdminRentalAddMemberSheetState();
}

class _AdminRentalAddMemberSheetState extends State<_AdminRentalAddMemberSheet> {
  final _lookup = TextEditingController();
  final _label = TextEditingController();
  RentalMemberRole _role = RentalMemberRole.tenant;
  RentalMemberLookupResult? _resolved;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _lookup.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _busy = true;
      _error = null;
      _resolved = null;
    });
    final hit = await RentalMemberLookup.resolve(_lookup.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _resolved = hit;
      if (hit == null) {
        _error = context.s.adminRentalAddMemberNotFound;
      } else if (_label.text.trim().isEmpty) {
        _label.text = hit.displayLabelHint;
      }
    });
  }

  String _defaultDisplayLabel(RentalMemberRole role, RentalMemberLookupResult hit) {
    final member = RentalGroupMember(
      userId: hit.userId,
      role: role,
      displayLabel: '',
      profileTagCode: hit.profileTagCode,
    );
    final roleName = member.roleLabelTh;
    final suffix = hit.profileTagCode ?? hit.displayLabelHint;
    return '$roleName · $suffix';
  }

  Future<void> _submit() async {
    final s = context.s;
    final hit = _resolved;
    if (hit == null) {
      setState(() => _error = s.adminRentalAddMemberNotFound);
      return;
    }
    if (widget.lease.members.any((m) => m.userId == hit.userId)) {
      setState(() => _error = s.adminRentalAddMemberDuplicate);
      return;
    }

    final displayLabel = _label.text.trim().isNotEmpty
        ? _label.text.trim()
        : _defaultDisplayLabel(_role, hit);

    setState(() => _busy = true);
    final ok = await RentalLeaseService.instance.addLeaseMember(
      leaseId: widget.lease.id,
      member: RentalGroupMember(
        userId: hit.userId,
        role: _role,
        displayLabel: displayLabel,
        profileTagCode: hit.profileTagCode,
      ),
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = s.adminRentalAddMemberFailed;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.adminRentalAddMemberTitle,
            style: AdminTheme.section.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(s.adminRentalAddMemberHint, style: AdminTheme.caption),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lookup,
                  decoration: InputDecoration(
                    labelText: s.adminRentalAddMemberLookupLabel,
                    hintText: s.adminRentalAddMemberLookupHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : _search,
                child: Text(s.adminRentalAddMemberSearch),
              ),
            ],
          ),
          if (_resolved != null) ...[
            const SizedBox(height: 8),
            Text(
              s.adminRentalAddMemberResolved(_resolved!.userId),
              style: AdminTheme.caption,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<RentalMemberRole>(
            value: _role,
            decoration: InputDecoration(
              labelText: s.adminRentalAddMemberRoleLabel,
              border: const OutlineInputBorder(),
            ),
            items: RentalMemberRole.values
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(_roleLabel(r, s)),
                  ),
                )
                .toList(),
            onChanged: _busy
                ? null
                : (v) {
                    if (v == null) return;
                    setState(() => _role = v);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _label,
            decoration: InputDecoration(
              labelText: s.adminRentalAddMemberDisplayLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy || _resolved == null ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(s.adminRentalAddMemberSubmit),
          ),
        ],
      ),
    );
  }

  String _roleLabel(RentalMemberRole role, AppStrings s) => switch (role) {
        RentalMemberRole.tenant => s.adminRentalRoleTenant,
        RentalMemberRole.owner => s.adminRentalRoleOwner,
        RentalMemberRole.agent => s.adminRentalRoleAgent,
        RentalMemberRole.admin => s.adminRentalRoleAdmin,
      };
}
