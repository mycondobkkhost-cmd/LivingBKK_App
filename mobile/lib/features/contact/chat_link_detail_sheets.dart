import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/hub_demo_seed.dart';
import '../../features/admin/admin_inbox_preview.dart';
import '../../l10n/app_strings.dart';
import '../../models/appointment.dart';
import '../../models/viewing_appointment_record.dart';
import '../../models/chat_message.dart';
import '../../models/profile_tag.dart';
import '../../models/viewing_request.dart';
import '../../services/appointment_repository.dart';
import '../../services/profile_tag_service.dart';
import '../../services/viewing_appointment_record_service.dart';
import '../../services/viewing_request_service.dart';
import '../../utils/admin_reference_nav.dart';
import '../../utils/appointment_staff_labels.dart';
import '../../utils/appointment_time_format.dart' show formatAppointmentDisplayTime;
import '../../utils/reference_codes.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';

/// เปิดรายละเอียดจากลิงก์ในแชท (แท็ก / คำขอนัดดู / ฟอร์ม / ทรัพย์)
Future<void> openChatMessageLink(
  BuildContext context,
  ChatMessageLink link, {
  bool adminView = false,
  Future<void> Function(ChatMessageLink)? onFormLink,
  Future<void> Function(ChatMessageLink)? onListingLink,
}) async {
  switch (link.kind) {
    case ChatMessageLinkKind.profileTag:
      await showProfileTagDetailSheet(
        context,
        link.refCode.isNotEmpty ? link.refCode : link.label,
        adminView: adminView,
      );
    case ChatMessageLinkKind.viewingRequest:
      await showViewingRequestDetailSheet(
        context,
        link.refCode.isNotEmpty ? link.refCode : link.label,
        adminView: adminView,
      );
    case ChatMessageLinkKind.requirementForm:
    case ChatMessageLinkKind.viewingForm:
      if (onFormLink != null) await onFormLink(link);
    case ChatMessageLinkKind.viewingLocation:
      await _openViewingLocation(context, link);
    case ChatMessageLinkKind.viewingAppointment:
      await showViewingAppointmentDetailSheet(
        context,
        link.refCode.isNotEmpty ? link.refCode : link.label,
        adminView: adminView,
      );
    case ChatMessageLinkKind.listing:
    case ChatMessageLinkKind.projectUnits:
      if (onListingLink != null) await onListingLink(link);
  }
}

Future<void> _openViewingLocation(
  BuildContext context,
  ChatMessageLink link,
) async {
  final url = link.refCode.trim();
  if (url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.chatLinkViewingLocationOpenFailed)),
    );
  }
}

Future<void> showProfileTagDetailSheet(
  BuildContext context,
  String code, {
  bool adminView = true,
}) async {
  HubDemoSeed.ensure();
  final tag = ProfileTagService.instance.tagByCode(code);
  if (tag == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.chatLinkTagNotFound(code))),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ProfileTagDetailBody(tag: tag, adminView: adminView),
  );
}

Future<void> showViewingAppointmentDetailSheet(
  BuildContext context,
  String appointmentId, {
  bool adminView = true,
}) async {
  await ViewingAppointmentRecordService.instance.init();
  var record =
      ViewingAppointmentRecordService.instance.byAppointmentId(appointmentId);
  final appt = await AppointmentRepository().fetchById(appointmentId);
  if (record == null && appt != null) {
    record = await ViewingAppointmentRecordService.instance.buildFromAppointment(
      appointment: appt,
      s: context.s,
    );
  }
  if (record == null && appt == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.s.chatLinkViewingAppointmentNotFound(appointmentId)),
      ),
    );
    return;
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ViewingAppointmentDetailBody(
      record: record,
      appointment: appt,
      adminView: adminView,
    ),
  );
}

Future<void> showViewingRequestDetailSheet(
  BuildContext context,
  String code, {
  bool adminView = true,
}) async {
  HubDemoSeed.ensure();
  final req = ViewingRequestService.instance.byCode(code);
  if (req == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.chatLinkViewingNotFound(code))),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ViewingRequestDetailBody(req: req, adminView: adminView),
  );
}

class _ProfileTagDetailBody extends StatelessWidget {
  const _ProfileTagDetailBody({required this.tag, required this.adminView});

