import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/hub_demo_data.dart';
import '../../l10n/app_strings.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../models/profile_tag.dart';
import '../../models/viewing_request.dart';
import '../../services/profile_tag_service.dart';
import '../../services/viewing_request_service.dart';
import '../../theme/app_theme.dart';

/// เรียงรายการแชทใน inbox
enum AdminInboxSort {
  recentFirst,
  oldestWaitingFirst,
}

/// แท็กกรอง — แท็บรอรับงาน (ก่อนรับงาน)
enum AdminInboxFilterTag {
  all,
  agent,
  direct,
  coAgent,
  viewing,
  property,
  general,
  urgent,
}

/// บทบาทสำหรับ suffix และกรอง
enum AdminInboxRoleKind {
  direct,
  agent,
  coAgent,
}

/// เจตนา/ประเภทเคสสำหรับกรอง
enum AdminInboxIntentKind {
  viewing,
  property,
  discovery,
  general,
  booking,
  offer,
  requirement,
  escalation,
  agentInterest,
}

/// สรุปแถวแชท — ชื่อ (ROLE) · เจตนา · ตัวอย่างข้อความ + เวลาส่ง
class AdminInboxPreview {
  const AdminInboxPreview({
    required this.displayName,
    required this.titleLine,
    required this.roleKind,
    required this.roleLabel,
    required this.roleSuffix,
    required this.intentKind,
    required this.intentLabel,
    required this.previewText,
    required this.previewMessageAt,
    this.isUrgent = false,
  });

  final String displayName;
  final String titleLine;
  final AdminInboxRoleKind roleKind;
  final String roleLabel;
  final String roleSuffix;
  final AdminInboxIntentKind intentKind;
  final String intentLabel;
  final String previewText;
  final DateTime previewMessageAt;
  final bool isUrgent;

  bool get isCoAgencyCustomer => roleKind == AdminInboxRoleKind.coAgent;

  static AdminInboxPreview fromRoom(ChatRoom room, AppStrings s) {
    final name = _resolveDisplayName(room);
    final role = _resolveRole(room, s);
    final intent = _resolveIntent(room, s);
    final previewMsg = _resolvePreviewMessage(room, s);
    final titleLine = name;

    return AdminInboxPreview(
      displayName: name,
      titleLine: titleLine,
      roleKind: role.kind,
      roleLabel: role.label,
      roleSuffix: role.suffix,
      intentKind: intent.kind,
      intentLabel: intent.label,
      previewText: previewMsg.text,
      previewMessageAt: previewMsg.at,
      isUrgent: room.priority == 'high' || room.category == 'booking_interest',
    );
  }

  static String formatMessageSentAt(DateTime at, AppStrings s) {
    final locale = s.isEnglish ? 'en' : 'th';
    final now = DateTime.now();
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    if (sameDay) return DateFormat('HH:mm', locale).format(at);
    return DateFormat('d MMM HH:mm', locale).format(at);
  }

  static List<ChatRoom> filterRooms(
    List<ChatRoom> rooms,
    AdminInboxFilterTag filter,
    AppStrings s,
  ) {
    if (filter == AdminInboxFilterTag.all) return rooms;
    return rooms
        .where((r) => fromRoom(r, s).matchesFilter(filter))
        .toList();
  }

  bool matchesFilter(AdminInboxFilterTag filter) {
    switch (filter) {
      case AdminInboxFilterTag.all:
        return true;
      case AdminInboxFilterTag.agent:
        return roleKind == AdminInboxRoleKind.agent;
      case AdminInboxFilterTag.direct:
        return roleKind == AdminInboxRoleKind.direct;
      case AdminInboxFilterTag.coAgent:
        return roleKind == AdminInboxRoleKind.coAgent;
      case AdminInboxFilterTag.viewing:
        return intentKind == AdminInboxIntentKind.viewing;
      case AdminInboxFilterTag.property:
        return intentKind == AdminInboxIntentKind.property ||
            intentKind == AdminInboxIntentKind.discovery;
      case AdminInboxFilterTag.general:
        return intentKind == AdminInboxIntentKind.general ||
            intentKind == AdminInboxIntentKind.escalation;
      case AdminInboxFilterTag.urgent:
        return isUrgent;
    }
  }

