import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_mobile_layout.dart';

/// ตั้งค่า FAQ อัตโนมัติ — ลดงานแอดมิน (แก้ได้โดยไม่ deploy)
class AdminFaqPage extends StatefulWidget {
  const AdminFaqPage({super.key});

  @override
  State<AdminFaqPage> createState() => _AdminFaqPageState();
}

class _AdminFaqPageState extends State<AdminFaqPage> {
  final _admin = AdminRepository();
  List<Map<String, dynamic>> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rules = await _admin.listChatFaqRules();
    if (!mounted) return;
    setState(() {
      _rules = rules;
      _loading = false;
    });
  }

  Future<void> _editRule(Map<String, dynamic> rule) async {
    final controller = TextEditingController(
      text: rule['reply_text']?.toString() ?? '',
    );
    final s = AppStrings.of(context);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.adminFaqEditTitle),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: s.adminFaqReplyLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.save)),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    await _admin.updateChatFaqRule(
      rule['id'] as String,
      replyText: controller.text.trim(),
    );
    _load();
  }

  Future<void> _toggleRule(Map<String, dynamic> rule, bool active) async {
    await _admin.updateChatFaqRule(rule['id'] as String, isActive: active);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AdminMobileLayout.scaffold(
      context: context,
      appBar: AdminMobileLayout.appBar(
        context: context,
        title: Text(s.adminFaqTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AdminMobileLayout.scrollPadding(context, top: 12, horizontal: 12),
              children: [
                Card(
                  color: AppTheme.primaryLight,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      s.adminFaqIntro,
                      style: TextStyle(fontSize: 13, height: 1.45),
                    ),
                  ),
                ),
                if (_rules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      s.adminFaqEmpty,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._rules.map((rule) {
                    final patterns = (rule['patterns'] as List?)?.cast<String>() ?? [];
                    final scope = rule['scope']?.toString() ?? 'global';
                    final active = rule['is_active'] != false;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: SwitchListTile(
                        value: active,
                        onChanged: (v) => _toggleRule(rule, v),
                        title: Text(
                          patterns.take(3).join(' · '),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: active ? null : AppTheme.textSecondary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            _ScopeChip(scope: scope),
                            const SizedBox(height: 6),
                            Text(
                              rule['reply_text']?.toString() ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: active ? () => _editRule(rule) : null,
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.scope});

  final String scope;

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (scope) {
      case 'property':
        c = AppTheme.primary;
      case 'discovery':
        c = AppTheme.accentDeep;
      default:
        c = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(scope, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }
}
