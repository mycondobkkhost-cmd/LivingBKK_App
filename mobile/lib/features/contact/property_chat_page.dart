import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/demo_listings_factory.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../utils/listing_navigation.dart';
import '../../models/listing_public.dart';
import '../../models/listing_route_extra.dart';
import '../../l10n/app_strings.dart';
import '../../utils/localized_content.dart';
import '../../services/chat_repository.dart';
import '../../services/chat_service.dart';
import '../../services/listing_repository.dart';
import '../../theme/app_theme.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../utils/chat_room_display.dart';
import '../../widgets/reference_code_chip.dart';
import 'book_viewing_form_sheet.dart';
import 'viewing_submitted_dialog.dart';
import '../../widgets/app_mobile_scaffold.dart';

void openPropertyChat(
  BuildContext context,
  ListingPublic listing, {
  bool allowViewingRequest = false,
  bool openViewingForm = false,
}) {
  _openPropertyChatAsync(
    context,
    listing,
    allowViewingRequest: allowViewingRequest,
    openViewingForm: openViewingForm,
  );
}

Future<void> _openPropertyChatAsync(
  BuildContext context,
  ListingPublic listing, {
  bool allowViewingRequest = false,
  bool openViewingForm = false,
}) async {
  final room = await ChatService.instance.openRoom(
    listingId: listing.id,
    listingCode: listing.listingCode,
    listingTitle: listing.localizedTitle(AppStrings.of(context).isEnglish),
    projectName: listing.localizedProjectName(AppStrings.of(context).isEnglish) ??
        listing.projectName,
    allowViewingRequest: allowViewingRequest,
  );
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => PropertyChatPage(
        room: room,
        openViewingFormOnStart: openViewingForm,
      ),
    ),
  );
}

class PropertyChatPage extends StatefulWidget {
  const PropertyChatPage({
    super.key,
    required this.room,
    this.openViewingFormOnStart = false,
  });

  final ChatRoom room;
  final bool openViewingFormOnStart;

  @override
  State<PropertyChatPage> createState() => _PropertyChatPageState();
}