  final ProfileTag tag;
  final bool adminView;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final snap = adminView ? tag.snapshot : tag.publicSnapshot;
    final dateFmt = DateFormat('d MMM yyyy HH:mm');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.chatLinkTagDetailTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (adminView && tag.role == ProfileTagRole.clientSubject) ...[
            AdminInboxPreview.coAgencyCustomerChip(context),
            const SizedBox(height: 10),
          ],
          _codeRow(
            context,
            tag.code,
            adminView: adminView,
            onNavigate: adminView
                ? () {
                    Navigator.pop(context);
                    context.push('/admin?nav=participant360');
                  }
                : null,
          ),
          const SizedBox(height: 8),
          _infoRow(
            context,
            s.chatLinkTagRole,
            _roleLabel(s, tag.role, adminView: adminView),
          ),
          if (tag.subjectDisplayName != null)
            _infoRow(context, s.chatLinkTagSubject, tag.subjectDisplayName!),
          _infoRow(context, s.chatLinkTagVersion, 'v${tag.version}'),
          _infoRow(context, s.chatLinkTagCreated, dateFmt.format(tag.createdAt)),
          const SizedBox(height: 12),
          Text(s.chatLinkTagSnapshot, style: AdminTheme.section),
          const SizedBox(height: 8),
          ...snap.entries.map(
            (e) => _infoRow(
              context,
              _fieldLabel(s, e.key),
              e.value,
              adminView: adminView,
              fieldKey: e.key,
            ),
          ),
          if (adminView) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/admin?nav=participant360');
              },
              icon: const Icon(Icons.person_search_outlined, size: 18),
              label: Text(s.adminParticipantTitle),
            ),
          ],
        ],
      ),
    );
  }

  String _roleLabel(
    AppStrings s,
    ProfileTagRole role, {
    required bool adminView,
  }) =>
      switch (role) {
        ProfileTagRole.seekerSelf => s.profileTagFormSeeker,
        ProfileTagRole.coAgentPresenter => s.profileTagFormPresenter,
        ProfileTagRole.clientSubject => adminView
            ? s.profileTagRoleCoAgencyCustomer
            : s.profileTagFormClient,
      };

  String _fieldLabel(AppStrings s, String key) => switch (key) {
        'nickname' => s.chatLinkFieldNickname,
        'phone' => s.chatLinkFieldPhone,
        'occupants' => s.chatLinkFieldOccupants,
        'occupation' => s.chatLinkFieldOccupation,
        'contract' => s.chatLinkFieldContract,
        'budget' => s.chatLinkFieldBudget,
        'workplace' => s.chatLinkFieldWorkplace,
        'displayName' => s.chatLinkFieldDisplayName,
        'agencyName' => s.chatLinkFieldAgency,
        'licenseNo' => s.chatLinkFieldLicense,
        _ => key,
      };
}

class _ViewingAppointmentDetailBody extends StatelessWidget {
  const _ViewingAppointmentDetailBody({
    required this.record,
    required this.appointment,
    required this.adminView,
  });

  final ViewingAppointmentRecord? record;
  final Appointment? appointment;
  final bool adminView;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final r = record;
    final a = appointment;
    if (r == null && a == null) return const SizedBox.shrink();

