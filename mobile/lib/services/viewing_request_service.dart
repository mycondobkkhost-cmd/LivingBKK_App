import 'package:flutter/foundation.dart';

import '../models/profile_tag.dart';
import '../models/viewing_request.dart';
import 'auth_service.dart';

class ViewingRequestService extends ChangeNotifier {
  ViewingRequestService._();
  static final instance = ViewingRequestService._();

  final _requests = <String, ViewingRequest>{};
  int _seq = 100;

  int get count => _requests.length;

  String? get _userId => AuthService.instance.effectiveUserId ?? 'demo-user';

  ViewingRequest create({
    required String listingId,
    required String listingCode,
    required String listingTitle,
    String? projectName,
    required DateTime scheduledAt,
    required ProfileTag clientTag,
    ProfileTag? presenterTag,
    required ViewingRequestSource source,
    String? threadId,
    String? createdByUserId,
  }) {
    final code = 'VR-2026-${_seq.toString().padLeft(6, '0')}';
    _seq++;
    final req = ViewingRequest(
      id: 'vr-${DateTime.now().microsecondsSinceEpoch}',
      code: code,
      listingId: listingId,
      listingCode: listingCode,
      listingTitle: listingTitle,
      projectName: projectName,
      scheduledAt: scheduledAt,
      clientTagId: clientTag.id,
      clientTagCode: clientTag.code,
      presenterTagId: presenterTag?.id,
      presenterTagCode: presenterTag?.code,
      source: source,
      status: ViewingRequestStatus.submitted,
      createdAt: DateTime.now(),
      createdByUserId: createdByUserId ?? _userId!,
      threadId: threadId,
    );
    _requests[req.id] = req;
    notifyListeners();
    return req;
  }

  List<ViewingRequest> forUser(String userId) {
    return _requests.values
        .where((r) => r.createdByUserId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<ViewingRequest> forListing(String listingId) {
    return _requests.values
        .where((r) => r.listingId == listingId)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }

  List<ViewingRequest> all() {
    return _requests.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  ViewingRequest? byId(String id) => _requests[id];

  ViewingRequest? byCode(String code) {
    for (final r in _requests.values) {
      if (r.code == code) return r;
    }
    return null;
  }

  ViewingRequest? byThreadId(String threadId) {
    if (threadId.isEmpty) return null;
    final matches = _requests.values
        .where((r) => r.threadId == threadId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.isEmpty ? null : matches.first;
  }

  ViewingRequest? byAppointmentId(String appointmentId) {
    if (appointmentId.isEmpty) return null;
    for (final r in _requests.values) {
      if (r.appointmentId == appointmentId) return r;
    }
    return null;
  }

  void linkAppointment({
    required String viewingRequestCode,
    required String appointmentId,
    ViewingRequestStatus? status,
  }) {
    final req = byCode(viewingRequestCode);
    if (req == null) return;
    _requests[req.id] = req.copyWith(
      appointmentId: appointmentId,
      status: status,
    );
    notifyListeners();
  }

  void registerDemoRequest(ViewingRequest request) {
    _requests[request.id] = request;
    final parts = request.code.split('-');
    final n = int.tryParse(parts.last) ?? 0;
    if (n >= _seq) _seq = n + 1;
  }

  /// ล้างคำขอนัด in-memory — ใช้ตอนรีเซ็ตเคสทดลอง
  void resetDemo() {
    _requests.clear();
    _seq = 100;
    notifyListeners();
  }
}
