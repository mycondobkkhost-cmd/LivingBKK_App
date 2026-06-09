import 'package:flutter/material.dart';

import '../../data/demo_calendar_scenarios.dart';
import '../../data/demo_cast_listing_pins.dart';
import '../../data/demo_viewing_record_seed.dart';
import '../../l10n/app_strings.dart';
import '../../models/appointment.dart';
import '../../models/viewing_request.dart';
import '../../services/admin_comp_card_service.dart';
import '../../services/profile_tag_service.dart';
import '../../services/viewing_request_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/admin_listing_nav.dart';
import '../../utils/appointment_staff_labels.dart';
import '../../utils/appointment_time_format.dart';
import '../../widgets/reference_code_chip.dart';
import '../contact/chat_link_detail_sheets.dart';
import 'admin_calendar_appointment_actions.dart';
import 'admin_comp_card_widgets.dart';
import 'admin_viewing_follow_up_actions.dart';

/// ข้อมูลสรุปนัด — ใช้แสดงในรายการภาพรวมรายวัน
class AdminCalendarAppointmentMeta {
  const AdminCalendarAppointmentMeta({
    required this.timeLabel,
    required this.guideName,
    this.guideTagCode,
    required this.channelLabel,
    required this.channelDisplayName,
    this.channelTagCode,
    required this.projectName,
    this.listingCode,
    this.viewingProfileLabel,
    this.viewingProfileName,
    this.viewingProfileTagCode,
    this.adminName,
    this.adminTagCode,
    required this.isCoAgent,
    required this.noShow,
  });

  final String timeLabel;
  final String guideName;
  final String? guideTagCode;
  final String channelLabel;
  final String channelDisplayName;
  final String? channelTagCode;
  final String projectName;
  final String? listingCode;
  final String? viewingProfileLabel;
  final String? viewingProfileName;
  final String? viewingProfileTagCode;
  final String? adminName;
  final String? adminTagCode;
  final bool isCoAgent;
  final bool noShow;
}

AdminCalendarAppointmentMeta resolveAdminCalendarAppointmentMeta(
  Appointment appointment,
  AppStrings s,
) {
  DemoViewingRecordSeed.ensure();
  final scenario = DemoCalendarScenarios.byLeadId(appointment.leadId);
  final threadId = appointment.leadId != null && appointment.leadId!.isNotEmpty
      ? 'demo-lead-chat-${appointment.leadId}'
      : null;
  final vr = threadId != null
      ? ViewingRequestService.instance.byThreadId(threadId)
      : null;

  final isCoAgent =
      scenario?.isCoAgent ?? vr?.source == ViewingRequestSource.coAgent;

  final guideAssigned =
      appointment.assignedTo != null && appointment.assignedTo!.trim().isNotEmpty;
  final guideName = guideAssigned
      ? AppointmentStaffLabels.label(appointment.assignedTo, isEn: s.isEnglish)
      : s.adminCalendarGuideUnset;
  final guideCard =
      AdminCompCardService.instance.byProfileId(appointment.assignedTo);

  final adminInfo = AdminChatAdminInfo.resolve(appointment);

  final projectName = scenario?.projectName ??
      vr?.projectName ??
      _projectFromLabel(appointment.locationLabel) ??
      (appointment.listingCode != null
          ? (DemoCastListingPins.titles[appointment.listingCode!]
                  ?.split(' · ')
                  .first ??
              appointment.listingCode)
          : '—');

  String channelLabel;
  String channelDisplayName;
  String? channelTagCode;
  String? viewingProfileLabel;
  String? viewingProfileName;
  String? viewingProfileTagCode;

  if (isCoAgent) {
    channelLabel = s.adminCalendarRowCoAgencyChannel;
    channelTagCode = vr?.presenterTagCode;
    final presenterTag = channelTagCode != null
        ? ProfileTagService.instance.tagByCode(channelTagCode)
        : null;
    channelDisplayName = presenterTag?.subjectDisplayName ??
        appointment.seekerNickname;
    viewingProfileLabel = s.adminCalendarRowCoAgencyClient;
  } else {
    channelLabel = s.adminCalendarRowDirectChannel;
    channelDisplayName = appointment.seekerNickname;
    viewingProfileLabel = s.adminCalendarRowViewingProfile;
  }

  final clientTagCode = vr?.clientTagCode;
  if (clientTagCode != null && clientTagCode.isNotEmpty) {
    viewingProfileTagCode = clientTagCode;
    viewingProfileName = ProfileTagService.instance
            .tagByCode(clientTagCode)
            ?.subjectDisplayName ??
        appointment.seekerNickname;
  }

  return AdminCalendarAppointmentMeta(
    timeLabel: appointment.displayTimeSlot,
    guideName: guideName,
    guideTagCode: guideCard?.tagCode,
    channelLabel: channelLabel,
    channelDisplayName: channelDisplayName,
    channelTagCode: channelTagCode,
    projectName: projectName?.toString() ?? '—',
    listingCode: appointment.listingCode,
    viewingProfileLabel: viewingProfileLabel,
    viewingProfileName: viewingProfileName,
    viewingProfileTagCode: viewingProfileTagCode,
    adminName: adminInfo.hasAdmin ? adminInfo.adminName : null,
    adminTagCode: adminInfo.compCard?.tagCode,
    isCoAgent: isCoAgent,
    noShow: appointmentIsNoShow(appointment),
  );
}