    final d = r?.scheduledDate ?? a!.scheduledDate;
    final y = s.isEnglish ? d.year : d.year + 543;
    final dateLabel = '${d.day}/${d.month}/$y';
    final timeSlot = r?.timeSlot ?? a!.timeSlot;
    final displayTime = formatAppointmentDisplayTime(timeSlot);
    final place = (r?.locationLabel ?? a?.locationLabel)?.trim().isNotEmpty == true
        ? (r?.locationLabel ?? a!.locationLabel)!.trim()
        : (r?.listingCode ?? a?.listingCode ?? '—');
    final guide = r?.guideName ??
        (a?.assignedTo != null && a!.assignedTo!.trim().isNotEmpty
            ? AppointmentStaffLabels.label(a.assignedTo!, isEn: s.isEnglish)
            : '—');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.chatLinkViewingAppointmentDetailTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (r?.transactionRef != null && r!.transactionRef!.trim().isNotEmpty)
              _codeRow(
                context,
                r.transactionRef!.trim(),
                adminView: adminView,
              ),
            const SizedBox(height: 8),
            if (r?.viewingRequestCode != null)
              _infoRow(
                context,
                s.viewingRequestCodeLine,
                r!.viewingRequestCode!,
                adminView: adminView,
                fieldKey: 'viewingRequest',
              ),
            if (r?.clientTagCode != null)
              _infoRow(
                context,
                s.profileTagClientLine,
                r!.clientTagCode!,
                adminView: adminView,
                fieldKey: 'clientTag',
              ),
            if (r?.presenterTagCode != null)
              _infoRow(
                context,
                s.profileTagPresenterLine,
                r!.presenterTagCode!,
                adminView: adminView,
                fieldKey: 'presenterTag',
              ),
            if ((r?.listingCode ?? a?.listingCode) != null)
              _infoRow(
                context,
                s.chatLinkViewingListing,
                r?.listingCode ?? a!.listingCode!,
                adminView: adminView,
                fieldKey: 'listingCode',
              ),
            _infoRow(context, s.chatLinkViewingSchedule, '$dateLabel · $displayTime'),
            _infoRow(context, s.chatLinkViewingPlace, place),
            _infoRow(context, s.chatLinkViewingAppointmentGuide, guide),
            if (r?.guidePhone != null && r!.guidePhone!.trim().isNotEmpty)
              _infoRow(
                context,
                s.summaryPhone,
                r.guidePhone!,
                adminView: adminView,
                fieldKey: 'phone',
              ),
            _infoRow(
              context,
              s.chatLinkViewingStatus,
              _statusLabel(s, r?.status ?? a?.status ?? 'pending'),
            ),
            if ((r?.seekerNickname ?? a?.seekerNickname)?.trim().isNotEmpty == true)
              _infoRow(
                context,
                s.chatLinkFieldNickname,
                r?.seekerNickname ?? a!.seekerNickname,
              ),
            if (adminView &&
                r != null &&
                r.clientSnapshot.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(s.chatLinkTagSnapshot, style: AdminTheme.section),
              const SizedBox(height: 8),
              ...r.clientSnapshot.entries.map(
                (e) => _infoRow(
                  context,
                  _fieldLabel(s, e.key),
                  e.value,
                  adminView: adminView,
                  fieldKey: e.key,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fieldLabel(AppStrings s, String key) => switch (key) {
        'nickname' => s.chatLinkFieldNickname,
        'phone' => s.chatLinkFieldPhone,
        'occupants' => s.chatLinkFieldOccupants,
        'occupation' => s.chatLinkFieldOccupation,
        'contract' => s.chatLinkFieldContract,
        'budget' => s.chatLinkFieldBudget,
        'workplace' => s.chatLinkFieldWorkplace,
        'displayName' => s.chatLinkFieldDisplayName,
        _ => key,
      };

  String _statusLabel(AppStrings s, String status) => switch (status) {
        'confirmed' => s.isEnglish ? 'Confirmed' : 'ยืนยันแล้ว',
        'pending' => s.isEnglish ? 'Pending' : 'รอยืนยัน',
        'completed' => s.isEnglish ? 'Completed' : 'เสร็จสิ้น',
        'cancelled' => s.isEnglish ? 'Cancelled' : 'ยกเลิก',
        _ => status,
      };
}

class _ViewingRequestDetailBody extends StatelessWidget {
  const _ViewingRequestDetailBody({required this.req, required this.adminView});

  final ViewingRequest req;
  final bool adminView;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateFmt = DateFormat('EEEE d MMM yyyy HH:mm', 'th');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.chatLinkViewingDetailTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _codeRow(context, req.code, adminView: adminView),
          const SizedBox(height: 8),
          if (adminView && req.source == ViewingRequestSource.coAgent) ...[
            AdminInboxPreview.coAgencyCustomerChip(context),
            const SizedBox(height: 8),
          ],
          _infoRow(
            context,
            s.chatLinkViewingListing,
            '${req.listingCode} · ${req.listingTitle}',
            adminView: adminView,
            fieldKey: 'listingCode',
          ),
          if (req.projectName != null)
            _infoRow(context, s.chatLinkViewingProject, req.projectName!),
          _infoRow(context, s.chatLinkViewingSchedule, dateFmt.format(req.scheduledAt)),
          _infoRow(context, s.chatLinkViewingStatus, _statusLabel(req.status)),
          if (req.appointmentId != null && req.appointmentId!.isNotEmpty)
            _infoRow(
              context,
              s.chatLinkViewingAppointment,
              req.appointmentId!,
              adminView: adminView,
              fieldKey: 'appointmentId',
            ),
          const SizedBox(height: 8),
          _infoRow(
            context,
            s.profileTagClientLine,
            req.clientTagCode,
            adminView: adminView,
            fieldKey: 'clientTag',
          ),
          if (req.presenterTagCode != null)
            _infoRow(
              context,
              s.profileTagPresenterLine,
              req.presenterTagCode!,
              adminView: adminView,
              fieldKey: 'presenterTag',
            ),
        ],
      ),
    );
  }

  String _statusLabel(ViewingRequestStatus status) => switch (status) {
        ViewingRequestStatus.draft => 'ร่าง',
        ViewingRequestStatus.submitted => 'ส่งแล้ว',
        ViewingRequestStatus.sentToOwner => 'ส่งเจ้าของแล้ว',
        ViewingRequestStatus.ownerConfirmed => 'เจ้าของยืนยัน',
        ViewingRequestStatus.ownerDeclined => 'เจ้าของปฏิเสธ',
        ViewingRequestStatus.cancelled => 'ยกเลิก',
      };
}