class _PropertyChatPageState extends State<PropertyChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _listingRepo = ListingRepository();
  bool _sending = false;
  bool _translateEn = false;
  RealtimeChannel? _realtimeChannel;

  ChatRoom get _room =>
      ChatService.instance.roomById(widget.room.id) ??
      ChatService.instance.roomForListing(widget.room.listingId) ??
      ChatService.instance.roomForListing(widget.room.listingCode) ??
      widget.room;

  bool get _showViewingButton =>
      _room.isPropertyListing &&
      !_room.isDiscovery &&
      _room.allowViewingRequest &&
      !_room.isStaffSupport;

  @override
  void initState() {
    super.initState();
    ChatService.instance.markThreadRead(_room.id);
    ChatService.instance.ensureCustomerInboxRealtime();
    _realtimeChannel = ChatService.instance.subscribeToThread(_room, () {
      if (mounted) setState(() {});
      _scrollToBottom();
    });
    if (widget.openViewingFormOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openViewingForm());
    }
  }

  Future<void> _send() async {
    var text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (_translateEn) {
      text = '[EN] $text';
    }
    _input.clear();
    setState(() => _sending = true);
    await ChatService.instance.sendUserMessage(_room, text);
    if (!mounted) return;
    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openViewingForm() async {
    if (!_showViewingButton || _room.viewingSubmitted) return;
    await _openViewingFormFromLink();
  }

  Future<void> _openViewingFormFromLink() async {
    final result = await showBookViewingFormSheet(context, room: _room);
    if (!mounted || result == null) return;
    setState(() {});
    _scrollToBottom();
    await showViewingSubmittedDialog(
      context,
      profileSummary: result.summary,
      savedToDatabase: result.savedToDatabase,
      duplicatePhoneSuffix: result.duplicatePhoneSuffix,
      chatRef: _room.effectiveTransactionRef,
      leadRef: result.leadTransactionRef,
    );
  }

  Future<void> _handleActionLink(ChatMessageLink link) async {
    switch (link.kind) {
      case ChatMessageLinkKind.requirementForm:
        DemandBoardNavigation.openCreateRequirement(
          context,
          sourceThreadId: _room.id,
        );
        break;
      case ChatMessageLinkKind.viewingForm:
        await _openViewingFormFromLink();
        break;
      case ChatMessageLinkKind.listing:
      case ChatMessageLinkKind.projectUnits:
        break;
    }
  }

  Future<void> _askListing(ChatMessageLink link) async {
    List<ListingPublic> all;
    try {
      all = await _listingRepo.fetchPublished();
    } catch (_) {
      all = DemoListingsFactory.cached;
    }

    final listing = all.cast<ListingPublic?>().firstWhere(
          (l) => l?.id == link.listingId,
          orElse: () => null,
        );
    if (listing == null || !mounted) return;
    openPropertyChat(context, listing);
  }

  Future<void> _openLink(ChatMessageLink link) async {
    List<ListingPublic> all;
    try {
      all = await _listingRepo.fetchPublished();
    } catch (_) {
      all = DemoListingsFactory.cached;
    }

    if (link.kind == ChatMessageLinkKind.listing) {
      final listing = all.cast<ListingPublic?>().firstWhere(
            (l) => l?.id == link.listingId,
            orElse: () => null,
          );
      if (listing == null || !mounted) return;
      context.push(
        '/listing/${listing.id}',
        extra: ListingRouteExtra(listing: listing, isAgent: false),
      );
      return;
    }

    final project = link.projectName;
    if (project == null) return;
    ListingNavigation.openProject(
      context,
      projectName: project,
      isAgent: false,
    );
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      ChatRepository().unsubscribe(_realtimeChannel);
    }
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        final s = context.s;
        final room = _room;
        final showAiNote = !room.isStaffSupport;
        final quickReplies = room.isDiscovery
            ? s.discoveryChatQuickReplies
            : room.isCustomerRequirement
                ? s.requirementChatQuickReplies
                : s.propertyChatQuickReplies;

        return AppMobileScaffold(
      safeBottomBody: false,
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.chatScreenTitle(s),
              style: TextStyle(fontSize: 16),
            ),
            Text(
              room.displayTitle,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          TransactionReferenceBar(
            listingCode: room.isPropertyListing ? room.listingCode : null,
            transactionRef: room.effectiveTransactionRef,
          ),
          if (showAiNote && !room.isStaffSupport)
            Container(
              width: double.infinity,
              color: AppTheme.accentDeepLight,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                s.chatAiDisclaimer,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.accentDeep.withOpacity(0.95),
                  height: 1.35,
                ),
              ),
            ),
          if (room.adminEscalated && room.isStaffSupport)
            Container(
              width: double.infinity,
              color: AppTheme.accentMidLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                s.chatStaffEscalated,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: room.messages.length,
              itemBuilder: (context, i) => _Bubble(
                message: room.messages[i],
                onLinkTap: _openLink,
                onAskListing: _askListing,
                onActionLinkTap: _handleActionLink,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text(s.chatTranslate),
                          selected: _translateEn,
                          onSelected: (v) => setState(() => _translateEn = v),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 6),
                        ...quickReplies.map(
                          (q) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(q, style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                _input.text = q;
                                _send();
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          decoration: InputDecoration(
                            hintText: _translateEn ? s.chatHintEnglish : s.chatHintThai,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _showViewingButton
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FilledButton.icon(
                  onPressed: room.viewingSubmitted ? null : _openViewingForm,
                  icon: const Icon(Icons.event_available),
                  label: Text(room.viewingSubmitted ? s.chatViewingSubmitted : s.requestViewingTitle),
                ),
              ),
            )
          : null,
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.onLinkTap,
    required this.onAskListing,
    required this.onActionLinkTap,
  });

  final ChatMessage message;
  final ValueChanged<ChatMessageLink> onLinkTap;
  final ValueChanged<ChatMessageLink> onAskListing;
  final ValueChanged<ChatMessageLink> onActionLinkTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;
    final isStaffReply = message.role == ChatMessageRole.adminNotice &&
        !message.text.startsWith('รับข้อความแล้ว') &&
        !message.text.startsWith('⚠️') &&
        !message.text.startsWith('รายละเอียดนัดดู');
    final isSystem = message.role == ChatMessageRole.system ||
        (message.role == ChatMessageRole.adminNotice && !isStaffReply);

    Color bg;
    Alignment align;
    if (isUser) {
      bg = AppTheme.primary;
      align = Alignment.centerRight;
    } else if (isStaffReply) {
      bg = AppTheme.accentMidLight;
      align = Alignment.centerLeft;
    } else if (isSystem) {
      bg = AppTheme.primaryLight;
      align = Alignment.center;
    } else {
      bg = AppTheme.accentMutedLight;
      align = Alignment.centerLeft;
    }

    final textColor = isUser ? Colors.white : AppTheme.textPrimary;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: isSystem ? null : Border.all(color: AppTheme.border.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isStaffReply)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  context.s.chatTeamLivingBkk,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentMid,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(color: textColor, height: 1.35),
            ),
            if (message.links.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...message.links.map(
                (link) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        link.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (link.isFormAction)
                        FilledButton.icon(
                          onPressed: () => onActionLinkTap(link),
                          icon: Icon(
                            link.kind == ChatMessageLinkKind.requirementForm
                                ? Icons.edit_note_outlined
                                : Icons.event_available_outlined,
                            size: 18,
                          ),
                          label: Text(link.label),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => onLinkTap(link),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  backgroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                                child: Text(
                                  context.s.chatLinkViewListing,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            if (link.kind == ChatMessageLinkKind.listing) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => onAskListing(link),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.accentDeep,
                                    backgroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: Text(
                                    context.s.chatLinkAskListing,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
