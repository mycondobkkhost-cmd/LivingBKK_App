import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../data/demo_listings_factory.dart';
import '../data/hub_demo_data.dart';
import '../features/work/owner_viewing_response_sheet.dart';
import '../l10n/app_strings.dart';
import '../models/viewing_request.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import 'listing_owner_repository.dart';
import 'supabase_service.dart';
import 'viewing_ops_repository.dart';
import 'viewing_request_repository.dart';

class OwnerListingRef {
  const OwnerListingRef({
    required this.id,
    required this.listingCode,
    required this.title,
    this.projectName,
  });

  final String id;
  final String listingCode;
  final String title;
  final String? projectName;
}

/// Owner Hub — คำขอนัดดูต่อทรัพย์ + ยืนยัน/ปฏิเสธ (Phase 25)
class OwnerHubRepository extends ChangeNotifier {
  OwnerHubRepository._();
  static final OwnerHubRepository instance = OwnerHubRepository._();

  final _ownerListings = ListingOwnerRepository();

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  Future<List<OwnerListingRef>> fetchOwnerListings() async {
    final uid = AuthService.instance.effectiveUserId;
    if (uid == null || uid.isEmpty) return [];

    if (!_live && uid == HubDemoData.ownerUserId) {
      return DemoListingsFactory.cached.take(5).map((l) {
        return OwnerListingRef(
          id: l.id,
          listingCode: l.listingCode,
          title: l.title,
          projectName: l.projectName,
        );
      }).toList();
    }

    final rows = await _ownerListings.myListings(includeArchived: false);
    return rows.map((row) {
      return OwnerListingRef(
        id: row['id']?.toString() ?? '',
        listingCode: row['listing_code']?.toString() ?? '',
        title: row['title']?.toString() ?? '',
        projectName: row['project_name']?.toString(),
      );
    }).where((l) => l.id.isNotEmpty).toList();
  }

  Future<List<ViewingRequest>> fetchPendingViewings() async {
    await ViewingRequestRepository.instance.fetchAllForAdmin();
    final listings = await fetchOwnerListingIds();
    return ViewingRequestRepository.instance.pendingForOwnerListings(listings);
  }

  Future<Set<String>> fetchOwnerListingIds() async {
    final listings = await fetchOwnerListings();
    return listings.map((l) => l.id).toSet();
  }

  /// แอดมินส่งคำขอไป Owner Hub
  Future<void> dispatchToOwner({
    required ViewingRequest viewingRequest,
    required AppStrings s,
    String? blindSummary,
  }) async {
    await ViewingRequestRepository.instance.updateStatus(
      id: viewingRequest.id,
      status: ViewingRequestStatus.sentToOwner,
    );

    final schedule =
        DateFormat('d/M/yyyy HH:mm').format(viewingRequest.scheduledAt);
    final summary = blindSummary ??
        s.ownerHubViewingNotice(
          listingCode: viewingRequest.listingCode,
          schedule: schedule,
          clientTag: viewingRequest.clientTagCode,
          viewingCode: viewingRequest.code,
        );

    final ownerId = await ViewingOpsRepository().resolveOwnerId(
      listingId: viewingRequest.listingId,
      listingCode: viewingRequest.listingCode,
    );

    ChatService.instance.ensureOwnerHubForListing(
      listingId: viewingRequest.listingId,
      listingCode: viewingRequest.listingCode,
      listingTitle: viewingRequest.listingTitle,
      projectName: viewingRequest.projectName,
      ownerUserId: ownerId,
    );

    ChatService.instance.postOwnerViewingRequestNotice(
      viewingRequest: viewingRequest.copyWith(
        status: ViewingRequestStatus.sentToOwner,
      ),
      blindSummary: summary,
    );
    notifyListeners();
  }

  Future<ViewingRequest?> confirmViewing({
    required ViewingRequest viewingRequest,
    required OwnerViewingResponse response,
    required AppStrings s,
  }) async {
    var scheduledAt = viewingRequest.scheduledAt;
    if (response.mode == OwnerViewingResponseMode.proposeAlternative &&
        response.proposedDate != null) {
      final parts = (response.timeStart ?? '10:00').split(':');
      scheduledAt = DateTime(
        response.proposedDate!.year,
        response.proposedDate!.month,
        response.proposedDate!.day,
        int.tryParse(parts.first) ?? 10,
        int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
    }

    await ViewingRequestRepository.instance.updateStatus(
      id: viewingRequest.id,
      status: ViewingRequestStatus.ownerConfirmed,
      scheduledAt: scheduledAt,
    );

    final updated = viewingRequest.copyWith(
      status: ViewingRequestStatus.ownerConfirmed,
      scheduledAt: scheduledAt,
    );

    ChatService.instance.postOwnerViewingDecisionNotice(
      viewingRequest: updated,
      confirmed: true,
      decisionText: s.ownerHubDecisionConfirmed(
        code: viewingRequest.code,
        schedule: response.displaySchedule(s),
      ),
    );

    await _notifyParticipant(
      updated,
      s.ownerHubParticipantConfirmed(
        updated.code,
        response.displaySchedule(s),
      ),
      agent: updated.source == ViewingRequestSource.coAgent,
    );
    notifyListeners();
    return updated;
  }

  Future<ViewingRequest?> declineViewing({
    required ViewingRequest viewingRequest,
    required AppStrings s,
    String? note,
  }) async {
    await ViewingRequestRepository.instance.updateStatus(
      id: viewingRequest.id,
      status: ViewingRequestStatus.ownerDeclined,
    );

    final updated = viewingRequest.copyWith(
      status: ViewingRequestStatus.ownerDeclined,
    );

    ChatService.instance.postOwnerViewingDecisionNotice(
      viewingRequest: updated,
      confirmed: false,
      decisionText: s.ownerHubDecisionDeclined(
        code: viewingRequest.code,
        note: note,
      ),
    );

    await _notifyParticipant(
      updated,
      s.ownerHubParticipantDeclined(updated.code),
      agent: updated.source == ViewingRequestSource.coAgent,
    );
    notifyListeners();
    return updated;
  }

  Future<void> _notifyParticipant(
    ViewingRequest req,
    String text, {
    required bool agent,
  }) async {
    final uid = req.createdByUserId;
    if (uid.isEmpty) return;
    await ChatService.instance.postAdminMessageToHub(uid, text, agent: agent);
  }
}