Future<void> _copyCode(BuildContext context, String code) async {
  if (code.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: code));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.s.referenceCopied(code))),
  );
}

bool _isPhoneField(String? fieldKey) =>
    fieldKey == 'phone' || fieldKey == 'licenseNo';

bool _looksLikePhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 9 && digits.length <= 12;
}

bool _looksLikeAdminRefCode(String value) {
  final u = value.trim().toUpperCase();
  if (u.isEmpty) return false;
  return u.startsWith('SP-') ||
      u.startsWith('CL-') ||
      u.startsWith('PR-') ||
      u.startsWith('VR-') ||
      u.startsWith('LEAD-') ||
      u.startsWith('CHAT-') ||
      u.startsWith('APPT-') ||
      isNavigableListingCode(u);
}

Future<void> _openRefNavigate(
  BuildContext context, {
  required String code,
  required bool adminView,
  String? fieldKey,
}) async {
  if (!adminView) {
    await _copyCode(context, code);
    return;
  }
  Navigator.pop(context);
  final ref = code.split('·').first.trim();
  switch (fieldKey) {
    case 'clientTag':
    case 'presenterTag':
      await showProfileTagDetailSheet(context, ref, adminView: true);
    case 'appointmentId':
      await showViewingAppointmentDetailSheet(context, ref, adminView: true);
    case 'viewingRequest':
      await showViewingRequestDetailSheet(context, ref, adminView: true);
    case 'listingCode':
      await openAdminReferenceCode(context, code: ref);
    default:
      await openAdminReferenceCode(context, code: ref);
  }
}

Widget _codeRow(
  BuildContext context,
  String code, {
  bool adminView = false,
  VoidCallback? onNavigate,
}) {
  if (code.isEmpty) return const SizedBox.shrink();
  final s = context.s;
  final mono = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w700,
    fontSize: 15,
    color: AppTheme.primary,
  );
  final navigate = onNavigate ??
      (adminView
          ? () => openAdminReferenceCode(context, code: code)
          : null);

  return Material(
    color: AppTheme.primary.withOpacity(0.08),
    borderRadius: BorderRadius.circular(10),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: navigate != null
                  ? navigate
                  : () => _copyCode(context, code),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(code, style: mono)),
                    Icon(
                      navigate != null ? Icons.open_in_new : Icons.copy,
                      size: 16,
                      color: AppTheme.primary.withOpacity(0.75),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: s.t('คัดลอก', 'Copy'),
            visualDensity: VisualDensity.compact,
            onPressed: () => _copyCode(context, code),
          ),
        ],
      ),
    ),
  );
}

Widget _infoRow(
  BuildContext context,
  String label,
  String value, {
  bool adminView = false,
  String? fieldKey,
}) {
  final interactive = _isPhoneField(fieldKey) && _looksLikePhone(value) ||
      (fieldKey != null &&
          (fieldKey == 'clientTag' ||
              fieldKey == 'presenterTag' ||
              fieldKey == 'viewingRequest' ||
              fieldKey == 'appointmentId' ||
              fieldKey == 'listingCode')) ||
      _looksLikeAdminRefCode(value);

  final valueStyle = TextStyle(
    fontSize: 13,
    fontWeight: interactive ? FontWeight.w600 : FontWeight.w500,
    color: interactive ? AppTheme.primary : AppTheme.textPrimary,
    decoration: interactive ? TextDecoration.underline : null,
    fontFamily: _looksLikeAdminRefCode(value) ? 'monospace' : null,
  );

  Widget valueWidget = Text(value, style: valueStyle);

  if (interactive) {
    valueWidget = InkWell(
      onTap: () {
        if (_isPhoneField(fieldKey) && _looksLikePhone(value)) {
          _copyCode(context, value);
          return;
        }
        _openRefNavigate(context, code: value, adminView: adminView, fieldKey: fieldKey);
      },
      child: valueWidget,
    );
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: AdminTheme.caption),
        ),
        Expanded(child: valueWidget),
        if (_isPhoneField(fieldKey) && _looksLikePhone(value)) ...[
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: context.s.t('คัดลอก', 'Copy'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _copyCode(context, value),
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined, size: 16),
            tooltip: context.s.t('โทร', 'Call'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () async {
              final digits = value.replaceAll(RegExp(r'\D'), '');
              final uri = Uri.parse('tel:$digits');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ] else if (interactive) ...[
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: context.s.t('คัดลอก', 'Copy'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _copyCode(context, value),
          ),
        ],
      ],
    ),
  );
}