  static List<ChatRoom> sortRooms(List<ChatRoom> rooms, AdminInboxSort sort) {
    final copy = List<ChatRoom>.from(rooms);
    switch (sort) {
      case AdminInboxSort.recentFirst:
        copy.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case AdminInboxSort.oldestWaitingFirst:
        copy.sort(
          (a, b) =>
              previewMessageAtForRoom(a).compareTo(previewMessageAtForRoom(b)),
        );
    }
    return copy;
  }

  static DateTime previewMessageAtForRoom(ChatRoom room) {
    for (final m in room.messages.reversed) {
      if (m.role == ChatMessageRole.user) return m.createdAt;
    }
    for (final m in room.messages.reversed) {
      if (m.role == ChatMessageRole.adminNotice ||
          m.role == ChatMessageRole.system) {
        return m.createdAt;
      }
    }
    return room.updatedAt;
  }

  /// ป้าย「ลูกค้าของโคเอเจนซี่」ในแชท/รายการ
  static Widget coAgencyCustomerChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.accentRoseLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.accentDeep.withOpacity(0.35)),
      ),
      child: Text(
        context.s.adminInboxRoleCoAgencyCustomer,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.accentDeep,
          height: 1.1,
        ),
      ),
    );
  }

  static String initials(String titleLine) {
    final base = titleLine.replaceAll(RegExp(r'\s*\([^)]+\)\s*$'), '').trim();
    if (base.isEmpty) return '?';
    if (base.startsWith('คุณ') && base.length > 3) {
      return base.substring(3, base.length > 4 ? 4 : base.length);
    }
    final parts = base.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return base.length >= 2
        ? base.substring(0, 2).toUpperCase()
        : base[0].toUpperCase();
  }

  static String _resolveDisplayName(ChatRoom room) {
    final admin = room.adminDisplayName?.trim();
    if (admin != null && admin.isNotEmpty) return admin;

    final fromTag = _nameFromProfileTag(room);
    if (fromTag != null) return fromTag;

    final fromSummary = _nameFromViewingSummary(room);
    if (fromSummary != null) return fromSummary;

    final pid = room.participantUserId?.trim();
    if (pid != null && pid.isNotEmpty) {
      for (final row in HubDemoData.demoUserDirectory) {
        if (row.$2 == pid) {
          final label = row.$1;
          final paren = label.indexOf('(');
          return paren > 0 ? label.substring(0, paren).trim() : label;
        }
      }
    }

    for (final m in room.messages.reversed) {
      if (m.role != ChatMessageRole.user) continue;
      final parsed = _parseNameField(m.text);
      if (parsed != null) return parsed;
    }

    return 'ลูกค้า';
  }

  static _Role _resolveRole(ChatRoom room, AppStrings s) {
    if (room.roomKind == 'agent_hub') {
      return _Role(AdminInboxRoleKind.agent, s.adminInboxRoleAgent, 'AGENT');
    }

    if (_isCoAgencyCustomerRoom(room)) {
      final label = s.adminInboxRoleCoAgencyCustomer;
      return _Role(AdminInboxRoleKind.coAgent, label, label);
    }

    final tag = _primaryProfileTag(room);
    if (tag != null) {
      switch (tag.role) {
        case ProfileTagRole.coAgentPresenter:
          return _Role(AdminInboxRoleKind.agent, s.adminInboxRoleAgent, 'AGENT');
        case ProfileTagRole.clientSubject:
          final label = s.adminInboxRoleCoAgencyCustomer;
          return _Role(AdminInboxRoleKind.coAgent, label, label);
        case ProfileTagRole.seekerSelf:
          return _Role(AdminInboxRoleKind.direct, s.adminInboxRoleDirect, 'DIRECT');
      }
    }

    if (room.participantUserId == HubDemoData.agentUserId) {
      return _Role(AdminInboxRoleKind.agent, s.adminInboxRoleAgent, 'AGENT');
    }

    return _Role(AdminInboxRoleKind.direct, s.adminInboxRoleDirect, 'DIRECT');
  }

  static bool _isCoAgencyCustomerRoom(ChatRoom room) {
    final vr = ViewingRequestService.instance.byThreadId(room.id);
    if (vr != null) {
      return vr.source == ViewingRequestSource.coAgent ||
          (vr.presenterTagCode != null && vr.presenterTagCode!.isNotEmpty);
    }
    final clientTag = _clientProfileTag(room);
    return clientTag?.role == ProfileTagRole.clientSubject;
  }

  static _Intent _resolveIntent(ChatRoom room, AppStrings s) {
    if (room.category == 'booking_interest') {
      return _Intent(AdminInboxIntentKind.booking, s.adminInboxIntentBooking);
    }
    if (room.viewingSubmitted || room.category == 'viewing_request') {
      return _Intent(AdminInboxIntentKind.viewing, s.adminInboxIntentViewing);
    }
    if (room.isDiscovery) {
      return _Intent(AdminInboxIntentKind.discovery, s.adminInboxIntentDiscovery);
    }
    if (room.isStaffSupport) {
      return _Intent(AdminInboxIntentKind.general, s.adminInboxIntentGeneral);
    }
    if (room.isDemandOffer) {
      return _Intent(AdminInboxIntentKind.offer, s.adminInboxIntentOffer);
    }
    if (room.isCustomerRequirement) {
      return _Intent(
        AdminInboxIntentKind.requirement,
        s.adminInboxIntentRequirement,
      );
    }
    if (room.category == 'escalation' || room.adminEscalated) {
      return _Intent(AdminInboxIntentKind.escalation, s.adminInboxIntentEscalation);
    }
    if (room.roomKind == 'agent_hub') {
      return _Intent(
        AdminInboxIntentKind.agentInterest,
        s.adminInboxIntentAgentInterest,
      );
    }
    if (room.isPropertyListing) {
      return _Intent(AdminInboxIntentKind.property, s.adminInboxIntentProperty);
    }
    return _Intent(AdminInboxIntentKind.general, s.adminInboxIntentGeneral);
  }

  static _PreviewMsg _resolvePreviewMessage(ChatRoom room, AppStrings s) {
    for (final m in room.messages.reversed) {
      if (m.role == ChatMessageRole.user) {
        return _PreviewMsg(_clip(_stripListingRefs(m.text)), m.createdAt);
      }
    }

    if (room.viewingSubmitted) {
      return _PreviewMsg(s.adminInboxPreviewViewingSubmitted, room.updatedAt);
    }

    for (final m in room.messages.reversed) {
      if (m.role == ChatMessageRole.adminNotice) {
        return _PreviewMsg(
          _clip(m.text.replaceFirst(RegExp(r'^ทีมงาน:\s*'), '')),
          m.createdAt,
        );
      }
      if (m.role == ChatMessageRole.system) {
        if (m.text.contains('นัดดู') ||
            m.links.any(
              (l) =>
                  l.kind == ChatMessageLinkKind.viewingRequest ||
                  l.kind == ChatMessageLinkKind.viewingForm,
            )) {
          return _PreviewMsg(s.adminInboxPreviewViewingSubmitted, m.createdAt);
        }
        final clipped = _clip(_stripListingRefs(m.text));
        if (clipped.isNotEmpty) {
          return _PreviewMsg(clipped, m.createdAt);
        }
      }
    }

    return _PreviewMsg(s.adminInboxNoPreview, room.updatedAt);
  }

  static String? _nameFromProfileTag(ChatRoom room) {
    final tag = _clientProfileTag(room) ?? _primaryProfileTag(room);
    if (tag == null) return null;

    if (tag.subjectDisplayName != null &&
        tag.subjectDisplayName!.trim().isNotEmpty) {
      return tag.subjectDisplayName!.trim();
    }

    for (final key in ['displayName', 'name', 'ชื่อ', 'nickname']) {
      final v = tag.snapshot[key]?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  static String? _nameFromViewingSummary(ChatRoom room) {
    for (final m in room.messages.reversed) {
      final name = _parseNameField(m.text);
      if (name != null) return name;
    }
    return null;
  }

  static String? _parseNameField(String text) {
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.startsWith('ชื่อ:') || t.startsWith('ชื่อ :')) {
        final v = t.split(':').skip(1).join(':').trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }

  static ProfileTag? _clientProfileTag(ChatRoom room) {
    final svc = ProfileTagService.instance;
    ProfileTag? seeker;
    for (final m in room.messages.reversed) {
      for (final link in m.links) {
        if (link.kind != ChatMessageLinkKind.profileTag) continue;
        final code = link.refCode.isNotEmpty ? link.refCode : link.label;
        final tag = svc.tagByCode(code);
        if (tag == null) continue;
        if (tag.role == ProfileTagRole.clientSubject) return tag;
        if (tag.role == ProfileTagRole.seekerSelf) seeker ??= tag;
      }
    }
    return seeker;
  }

  static ProfileTag? _primaryProfileTag(ChatRoom room) {
    final client = _clientProfileTag(room);
    if (client != null) return client;

    final svc = ProfileTagService.instance;
    for (final m in room.messages.reversed) {
      for (final link in m.links) {
        if (link.kind == ChatMessageLinkKind.profileTag) {
          final code = link.refCode.isNotEmpty ? link.refCode : link.label;
          final tag = svc.tagByCode(code);
          if (tag != null) return tag;
        }
      }
    }
    final pid = room.participantUserId;
    if (pid != null) {
      return svc.latestTag(userId: pid, role: ProfileTagRole.clientSubject) ??
          svc.latestTag(userId: pid, role: ProfileTagRole.seekerSelf) ??
          svc.latestTag(userId: pid, role: ProfileTagRole.coAgentPresenter);
    }
    return null;
  }

  static String _stripListingRefs(String text) {
    var t = text.trim();
    t = t.replaceAll(RegExp(r'RENT-[A-Z]{2}-\d{4}-\d{6}'), '');
    t = t.replaceAll(RegExp(r'VR-\d{4}-\d{6}'), '');
    t = t.replaceAll(RegExp(r'SP-\d{4}-\d{6}'), '');
    t = t.replaceAll(RegExp(r'CL-\d{4}-\d{6}'), '');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  static String _clip(String text, {int max = 80}) {
    final t = text.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max - 1)}…';
  }
}

