import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../models/profile_tag.dart';
import '../../models/viewing_request.dart';
import '../../services/chat_service.dart';
import '../../services/participant_moderation_service.dart';
import '../../data/hub_demo_data.dart';
import '../../data/hub_demo_seed.dart';
import '../../services/profile_tag_repository.dart';
import '../../services/profile_tag_service.dart';
import '../../services/viewing_request_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_mobile_layout.dart';
import '../contact/chat_link_detail_sheets.dart';
import 'admin_chat_panel.dart';

/// ภาพรวมผู้ใช้ 360° — Hub + threads + แท็ก + นัดดู + moderation
class AdminParticipantPage extends StatefulWidget {
  const AdminParticipantPage({super.key});

  @override
  State<AdminParticipantPage> createState() => _AdminParticipantPageState();
}

class _AdminParticipantPageState extends State<AdminParticipantPage> {
  final _search = TextEditingController();
  final _hubMessage = TextEditingController();
  String _selectedUserId = 'demo-user';
  bool _asAgent = false;
  String? _selectedThreadId;

  @override
  void initState() {
    super.initState();
    ProfileTagRepository.instance.ensureLoaded();
    HubDemoSeed.ensure();
    _search.text = 'ทดลอง-คนหาบ้าน@livingbkk.local';
    _selectedUserId = HubDemoData.seekerUserId;
  }

  @override
  void dispose() {
    _search.dispose();
    _hubMessage.dispose();
    super.dispose();
  }

  void _selectUser(String userId, {bool? agent}) {
    setState(() {
      _selectedUserId = userId;
      _selectedThreadId = null;
      if (agent != null) _asAgent = agent;
    });
    ChatService.instance.ensureHubForUser(_selectedUserId, agent: _asAgent);
  }

  void _resolveUser() {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    final id = HubDemoData.resolveUserId(q) ?? HubDemoData.seekerUserId;
    final agent = id == HubDemoData.agentUserId;
    _selectUser(id, agent: agent);
  }

  void _clearThread() => setState(() => _selectedThreadId = null);

  void _openTag(ProfileTag tag) {
    showProfileTagDetailSheet(context, tag.code, adminView: true);
  }

