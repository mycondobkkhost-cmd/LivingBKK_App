import '../config/env.dart';
import '../models/demo_cast_persona.dart';
import '../models/profile_tag.dart';
import '../models/viewing_request.dart';
import '../services/profile_tag_service.dart';
import '../services/viewing_request_service.dart';
import 'demo_calendar_scenarios.dart';
import 'demo_cast_catalog.dart';
import 'demo_cast_listing_pins.dart';
import 'demo_cast_simulation.dart';

/// ฟอร์มนัดดู + แท็กโปรไฟล์ demo — ผูกกับ lead/แชทปฏิทินทดลอง
abstract final class DemoViewingRecordSeed {
  static bool _done = false;

  static void ensure() {
    if (!Env.adminDemoCases || _done) return;
    _done = true;

    final tagSvc = ProfileTagService.instance;
    final vrSvc = ViewingRequestService.instance;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final brokers = DemoCastCatalog.byKind(DemoCastKind.broker);
    final seekers = DemoCastCatalog.byKind(DemoCastKind.seeker);

    for (final scenario in DemoCalendarScenarios.all) {
      final threadId = scenario.threadId;
      if (vrSvc.byThreadId(threadId) != null) continue;

      final n = scenario.leadNum;
      final listingCode = scenario.listingCode;
      final nick = scenario.seekerNickname;
      final phone = scenario.seekerPhone;
      final lead = DemoCastSimulation.leads().firstWhere(
        (l) => l['id'] == scenario.leadId,
      );
      final castId = lead['seeker_cast_id']?.toString();
      final seekerPersona = DemoCastCatalog.find(castId ?? '') ??
          seekers[(n - 1) % seekers.length];
      final userId = seekerPersona.profileId;

      final clientTag = _ensureClientTag(
        tagSvc: tagSvc,
        n: n,
        nick: nick,
        phone: phone,
        userId: userId,
        isCoAgency: scenario.isCoAgent,
      );

      ProfileTag? presenterTag;
      String createdBy = userId;
      if (scenario.isCoAgent && brokers.isNotEmpty) {
        final broker = brokers[(n - 1) % brokers.length];
        presenterTag = _ensureBrokerPresenterTag(tagSvc, broker, n);
        createdBy = broker.profileId;
      }

      final scheduled = today.add(Duration(days: scenario.dayOffset));
      final vrCode = 'VR-2026-${(100900 + n).toString().padLeft(6, '0')}';
      if (vrSvc.byCode(vrCode) != null) continue;

      final status = scenario.viewingAccepted
          ? ViewingRequestStatus.ownerConfirmed
          : ViewingRequestStatus.submitted;
      final title =
          DemoCastListingPins.titles[listingCode] ?? scenario.projectName;

      vrSvc.registerDemoRequest(
        ViewingRequest(
          id: 'vr-demo-lead-$n',
          code: vrCode,
          listingId: DemoCastListingPins.idForCode(listingCode),
          listingCode: listingCode,
          listingTitle: title,
          projectName: scenario.projectName,
          scheduledAt: scheduled,
          clientTagId: clientTag.id,
          clientTagCode: clientTag.code,
          presenterTagId: presenterTag?.id,
          presenterTagCode: presenterTag?.code,
          source: scenario.isCoAgent
              ? ViewingRequestSource.coAgent
              : ViewingRequestSource.customer,
          status: status,
          createdAt: now.subtract(Duration(hours: n + 2)),
          createdByUserId: createdBy,
          threadId: threadId,
          appointmentId:
              scenario.viewingAccepted ? scenario.appointmentId : null,
        ),
      );
    }
  }

  static ProfileTag _ensureClientTag({
    required ProfileTagService tagSvc,
    required int n,
    required String nick,
    required String phone,
    required String userId,
    required bool isCoAgency,
  }) {
    final role =
        isCoAgency ? ProfileTagRole.clientSubject : ProfileTagRole.seekerSelf;
    final existingTag = tagSvc.latestTag(userId: userId, role: role);
    if (existingTag != null) return existingTag;

    final prefix = isCoAgency ? 'CL' : 'SP';
    final tagCode =
        '$prefix-2026-${(100900 + n).toString().padLeft(6, '0')}';
    final hit = tagSvc.tagByCode(tagCode);
    if (hit != null) return hit;

    final clientTag = ProfileTag(
      id: 'tag-demo-lead-$n',
      code: tagCode,
      role: role,
      version: 1,
      label: tagCode,
      snapshot: {
        'nickname': nick,
        'phone': phone,
        'occupants': '2',
        'contract': '12m',
        if (isCoAgency) 'customerType': 'co_agency',
      },
      ownerUserId: userId,
      createdAt: DateTime.now().subtract(Duration(hours: n + 2)),
      subjectDisplayName: nick,
    );
    tagSvc.registerDemoTag(clientTag);
    return clientTag;
  }

  static ProfileTag _ensureBrokerPresenterTag(
    ProfileTagService tagSvc,
    DemoCastPersona broker,
    int n,
  ) {
    final tagCode = 'PR-2026-${(200900 + n).toString().padLeft(6, '0')}';
    final hit = tagSvc.tagByCode(tagCode);
    if (hit != null) return hit;

    final tag = ProfileTag(
      id: 'tag-demo-broker-pr-$n',
      code: tagCode,
      role: ProfileTagRole.coAgentPresenter,
      version: 1,
      label: tagCode,
      snapshot: {
        'displayName': broker.displayNameTh,
        'agencyName': 'RealXtate Partner',
        'phone': broker.phone ?? '',
        'role': 'โคนายหน้า',
      },
      ownerUserId: broker.profileId,
      createdAt: DateTime.now().subtract(Duration(hours: n + 1)),
      subjectDisplayName: broker.displayNameTh,
    );
    tagSvc.registerDemoTag(tag);
    return tag;
  }

  static void reset() => _done = false;
}
