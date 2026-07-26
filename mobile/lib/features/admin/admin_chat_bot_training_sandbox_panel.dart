import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_bot_sandbox_message.dart';
import '../../services/chat_bot_training_sandbox_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';

/// แท็บทดลองแชท — สลับบทบาทลูกค้า/โค้ช · ผ่าน-ไม่ผ่าน · บันทึก FAQ ในแชทเดียว
class AdminChatBotTrainingSandboxPanel extends StatefulWidget {
  const AdminChatBotTrainingSandboxPanel({super.key});

  @override
  State<AdminChatBotTrainingSandboxPanel> createState() =>
      _AdminChatBotTrainingSandboxPanelState();
}

class _AdminChatBotTrainingSandboxPanelState
    extends State<AdminChatBotTrainingSandboxPanel> {
  final _sandbox = ChatBotTrainingSandboxService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _fixCtrl = TextEditingController();
  String? _fixForBotId;

  @override
  void initState() {
    super.initState();
    _sandbox.addListener(_onSandbox);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sandbox.init(isEnglish: context.s.isEnglish);
    });
  }

  @override
  void dispose() {
    _sandbox.removeListener(_onSandbox);
    _input.dispose();
    _scroll.dispose();
    _fixCtrl.dispose();
    super.dispose();
  }

  void _onSandbox() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await _sandbox.send(text, isEnglish: context.s.isEnglish);
  }

  Future<void> _sendQuick(String text) async {
    await _sandbox.send(text, isEnglish: context.s.isEnglish);
  }

  Future<void> _submitFix(String botId) async {
    final fix = _fixCtrl.text.trim();
    if (fix.isEmpty) return;
    await _sandbox.reviewBot(
      botMessageId: botId,
      passed: false,
      suggestedReply: fix,
      isEnglish: context.s.isEnglish,
    );
    setState(() {
      _fixForBotId = null;
      _fixCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (_sandbox.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.adminChatBotSandboxHint, style: AdminTheme.caption),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<ChatBotSandboxRole>(
                      segments: [
                        ButtonSegment(
                          value: ChatBotSandboxRole.customer,
                          label: Text(s.adminChatBotSandboxRoleCustomer),
                          icon: const Icon(Icons.person_outline, size: 18),
                        ),
                        ButtonSegment(
                          value: ChatBotSandboxRole.coach,
                          label: Text(s.adminChatBotSandboxRoleCoach),
                          icon: const Icon(Icons.school_outlined, size: 18),
                        ),
                      ],
                      selected: {_sandbox.role},
                      onSelectionChanged: (v) {
                        if (v.isEmpty) return;
                        _sandbox.setRole(v.first);
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: s.adminChatBotSandboxReset,
                    onPressed: () => _sandbox.reset(isEnglish: s.isEnglish),
                    icon: const Icon(Icons.restart_alt),
                  ),
                ],
              ),
              if (_sandbox.role == ChatBotSandboxRole.customer) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.adminChatBotSandboxPersonaLabel,
                    style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<ChatBotSandboxPersona>(
                  segments: [
                    ButtonSegment(
                      value: ChatBotSandboxPersona.seeker,
                      label: Text(s.adminChatBotSandboxPersonaSeeker),
                      icon: const Icon(Icons.search, size: 16),
                    ),
                    ButtonSegment(
                      value: ChatBotSandboxPersona.coAgent,
                      label: Text(s.adminChatBotSandboxPersonaCoAgent),
                      icon: const Icon(Icons.handshake_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ChatBotSandboxPersona.owner,
                      label: Text(s.adminChatBotSandboxPersonaOwner),
                      icon: const Icon(Icons.home_work_outlined, size: 16),
                    ),
                  ],
                  selected: {_sandbox.customerPersona},
                  onSelectionChanged: (v) {
                    if (v.isEmpty) return;
                    _sandbox.setCustomerPersona(v.first);
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.lightbulb_outline, size: 16),
                    label: Text(
                      '${s.adminChatBotSandboxSampleAsk}: '
                      '${ChatBotTrainingSandboxService.personaSampleQuestion(_sandbox.customerPersona)}',
                    ),
                    onPressed: () {
                      _input.text = ChatBotTrainingSandboxService
                          .personaSampleQuestion(_sandbox.customerPersona);
                      setState(() {});
                    },
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 18,
                            color: LivingBkkBrand.purplePrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.adminChatBotSandboxCoachGuideTitle,
                            style: AdminTheme.body.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.adminChatBotSandboxCoachGuideBody,
                        style: AdminTheme.caption.copyWith(height: 1.45),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _CoachQuickChip(
                            label: s.adminChatBotSandboxCoachQuickPass,
                            onTap: () => _sendQuick('ผ่าน'),
                          ),
                          _CoachQuickChip(
                            label: s.adminChatBotSandboxCoachQuickFail,
                            onTap: () => _sendQuick('ไม่ผ่าน'),
                          ),
                          _CoachQuickChip(
                            label: s.adminChatBotSandboxCoachQuickFix,
                            onTap: () {
                              _input.text = s.adminChatBotSandboxCoachQuickFix;
                              setState(() {});
                            },
                          ),
                          _CoachQuickChip(
                            label: s.adminChatBotSandboxCoachQuickReset,
                            onTap: () => _sandbox.reset(isEnglish: s.isEnglish),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            itemCount: _sandbox.messages.length,
            itemBuilder: (context, i) {
              final m = _sandbox.messages[i];
              return _MessageBlock(
                message: m,
                fixForBotId: _fixForBotId,
                fixController: _fixCtrl,
                onPass: () => _sandbox.reviewBot(
                  botMessageId: m.id,
                  passed: true,
                  isEnglish: s.isEnglish,
                ),
                onFail: () => setState(() {
                  _fixForBotId = m.id;
                  _fixCtrl.clear();
                }),
                onSubmitFix: () => _submitFix(m.id),
                onCancelFix: () => setState(() => _fixForBotId = null),
                labels: _MessageLabels(s),
              );
            },
          ),
        ),
        Material(
          elevation: 8,
          color: AdminTheme.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _sandbox.role == ChatBotSandboxRole.customer
                            ? '${ChatBotTrainingSandboxService.personaLabel(_sandbox.customerPersona, isEnglish: s.isEnglish)} — ${s.adminChatBotSandboxInputCustomer}'
                            : s.adminChatBotSandboxInputCoach,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _send,
                    child: Text(s.adminSendReply),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageLabels {
  const _MessageLabels(this.s);

  final AppStrings s;

  String get pass => s.adminChatBotSandboxPass;
  String get fail => s.adminChatBotSandboxFail;
  String get fixHint => s.adminChatBotSandboxFixHint;
  String get applyFix => s.adminChatBotSandboxApplyFix;
  String get cancel => s.cancel;

  String roleLabel(ChatBotSandboxMessageKind kind, {ChatBotSandboxPersona? persona}) {
    switch (kind) {
      case ChatBotSandboxMessageKind.customer:
        if (persona != null) {
          return ChatBotTrainingSandboxService.personaLabel(
            persona,
            isEnglish: s.isEnglish,
          );
        }
        return s.adminChatBotSandboxRoleCustomer;
      case ChatBotSandboxMessageKind.bot:
        return s.adminChatBotSandboxBotLabel;
      case ChatBotSandboxMessageKind.coach:
        return s.adminChatBotSandboxRoleCoach;
      case ChatBotSandboxMessageKind.system:
        return s.adminChatBotSandboxSystemLabel;
    }
  }
}

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({
    required this.message,
    required this.fixForBotId,
    required this.fixController,
    required this.onPass,
    required this.onFail,
    required this.onSubmitFix,
    required this.onCancelFix,
    required this.labels,
  });

  final ChatBotSandboxMessage message;
  final String? fixForBotId;
  final TextEditingController fixController;
  final VoidCallback onPass;
  final VoidCallback onFail;
  final VoidCallback onSubmitFix;
  final VoidCallback onCancelFix;
  final _MessageLabels labels;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final isBot = m.kind == ChatBotSandboxMessageKind.bot;
    final isSystem = m.kind == ChatBotSandboxMessageKind.system;
    final align = m.kind == ChatBotSandboxMessageKind.customer ||
            m.kind == ChatBotSandboxMessageKind.coach
        ? Alignment.centerRight
        : Alignment.centerLeft;

    Color bg;
    Color fg = AdminTheme.text;
    switch (m.kind) {
      case ChatBotSandboxMessageKind.customer:
        bg = LivingBkkBrand.purplePrimary.withOpacity(0.12);
      case ChatBotSandboxMessageKind.coach:
        bg = const Color(0xFFEFF6FF);
      case ChatBotSandboxMessageKind.bot:
        bg = Colors.white;
      case ChatBotSandboxMessageKind.system:
        bg = const Color(0xFFF4F4F5);
        fg = AdminTheme.textMuted;
    }

    final showReview = isBot && m.reviewPassed == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: align,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.88,
          ),
          child: Column(
            crossAxisAlignment: align == Alignment.centerRight
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSystem)
                    Text(
                      labels.roleLabel(m.kind, persona: m.persona),
                      style: AdminTheme.caption.copyWith(fontSize: 10),
                    ),
                  if (m.sourceLabel != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        m.sourceLabel!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                  if (m.reviewPassed == true) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_circle, size: 14, color: AppTheme.success),
                  ],
                  if (m.reviewPassed == false) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.cancel, size: 14, color: AppTheme.error),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isBot ? AdminTheme.border : Colors.transparent,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Text(
                    m.text,
                    style: TextStyle(fontSize: 13, height: 1.4, color: fg),
                  ),
                ),
              ),
              if (m.appliedTraining != null && m.appliedTraining!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '→ ${m.appliedTraining!}',
                  style: AdminTheme.caption.copyWith(
                    color: AppTheme.success,
                    fontSize: 11,
                  ),
                ),
              ],
              if (showReview) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onPass,
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(labels.pass),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppTheme.success,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onFail,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(labels.fail),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ],
              if (fixForBotId == m.id) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: fixController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: labels.fixHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: onSubmitFix,
                      child: Text(labels.applyFix),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: onCancelFix, child: Text(labels.cancel)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachQuickChip extends StatelessWidget {
  const _CoachQuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}