class _Role {
  const _Role(this.kind, this.label, this.suffix);
  final AdminInboxRoleKind kind;
  final String label;
  final String suffix;
}

class _Intent {
  const _Intent(this.kind, this.label);
  final AdminInboxIntentKind kind;
  final String label;
}

class _PreviewMsg {
  const _PreviewMsg(this.text, this.at);
  final String text;
  final DateTime at;
}

/// ป้ายกรองสำหรับแท็บรอรับงาน
class AdminInboxFilterOption {
  const AdminInboxFilterOption(this.tag, this.label);
  final AdminInboxFilterTag tag;
  final String label;
}

List<AdminInboxFilterOption> adminInboxFilterOptions(AppStrings s) => [
      AdminInboxFilterOption(AdminInboxFilterTag.all, s.adminInboxFilterAll),
      AdminInboxFilterOption(AdminInboxFilterTag.agent, s.adminInboxFilterAgent),
      AdminInboxFilterOption(AdminInboxFilterTag.direct, s.adminInboxFilterDirect),
      AdminInboxFilterOption(AdminInboxFilterTag.coAgent, s.adminInboxFilterCoAgent),
      AdminInboxFilterOption(AdminInboxFilterTag.viewing, s.adminInboxFilterViewing),
      AdminInboxFilterOption(AdminInboxFilterTag.property, s.adminInboxFilterProperty),
      AdminInboxFilterOption(AdminInboxFilterTag.general, s.adminInboxFilterGeneral),
      AdminInboxFilterOption(AdminInboxFilterTag.urgent, s.adminInboxFilterUrgent),
    ];
