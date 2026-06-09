import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/demo_cast_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../models/demo_cast_persona.dart';
import '../../services/demo_cast_session.dart';
import '../../state/user_role_controller.dart';
import '../../theme/admin_theme.dart';
import '../../utils/admin_routing.dart';

Future<void> showAdminDemoCastSwitchSheet(
  BuildContext context, {
  required UserRoleController roleController,
  required VoidCallback onCastChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => _CastSwitchSheet(
      roleController: roleController,
      onCastChanged: onCastChanged,
    ),
  );
}

class _CastSwitchSheet extends StatefulWidget {
  const _CastSwitchSheet({
    required this.roleController,
    required this.onCastChanged,
  });

  final UserRoleController roleController;
  final VoidCallback onCastChanged;

  @override
  State<_CastSwitchSheet> createState() => _CastSwitchSheetState();
}

class _CastSwitchSheetState extends State<_CastSwitchSheet> {
  final _castId = TextEditingController();
  final _password = TextEditingController();
  DemoCastKind? _filter;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _castId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _activate(DemoCastPersona persona) async {
    setState(() {
      _busy = true;
      _error = null;
      _castId.text = persona.castId;
      _password.text = persona.password;
    });
    final ok = DemoCastSession.instance.authenticateAndActivate(
      castId: persona.castId,
      password: persona.password,
      roleController: widget.roleController,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() => _error = 'รหัสไม่ถูกต้อง');
      return;
    }
    widget.onCastChanged();
    Navigator.pop(context);
    _navigateAfterCast(persona);
  }

  void _navigateAfterCast(DemoCastPersona persona) {
    if (!context.mounted) return;
    if (persona.kind == DemoCastKind.guide) {
      context.go(viewingStaffHomePath());
      return;
    }
    if (persona.kind.isBackOfficeStaff) {
      context.go('/admin?nav=viewingCalendar');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'สลับเป็น ${persona.displayNameTh} — เปิดหน้าบ้านเพื่อทดสอบบทบาทลูกค้า/นายหน้า/เจ้าของ',
        ),
      ),
    );
  }

  void _submitManual() {
    final id = _castId.text.trim();
    final pass = _password.text.trim();
    final persona = DemoCastCatalog.authenticate(castId: id, password: pass);
    if (persona == null) {
      setState(() => _error = 'ไม่พบตัวละครหรือรหัสผ่านไม่ตรง');
      return;
    }
    _activate(persona);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final active = DemoCastSession.instance.active;
    final filtered = _filter == null
        ? DemoCastCatalog.all
        : DemoCastCatalog.byKind(_filter!);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.t('สลับตัวละคร', 'Switch character'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          Text(
            s.t(
              'ล็อกอินบัญชีกลางแล้ว — ใส่รหัสตัวละคร (รหัสผ่าน = รหัสตัวละคร)',
              'Shared login — character ID = password (e.g. ceo-01)',
            ),
            style: AdminTheme.caption,
          ),
          if (active != null) ...[
            const SizedBox(height: 8),
            Chip(
              avatar: const Icon(Icons.person, size: 18),
              label: Text('${active.displayName(s.isEnglish)} (${active.castId})'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _castId,
            decoration: InputDecoration(
              labelText: s.t('รหัสตัวละคร', 'Character ID'),
              hintText: 'ceo-01, guide-03, seeker-05',
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: s.t('รหัสผ่าน', 'Password'),
              hintText: s.t('เท่ากับรหัสตัวละคร', 'Same as character ID'),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submitManual(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _submitManual,
            child: Text(s.t('เข้าใช้งานในบทบาทนี้', 'Enter as this character')),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              FilterChip(
                label: Text(s.t('ทั้งหมด', 'All')),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final kind in DemoCastKind.values)
                FilterChip(
                  label: Text(kind.labelTh(s.isEnglish)),
                  selected: _filter == kind,
                  onSelected: (_) => setState(() => _filter = kind),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.35,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final p = filtered[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text(p.castId.split('-').last, style: const TextStyle(fontSize: 10)),
                  ),
                  title: Text(p.displayName(s.isEnglish)),
                  subtitle: Text('${p.castId} · ${p.kind.labelTh(s.isEnglish)}'),
                  trailing: active?.castId == p.castId
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      : const Icon(Icons.chevron_right, size: 20),
                  onTap: _busy ? null : () => _activate(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
