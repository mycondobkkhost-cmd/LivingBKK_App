import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_bot_logic_settings.dart';
import '../../models/chat_learned_answer.dart';
import '../../services/chat_bot_training_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import 'admin_chat_bot_training_sandbox_panel.dart';

/// หลังบ้าน — เทรนบอท AI (FAQ · ความจำ · ตรรกะการสื่อสาร)
class AdminChatBotTrainingTab extends StatefulWidget {
  const AdminChatBotTrainingTab({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AdminChatBotTrainingTab> createState() =>
      _AdminChatBotTrainingTabState();
}

class _AdminChatBotTrainingTabState extends State<AdminChatBotTrainingTab>
    with SingleTickerProviderStateMixin {
  final _repo = ChatBotTrainingRepository.instance;
  late TabController _tabs;

  List<Map<String, dynamic>> _faq = [];
  List<ChatLearnedAnswer> _learned = [];
  ChatBotLogicSettings _logic = ChatBotLogicSettings.defaults();
  bool _loading = true;
  bool _savingLogic = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final faq = await _repo.listFaqRules();
    final learned = await _repo.listLearnedAnswers();
    final logic = await _repo.loadLogicSettings();
    if (!mounted) return;
    setState(() {
      _faq = faq;
      _learned = learned;
      _logic = logic;
      _loading = false;
    });
  }

  Future<void> _saveLogic() async {
    setState(() => _savingLogic = true);
    await _repo.saveLogicSettings(_logic);
    if (!mounted) return;
    setState(() => _savingLogic = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminChatBotLogicSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(s.adminChatBotTrainingIntro, style: AdminTheme.hint),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: s.adminChatBotTabSandbox),
            Tab(text: s.adminChatBotTabFaq),
            Tab(text: s.adminChatBotTabMemory),
            Tab(text: s.adminChatBotTabLogic),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabs,
                  children: [
                    const AdminChatBotTrainingSandboxPanel(),
                    _FaqPanel(
                      rules: _faq,
                      onRefresh: _loadAll,
                      repo: _repo,
                    ),
                    _MemoryPanel(
                      answers: _learned,
                      onRefresh: _loadAll,
                      repo: _repo,
                    ),
                    _LogicPanel(
                      settings: _logic,
                      saving: _savingLogic,
                      onChanged: (v) => setState(() => _logic = v),
                      onSave: _saveLogic,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _FaqPanel extends StatelessWidget {
  const _FaqPanel({
    required this.rules,
    required this.onRefresh,
    required this.repo,
  });

  final List<Map<String, dynamic>> rules;
  final VoidCallback onRefresh;
  final ChatBotTrainingRepository repo;

  Future<void> _editRule(BuildContext context, Map<String, dynamic> rule) async {
    final s = context.s;
    final replyCtrl = TextEditingController(
      text: rule['reply_text']?.toString() ?? '',
    );
    final patternsCtrl = TextEditingController(
      text: ((rule['patterns'] as List?)?.cast<String>() ?? []).join(', '),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.adminChatBotFaqEditTitle),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: patternsCtrl,
                decoration: InputDecoration(
                  labelText: s.adminChatBotFaqPatternsLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replyCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: s.adminFaqReplyLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.save)),
        ],
      ),
    );
    if (ok != true) return;
    final patterns = patternsCtrl.text
        .split(RegExp(r'[,;\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await repo.updateFaqRule(
      rule['id'] as String,
      replyText: replyCtrl.text.trim(),
      patterns: patterns,
    );
    replyCtrl.dispose();
    patternsCtrl.dispose();
    onRefresh();
  }

  Future<void> _addRule(BuildContext context) async {
    final s = context.s;
    var scope = 'global';
    final patternsCtrl = TextEditingController();
    final replyCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(s.adminChatBotFaqAddTitle),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: scope,
                  decoration: InputDecoration(
                    labelText: s.adminChatBotFaqScopeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'global', child: Text(s.adminChatBotScopeGlobal)),
                    DropdownMenuItem(value: 'property', child: Text(s.adminChatBotScopeProperty)),
                    DropdownMenuItem(value: 'discovery', child: Text(s.adminChatBotScopeDiscovery)),
                  ],
                  onChanged: (v) => setSt(() => scope = v ?? 'global'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: patternsCtrl,
                  decoration: InputDecoration(
                    labelText: s.adminChatBotFaqPatternsLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: replyCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: s.adminFaqReplyLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.save)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await repo.createFaqRule(
      scope: scope,
      patterns: patternsCtrl.text
          .split(RegExp(r'[,;\n]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      replyText: replyCtrl.text.trim(),
    );
    patternsCtrl.dispose();
    replyCtrl.dispose();
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.adminChatBotFaqHint,
                  style: AdminTheme.caption,
                ),
              ),
              IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
              FilledButton.icon(
                onPressed: () => _addRule(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(s.adminChatBotFaqAddBtn),
              ),
            ],
          ),
        ),
        Expanded(
          child: rules.isEmpty
              ? Center(child: Text(s.adminFaqEmpty))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rules.length,
                  itemBuilder: (context, i) {
                    final rule = rules[i];
                    final patterns =
                        (rule['patterns'] as List?)?.cast<String>() ?? [];
                    final scope = rule['scope']?.toString() ?? 'global';
                    final active = rule['is_active'] != false;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: SwitchListTile(
                        value: active,
                        onChanged: (v) async {
                          await repo.updateFaqRule(
                            rule['id'] as String,
                            isActive: v,
                          );
                          onRefresh();
                        },
                        title: Text(
                          patterns.take(4).join(' · '),
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
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: active ? () => _editRule(context, rule) : null,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MemoryPanel extends StatelessWidget {
  const _MemoryPanel({
    required this.answers,
    required this.onRefresh,
    required this.repo,
  });

  final List<ChatLearnedAnswer> answers;
  final VoidCallback onRefresh;
  final ChatBotTrainingRepository repo;

  Future<void> _editAnswer(BuildContext context, ChatLearnedAnswer? existing) async {
    final s = context.s;
    final topicCtrl = TextEditingController(text: existing?.topicKey ?? '');
    final qCtrl = TextEditingController(text: existing?.questionExample ?? '');
    final aCtrl = TextEditingController(text: existing?.answerGuidance ?? '');
    var scope = existing?.scope ?? 'global';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(
            existing == null ? s.adminChatBotMemoryAddTitle : s.adminChatBotMemoryEditTitle,
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: topicCtrl,
                    decoration: InputDecoration(
                      labelText: s.adminChatBotMemoryTopicLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: qCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: s.adminChatBotMemoryQuestionLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: aCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: s.adminChatBotMemoryGuidanceLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: scope,
                    decoration: InputDecoration(
                      labelText: s.adminChatBotFaqScopeLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'global', child: Text('global')),
                      DropdownMenuItem(value: 'property_type', child: Text('property_type')),
                      DropdownMenuItem(value: 'listing', child: Text('listing')),
                    ],
                    onChanged: (v) => setSt(() => scope = v ?? 'global'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.save)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (existing != null) {
      await repo.upsertLearnedAnswer(
        existing.copyWith(
          topicKey: topicCtrl.text.trim(),
          questionExample: qCtrl.text.trim(),
          answerGuidance: aCtrl.text.trim(),
          scope: scope,
        ),
      );
    } else {
      await repo.createLearnedAnswer(
        topicKey: topicCtrl.text.trim(),
        questionExample: qCtrl.text.trim(),
        answerGuidance: aCtrl.text.trim(),
        scope: scope,
      );
    }
    topicCtrl.dispose();
    qCtrl.dispose();
    aCtrl.dispose();
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(child: Text(s.adminChatBotMemoryHint, style: AdminTheme.caption)),
              IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
              FilledButton.icon(
                onPressed: () => _editAnswer(context, null),
                icon: const Icon(Icons.add, size: 18),
                label: Text(s.adminChatBotMemoryAddBtn),
              ),
            ],
          ),
        ),
        Expanded(
          child: answers.isEmpty
              ? Center(child: Text(s.adminChatBotMemoryEmpty))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: answers.length,
                  itemBuilder: (context, i) {
                    final a = answers[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(a.topicKey, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '「${a.questionExample}」\n→ ${a.answerGuidance}',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${a.scope} · ${a.useCount}', style: AdminTheme.caption),
                            Switch(
                              value: a.isActive,
                              onChanged: (v) async {
                                await repo.setLearnedActive(a.id, v);
                                onRefresh();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _editAnswer(context, a),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _LogicPanel extends StatelessWidget {
  const _LogicPanel({
    required this.settings,
    required this.saving,
    required this.onChanged,
    required this.onSave,
  });

  final ChatBotLogicSettings settings;
  final bool saving;
  final ValueChanged<ChatBotLogicSettings> onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.adminChatBotLogicHint, style: AdminTheme.caption),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('voice-extra'),
          initialValue: settings.voiceExtraRules,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: s.adminChatBotLogicVoiceLabel,
            hintText: s.adminChatBotLogicVoiceHint,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: (v) => onChanged(settings.copyWith(voiceExtraRules: v)),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.adminChatBotLogicCoachSwitch),
          subtitle: Text(s.adminChatBotLogicCoachHint, style: AdminTheme.caption),
          value: settings.coachWhenLowConfidence,
          onChanged: (v) => onChanged(settings.copyWith(coachWhenLowConfidence: v)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.adminChatBotLogicEscalateLabel),
          subtitle: Slider(
            value: settings.unclearEscalateThreshold.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '${settings.unclearEscalateThreshold}',
            onChanged: (v) => onChanged(
              settings.copyWith(unclearEscalateThreshold: v.round()),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(s.adminChatBotLogicStrategyTitle, style: AdminTheme.body.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final key in ChatBotLogicSettings.strategyKeys)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              key: ValueKey('strategy-$key'),
              initialValue: settings.strategyHints[key] ??
                  ChatBotLogicSettings.defaults().strategyHints[key] ??
                  '',
              maxLines: 2,
              decoration: InputDecoration(
                labelText: key,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                final next = Map<String, String>.from(settings.strategyHints);
                next[key] = v;
                onChanged(settings.copyWith(strategyHints: next));
              },
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(s.adminChatBotLogicSaveBtn),
        ),
      ],
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