  void _openViewing(ViewingRequest v) {
    showViewingRequestDetailSheet(context, v.code, adminView: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final mod = ParticipantModerationService.instance.stateFor(_selectedUserId);
    final tags = ProfileTagService.instance.tagsForUser(userId: _selectedUserId);
    final viewings = ViewingRequestService.instance.forUser(_selectedUserId);
    final hub = ChatService.instance.participantHubForUser(
      _selectedUserId,
      agent: _asAgent,
    );
    final threads = ChatService.instance.threadsForUser(
      _selectedUserId,
      agent: _asAgent,
    );
    final dateFmt = DateFormat('d MMM yyyy HH:mm');

    return ListenableBuilder(
      listenable: Listenable.merge([
        ProfileTagService.instance,
        ViewingRequestService.instance,
        ParticipantModerationService.instance,
        ChatService.instance,
      ]),
      builder: (context, _) {
        return PopScope(
          canPop: _selectedThreadId == null,
          onPopInvoked: (didPop) {
            if (!didPop && _selectedThreadId != null) _clearThread();
          },
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.adminParticipantTitle, style: AdminTheme.title),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: s.adminParticipantSearchHint,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _resolveUser(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _resolveUser,
                    child: Text(s.t('ค้นหา', 'Search')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final row in HubDemoData.demoUserDirectory)
                    ActionChip(
                      label: Text(row.$1, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        _search.text = row.$3 ?? row.$2;
                        _selectUser(
                          row.$2,
                          agent: row.$2 == HubDemoData.agentUserId,
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: Text(s.customerRole),
                    selected: !_asAgent,
                    onSelected: (_) => setState(() => _asAgent = false),
                  ),
                  FilterChip(
                    label: Text(s.coAgentRole),
                    selected: _asAgent,
                    onSelected: (_) => setState(() => _asAgent = true),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _selectedUserId,
                style: AdminTheme.caption.copyWith(fontFamily: 'monospace'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth <
                        AdminMobileLayout.compactBreakpoint;

                    if (compact && _selectedThreadId != null) {
                      return AdminChatPanel(
                        key: ValueKey(_selectedThreadId),
                        roomId: _selectedThreadId!,
                        embedded: true,
                        onBack: _clearThread,
                      );
                    }

                    final list = _participantList(
                      s: s,
                      mod: mod,
                      hub: hub,
                      threads: threads,
                      tags: tags,
                      viewings: viewings,
                      dateFmt: dateFmt,
                    );

                    if (compact) {
                      return list;
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 280, child: list),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: _selectedThreadId == null
                              ? Center(
                                  child: Text(
                                    s.adminParticipantPickThread,
                                    style: AdminTheme.hint,
                                  ),
                                )
                              : AdminChatPanel(
                                  key: ValueKey(_selectedThreadId),
                                  roomId: _selectedThreadId!,
                                  embedded: true,
                                  onBack: _clearThread,
                                  backTooltip: s.back,
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _participantList({
    required AppStrings s,
    required ParticipantModerationState mod,
    required ChatRoom? hub,
    required List<ChatRoom> threads,
    required List<ProfileTag> tags,
    required List<ViewingRequest> viewings,
    required DateFormat dateFmt,
  }) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _section(s.adminParticipantModeration),
        SwitchListTile(
          title: Text(s.adminParticipantMute),
          value: mod.notificationsMuted,
          onChanged: (v) =>
              ParticipantModerationService.instance.setMuted(_selectedUserId, v),
        ),
        SwitchListTile(
          title: Text(s.adminParticipantFlag),
          value: mod.flaggedDisruptive,
          onChanged: (v) =>
              ParticipantModerationService.instance.setFlagged(_selectedUserId, v),
        ),
        SwitchListTile(
          title: Text(s.adminParticipantSuspend),
          value: mod.suspended,
          onChanged: (v) =>
              ParticipantModerationService.instance.setSuspended(_selectedUserId, v),
        ),
        const Divider(height: 24),
        _section(s.adminParticipantHub),
        if (hub == null)
          Text(s.adminParticipantNoUser, style: AdminTheme.hint)
        else
          ListTile(
            selected: _selectedThreadId == hub.id,
            title: Text(hub.listingTitle),
            subtitle: Text(hub.listingCode, style: AdminTheme.caption),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => setState(() => _selectedThreadId = hub.id),
          ),
        TextField(
          controller: _hubMessage,
          decoration: InputDecoration(
            hintText: s.adminParticipantMessageHub,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: () async {
            final text = _hubMessage.text.trim();
            if (text.isEmpty) return;
            await ChatService.instance.postAdminMessageToHub(
              _selectedUserId,
              text,
              agent: _asAgent,
            );
            _hubMessage.clear();
          },
          child: Text(s.adminParticipantMessageHub),
        ),
        const Divider(height: 24),
        _section(s.adminParticipantThreads),
        ...threads.map(
          (t) => ListTile(
            selected: _selectedThreadId == t.id,
            title: Text(
              t.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(t.listingCode),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => setState(() => _selectedThreadId = t.id),
          ),
        ),
        const Divider(height: 24),
        _section(s.adminParticipantTags),
        ...tags.map(_tagTile),
        const Divider(height: 24),
        _section(s.adminParticipantViewings),
        ...viewings.map(
          (v) => ListTile(
            dense: true,
            title: Text(
              '${v.code} · ${v.listingCode}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${dateFmt.format(v.scheduledAt)} · ${v.clientTagCode}\n${_statusLabel(v.status)}',
              style: AdminTheme.caption,
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _openViewing(v),
          ),
        ),
        if (viewings.isEmpty)
          Text(s.adminParticipantNoViewings, style: AdminTheme.hint),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AdminTheme.body.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }

  Widget _tagTile(ProfileTag t) {
    return ListTile(
      dense: true,
      title: Text(
        t.code,
        style: TextStyle(
          color: AppTheme.primary,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${t.subjectDisplayName ?? t.role.name} · v${t.version}',
        style: AdminTheme.caption,
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => _openTag(t),
    );
  }

  String _statusLabel(ViewingRequestStatus s) => switch (s) {
        ViewingRequestStatus.draft => 'ร่าง',
        ViewingRequestStatus.submitted => 'ส่งแล้ว',
        ViewingRequestStatus.sentToOwner => 'ส่งเจ้าของแล้ว',
        ViewingRequestStatus.ownerConfirmed => 'เจ้าของยืนยัน',
        ViewingRequestStatus.ownerDeclined => 'เจ้าของปฏิเสธ',
        ViewingRequestStatus.cancelled => 'ยกเลิก',
      };
}
