import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_chat_ops.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import 'admin_inbox_preview.dart';

class AdminChatSearchResult {
  const AdminChatSearchResult({
    required this.room,
    required this.message,
    required this.score,
    required this.titleLine,
    required this.snippet,
  });

  final ChatRoom room;
  final ChatMessage message;
  final int score;
  final String titleLine;
  final String snippet;
}

/// ค้นหาข้อความในแชทแอดมิน — เรียงจากตรงที่สุด
List<AdminChatSearchResult> searchAdminChatMessages(
  String query,
  List<ChatRoom> rooms,
  AppStrings s,
) {
  final q = query.trim().toLowerCase();
  if (q.length < 2) return [];

  final results = <AdminChatSearchResult>[];
  for (final room in rooms) {
    final preview = AdminInboxPreview.fromRoom(room, s);
    for (final msg in room.messages) {
      final text = msg.text.trim();
      if (text.isEmpty) continue;
      final score = _matchScore(q, text);
      if (score <= 0) continue;
      results.add(
        AdminChatSearchResult(
          room: room,
          message: msg,
          score: score,
          titleLine: preview.titleLine,
          snippet: _snippetAround(text, q),
        ),
      );
    }
  }

  results.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return b.message.createdAt.compareTo(a.message.createdAt);
  });
  return results.take(40).toList();
}

int _matchScore(String q, String text) {
  final t = text.toLowerCase();
  if (t == q) return 1000;
  if (t.startsWith(q)) return 850;
  final word = RegExp(r'(^|\s)' + RegExp.escape(q));
  if (word.hasMatch(t)) return 700;
  if (t.contains(q)) return 500;
  return 0;
}

String _snippetAround(String text, String q) {
  final lower = text.toLowerCase();
  final idx = lower.indexOf(q.toLowerCase());
  if (idx < 0) {
    return text.length > 90 ? '${text.substring(0, 89)}…' : text;
  }
  const pad = 28;
  final start = (idx - pad).clamp(0, text.length);
  final end = (idx + q.length + pad).clamp(0, text.length);
  var slice = text.substring(start, end).trim();
  if (start > 0) slice = '…$slice';
  if (end < text.length) slice = '$slice…';
  return slice;
}

Future<AdminChatSearchResult?> showAdminInboxSearchSheet(
  BuildContext context, {
  required List<ChatRoom> rooms,
}) async {
  return showModalBottomSheet<AdminChatSearchResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _AdminInboxSearchSheet(rooms: rooms),
  );
}

class _AdminInboxSearchSheet extends StatefulWidget {
  const _AdminInboxSearchSheet({required this.rooms});

  final List<ChatRoom> rooms;

  @override
  State<_AdminInboxSearchSheet> createState() => _AdminInboxSearchSheetState();
}

class _AdminInboxSearchSheetState extends State<_AdminInboxSearchSheet> {
  final _query = TextEditingController();
  List<AdminChatSearchResult> _results = const [];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _runSearch() {
    setState(() {
      _results = searchAdminChatMessages(
        _query.text,
        widget.rooms,
        context.s,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final locale = s.isEnglish ? 'en' : 'th';
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.adminChatSearchTitle, style: AdminTheme.title),
            const SizedBox(height: 8),
            TextField(
              controller: _query,
              autofocus: true,
              decoration: InputDecoration(
                hintText: s.adminChatSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _runSearch(),
              onSubmitted: (_) => _runSearch(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _query.text.trim().length < 2
                            ? s.adminChatSearchMinChars
                            : s.adminChatSearchEmpty,
                        style: AdminTheme.hint,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = _results[i];
                        final time = DateFormat('d MMM HH:mm', locale)
                            .format(r.message.createdAt);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            r.titleLine,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '$time · ${r.snippet}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: LivingBkkBrand.purplePrimary,
                          ),
                          onTap: () => Navigator.pop(context, r),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// รวมห้องจากทุก bucket สำหรับค้นหา
List<ChatRoom> adminInboxSearchScope() {
  final chat = ChatService.instance;
  final ids = <String>{};
  final out = <ChatRoom>[];
  void addAll(Iterable<ChatRoom> list) {
    for (final r in list) {
      if (ids.add(r.id)) out.add(r);
    }
  }

  addAll(chat.listAdminInbox(bucket: AdminInboxBucket.unclaimed));
  addAll(chat.listAdminInbox(bucket: AdminInboxBucket.mine));
  addAll(chat.listAdminInbox(bucket: AdminInboxBucket.resolved, includeResolved: true));
  addAll(chat.allAdminSearchableRooms());
  return out;
}