String? _projectFromLabel(String? label) {
  if (label == null || label.trim().isEmpty) return null;
  final parts = label.split('—');
  return parts.first.trim();
}

/// การ์ดรายการนัดในภาพรวมรายวัน — คอม + มือถือ
class AdminCalendarDayAppointmentCard extends StatelessWidget {
  const AdminCalendarDayAppointmentCard({
    super.key,
    required this.appointment,
    required this.s,
    required this.statusColor,
    required this.onTapDetail,
    this.onOpenCustomerChat,
    this.onOpenAdminOwnerChat,
    this.onConfirmGuide,
    this.confirmGuideBusy = false,
  });

  final Appointment appointment;
  final AppStrings s;
  final Color statusColor;
  final VoidCallback onTapDetail;
  final VoidCallback? onOpenCustomerChat;
  final VoidCallback? onOpenAdminOwnerChat;
  final VoidCallback? onConfirmGuide;
  final bool confirmGuideBusy;

  @override
  Widget build(BuildContext context) {
    final meta = resolveAdminCalendarAppointmentMeta(appointment, s);
    final accent = meta.noShow ? Colors.red.shade700 : statusColor;
    final isDemo = appointment.id.startsWith('demo-appt');
    final needsGuideConfirm = appointmentNeedsGuideConfirm(appointment);
    final hasLead = appointment.leadId != null && appointment.leadId!.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: meta.noShow
            ? Colors.red.shade50.withOpacity(0.85)
            : AdminTheme.surfaceMuted.withOpacity(0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.border.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTapDetail,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        meta.timeLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: accent,
                        ),
                      ),
                      if (meta.noShow) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s.adminCalendarNoShowBadge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          size: 20, color: AdminTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _MetaLine(
              label: s.adminCalendarRowGuide,
              value: meta.guideName,
              tagCode: meta.guideTagCode,
              onTagNavigate: meta.guideTagCode != null
                  ? () => showProfileTagDetailSheet(
                        context,
                        meta.guideTagCode!,
                        adminView: true,
                      )
                  : null,
            ),
            _MetaLine(
              label: meta.channelLabel,
              value: meta.channelDisplayName,
              tagCode: meta.channelTagCode,
              onTagNavigate: meta.channelTagCode != null
                  ? () => showProfileTagDetailSheet(
                        context,
                        meta.channelTagCode!,
                        adminView: true,
                      )
                  : null,
            ),
            _MetaLine(
              label: s.adminCalendarRowProject,
              value: meta.projectName,
              tagCode: meta.listingCode,
              onTagNavigate: meta.listingCode != null
                  ? () => openAdminListing(
                        context,
                        listingId: appointment.listingId,
                        listingCode: meta.listingCode,
                      )
                  : null,
            ),
            if (meta.viewingProfileTagCode != null)
              _MetaLine(
                label: meta.viewingProfileLabel ??
                    s.adminCalendarRowViewingProfile,
                value: meta.viewingProfileName ?? meta.viewingProfileTagCode!,
                tagCode: meta.viewingProfileTagCode,
                onTagNavigate: () => showProfileTagDetailSheet(
                  context,
                  meta.viewingProfileTagCode!,
                  adminView: true,
                ),
              ),
            _MetaLine(
              label: s.adminCalendarRowContactAdmin,
              value: meta.adminName ?? s.adminCalendarContactAdminUnset,
              tagCode: meta.adminTagCode,
              onTagNavigate: meta.adminTagCode != null
                  ? () => showProfileTagDetailSheet(
                        context,
                        meta.adminTagCode!,
                        adminView: true,
                      )
                  : null,
              muted: meta.adminName == null,
            ),
            if (isDemo) ...[
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.amber.shade700.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    s.demoSampleLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (hasLead && onOpenCustomerChat != null)
                  OutlinedButton.icon(
                    onPressed: onOpenCustomerChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 15),
                    label: Text(s.adminCalendarBtnViewChat),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                if (needsGuideConfirm && onConfirmGuide != null)
                  FilledButton.tonal(
                    onPressed: confirmGuideBusy ? null : onConfirmGuide,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: confirmGuideBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(guideConfirmLabel(s, appointment)),
                  ),
                if (onOpenAdminOwnerChat != null)
                  OutlinedButton.icon(
                    onPressed: onOpenAdminOwnerChat,
                    icon: const Icon(Icons.support_agent_outlined, size: 15),
                    label: Text(s.adminCalendarBtnAdminOwnerChat),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
    this.tagCode,
    this.onTagNavigate,
    this.muted = false,
  });

  final String label;
  final String value;
  final String? tagCode;
  final VoidCallback? onTagNavigate;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: AdminTheme.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: LivingBkkBrand.purplePrimary.withOpacity(0.85),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: muted ? AdminTheme.textMuted : AdminTheme.text,
                  ),
                ),
                if (tagCode != null && tagCode!.isNotEmpty)
                  ReferenceCodeChip(
                    code: tagCode!,
                    label: '',
                    compact: true,
                    onNavigate: onTagNavigate,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
