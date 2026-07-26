import '../models/owner_inquiry.dart';
import '../utils/listing_ids.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class OwnerInquiryRepository {
  OwnerInquiryRepository._();
  static final OwnerInquiryRepository instance = OwnerInquiryRepository._();

  Future<Map<String, dynamic>> submit({
    required String threadId,
    required String listingCode,
    String? listingId,
    required String inquiryType,
    required String seekerQuestion,
    Map<String, dynamic> seekerContext = const {},
  }) async {
    if (!SupabaseService.isReady) {
      throw Exception('offline');
    }

    final res = await SupabaseService.client!.functions.invoke(
      'owner-inquiry-submit',
      body: {
        'thread_id': threadId,
        'listing_code': listingCode,
        if (listingIdForBackend(listingId) != null)
          'listing_id': listingIdForBackend(listingId),
        'inquiry_type': inquiryType,
        'seeker_question': seekerQuestion,
        'seeker_context': seekerContext,
      },
    );

    final data = res.data as Map<String, dynamic>?;
    if (res.status != 200 || data == null || data['error'] != null) {
      throw Exception(data?['error']?.toString() ?? 'submit failed');
    }
    return data;
  }

  Future<void> replyAsOwner({
    required String inquiryId,
    required String replyText,
  }) async {
    if (!SupabaseService.isReady) throw Exception('offline');

    final res = await SupabaseService.client!.functions.invoke(
      'owner-inquiry-reply',
      body: {
        'inquiry_id': inquiryId,
        'reply_text': replyText,
      },
    );

    final data = res.data as Map<String, dynamic>?;
    if (res.status != 200 || data == null || data['error'] != null) {
      throw Exception(data?['error']?.toString() ?? 'reply failed');
    }
  }

  Future<List<OwnerInquiryRow>> listPendingForOwner() async {
    if (!SupabaseService.isReady || !AuthService.instance.isSignedIn) {
      return [];
    }

    final uid = SupabaseService.client!.auth.currentUser!.id;
    final rows = await SupabaseService.client!
        .from('owner_inquiries')
        .select(
          'id, code, thread_id, listing_id, listing_code, inquiry_type, '
          'seeker_question, seeker_context, status, owner_id, created_at',
        )
        .eq('owner_id', uid)
        .eq('status', 'pending_owner')
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((e) => OwnerInquiryRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<OwnerInquiryRow?> fetch(String id) async {
    if (!SupabaseService.isReady) return null;
    final row = await SupabaseService.client!
        .from('owner_inquiries')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return OwnerInquiryRow.fromJson(Map<String, dynamic>.from(row));
  }
}
